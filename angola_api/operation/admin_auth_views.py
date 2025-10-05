from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from .permissions import IsSuperAdminOnly
from operation.models import User
from django.db import transaction
from django.utils import timezone
from datetime import timedelta
from django.utils import timezone
from datetime import timedelta
from .models import AdminAction, ClientVerification, Conversation, Message, Notification, PhoneVerification, Provider, ProviderVerification, User
from .serializers import ClientVerificationListSerializer, ClientVerificationSerializer, ConversationSerializer, MessageSerializer, NotificationSerializer, PhoneVerificationSerializer, ProviderVerificationAdminSerializer, ProviderVerificationListSerializer, ProviderVerificationSerializer
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from django.db.models import Q, Count, Prefetch
from rest_framework import viewsets, status, filters
from rest_framework.decorators import action, api_view, permission_classes
import logging
from django.db.models import Q, Case, When, IntegerField 
from django_filters.rest_framework import DjangoFilterBackend

logger = logging.getLogger(__name__)

@api_view(['POST'])
@permission_classes([AllowAny])
def admin_login(request):
    """
    Endpoint de connexion spécifique pour les administrateurs
    Vérifie que l'utilisateur est admin (is_staff=True) avant de se connecter
    """
    # Debug de la requête (sans émojis)
    logger.debug("ADMIN LOGIN - Début de la requête")
    logger.debug(f"Method: {request.method}")
    logger.debug(f"User: {request.user}")
    logger.debug(f"Is authenticated: {getattr(request.user, 'is_authenticated', 'N/A')}")
    
    email = request.data.get('email')
    password = request.data.get('password')
    
    logger.debug(f"Email reçu: {email}")
    logger.debug(f"Password reçu: {'*' * len(password) if password else 'None'}")
    
    if not email or not password:
        logger.warning(f"Données manquantes - Email: {email}, Password: {'Oui' if password else 'Non'}")
        return Response({
            'error': 'Email et mot de passe requis',
            'code': 'MISSING_CREDENTIALS'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        # 1. Vérifier si l'utilisateur existe
        logger.debug(f"Recherche de l'utilisateur avec email: {email}")
        try:
            user = User.objects.get(email=email)
            logger.debug(f"Utilisateur trouvé: {user.username} (ID: {user.id})")
            logger.debug(f"Is Staff: {user.is_staff}")
            logger.debug(f"Is Active: {user.is_active}")
            logger.debug(f"Is Superuser: {user.is_superuser}")
        except User.DoesNotExist:
            logger.warning(f"Utilisateur non trouvé avec email: {email}")
            total_users = User.objects.count()
            admin_users = User.objects.filter(is_staff=True).count()
            logger.debug(f"Total utilisateurs: {total_users}, Admins: {admin_users}")
            
            return Response({
                'error': 'Utilisateur non trouvé ou non autorisé',
                'code': 'ADMIN_NOT_FOUND',
                'debug': f'Total users: {total_users}, Admin users: {admin_users}'
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        # 2. Vérifier que l'utilisateur est admin AVANT l'authentification
        if not user.is_staff:
            logger.warning(f"Utilisateur {email} n'est pas staff")
            return Response({
                'error': 'Accès administrateur requis',
                'code': 'NOT_ADMIN'
            }, status=status.HTTP_403_FORBIDDEN)
        
        # 3. Vérifier que le compte est actif
        if not user.is_active:
            logger.warning(f"Compte {email} inactif")
            return Response({
                'error': 'Compte administrateur désactivé',
                'code': 'ACCOUNT_DISABLED'
            }, status=status.HTTP_403_FORBIDDEN)
        
        # 4. Vérifrication du mot de passe DIRECTEMENT (contournement du problème authenticate)
        logger.debug(f"Vérification directe du mot de passe")
        password_is_valid = user.check_password(password)
        logger.debug(f"Password check result: {password_is_valid}")
        
        if not password_is_valid:
            logger.warning(f"Mot de passe incorrect pour {email}")
            return Response({
                'error': 'Email ou mot de passe incorrect',
                'code': 'INVALID_CREDENTIALS'
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        # 5. Tentative d'authentification Django (optionnelle - pour debug)
        logger.debug(f"Tentative d'authentification Django pour: {user.username}")
        authenticated_user = authenticate(username=user.username, password=password)
        logger.debug(f"Django authenticate result: {authenticated_user}")
        
        # Si Django authenticate échoue mais que le mot de passe est correct, 
        # on utilise directement l'utilisateur
        if not authenticated_user:
            logger.warning(f"Django authenticate a échoué mais password check OK - utilisation directe de l'utilisateur")
            authenticated_user = user
        
        logger.debug(f"Utilisateur final pour tokens: {authenticated_user.username}")
        
        # 6. Générer les tokens JWT
        refresh = RefreshToken.for_user(authenticated_user)
        access_token = refresh.access_token
        
        # 7. Ajouter des claims spécifiques admin au token
        access_token['is_admin'] = True
        access_token['user_type'] = 'admin'
        access_token['permissions'] = ['admin_panel', 'manage_users', 'manage_projects', 'manage_disputes']
        
        # 8. Logger la connexion réussie
        logger.info(f"Connexion admin réussie pour: {email}")
        
        # 9. Mettre à jour la dernière connexion
        authenticated_user.last_login = timezone.now()
        authenticated_user.save(update_fields=['last_login'])
        
        response_data = {
            'access': str(access_token),
            'refresh': str(refresh),
            'user': {
                'id': authenticated_user.id,
                'email': authenticated_user.email,
                'username': authenticated_user.username,
                'first_name': authenticated_user.first_name,
                'last_name': authenticated_user.last_name,
                'is_staff': True,
                'is_superuser': authenticated_user.is_superuser,
                'last_login': authenticated_user.last_login,
                'permissions': ['admin_panel', 'manage_users', 'manage_projects', 'manage_disputes']
            },
            'message': 'Connexion administrateur réussie'
        }
        
        logger.debug(f"Réponse prête - Token généré pour user ID: {authenticated_user.id}")
        
        return Response(response_data, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(f"Erreur lors de la connexion admin: {str(e)}", exc_info=True)
        return Response({
            'error': 'Erreur interne du serveur',
            'code': 'INTERNAL_ERROR',
            'debug': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([AllowAny])
def check_admin_status(request):
    """
    Vérifier si un email correspond à un administrateur
    (sans révéler le mot de passe)
    """
    email = request.data.get('email')
    
    if not email:
        return Response({
            'error': 'Email requis'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        user = User.objects.get(email=email)
        is_admin = user.is_staff and user.is_active
        
        return Response({
            'is_admin': is_admin,
            'email': email,
            'exists': True
        })
        
    except User.DoesNotExist:
        return Response({
            'is_admin': False,
            'email': email,
            'exists': False
        })


@api_view(['GET'])
@permission_classes([AllowAny])  # Endpoint public pour vérification initiale
def admin_setup_status(request):
    """
    Vérifier si l'admin par défaut existe
    """
    admin_exists = User.objects.filter(
        email='admin@gmail.com',
        is_staff=True
    ).exists()
    
    total_admins = User.objects.filter(is_staff=True).count()
    
    return Response({
        'default_admin_exists': admin_exists,
        'total_admins': total_admins,
        'setup_required': not admin_exists
    })


# Test endpoint pour debug
@api_view(['GET', 'POST'])
@permission_classes([AllowAny])
def test_auth_debug(request):
    """
    Endpoint de test pour débugger l'authentification
    """
    return Response({
        'method': request.method,
        'user': str(request.user),
        'is_authenticated': getattr(request.user, 'is_authenticated', False),
        'headers': dict(request.headers),
        'data': request.data if request.method == 'POST' else None,
        'get_params': dict(request.GET),
    })


@api_view(['POST'])
@permission_classes([AllowAny])
def check_admin_status(request):
    """
    Vérifier si un email correspond à un administrateur
    (sans révéler le mot de passe)
    """
    email = request.data.get('email')
    
    if not email:
        return Response({
            'error': 'Email requis'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        user = User.objects.get(email=email)
        is_admin = user.is_staff and user.is_active
        
        return Response({
            'is_admin': is_admin,
            'email': email,
            'exists': True
        })
        
    except User.DoesNotExist:
        return Response({
            'is_admin': False,
            'email': email,
            'exists': False
        })


@api_view(['GET'])
@permission_classes([AllowAny])  # Endpoint public pour vérification initiale
def admin_setup_status(request):
    """
    Vérifier si l'admin par défaut existe
    """
    admin_exists = User.objects.filter(
        email='admin@gmail.com',
        is_staff=True
    ).exists()
    
    total_admins = User.objects.filter(is_staff=True).count()
    
    return Response({
        'default_admin_exists': admin_exists,
        'total_admins': total_admins,
        'setup_required': not admin_exists
    })


# angola_api/operation/admin_auth_serializers.py - Serializers pour l'admin

from rest_framework import serializers
from operation.models import User

class AdminLoginSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)
    password = serializers.CharField(required=True, write_only=True)
    
    def validate_email(self, value):
        if not value:
            raise serializers.ValidationError("L'email est requis")
        return value.lower()
    
    def validate_password(self, value):
        if len(value) < 6:
            raise serializers.ValidationError("Le mot de passe doit contenir au moins 6 caractères")
        return value


class AdminUserSerializer(serializers.ModelSerializer):
    full_name = serializers.SerializerMethodField()
    permissions = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name', 'full_name',
            'is_staff', 'is_superuser', 'is_active', 'last_login', 'date_joined',
            'permissions'
        ]
        read_only_fields = ['id', 'date_joined', 'last_login']
    
    def get_full_name(self, obj):
        return f"{obj.first_name} {obj.last_name}".strip() or obj.username
    
    def get_permissions(self, obj):
        if obj.is_superuser:
            return ['admin_panel', 'manage_users', 'manage_projects', 'manage_disputes', 'system_settings']
        elif obj.is_staff:
            return ['admin_panel', 'manage_projects', 'manage_disputes']
        else:
            return []
        

#*************** MESSAGERIE ******************************
class AdminConversationViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour l'administration des conversations
    """
    serializer_class = ConversationSerializer
    permission_classes = [IsAuthenticated, IsAdminUser]
    
    def get_queryset(self):
        queryset = Conversation.objects.select_related(
            'client', 'provider__user'
        ).prefetch_related('messages')
        
        # Filtres de base
        print("on a donc:")
        print(queryset)
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(client__username__icontains=search) |
                Q(client__email__icontains=search) |
                Q(provider__user__username__icontains=search) |
                Q(provider__user__email__icontains=search)
            )
        
        return queryset.order_by('-updated_at')
    
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """
        Statistiques sur les conversations
        """
        try:
            total_conversations = Conversation.objects.count()
            conversations_with_unread = Conversation.objects.filter(
                messages__is_read=False
            ).distinct().count()
            
            # Conversations récentes (dernières 24h)
            recent_conversations = Conversation.objects.filter(
                updated_at__gte=timezone.now() - timedelta(days=1)
            ).count()
            
            # Messages totaux
            total_messages = Message.objects.count()
            unread_messages = Message.objects.filter(is_read=False).count()
            
            return Response({
                'total_conversations': total_conversations,
                'conversations_with_unread': conversations_with_unread,
                'recent_conversations': recent_conversations,
                'total_messages': total_messages,
                'unread_messages': unread_messages,
                'active_users': []  # Simplifié pour l'instant
            })
        except Exception as e:
            logger.error(f"Erreur dans stats: {e}")
            return Response({
                'total_conversations': 0,
                'conversations_with_unread': 0,
                'recent_conversations': 0,
                'total_messages': 0,
                'unread_messages': 0,
                'active_users': []
            })
    
    @action(detail=True, methods=['get'])
    def messages(self, request, pk=None):
        """
        Récupérer tous les messages d'une conversation
        """
        try:
            conversation = self.get_object()
            messages = conversation.messages.select_related('sender').order_by('created_at')
            
            serializer = MessageSerializer(messages, many=True)
            return Response(serializer.data)
        except Exception as e:
            logger.error(f"Erreur messages: {e}")
            return Response([])
    
    @action(detail=True, methods=['post'])
    def mark_all_read(self, request, pk=None):
        """
        Marquer tous les messages d'une conversation comme lus
        """
        try:
            conversation = self.get_object()
            unread_count = conversation.messages.filter(is_read=False).update(is_read=True)
            
            return Response({
                'success': True,
                'marked_count': unread_count,
                'message': f'{unread_count} messages marqués comme lus'
            })
        except Exception as e:
            logger.error(f"Erreur mark_all_read: {e}")
            return Response({
                'success': False,
                'message': 'Erreur lors du marquage'
            }, status=500)
    
    @action(detail=True, methods=['post'])
    def add_admin_message(self, request, pk=None):
        """
        Ajouter un message de la part de l'admin dans la conversation
        """
        try:
            conversation = self.get_object()
            content = request.data.get('content')
            
            if not content:
                return Response({
                    'error': 'Le contenu du message est requis'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Créer le message admin
            message = Message.objects.create(
                conversation=conversation,
                sender=request.user,
                content=f"[MESSAGE ADMIN] {content}",
                is_read=False
            )
            
            serializer = MessageSerializer(message)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        except Exception as e:
            logger.error(f"Erreur add_admin_message: {e}")
            return Response({
                'error': 'Erreur lors de l\'ajout du message'
            }, status=500)


@api_view(['GET'])
@permission_classes([IsAuthenticated, IsAdminUser])
def conversation_overview(request):
    """
    Vue d'ensemble des conversations pour le dashboard admin
    """
    try:
        total = Conversation.objects.count()
        with_unread = Conversation.objects.filter(messages__is_read=False).distinct().count()
        recent = Conversation.objects.filter(
            updated_at__gte=timezone.now() - timedelta(hours=24)
        ).count()
        
        return Response({
            'conversations': {
                'total': total,
                'with_unread': with_unread,
                'recent_24h': recent
            }
        })
    except Exception as e:
        logger.error(f"Erreur conversation_overview: {e}")
        return Response({
            'conversations': {
                'total': 0,
                'with_unread': 0,
                'recent_24h': 0
            }
        })


@api_view(['DELETE'])
@permission_classes([IsAuthenticated, IsAdminUser])
def delete_message(request, message_id):
    """
    Supprimer un message spécifique
    """
    try:
        message = Message.objects.get(id=message_id)
        message.delete()
        
        return Response({
            'success': True,
            'message': 'Message supprimé'
        })
    except Message.DoesNotExist:
        return Response({
            'error': 'Message non trouvé'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        logger.error(f"Erreur delete_message: {e}")
        return Response({
            'error': 'Erreur lors de la suppression'
        }, status=500)


@api_view(['POST'])
@permission_classes([IsAuthenticated, IsAdminUser])
def bulk_mark_read(request):
    """
    Marquer plusieurs conversations comme lues
    """
    try:
        conversation_ids = request.data.get('conversation_ids', [])
        
        if not conversation_ids:
            return Response({
                'error': 'Liste des IDs de conversations requise'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        updated_count = Message.objects.filter(
            conversation_id__in=conversation_ids,
            is_read=False
        ).update(is_read=True)
        
        return Response({
            'success': True,
            'updated_count': updated_count,
            'conversation_count': len(conversation_ids)
        })
    except Exception as e:
        logger.error(f"Erreur bulk_mark_read: {e}")
        return Response({
            'error': 'Erreur lors du marquage en lot'
        }, status=500)
    




# *******************NOTIFICATIONS **************************

# class AdminNotificationViewSet(viewsets.ModelViewSet):
#     queryset = Notification.objects.all()
#     serializer_class = NotificationSerializer
#     permission_classes = [IsAuthenticated, IsAdminUser]
    
#     @action(detail=False, methods=['get'])
#     def stats(self, request):
#         total = Notification.objects.count()
#         unread = Notification.objects.filter(is_read=False).count()
#         recent = Notification.objects.filter(
#             created_at__gte=timezone.now() - timedelta(days=1)
#         ).count()
        
#         return Response({
#             'total': total,
#             'unread': unread,
#             'recent': recent,
#             'activeUsers': User.objects.filter(
#                 notifications__created_at__gte=timezone.now() - timedelta(days=7)
#             ).distinct().count()
#         })

@api_view(['POST'])
@permission_classes([IsAuthenticated, IsAdminUser])
def send_notification_to_user(request):
    user_id = request.data.get('user_id')
    title = request.data.get('title')
    message = request.data.get('message')
    notification_type = request.data.get('notification_type', 'system')
    
    try:
        user = User.objects.get(id=user_id)
        notification = Notification.objects.create(
            user=user,
            title=title,
            message=message,
            notification_type=notification_type
        )
        return Response(NotificationSerializer(notification).data)
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=404)

@api_view(['POST'])
@permission_classes([IsAuthenticated, IsAdminUser])
def broadcast_notification(request):
    title = request.data.get('title')
    message = request.data.get('message')
    notification_type = request.data.get('notification_type', 'system')
    
    users = User.objects.filter(is_active=True)
    notifications = []
    
    for user in users:
        notifications.append(Notification(
            user=user,
            title=title,
            message=message,
            notification_type=notification_type
        ))
    
    Notification.objects.bulk_create(notifications)
    return Response({'count': len(notifications), 'message': 'Notifications envoyées'})





# ================================================================
# 2. VIEWSET ADMIN POUR VÉRIFICATION DES PRESTATAIRES
# ================================================================

class AdminProviderVerificationViewSet(viewsets.ModelViewSet):
    """
    ViewSet admin pour gérer toutes les vérifications de prestataires
    
    Endpoints disponibles pour les admins:
    - GET /admin/provider-verification/ : Liste de toutes les vérifications
    - GET /admin/provider-verification/{id}/ : Détail d'une vérification
    - PUT/PATCH /admin/provider-verification/{id}/ : Modifier une vérification
    
    Actions personnalisées:
    - GET /admin/provider-verification/pending/ : Vérifications en attente
    - GET /admin/provider-verification/statistics/ : Statistiques globales
    - POST /admin/provider-verification/{id}/approve/ : Approuver
    - POST /admin/provider-verification/{id}/reject/ : Rejeter
    - POST /admin/provider-verification/bulk-approve/ : Approbation en lot
    - POST /admin/provider-verification/bulk-reject/ : Rejet en lot
    """
    
    queryset = ProviderVerification.objects.all().select_related(
        'provider__user', 'verified_by'
    ).order_by('-created_at')
    
    # permission_classes = [IsAdminUser]
    
    def get_serializer_class(self):
        """Choisir le serializer selon l'action"""
        if self.action == 'list':
            return ProviderVerificationListSerializer
        elif self.action in ['approve', 'reject', 'bulk_approve', 'bulk_reject']:
            return ProviderVerificationAdminSerializer
        return ProviderVerificationSerializer
    
    def get_queryset(self):
        """Filtrage avancé pour les admins"""
        queryset = super().get_queryset()
        
        # Filtres par paramètres GET
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(verification_status=status_filter)
        
        business_filter = self.request.query_params.get('is_business')
        if business_filter is not None:
            is_business = business_filter.lower() == 'true'
            queryset = queryset.filter(is_business=is_business)
        
        # Filtre par période
        days_filter = self.request.query_params.get('days')
        if days_filter:
            try:
                days = int(days_filter)
                date_threshold = timezone.now() - timedelta(days=days)
                queryset = queryset.filter(submitted_at__gte=date_threshold)
            except ValueError:
                pass
        
        # Recherche par nom/email
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(provider__user__username__icontains=search) |
                Q(provider__user__email__icontains=search) |
                Q(provider__user__first_name__icontains=search) |
                Q(provider__user__last_name__icontains=search) |
                Q(provider__company_name__icontains=search)
            )
        
        return queryset
    
    @action(detail=False, methods=['get'], url_path='pending')
    def pending(self, request):
        """
        Récupérer toutes les vérifications en attente
        Triées par date de soumission (plus anciennes en premier)
        """
        pending_verifications = self.get_queryset().filter(
            verification_status='pending'
        ).order_by('submitted_at')
        
        serializer = ProviderVerificationListSerializer(
            pending_verifications, 
            many=True,
            context={'request': request}
        )
        
        return Response({
            'count': pending_verifications.count(),
            'results': serializer.data
        })
    
    @action(detail=False, methods=['get'], url_path='statistics')
    def statistics(self, request):
        """
        Statistiques complètes des vérifications prestataires
        """
        # Compter par statut
        status_counts = ProviderVerification.objects.aggregate(
            total=Count('id'),
            pending=Count(Case(When(verification_status='pending', then=1), 
                              output_field=IntegerField())),
            verified=Count(Case(When(verification_status='verified', then=1), 
                               output_field=IntegerField())),
            rejected=Count(Case(When(verification_status='rejected', then=1), 
                               output_field=IntegerField())),
            not_started=Count(Case(When(verification_status='not_started', then=1), 
                                  output_field=IntegerField()))
        )
        
        # Compter par type (entreprise/particulier)
        type_counts = ProviderVerification.objects.aggregate(
            businesses=Count(Case(When(is_business=True, then=1), 
                                 output_field=IntegerField())),
            individuals=Count(Case(When(is_business=False, then=1), 
                                  output_field=IntegerField()))
        )
        
        # Statistiques temporelles (30 derniers jours)
        thirty_days_ago = timezone.now() - timedelta(days=30)
        recent_stats = ProviderVerification.objects.filter(
            submitted_at__gte=thirty_days_ago
        ).aggregate(
            recent_submissions=Count('id'),
            recent_approvals=Count(Case(When(
                verification_status='verified',
                verified_at__gte=thirty_days_ago,
                then=1
            ), output_field=IntegerField()))
        )
        
        # Temps moyen d'approbation
        approved_verifications = ProviderVerification.objects.filter(
            verification_status='verified',
            submitted_at__isnull=False,
            verified_at__isnull=False
        )
        
        avg_approval_time = None
        if approved_verifications.exists():
            total_time = 0
            count = 0
            for verification in approved_verifications:
                if verification.submitted_at and verification.verified_at:
                    time_diff = verification.verified_at - verification.submitted_at
                    total_time += time_diff.total_seconds()
                    count += 1
            
            if count > 0:
                avg_approval_time = total_time / count / 3600  # en heures
        
        # Vérifications urgentes (en attente depuis plus de 7 jours)
        urgent_threshold = timezone.now() - timedelta(days=7)
        urgent_count = ProviderVerification.objects.filter(
            verification_status='pending',
            submitted_at__lte=urgent_threshold
        ).count()
        
        return Response({
            'status_distribution': status_counts,
            'type_distribution': type_counts,
            'recent_activity': recent_stats,
            'average_approval_time_hours': avg_approval_time,
            'urgent_verifications': urgent_count,
            'total_providers': Provider.objects.count(),
            'verified_providers': Provider.objects.filter(is_verified=True).count()
        })
    
    @action(detail=True, methods=['post'], url_path='approve')
    def approve(self, request, pk=None):
        """
        Approuver une vérification de prestataire
        
        Données optionnelles:
        - admin_notes: Notes administratives
        """
        verification = self.get_object()
        
        if verification.verification_status == 'verified':
            return Response({
                'detail': 'Cette vérification est déjà approuvée'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        with transaction.atomic():
            # Mettre à jour la vérification
            verification.verification_status = 'verified'
            verification.verified_by = request.user
            verification.verified_at = timezone.now()
            verification.rejection_reason = ''  # Effacer raison rejet précédente
            
            # Ajouter notes admin si fournies
            admin_notes = request.data.get('admin_notes', '')
            if admin_notes:
                existing_notes = verification.admin_notes or ''
                timestamp = timezone.now().strftime('%Y-%m-%d %H:%M')
                new_note = f"[{timestamp} - {request.user.username}] {admin_notes}"
                verification.admin_notes = f"{existing_notes}\n{new_note}".strip()
            
            verification.save()
            
            # Logger l'action
            AdminAction.objects.create(
                admin_user=request.user,
                action_type='provider_verification_approve',
                target_model='ProviderVerification',
                target_id=verification.id,
                description=f"Vérification approuvée pour {verification.provider.user.username}",
                new_value={'status': 'verified', 'admin_notes': verification.admin_notes}
            )
            
            logger.info(f"Vérification approuvée par {request.user.username} pour {verification.provider.user.username}")
        
        serializer = self.get_serializer(verification)
        return Response({
            'message': 'Vérification approuvée avec succès',
            'verification': serializer.data
        })
    
    @action(detail=True, methods=['post'], url_path='reject')
    def reject(self, request, pk=None):
        """
        Rejeter une vérification de prestataire
        
        Données requises:
        - rejection_reason: Raison du rejet
        
        Données optionnelles:
        - admin_notes: Notes administratives supplémentaires
        """
        verification = self.get_object()
        rejection_reason = request.data.get('rejection_reason', '').strip()
        
        if not rejection_reason:
            return Response({
                'detail': 'La raison du rejet est requise'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if verification.verification_status == 'rejected':
            return Response({
                'detail': 'Cette vérification est déjà rejetée'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        with transaction.atomic():
            # Mettre à jour la vérification
            verification.verification_status = 'rejected'
            verification.verified_by = request.user
            verification.verified_at = None
            verification.rejection_reason = rejection_reason
            
            # Ajouter notes admin si fournies
            admin_notes = request.data.get('admin_notes', '')
            if admin_notes:
                existing_notes = verification.admin_notes or ''
                timestamp = timezone.now().strftime('%Y-%m-%d %H:%M')
                new_note = f"[{timestamp} - {request.user.username}] {admin_notes}"
                verification.admin_notes = f"{existing_notes}\n{new_note}".strip()
            
            verification.save()
            
            # Logger l'action
            AdminAction.objects.create(
                admin_user=request.user,
                action_type='provider_verification_reject',
                target_model='ProviderVerification',
                target_id=verification.id,
                description=f"Vérification rejetée pour {verification.provider.user.username}: {rejection_reason}",
                new_value={'status': 'rejected', 'rejection_reason': rejection_reason}
            )
            
            logger.info(f"Vérification rejetée par {request.user.username} pour {verification.provider.user.username}")
        
        serializer = self.get_serializer(verification)
        return Response({
            'message': 'Vérification rejetée avec succès',
            'verification': serializer.data
        })
    
    @action(detail=False, methods=['post'], url_path='bulk-approve')
    def bulk_approve(self, request):
        """
        Approuver plusieurs vérifications en lot
        
        Données requises:
        - verification_ids: Liste des IDs à approuver
        
        Données optionnelles:
        - admin_notes: Notes appliquées à toutes les vérifications
        """
        verification_ids = request.data.get('verification_ids', [])
        admin_notes = request.data.get('admin_notes', '')
        
        if not verification_ids:
            return Response({
                'detail': 'Liste des vérifications requise'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Filtrer les vérifications modifiables
        verifications = ProviderVerification.objects.filter(
            id__in=verification_ids,
            verification_status__in=['pending', 'rejected']
        )
        
        if not verifications.exists():
            return Response({
                'detail': 'Aucune vérification valide trouvée'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        approved_count = 0
        errors = []
        
        with transaction.atomic():
            for verification in verifications:
                try:
                    # Mettre à jour
                    verification.verification_status = 'verified'
                    verification.verified_by = request.user
                    verification.verified_at = timezone.now()
                    verification.rejection_reason = ''
                    
                    # Ajouter notes si fournies
                    if admin_notes:
                        existing_notes = verification.admin_notes or ''
                        timestamp = timezone.now().strftime('%Y-%m-%d %H:%M')
                        new_note = f"[{timestamp} - {request.user.username}] {admin_notes}"
                        verification.admin_notes = f"{existing_notes}\n{new_note}".strip()
                    
                    verification.save()
                    
                    # Logger
                    AdminAction.objects.create(
                        admin_user=request.user,
                        action_type='verification_bulk_action',
                        target_model='ProviderVerification',
                        target_id=verification.id,
                        description=f"Approbation en lot pour {verification.provider.user.username}"
                    )
                    
                    approved_count += 1
                    
                except Exception as e:
                    errors.append({
                        'verification_id': verification.id,
                        'error': str(e)
                    })
        
        logger.info(f"Approbation en lot par {request.user.username}: {approved_count} vérifications approuvées")
        
        return Response({
            'message': f'{approved_count} vérifications approuvées avec succès',
            'approved_count': approved_count,
            'errors': errors
        })
    
    @action(detail=False, methods=['post'], url_path='bulk-reject')
    def bulk_reject(self, request):
        """
        Rejeter plusieurs vérifications en lot
        
        Données requises:
        - verification_ids: Liste des IDs à rejeter
        - rejection_reason: Raison du rejet (commune à toutes)
        """
        verification_ids = request.data.get('verification_ids', [])
        rejection_reason = request.data.get('rejection_reason', '').strip()
        admin_notes = request.data.get('admin_notes', '')
        
        if not verification_ids:
            return Response({
                'detail': 'Liste des vérifications requise'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if not rejection_reason:
            return Response({
                'detail': 'Raison du rejet requise'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Filtrer les vérifications modifiables
        verifications = ProviderVerification.objects.filter(
            id__in=verification_ids,
            verification_status__in=['pending', 'verified']
        )
        
        rejected_count = 0
        errors = []
        
        with transaction.atomic():
            for verification in verifications:
                try:
                    verification.verification_status = 'rejected'
                    verification.verified_by = request.user
                    verification.verified_at = None
                    verification.rejection_reason = rejection_reason
                    
                    if admin_notes:
                        existing_notes = verification.admin_notes or ''
                        timestamp = timezone.now().strftime('%Y-%m-%d %H:%M')
                        new_note = f"[{timestamp} - {request.user.username}] {admin_notes}"
                        verification.admin_notes = f"{existing_notes}\n{new_note}".strip()
                    
                    verification.save()
                    
                    AdminAction.objects.create(
                        admin_user=request.user,
                        action_type='verification_bulk_action',
                        target_model='ProviderVerification',
                        target_id=verification.id,
                        description=f"Rejet en lot pour {verification.provider.user.username}: {rejection_reason}"
                    )
                    
                    rejected_count += 1
                    
                except Exception as e:
                    errors.append({
                        'verification_id': verification.id,
                        'error': str(e)
                    })
        
        logger.info(f"Rejet en lot par {request.user.username}: {rejected_count} vérifications rejetées")
        
        return Response({
            'message': f'{rejected_count} vérifications rejetées avec succès',
            'rejected_count': rejected_count,
            'errors': errors
        })


# ================================================================
# 3. VIEWSET ADMIN POUR VÉRIFICATION DES CLIENTS
# ================================================================



class AdminClientVerificationViewSet(viewsets.ModelViewSet):
    """
    ViewSet Admin pour gérer les vérifications de CLIENTS
    SÉPARÉ des vérifications de prestataires
    """
    
    queryset = ClientVerification.objects.all()
    serializer_class = ClientVerificationSerializer
    permission_classes = [IsAdminUser]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    
    filterset_fields = ['verification_status', 'document_type', 'user__username']
    search_fields = ['user__username', 'user__email', 'user__first_name', 'user__last_name']
    ordering_fields = ['submitted_at', 'verified_at', 'created_at']
    ordering = ['-submitted_at']
    
    def get_serializer_class(self):
        """Utiliser un serializer allégé pour les listes"""
        if self.action == 'list':
            return ClientVerificationListSerializer
        return ClientVerificationSerializer
    
    def list(self, request, *args, **kwargs):
        """Liste avec pagination"""
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def pending(self, request):
        """Liste des vérifications clients EN ATTENTE"""
        pending_verifications = self.get_queryset().filter(verification_status='pending')
        serializer = ClientVerificationListSerializer(pending_verifications, many=True)
        
        return Response({
            'count': pending_verifications.count(),
            'results': serializer.data
        })
    
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Statistiques des vérifications clients pour le dashboard admin"""
        queryset = self.get_queryset()
        
        stats = {
            'total': queryset.count(),
            'pending': queryset.filter(verification_status='pending').count(),
            'verified': queryset.filter(verification_status='verified').count(),
            'rejected': queryset.filter(verification_status='rejected').count(),
            'not_started': queryset.filter(verification_status='not_started').count(),
            'recent': queryset.filter(submitted_at__gte=timezone.now() - timedelta(days=7)).count(),
            'urgent': queryset.filter(
                verification_status='pending',
                submitted_at__lte=timezone.now() - timedelta(days=7)
            ).count(),
        }
        
        return Response(stats)
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """
        ✅ APPROUVER une vérification client
        """
        verification = self.get_object()
        
        if verification.verification_status == 'verified':
            return Response({
                'detail': 'Cette vérification est déjà approuvée'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Approuver la vérification
        verification.verification_status = 'verified'
        verification.verified_by = request.user
        verification.verified_at = timezone.now()
        verification.rejection_reason = ''
        verification.save()
        
        # Mettre à jour le statut utilisateur
        verification.user.is_verified = True
        verification.user.save()
        
        # Logger l'action admin
        AdminAction.objects.create(
            admin_user=request.user,
            action_type='client_verification_approved',
            target_model='ClientVerification',
            target_id=verification.id,
            description=f"Vérification client approuvée pour {verification.user.username}"
        )
        
        logger.info(f"✅ Vérification client approuvée par {request.user.username} pour {verification.user.username}")
        
        # ✅ CORRECTION : Envoyer une notification FCM au client
        try:
            from .fcm_service import FCMService
            
            # Envoyer via FCM
            fcm_success = FCMService.send_notification_to_user(
                user=verification.user.id,
                title="Compte vérifié ! ✅",
                body="Votre compte a été vérifié avec succès. Vous pouvez maintenant utiliser toutes les fonctionnalités de l'application.",
                notification_type='client_verification_approved',
                data={
                    'type': 'client_verification_approved',
                    'verification_id': verification.id,
                    'click_action': 'PROFILE'
                },
                click_action='FLUTTER_NOTIFICATION_CLICK'
            )
            
            if fcm_success:
                logger.info(f"✅ Notification FCM envoyée au client {verification.user.username}")
            else:
                logger.warning(f"⚠️ Échec envoi notification FCM au client {verification.user.username}")
                
        except Exception as e:
            logger.error(f"❌ Erreur envoi notification FCM : {e}")
            import traceback
            logger.error(f"Traceback: {traceback.format_exc()}")
        
        serializer = self.get_serializer(verification)
        return Response({
            'message': 'Vérification client approuvée avec succès',
            'verification': serializer.data
        })

    
    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """
        ❌ REJETER une vérification client
        """
        verification = self.get_object()
        rejection_reason = request.data.get('rejection_reason', '').strip()
        
        if not rejection_reason:
            return Response({
                'detail': 'La raison du rejet est requise'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if verification.verification_status == 'rejected':
            return Response({
                'detail': 'Cette vérification est déjà rejetée'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Rejeter la vérification
        verification.verification_status = 'rejected'
        verification.verified_by = request.user
        verification.verified_at = None
        verification.rejection_reason = rejection_reason
        
        # Ajouter notes admin si fournies
        admin_notes = request.data.get('admin_notes', '')
        if admin_notes:
            existing_notes = verification.admin_notes or ''
            timestamp = timezone.now().strftime('%Y-%m-%d %H:%M')
            new_note = f"[{timestamp} - {request.user.username}] {admin_notes}"
            verification.admin_notes = f"{existing_notes}\n{new_note}".strip()
        
        verification.save()
        
        # Mettre à jour le statut utilisateur
        verification.user.is_verified = False
        verification.user.save()
        
        # Logger l'action admin
        AdminAction.objects.create(
            admin_user=request.user,
            action_type='client_verification_rejected',
            target_model='ClientVerification',
            target_id=verification.id,
            description=f"Vérification client rejetée pour {verification.user.username}: {rejection_reason}"
        )
        
        logger.info(f"❌ Vérification client rejetée par {request.user.username} pour {verification.user.username}")
        
        # ✅ CORRECTION : Envoyer une notification FCM au client
        try:
            from .fcm_service import FCMService
            
            # Envoyer via FCM
            fcm_success = FCMService.send_notification_to_user(
                user=verification.user.id,
                title="Vérification rejetée ❌",
                body=f"Votre demande de vérification a été rejetée. Raison : {rejection_reason}",
                notification_type='client_verification_rejected',
                data={
                    'type': 'client_verification_rejected',
                    'verification_id': verification.id,
                    'rejection_reason': rejection_reason,
                    'click_action': 'CLIENT_VERIFICATION'
                },
                click_action='FLUTTER_NOTIFICATION_CLICK'
            )
            
            if fcm_success:
                logger.info(f"✅ Notification FCM rejet envoyée au client {verification.user.username}")
            else:
                logger.warning(f"⚠️ Échec envoi notification FCM rejet au client {verification.user.username}")
                
        except Exception as e:
            logger.error(f"❌ Erreur envoi notification FCM rejet : {e}")
            import traceback
            logger.error(f"Traceback: {traceback.format_exc()}")
        
        serializer = self.get_serializer(verification)
        return Response({
            'message': 'Vérification client rejetée',
            'verification': serializer.data
        })

    
    @action(detail=True, methods=['post'])
    def reset(self, request, pk=None):
        """
        🔄 RÉINITIALISER une vérification client
        """
        verification = self.get_object()
        
        if verification.verification_status == 'verified':
            return Response({
                'detail': 'Impossible de réinitialiser une vérification approuvée'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Réinitialiser
        verification.verification_status = 'not_started'
        verification.rejection_reason = ''
        verification.verified_by = None
        verification.verified_at = None
        verification.submitted_at = None
        verification.save()
        
        # Mettre à jour le statut utilisateur
        verification.user.is_verified = False
        verification.user.save()
        
        # Logger l'action admin
        AdminAction.objects.create(
            admin_user=request.user,
            action_type='client_verification_reset',
            target_model='ClientVerification',
            target_id=verification.id,
            description=f"Vérification client réinitialisée pour {verification.user.username}"
        )
        
        logger.info(f"🔄 Vérification client réinitialisée par {request.user.username} pour {verification.user.username}")
        
        serializer = self.get_serializer(verification)
        return Response({
            'message': 'Vérification client réinitialisée avec succès',
            'verification': serializer.data
        })
    
    @action(detail=True, methods=['patch'])
    def add_notes(self, request, pk=None):
        """
        📝 Ajouter des notes administratives
        """
        verification = self.get_object()
        admin_notes = request.data.get('admin_notes', '')
        
        verification.admin_notes = admin_notes
        verification.save()
        
        serializer = self.get_serializer(verification)
        return Response({
            'message': 'Notes ajoutées avec succès',
            'verification': serializer.data
        })
    
class AdminPhoneVerificationViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet admin pour consulter les vérifications téléphone
    (lecture seule - pas de modification des vérifications téléphone par les admins)
    
    Actions personnalisées:
    - GET /admin/phone-verification/statistics/ : Statistiques des vérifications téléphone
    - POST /admin/phone-verification/{id}/reset/ : Réinitialiser une vérification
    """
    
    queryset = PhoneVerification.objects.all().select_related('user').order_by('-created_at')
    serializer_class = PhoneVerificationSerializer
    # permission_classes = [IsAdminUser]
    
    def get_queryset(self):
        """Filtrage pour les admins"""
        queryset = super().get_queryset()
        
        # Filtre par statut
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        # Recherche par utilisateur
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(user__username__icontains=search) |
                Q(user__email__icontains=search) |
                Q(phone_number__icontains=search)
            )
        
        return queryset
    
    @action(detail=False, methods=['get'], url_path='statistics')
    def statistics(self, request):
        """Statistiques des vérifications téléphone"""
        
        # Compter par statut
        status_counts = PhoneVerification.objects.aggregate(
            total=Count('id'),
            verified=Count(Case(When(status='verified', then=1), 
                               output_field=IntegerField())),
            pending=Count(Case(When(status='pending', then=1), 
                              output_field=IntegerField())),
            expired=Count(Case(When(status='expired', then=1), 
                              output_field=IntegerField())),
            failed=Count(Case(When(status='failed', then=1), 
                             output_field=IntegerField()))
        )
        
        # Taux de succès
        total_attempts = PhoneVerification.objects.count()
        success_rate = 0
        if total_attempts > 0:
            success_rate = (status_counts['verified'] / total_attempts) * 100
        
        # Statistiques temporelles
        thirty_days_ago = timezone.now() - timedelta(days=30)
        recent_verifications = PhoneVerification.objects.filter(
            created_at__gte=thirty_days_ago
        ).count()
        
        return Response({
            'status_distribution': status_counts,
            'success_rate_percentage': round(success_rate, 2),
            'recent_verifications_30_days': recent_verifications,
            'total_users': User.objects.filter(role='client').count(),
            'verified_users': User.objects.filter(
                role='client',
                phone_verification__status='verified'
            ).count()
        })
    
    @action(detail=True, methods=['post'], url_path='reset')
    def reset(self, request, pk=None):
        """
        Réinitialiser une vérification téléphone
        Permet à l'utilisateur de recommencer le processus
        """
        verification = self.get_object()
        
        if verification.status == 'verified':
            return Response({
                'detail': 'Impossible de réinitialiser une vérification approuvée'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Réinitialiser
        verification.status = 'pending'
        verification.attempts = 0
        verification.verification_code = PhoneVerification.generate_code()
        verification.expires_at = timezone.now() + timedelta(minutes=10)
        verification.last_code_sent_at = timezone.now()
        verification.save()
        
        # Mettre à jour le statut utilisateur
        verification.user.is_verified = False
        verification.user.save()
        
        # Logger l'action
        AdminAction.objects.create(
            admin_user=request.user,
            action_type='phone_verification_reset',
            target_model='PhoneVerification',
            target_id=verification.id,
            description=f"Vérification téléphone réinitialisée pour {verification.user.username}"
        )
        
        logger.info(f"Vérification téléphone réinitialisée par {request.user.username} pour {verification.user.username}")
        
        serializer = self.get_serializer(verification)
        return Response({
            'message': 'Vérification téléphone réinitialisée avec succès',
            'verification': serializer.data
        })


# ================================================================
# 4. DASHBOARD ET STATISTIQUES GLOBALES
# ================================================================

@api_view(['GET'])
# @permission_classes([IsAdminUser])
def verification_dashboard(request):
    """
    Dashboard global des vérifications pour les admins
    Vue d'ensemble de tous les types de vérifications
    """
    
    # Statistiques prestataires
    provider_stats = ProviderVerification.objects.aggregate(
        total=Count('id'),
        pending=Count(Case(When(verification_status='pending', then=1), 
                          output_field=IntegerField())),
        verified=Count(Case(When(verification_status='verified', then=1), 
                           output_field=IntegerField())),
        rejected=Count(Case(When(verification_status='rejected', then=1), 
                           output_field=IntegerField()))
    )
    
    # Statistiques clients
    client_stats = PhoneVerification.objects.aggregate(
        total=Count('id'),
        verified=Count(Case(When(status='verified', then=1), 
                           output_field=IntegerField())),
        pending=Count(Case(When(status='pending', then=1), 
                          output_field=IntegerField()))
    )
    
    # Vérifications urgentes (en attente depuis >7 jours)
    urgent_threshold = timezone.now() - timedelta(days=7)
    urgent_verifications = ProviderVerification.objects.filter(
        verification_status='pending',
        submitted_at__lte=urgent_threshold
    ).count()
    
    # Activité récente (7 derniers jours)
    week_ago = timezone.now() - timedelta(days=7)
    recent_activity = {
        'new_provider_verifications': ProviderVerification.objects.filter(
            submitted_at__gte=week_ago
        ).count(),
        'approved_verifications': ProviderVerification.objects.filter(
            verification_status='verified',
            verified_at__gte=week_ago
        ).count(),
        'new_phone_verifications': PhoneVerification.objects.filter(
            created_at__gte=week_ago
        ).count()
    }
    
    # Taux de vérification globaux
    total_providers = Provider.objects.count()
    verified_providers = Provider.objects.filter(is_verified=True).count()
    provider_verification_rate = (verified_providers / total_providers * 100) if total_providers > 0 else 0
    
    total_clients = User.objects.filter(role='client').count()
    verified_clients = User.objects.filter(
        role='client',
        phone_verification__status='verified'
    ).count()
    client_verification_rate = (verified_clients / total_clients * 100) if total_clients > 0 else 0
    
    return Response({
        'provider_verifications': provider_stats,
        'phone_verifications': client_stats,
        'urgent_verifications_count': urgent_verifications,
        'recent_activity': recent_activity,
        'verification_rates': {
            'providers': round(provider_verification_rate, 2),
            'clients': round(client_verification_rate, 2)
        },
        'totals': {
            'total_providers': total_providers,
            'verified_providers': verified_providers,
            'total_clients': total_clients,
            'verified_clients': verified_clients
        }
    })


@api_view(['GET'])
# @permission_classes([IsAdminUser])
def verification_reports(request):
    """
    Rapports détaillés des vérifications
    Avec données pour graphiques et analyses
    """
    
    # Évolution dans le temps (30 derniers jours)
    daily_stats = []
    for i in range(30):
        day = timezone.now().date() - timedelta(days=i)
        day_start = timezone.make_aware(timezone.datetime.combine(day, timezone.datetime.min.time()))
        day_end = day_start + timedelta(days=1)
        
        provider_submissions = ProviderVerification.objects.filter(
            submitted_at__gte=day_start,
            submitted_at__lt=day_end
        ).count()
        
        provider_approvals = ProviderVerification.objects.filter(
            verified_at__gte=day_start,
            verified_at__lt=day_end,
            verification_status='verified'
        ).count()
        
        phone_verifications = PhoneVerification.objects.filter(
            verified_at__gte=day_start,
            verified_at__lt=day_end,
            status='verified'
        ).count()
        
        daily_stats.append({
            'date': day.isoformat(),
            'provider_submissions': provider_submissions,
            'provider_approvals': provider_approvals,
            'phone_verifications': phone_verifications
        })
    
    # Répartition par type de document
    document_stats = ProviderVerification.objects.aggregate(
        id_cards=Count(Case(When(document_type='id_card', then=1), 
                           output_field=IntegerField())),
        passports=Count(Case(When(document_type='passport', then=1), 
                            output_field=IntegerField())),
        businesses=Count(Case(When(is_business=True, then=1), 
                             output_field=IntegerField())),
        individuals=Count(Case(When(is_business=False, then=1), 
                              output_field=IntegerField()))
    )
    
    # Top des raisons de rejet
    rejection_reasons = ProviderVerification.objects.filter(
        verification_status='rejected',
        rejection_reason__isnull=False
    ).exclude(rejection_reason='').values_list('rejection_reason', flat=True)
    
    # Compter les raisons les plus fréquentes
    reason_counts = {}
    for reason in rejection_reasons:
        reason_counts[reason] = reason_counts.get(reason, 0) + 1
    
    top_rejection_reasons = sorted(
        reason_counts.items(), 
        key=lambda x: x[1], 
        reverse=True
    )[:10]
    
    return Response({
        'daily_evolution': daily_stats,
        'document_distribution': document_stats,
        'top_rejection_reasons': [
            {'reason': reason, 'count': count} 
            for reason, count in top_rejection_reasons
        ],
        'generated_at': timezone.now().isoformat()
    })


# ================================================================
# 5. ACTIONS ADMIN AVANCÉES
# ================================================================

@api_view(['POST'])
@permission_classes([IsSuperAdminOnly])
def reset_all_verifications(request):
    """
    ATTENTION: Action destructrice réservée aux super-admins
    Remet à zéro toutes les vérifications (pour tests/développement)
    """
    
    if not request.data.get('confirm') == 'RESET_ALL_VERIFICATIONS':
        return Response({
            'detail': 'Confirmation requise: envoyez {"confirm": "RESET_ALL_VERIFICATIONS"}'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    with transaction.atomic():
        # Reset vérifications prestataires
        provider_count = ProviderVerification.objects.count()
        ProviderVerification.objects.all().delete()
        Provider.objects.update(is_verified=False)
        
        # Reset vérifications téléphone
        phone_count = PhoneVerification.objects.count()
        PhoneVerification.objects.all().delete()
        User.objects.filter(role='client').update(is_verified=False)
        
        # Logger l'action
        AdminAction.objects.create(
            admin_user=request.user,
            action_type='verification_reset_all',
            target_model='All',
            target_id=0,
            description=f"Reset complet des vérifications: {provider_count} prestataires, {phone_count} clients"
        )
    
    logger.warning(f"RESET COMPLET DES VÉRIFICATIONS par {request.user.username}")
    
    return Response({
        'message': 'Toutes les vérifications ont été réinitialisées',
        'provider_verifications_deleted': provider_count,
        'phone_verifications_deleted': phone_count
    })


@api_view(['GET'])
# @permission_classes([IsAdminUser])
def export_verifications(request):
    """
    Exporter les données de vérifications en CSV
    """
    import csv
    from django.http import HttpResponse
    
    response = HttpResponse(content_type='text/csv')
    response['Content-Disposition'] = 'attachment; filename="verifications_export.csv"'
    
    writer = csv.writer(response)
    
    # En-têtes
    writer.writerow([
        'Type', 'Utilisateur', 'Email', 'Statut', 'Date soumission', 
        'Date vérification', 'Vérifié par', 'Raison rejet'
    ])
    
    # Vérifications prestataires
    for verification in ProviderVerification.objects.select_related(
        'provider__user', 'verified_by'
    ).all():
        writer.writerow([
            'Prestataire',
            verification.provider.user.username,
            verification.provider.user.email,
            verification.get_verification_status_display(),
            verification.submitted_at,
            verification.verified_at,
            verification.verified_by.username if verification.verified_by else '',
            verification.rejection_reason
        ])
    
    # Vérifications téléphone
    for verification in PhoneVerification.objects.select_related('user').all():
        writer.writerow([
            'Client',
            verification.user.username,
            verification.user.email,
            verification.get_status_display(),
            verification.created_at,
            verification.verified_at,
            'Automatique',
            ''
        ])
    
    return response