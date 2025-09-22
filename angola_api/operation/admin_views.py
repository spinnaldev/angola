from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from django.db.models import Q, Count, Avg
from django.utils import timezone
from datetime import timedelta
from operation.models import User
from django.db.models import Sum
from .models import (
    ClientProject, ProjectOffer, Dispute, Report, 
    Provider, Review, Notification
)
from .serializers import (
    AdminNotificationSerializer, ClientProjectListSerializer, ProjectOfferSerializer,
    DisputeSerializer, ReportSerializer
)
class AdminProjectViewSet(viewsets.ModelViewSet):
    """ViewSet pour l'administration des projets"""
    serializer_class = ClientProjectListSerializer
    permission_classes = [IsAuthenticated, IsAdminUser]
    
    def get_queryset(self):
        queryset = ClientProject.objects.select_related(
            'client', 'category'
        ).prefetch_related(
            'project_offers', 'favorites', 'required_skills'
        ).annotate(
            # Use different names to avoid conflicts with model properties
            total_offers=Count('project_offers'),
            total_favorites=Count('favorites')
            # views_count is already a model field, no annotation needed
        )
        
        # Filtres
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search) |
                Q(description__icontains=search) |
                Q(client__first_name__icontains=search) |
                Q(client__last_name__icontains=search) |
                Q(client__email__icontains=search)
            )
        
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        category_filter = self.request.query_params.get('category')
        if category_filter:
            queryset = queryset.filter(category_id=category_filter)
        
        client_filter = self.request.query_params.get('client')
        if client_filter:
            queryset = queryset.filter(client_id=client_filter)
        
        return queryset.order_by('-created_at')
    
    def list(self, request, *args, **kwargs):
        """Liste des projets avec pagination"""
        queryset = self.get_queryset()
        page = self.paginate_queryset(queryset)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            # Enrichir les données pour l'admin
            for item in serializer.data:
                try:
                    project = ClientProject.objects.get(id=item['id'])
                    item['client_name'] = f"{project.client.first_name} {project.client.last_name}".strip() or project.client.email
                    item['category_name'] = project.category.name if project.category else 'N/A'
                except Exception as e:
                    print(f"Error enriching project {item.get('id')}: {e}")
                    item['client_name'] = 'Utilisateur supprimé'
                    item['category_name'] = 'N/A'
            
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    def retrieve(self, request, *args, **kwargs):
        """Détail d'un projet avec informations enrichies"""
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        
        # Enrichir les données
        data = serializer.data
        try:
            data['client_name'] = f"{instance.client.first_name} {instance.client.last_name}".strip() or instance.client.email
            data['category_name'] = instance.category.name if instance.category else 'N/A'
            # Use the annotated values or fallback to property/count
            data['offers_count'] = getattr(instance, 'total_offers', instance.offers_count)
            data['favorites_count'] = getattr(instance, 'total_favorites', instance.favorites.count())
            # views_count is already available as a model field
        except Exception as e:
            print(f"Error in retrieve: {e}")
            data['client_name'] = 'Utilisateur supprimé'
            data['category_name'] = 'N/A'
        
        return Response(data)
    
    @action(detail=True, methods=['get'])
    def offers(self, request, pk=None):
        """Récupérer les offres d'un projet"""
        project = self.get_object()
        offers = ProjectOffer.objects.filter(project=project).select_related(
            'provider__user'
        ).annotate(
            provider_rating=Avg('provider__reviews_received__overall_rating')
        ).order_by('-created_at')
        
        serializer = ProjectOfferSerializer(offers, many=True)
        
        # Enrichir les données des offres
        for item in serializer.data:
            try:
                offer = ProjectOffer.objects.get(id=item['id'])
                provider = offer.provider
                item['provider_name'] = f"{provider.user.first_name} {provider.user.last_name}".strip() or provider.user.email
                item['provider_rating'] = round(item.get('provider_rating', 0) or 0, 1)
            except Exception as e:
                print(f"Error enriching offer {item.get('id')}: {e}")
                item['provider_name'] = 'Prestataire supprimé'
                item['provider_rating'] = 0
        
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def close(self, request, pk=None):
        """Fermer un projet"""
        project = self.get_object()
        reason = request.data.get('reason', '')
        
        project.status = 'cancelled'
        project.admin_notes = f"{project.admin_notes or ''}\n[{timezone.now().strftime('%Y-%m-%d %H:%M')}] Fermé par admin: {reason}".strip()
        project.save()
        
        # Rejeter toutes les offres en attente
        ProjectOffer.objects.filter(
            project=project, 
            status='pending'
        ).update(status='rejected')
        
        return Response({
            'message': 'Projet fermé avec succès',
            'status': project.status
        })
    
    @action(detail=True, methods=['post'])
    def reopen(self, request, pk=None):
        """Rouvrir un projet"""
        project = self.get_object()
        reason = request.data.get('reason', '')
        
        project.status = 'open'
        project.admin_notes = f"{project.admin_notes or ''}\n[{timezone.now().strftime('%Y-%m-%d %H:%M')}] Réouvert par admin: {reason}".strip()
        project.save()
        
        return Response({
            'message': 'Projet réouvert avec succès',
            'status': project.status
        })
    
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Statistiques des projets"""
        total_projects = ClientProject.objects.count()
        
        stats_by_status = ClientProject.objects.values('status').annotate(
            count=Count('id')
        )
        
        # Statistiques par mois (6 derniers mois)
        six_months_ago = timezone.now() - timedelta(days=180)
        monthly_stats = []
        
        for i in range(6):
            start_date = six_months_ago + timedelta(days=30*i)
            end_date = start_date + timedelta(days=30)
            
            count = ClientProject.objects.filter(
                created_at__gte=start_date,
                created_at__lt=end_date
            ).count()
            
            monthly_stats.append({
                'month': start_date.strftime('%Y-%m'),
                'count': count
            })
        
        # Top catégories
        top_categories = ClientProject.objects.values(
            'category__name'
        ).annotate(
            count=Count('id')
        ).order_by('-count')[:5]
        
        return Response({
            'total_projects': total_projects,
            'by_status': {item['status']: item['count'] for item in stats_by_status},
            'monthly_stats': monthly_stats,
            'top_categories': top_categories
        })
    
class AdminDisputeViewSet(viewsets.ModelViewSet):
    """ViewSet amélioré pour l'administration des litiges"""
    serializer_class = DisputeSerializer
    permission_classes = [IsAuthenticated, IsAdminUser]
    
    def get_queryset(self):
        queryset = Dispute.objects.select_related(
            'client', 'provider__user'
        ).order_by('-created_at')
        
        # Filtres
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        priority_filter = self.request.query_params.get('priority')
        if priority_filter:
            queryset = queryset.filter(priority=priority_filter)
        
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search) |
                Q(description__icontains=search) |
                Q(client__email__icontains=search) |
                Q(provider__user__email__icontains=search)
            )
        
        return queryset
    
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Statistiques des litiges"""
        total_disputes = Dispute.objects.count()
        
        stats_by_status = Dispute.objects.values('status').annotate(
            count=Count('id')
        )
        
        # Litiges par priorité
        stats_by_priority = Dispute.objects.values('priority').annotate(
            count=Count('id')
        )
        
        # Temps moyen de résolution
        resolved_disputes = Dispute.objects.filter(
            status='resolved',
            resolved_at__isnull=False
        )
        
        avg_resolution_time = None
        if resolved_disputes.exists():
            total_time = sum([
                (d.resolved_at - d.created_at).total_seconds() 
                for d in resolved_disputes if d.resolved_at
            ])
            avg_resolution_time = total_time / resolved_disputes.count() / 3600  # en heures
        
        return Response({
            'total_disputes': total_disputes,
            'by_status': {item['status']: item['count'] for item in stats_by_status},
            'by_priority': {item['priority']: item['count'] for item in stats_by_priority},
            'avg_resolution_time_hours': avg_resolution_time
        })


@api_view(['GET'])
@permission_classes([IsAuthenticated, IsAdminUser])
def admin_dashboard_stats(request):
    """Statistiques globales pour le dashboard admin"""
    
    # Compteurs généraux
    total_users = User.objects.count()
    total_providers = Provider.objects.count()
    total_projects = ClientProject.objects.count()
    total_disputes = Dispute.objects.count()
    
    # Nouveaux utilisateurs ce mois
    current_month = timezone.now().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    new_users_this_month = User.objects.filter(
        date_joined__gte=current_month
    ).count()
    
    # Projets actifs
    active_projects = ClientProject.objects.filter(
        status__in=['open', 'in_progress']
    ).count()
    
    # Litiges ouverts
    open_disputes = Dispute.objects.filter(
        status__in=['open', 'under_review']
    ).count()
    
    # Revenus ce mois (simulé - vous devrez adapter selon votre modèle de revenus)
    monthly_revenue = ProjectOffer.objects.filter(
        status='accepted',
        created_at__gte=current_month
    ).aggregate(
        total=Sum('proposed_price')
    )['total'] or 0
    
    # Évolution des inscriptions (6 derniers mois)
    user_registrations = []
    for i in range(6):
        start_date = current_month - timedelta(days=30*i)
        end_date = start_date + timedelta(days=30)
        
        count = User.objects.filter(
            date_joined__gte=start_date,
            date_joined__lt=end_date
        ).count()
        
        user_registrations.append({
            'month': start_date.strftime('%Y-%m'),
            'count': count
        })
    
    user_registrations.reverse()
    
    # Activité récente
    recent_projects = ClientProject.objects.select_related('client').order_by('-created_at')[:5]
    recent_disputes = Dispute.objects.select_related('client').order_by('-created_at')[:5]
    
    return Response({
        'totals': {
            'users': total_users,
            'providers': total_providers,
            'projects': total_projects,
            'disputes': total_disputes
        },
        'this_month': {
            'new_users': new_users_this_month,
            'active_projects': active_projects,
            'open_disputes': open_disputes,
            'revenue': monthly_revenue
        },
        'user_registrations': user_registrations,
        'recent_activity': {
            'projects': [
                {
                    'id': p.id,
                    'title': p.title,
                    'client_name': f"{p.client.first_name} {p.client.last_name}".strip() or p.client.email,
                    'created_at': p.created_at,
                    'status': p.status
                } for p in recent_projects
            ],
            'disputes': [
                {
                    'id': d.id,
                    'title': d.title,
                    'client_name': f"{d.client.first_name} {d.client.last_name}".strip() or d.client.email,
                    'created_at': d.created_at,
                    'status': d.status
                } for d in recent_disputes
            ]
        }
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated, IsAdminUser])
def admin_recent_activity(request):
    """Activité récente pour le dashboard"""
    limit = int(request.GET.get('limit', 10))
    
    # Derniers projets créés
    recent_projects = ClientProject.objects.select_related('client').order_by('-created_at')[:limit]
    
    # Derniers litiges
    recent_disputes = Dispute.objects.select_related('client').order_by('-created_at')[:limit]
    
    # Dernières inscriptions
    recent_users = User.objects.order_by('-date_joined')[:limit]
    
    return Response({
        'projects': [
            {
                'id': p.id,
                'title': p.title,
                'client_name': f"{p.client.first_name} {p.client.last_name}".strip() or p.client.email,
                'created_at': p.created_at,
                'status': p.status,
                'type': 'project'
            } for p in recent_projects
        ],
        'disputes': [
            {
                'id': d.id,
                'title': d.title,
                'client_name': f"{d.client.first_name} {d.client.last_name}".strip() or d.client.email,
                'created_at': d.created_at,
                'status': d.status,
                'type': 'dispute'
            } for d in recent_disputes
        ],
        'users': [
            {
                'id': u.id,
                'name': f"{u.first_name} {u.last_name}".strip() or u.email,
                'email': u.email,
                'date_joined': u.date_joined,
                'is_provider': hasattr(u, 'provider_profile'),
                'type': 'user'
            } for u in recent_users
        ]
    })



from rest_framework.decorators import action
from rest_framework.response import Response
from .models import AdminNotification

class AdminNotificationViewSet(viewsets.ModelViewSet):
    """ViewSet pour les notifications admin"""
    queryset = AdminNotification.objects.all()
    permission_classes = [IsAuthenticated, IsAdminUser]
    
    def get_serializer_class(self):
        # Vous devrez créer AdminNotificationSerializer
        return AdminNotificationSerializer
    
    def get_queryset(self):
        queryset = AdminNotification.objects.all().order_by('-created_at')
        
        # Filtrer par statut de lecture
        is_read = self.request.query_params.get('is_read')
        if is_read is not None:
            queryset = queryset.filter(is_read=is_read.lower() == 'true')
        
        # Filtrer par type
        notification_type = self.request.query_params.get('type')
        if notification_type:
            queryset = queryset.filter(type=notification_type)
        
        # Filtrer par priorité
        priority = self.request.query_params.get('priority')
        if priority:
            queryset = queryset.filter(priority=priority)
        
        return queryset
    
    @action(detail=True, methods=['patch'])
    def mark_read(self, request, pk=None):
        """Marquer une notification comme lue"""
        notification = self.get_object()
        notification.mark_as_read()
        return Response({'status': 'marked_as_read'})
    
    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        """Marquer toutes les notifications comme lues"""
        count = AdminNotification.objects.filter(is_read=False).update(
            is_read=True,
            read_at=timezone.now()
        )
        return Response({'status': f'{count} notifications marked as read'})
    
    @action(detail=False, methods=['get'])
    def unread_count(self, request):
        """Compter les notifications non lues"""
        count = AdminNotification.objects.filter(is_read=False).count()
        return Response({'unread_count': count})
    
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Statistiques des notifications"""
        from django.db.models import Count
        
        stats = AdminNotification.objects.values('type').annotate(
            total=Count('id'),
            unread=Count('id', filter=Q(is_read=False))
        ).order_by('type')
        
        return Response({
            'total_notifications': AdminNotification.objects.count(),
            'unread_notifications': AdminNotification.objects.filter(is_read=False).count(),
            'by_type': list(stats)
        })
