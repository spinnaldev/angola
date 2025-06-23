from django.forms import ValidationError
from django.shortcuts import render
import math
from django.core.exceptions import PermissionDenied
# Create your views here.
from rest_framework import viewsets, generics, status, filters
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser, AllowAny
from rest_framework.pagination import PageNumberPagination
from django.db.models import Q, Count, Avg
from django.shortcuts import get_object_or_404
from django_filters.rest_framework import DjangoFilterBackend
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta
from .models import *
from rest_framework.views import APIView
from django.core.mail import send_mail
import random
import string
from django.conf import settings
from rest_framework_simplejwt.tokens import RefreshToken
from django.db import transaction
# from django.contrib.gis.geos import Point
# from django.contrib.gis.measure import D
# from django.contrib.gis.db.models.functions import Distance

from .serializers import *
from .permissions import IsOwnerOrReadOnly, IsProviderOwner, IsClientOrProviderOwner

User = get_user_model()

class StandardResultsSetPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100


class LoginView(APIView):
    permission_classes = (AllowAny,)
    """
    Vue pour la connexion avec email et mot de passe
    Retourne les informations utilisateur et les tokens
    """
    def post(self, request):
        email = request.data.get('email')
        password = request.data.get('password')
        
        if not email or not password:
            return Response(
                {"detail": "Email et mot de passe sont requis"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Chercher l'utilisateur par email
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response(
                {"detail": "Aucun compte trouvé avec cet email"}, 
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Vérifier le mot de passe
        if not user.check_password(password):
            return Response(
                {"detail": "Mot de passe incorrect"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Si l'utilisateur n'est pas actif
        if not user.is_active:
            return Response(
                {"detail": "Ce compte a été désactivé"}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Générer les tokens
        refresh = RefreshToken.for_user(user)
        
        # Récupérer les infos utilisateur
        serializer = UserSerializer(user)
        
        # Créer la réponse
        response_data = {
            'user': serializer.data,
            'access': str(refresh.access_token),
            'refresh': str(refresh)
        }
        
        return Response(response_data, status=status.HTTP_200_OK)
    
class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (AllowAny,)
    serializer_class = RegisterSerializer
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Créer l'utilisateur
        user = serializer.save()
        
        # Le serializer s'occupe déjà de retourner le bon format
        response_data = serializer.to_representation(user)
        
        return Response(response_data, status=status.HTTP_201_CREATED)
    
class PasswordResetRequestView(APIView):
    """
    Vue pour demander un code de réinitialisation de mot de passe
    """
    def post(self, request):
        email = request.data.get('email')
        
        if not email:
            return Response(
                {"detail": "Email est requis"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Vérifier si l'utilisateur existe
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            # Pour des raisons de sécurité, ne pas révéler que l'email n'existe pas
            return Response(
                {"detail": "Si cet email existe, un code de réinitialisation a été envoyé"}, 
                status=status.HTTP_200_OK
            )
        
        # Générer un code à 6 chiffres
        code = ''.join(random.choices(string.digits, k=6))
        
        # Supprimer les anciens codes pour cet utilisateur
        ResetPasswordCode.objects.filter(user=user).delete()
        
        # Créer un nouveau code
        expiration = timezone.now() + timedelta(minutes=15)
        reset_code = ResetPasswordCode.objects.create(
            user=user,
            code=code,
            expires_at=expiration
        )
        
        # Envoyer l'email
        subject = 'Code de réinitialisation de mot de passe'
        message = f"""
        Bonjour,
        
        Vous avez demandé la réinitialisation de votre mot de passe.
        Voici votre code de réinitialisation: {code}
        
        Ce code est valable pendant 15 minutes.
        
        Si vous n'avez pas demandé cette réinitialisation, veuillez ignorer cet email.
        
        Cordialement,
        L'équipe Angola
        """
        
        try:
            send_mail(
                subject,
                message,
                settings.DEFAULT_FROM_EMAIL,
                [email],
                fail_silently=False,
            )
        except Exception as e:
            return Response(
                {"detail": f"Erreur lors de l'envoi de l'email: {str(e)}"}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        return Response(
            {"detail": "Code de réinitialisation envoyé"}, 
            status=status.HTTP_200_OK
        )

class VerifyResetCodeView(APIView):
    """
    Vue pour vérifier le code de réinitialisation
    """
    def post(self, request):
        email = request.data.get('email')
        code = request.data.get('code')
        
        if not email or not code:
            return Response(
                {"detail": "Email et code sont requis"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Vérifier si l'utilisateur existe
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response(
                {"detail": "Code invalide"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Vérifier si le code existe et est valide
        try:
            reset_code = ResetPasswordCode.objects.get(user=user, code=code)
            
            # Vérifier si le code a expiré
            if reset_code.expires_at < timezone.now():
                reset_code.delete()
                return Response(
                    {"detail": "Code expiré"}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
                
        except ResetPasswordCode.DoesNotExist:
            return Response(
                {"detail": "Code invalide"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        return Response(
            {"detail": "Code vérifié avec succès"}, 
            status=status.HTTP_200_OK
        )

class PasswordResetConfirmView(APIView):
    """
    Vue pour réinitialiser le mot de passe avec le code
    """
    def post(self, request):
        email = request.data.get('email')
        code = request.data.get('code')
        new_password = request.data.get('new_password')
        
        if not email or not code or not new_password:
            return Response(
                {"detail": "Email, code et nouveau mot de passe sont requis"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Vérifier si l'utilisateur existe
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response(
                {"detail": "Code invalide"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Vérifier si le code existe et est valide
        try:
            reset_code = ResetPasswordCode.objects.get(user=user, code=code)
            
            # Vérifier si le code a expiré
            if reset_code.expires_at < timezone.now():
                reset_code.delete()
                return Response(
                    {"detail": "Code expiré"}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
                
        except ResetPasswordCode.DoesNotExist:
            return Response(
                {"detail": "Code invalide"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Changer le mot de passe
        user.set_password(new_password)
        user.save()
        
        # Supprimer le code
        reset_code.delete()
        
        return Response(
            {"detail": "Mot de passe réinitialisé avec succès"}, 
            status=status.HTTP_200_OK
        )
    
class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]
    
    # def get_permissions(self):
    #     if self.action == 'create':
    #         return [AllowAny()]
    #     elif self.action in ['update', 'partial_update', 'destroy']:
    #         return [IsOwnerOrReadOnly()]
    #     return [IsAuthenticated()]
    
    def get_serializer_class(self):
        if self.action in ['update', 'partial_update']:
            return UserUpdateSerializer
        return UserSerializer
    
    @action(detail=False, methods=['get'])
    def me(self, request):
        """Récupérer le profil de l'utilisateur connecté"""
        serializer = self.get_serializer(request.user)
        return Response(serializer.data)
    
    @action(detail=False, methods=['put', 'patch'])
    def update_me(self, request):
        """Mettre à jour le profil de l'utilisateur connecté"""
        user = request.user
        serializer = UserUpdateSerializer(user, data=request.data, partial=True)
        
        if serializer.is_valid():
            # Gérer l'upload de l'image de profil
            if 'profile_picture' in request.FILES:
                # Supprimer l'ancienne image si elle existe
                if user.profile_picture:
                    try:
                        user.profile_picture.delete(save=False)
                    except Exception:
                        pass
                user.profile_picture = request.FILES['profile_picture']
            
            serializer.save()
            
            # Retourner les données complètes de l'utilisateur
            response_serializer = UserSerializer(user)
            return Response(response_serializer.data)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def update(self, request, *args, **kwargs):
        """Mise à jour complète d'un utilisateur (PUT)"""
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        
        # Vérifier les permissions
        if not (request.user.is_staff or request.user == instance):
            return Response(
                {"detail": "Vous n'êtes pas autorisé à modifier cet utilisateur"}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        
        if serializer.is_valid():
            # Gérer l'upload de l'image de profil
            if 'profile_picture' in request.FILES:
                # Supprimer l'ancienne image si elle existe
                if instance.profile_picture:
                    try:
                        instance.profile_picture.delete(save=False)
                    except Exception:
                        pass
                instance.profile_picture = request.FILES['profile_picture']
            
            self.perform_update(serializer)
            
            # Si c'est un prestataire et qu'il y a un company_name
            if hasattr(instance, 'provider_profile') and 'company_name' in request.data:
                provider = instance.provider_profile
                provider.company_name = request.data['company_name']
                provider.save()
            
            # Retourner les données utilisateur mises à jour
            response_serializer = UserSerializer(instance)
            return Response(response_serializer.data)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def partial_update(self, request, *args, **kwargs):
        """Mise à jour partielle d'un utilisateur (PATCH)"""
        kwargs['partial'] = True
        return self.update(request, *args, **kwargs)
    
    def destroy(self, request, *args, **kwargs):
        """Supprimer un utilisateur"""
        instance = self.get_object()
        
        # Vérifier les permissions - seuls les admins peuvent supprimer
        # if not request.user.is_staff:
        #     return Response(
        #         {"detail": "Seuls les administrateurs peuvent supprimer des utilisateurs"}, 
        #         status=status.HTTP_403_FORBIDDEN
        #     )
        
        # Empêcher la suppression de son propre compte
        if request.user == instance:
            return Response(
                {"detail": "Vous ne pouvez pas supprimer votre propre compte"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            with transaction.atomic():
                # Supprimer l'image de profil si elle existe
                if instance.profile_picture:
                    try:
                        instance.profile_picture.delete(save=False)
                    except Exception:
                        pass
                
                # Marquer comme inactif au lieu de supprimer définitivement
                # (recommandé pour l'intégrité des données)
                # instance.is_active = False
                # instance.email =str(instance.email) + "_deleted"
                # instance.username = str(instance.username) + "_deleted"
                # instance.save()
                
                # Ou supprimer définitivement si vraiment nécessaire
                instance.delete()
                
                return Response(
                    {"detail": "Utilisateur supprimé avec succès"}, 
                    status=status.HTTP_204_NO_CONTENT
                )
        
        except Exception as e:
            return Response(
                {"detail": f"Erreur lors de la suppression: {str(e)}"}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=True, methods=['patch'])
    def toggle_status(self, request, pk=None):
        """Activer/désactiver un utilisateur"""
        user = self.get_object()
        
        # Vérifier les permissions
        if not request.user.is_staff:
            return Response(
                {"detail": "Seuls les administrateurs peuvent modifier le statut"}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Empêcher la désactivation de son propre compte
        if request.user == user:
            return Response(
                {"detail": "Vous ne pouvez pas modifier le statut de votre propre compte"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user.is_active = not user.is_active
        user.save()
        
        response_serializer = UserSerializer(user)
        return Response({
            "detail": f"Utilisateur {'activé' if user.is_active else 'désactivé'} avec succès",
            "user": response_serializer.data
        })
    
    @action(detail=True, methods=['patch'])
    def toggle_verification(self, request, pk=None):
        """Vérifier/dévérifier un utilisateur"""
        user = self.get_object()
        
        # Vérifier les permissions
        if not request.user.is_staff:
            return Response(
                {"detail": "Seuls les administrateurs peuvent modifier la vérification"}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        user.is_verified = not user.is_verified
        user.save()
        
        response_serializer = UserSerializer(user)
        return Response({
            "detail": f"Utilisateur {'vérifié' if user.is_verified else 'non vérifié'} avec succès",
            "user": response_serializer.data
        })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_profile_stats(request):
    """
    Récupérer les statistiques du profil utilisateur
    """
    user = request.user
    
    if user.role == 'provider':
        # Statistiques pour prestataire
        provider = user.provider_profile
        services_count = provider.provider_services.count()
        reviews_count = provider.reviews_received.count()
        avg_rating = provider.avg_rating
        total_quotes = provider.quote_requests.count()
        pending_quotes = provider.quote_requests.filter(status='pending').count()
        
        stats = {
            'user_type': 'provider',
            'services_count': services_count,
            'reviews_count': reviews_count,
            'avg_rating': float(avg_rating),
            'total_quotes': total_quotes,
            'pending_quotes': pending_quotes,
        }
    else:
        # Statistiques pour client
        total_projects = user.quote_requests.count()
        pending_projects = user.quote_requests.filter(status='pending').count()
        completed_projects = user.quote_requests.filter(status='completed').count()
        reviews_given = user.reviews_given.count()
        
        stats = {
            'user_type': 'client',
            'total_projects': total_projects,
            'pending_projects': pending_projects,
            'completed_projects': completed_projects,
            'reviews_given': reviews_given,
        }
    
    return Response(stats)

class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [AllowAny]
    filter_backends = [filters.SearchFilter]
    search_fields = ['name', 'description']
    
    # def get_permissions(self):
    #     if self.action in ['create', 'update', 'partial_update', 'destroy']:
    #         return [IsAdminUser()]
    #     return [AllowAny()]
class SubCategoryViewSet(viewsets.ModelViewSet):
    queryset = SubCategory.objects.all()
    serializer_class = SubCategorySerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['category']  # Permet de filtrer par category_id
    search_fields = ['name', 'description']
    
    def get_queryset(self):
        queryset = SubCategory.objects.all()
        
        # Récupérer le paramètre category_id de la requête
        category_id = self.request.query_params.get('category_id')
        
        # Si category_id est fourni, filtrer les sous-catégories par catégorie
        if category_id:
            try:
                category_id = int(category_id)  # Convertir en entier
                queryset = queryset.filter(category_id=category_id)
            except (ValueError, TypeError):
                # En cas d'erreur de conversion, on retourne une queryset vide
                queryset = SubCategory.objects.none()
                
        return queryset
    
    # Méthode pour fournir le nombre de services par sous-catégorie
    @action(detail=False, methods=['get'])
    def with_service_count(self, request):
        queryset = self.get_queryset()
        page = self.paginate_queryset(queryset)
        
        # Ajouter le nombre de services pour chaque sous-catégorie
        results = []
        for subcategory in (page or queryset):
            service_count = ProviderService.objects.filter(subcategory=subcategory).count()
            subcategory_data = SubCategorySerializer(subcategory).data
            subcategory_data['service_count'] = service_count
            results.append(subcategory_data)
            
        if page is not None:
            return self.get_paginated_response(results)
        
        return Response(results)

    # def get_permissions(self):
    #     if self.action in ['create', 'update', 'partial_update', 'destroy']:
    #         return [IsAdminUser()]
    #     return [AllowAny()]

class ProviderViewSet(viewsets.ModelViewSet):
    queryset = Provider.objects.all()
    serializer_class = ProviderListSerializer
    permission_classes = [AllowAny]
    pagination_class = StandardResultsSetPagination
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['is_verified', 'is_featured']
    search_fields = ['user__username', 'user__first_name', 'user__last_name', 'company_name']
    

    def get_queryset(self):
        queryset = Provider.objects.all().order_by('user__username')
        
        # Filtrage par catégorie
        category_id = self.request.query_params.get('category_id')
        if category_id:
            queryset = queryset.filter(expertise_categories__id=category_id)
            
        return queryset
    
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return ProviderDetailSerializer
        return ProviderListSerializer
    
    def get_permissions(self):
        if self.action in ['update', 'partial_update']:
            return [IsProviderOwner()]
        elif self.action == 'destroy':
            return [IsAdminUser()]
        return [AllowAny()]
    
    @action(detail=False, methods=['get'])
    def me(self, request):
        user = request.user
        if not hasattr(user, 'provider_profile'):
            return Response({"detail": "You are not a provider"}, status=status.HTTP_400_BAD_REQUEST)
        
        provider = user.provider_profile
        serializer = ProviderDetailSerializer(provider, context={'request': request})
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def expertise_categories(self, request):
        user = request.user
        if not hasattr(user, 'provider_profile'):
            return Response({"detail": "You are not a provider"}, status=status.HTTP_400_BAD_REQUEST)
            
        provider = user.provider_profile
        categories = provider.expertise_categories.all() # Ajustez l'import selon votre structure
        serializer = CategorySerializer(categories, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['put'])
    def update_expertise_categories(self, request):
        user = request.user
        if not hasattr(user, 'provider_profile'):
            return Response({"detail": "You are not a provider"}, status=status.HTTP_400_BAD_REQUEST)
            
        provider = user.provider_profile
        category_ids = request.data.get('categories', [])
        
        if not isinstance(category_ids, list):
            return Response({"detail": "categories field must be a list"}, status=status.HTTP_400_BAD_REQUEST)
            
        # Mise à jour des catégories
        from django.apps import apps
        Category = apps.get_model('categories', 'Category')  # Ajustez selon votre modèle
        categories = Category.objects.filter(id__in=category_ids)
        provider.expertise_categories.set(categories)
        
        # Retourner les catégories mises à jour
        serializer = CategorySerializer(categories, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['put'])
    def update_me(self, request):
        """
        Mettre à jour le profil prestataire de l'utilisateur connecté
        """
        user = request.user
        if not hasattr(user, 'provider_profile'):
            return Response(
                {"detail": "Vous n'êtes pas un prestataire"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        provider = user.provider_profile
        serializer = ProviderDetailSerializer(provider, data=request.data, partial=True)
        
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def by_category(self, request):
        category_id = request.query_params.get('category_id')
        if not category_id:
            return Response({"detail": "category_id parameter is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        # Get providers that have services in this category
        providers = Provider.objects.filter(
            provider_services__subcategory__category_id=category_id
        ).distinct()
        
        page = self.paginate_queryset(providers)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(providers, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def by_subcategory(self, request):
        subcategory_id = request.query_params.get('subcategory_id')
        if not subcategory_id:
            return Response({"detail": "subcategory_id parameter is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        # Get providers that have services in this subcategory
        providers = Provider.objects.filter(
            provider_services__subcategory_id=subcategory_id
        ).distinct()
        
        page = self.paginate_queryset(providers)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(providers, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def expertise_categories(self, request):
        """
        Récupère les catégories d'expertise du prestataire connecté
        """
        user = request.user
        if not hasattr(user, 'provider_profile'):
            return Response({"detail": "You are not a provider"}, status=status.HTTP_400_BAD_REQUEST)
        
        provider = user.provider_profile
        categories = provider.expertise_categories.all()
        
        # Nous utilisons une version simplifiée du serializer pour les catégories
        serializer = CategorySerializer(categories, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def nearby(self, request):
        lat = request.query_params.get('latitude')
        lng = request.query_params.get('longitude')
        radius = request.query_params.get('radius', 10)  # Default 10km
        
        if not lat or not lng:
            return Response({"detail": "latitude and longitude parameters are required"}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            lat = float(lat)
            lng = float(lng)
            radius = float(radius)
        except ValueError:
            return Response({"detail": "Invalid coordinates or radius"}, status=status.HTTP_400_BAD_REQUEST)
        
        # Filtrer les prestataires avec latitude et longitude non nulles
        providers = Provider.objects.filter(
            longitude__isnull=False,
            latitude__isnull=False
        )
        
        # Calculer une zone approximative basée sur le rayon (approche simplifiée)
        # 1 degré de latitude ≈ 111 km
        # 1 degré de longitude ≈ 111 km * cos(latitude)
        lat_radius = radius / 111.0
        lng_radius = radius / (111.0 * math.cos(math.radians(lat)))
        
        providers = providers.filter(
            latitude__gte=lat - lat_radius,
            latitude__lte=lat + lat_radius,
            longitude__gte=lng - lng_radius,
            longitude__lte=lng + lng_radius
        )
        
        # Tri par distance approximative (Pythagore)
        providers = sorted(providers, key=lambda p: (
            (p.latitude - lat) ** 2 + (p.longitude - lng) ** 2
        ))
        
        page = self.paginate_queryset(providers)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(providers, many=True)
        return Response(serializer.data)
    
class ProviderServiceViewSet(viewsets.ModelViewSet):
    queryset = ProviderService.objects.all()
    serializer_class = ProviderServiceSerializer
    permission_classes = [AllowAny]
    pagination_class = StandardResultsSetPagination
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['subcategory', 'is_available', 'price_type']
    search_fields = ['title', 'description']
    
    def get_serializer_context(self):
        """
        Ajoute la requête HTTP au contexte du sérialiseur pour générer l'URL absolue des images.
        """
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def get_queryset(self):
        queryset = ProviderService.objects.all()
        
        # Filtrer par provider_id si présent
        provider_id = self.request.query_params.get('provider_id')
        if provider_id:
            queryset = queryset.filter(provider_id=provider_id)
        
        # Filtrer par category_id si présent
        category_id = self.request.query_params.get('category_id')
        if category_id:
            queryset = queryset.filter(subcategory__category_id=category_id)
            
        # Filtrer par subcategory_id si présent
        subcategory_id = self.request.query_params.get('subcategory_id')
        if subcategory_id:
            queryset = queryset.filter(subcategory_id=subcategory_id)
        
        return queryset
    
    def perform_create(self, serializer):
        """
        Sets the provider to the current user when creating a service.
        """
        print(self.request.user)
        serializer.save(provider=self.request.user.provider_profile)

    def create(self, request, *args, **kwargs):
        # Extraire les données des fichiers et du formulaire
        gallery_images = []
        options_data = []
        
        # Traiter les images de galerie
        gallery_images_count = int(request.data.get('gallery_images_count', 0))
        for i in range(gallery_images_count):
            prefix = f'gallery_image_{i}_'
            if f'{prefix}image' in request.FILES:
                gallery_images.append({
                    'image': request.FILES[f'{prefix}image'],
                    'caption': request.data.get(f'{prefix}caption', ''),
                    'order': i
                })
        
        # Traiter les options
        options_count = int(request.data.get('options_count', 0))
        for i in range(options_count):
            prefix = f'option_{i}_'
            name = request.data.get(f'{prefix}name')
            if name:
                options_data.append({
                    'name': name,
                    'description': request.data.get(f'{prefix}description', ''),
                    'price': request.data.get(f'{prefix}price') or None,
                    'is_included': request.data.get(f'{prefix}is_included', 'true').lower() == 'true'
                })
        
        # Validation des images
        if gallery_images_count > 10:
            return Response(
                {'error': 'Vous ne pouvez pas ajouter plus de 10 images'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        # Créer le service avec le sérialiseur
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Ajouter les données au contexte
        serializer.context['gallery_images'] = gallery_images
        serializer.context['options'] = options_data
        
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
    
    def update(self, request, *args, **kwargs):
        # Code similaire à la méthode create pour traiter les images et options
        # ...
        
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=kwargs.get('partial', False))
        serializer.is_valid(raise_exception=True)
        
        serializer.context['gallery_images'] = gallery_images
        serializer.context['options'] = options_data
        
        self.perform_update(serializer)
        return Response(serializer.data)
    
    
    @action(detail=False, methods=['get'])
    def my_services(self, request):
        user = request.user
        if not hasattr(user, 'provider_profile'):
            return Response({"detail": "You are not a provider"}, status=status.HTTP_400_BAD_REQUEST)
        
        services = ProviderService.objects.filter(provider=user.provider_profile)
        page = self.paginate_queryset(services)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(services, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def count(self, request):
        """
        Endpoint pour compter le nombre de services par catégorie
        Paramètre: category_id
        """
        category_id = request.query_params.get('category_id')
        
        if not category_id:
            return Response({"detail": "category_id parameter is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # Convertir en entier
            category_id = int(category_id)
        except ValueError:
            return Response({"detail": "category_id must be an integer"}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # Compter les services pour cette catégorie
            # On compte les services qui ont une sous-catégorie appartenant à cette catégorie
            count = ProviderService.objects.filter(
                subcategory__category_id=category_id, 
                is_available=True
            ).count()
            print("La catégorie est:" + str(category_id))
            print("Le nombre est:" + str(count))
            return Response({"count": count})
        except Exception as e:
            return Response(
                {"detail": f"Error counting services: {str(e)}"}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=False, methods=['get'])
    def count_by_subcategory(self, request):
        """
        Endpoint pour compter le nombre de services par sous-catégorie
        Paramètre: subcategory_id
        """
        subcategory_id = request.query_params.get('subcategory_id')
        
        if not subcategory_id:
            return Response({"detail": "subcategory_id parameter is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # Convertir en entier
            subcategory_id = int(subcategory_id)
        except ValueError:
            return Response({"detail": "subcategory_id must be an integer"}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # Compter les services pour cette sous-catégorie
            count = ProviderService.objects.filter(
                subcategory_id=subcategory_id, 
                is_available=True
            ).count()
            
            return Response({"count": count})
        except Exception as e:
            return Response(
                {"detail": f"Error counting services: {str(e)}"}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=False, methods=['get'])
    def recent(self, request):
        """Endpoint pour récupérer les services les plus récents"""
        queryset = ProviderService.objects.filter(is_available=True).order_by('-created_at')[:10]
        serializer = self.get_serializer(queryset, many=True)
        print(serializer.data)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def top_rated(self, request):
        """Endpoint pour récupérer les services les mieux notés"""
        # Récupérer les services qui ont des avis et les trier par note moyenne
        from django.db.models import Avg
        queryset = ProviderService.objects.annotate(
            avg_rating=Avg('reviews__overall_rating')
        ).filter(
            is_available=True, 
            avg_rating__isnull=False
        ).order_by('-avg_rating')[:10]
        
        serializer = self.get_serializer(queryset, many=True)
        print(serializer.data)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def nearby(self, request):
        """Endpoint pour récupérer les services à proximité"""
        latitude = request.query_params.get('latitude')
        longitude = request.query_params.get('longitude')
        radius = request.query_params.get('radius', 10.0)  # Rayon par défaut: 10km
        
        if not (latitude and longitude):
            # Si pas de coordonnées, renvoyer simplement les services récents
            return self.recent(request)
        
        try:
            latitude = float(latitude)
            longitude = float(longitude)
            radius = float(radius)
        except (ValueError, TypeError):
            return Response(
                {"detail": "Coordonnées invalides"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Calcul simple de distance
        import math
        lat_radius = radius / 111.0
        lng_radius = radius / (111.0 * math.cos(math.radians(latitude)))
        
        queryset = ProviderService.objects.filter(
            is_available=True,
            provider__latitude__isnull=False,
            provider__longitude__isnull=False,
            provider__latitude__gte=latitude - lat_radius,
            provider__latitude__lte=latitude + lat_radius,
            provider__longitude__gte=longitude - lng_radius,
            provider__longitude__lte=longitude + lng_radius
        )[:10]
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
        
class PortfolioViewSet(viewsets.ModelViewSet):
    queryset = Portfolio.objects.all()
    serializer_class = PortfolioSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        provider_id = self.request.query_params.get('provider_id')
        if provider_id:
            return Portfolio.objects.filter(provider_id=provider_id)
        return Portfolio.objects.none()
    
    def get_permissions(self):
        if self.action == 'list' or self.action == 'retrieve':
            return [AllowAny()]
        return [IsAuthenticated()]
    
    def perform_create(self, serializer):
        # Make sure the logged-in user is a provider
        if not hasattr(self.request.user, 'provider_profile'):
            raise ValidationError("Only providers can create portfolio items")
        serializer.save(provider=self.request.user.provider_profile)
    
    @action(detail=False, methods=['get'])
    def my_portfolio(self, request):
        user = request.user
        if not hasattr(user, 'provider_profile'):
            return Response({"detail": "You are not a provider"}, status=status.HTTP_400_BAD_REQUEST)
        
        portfolio = Portfolio.objects.filter(provider=user.provider_profile)
        serializer = self.get_serializer(portfolio, many=True)
        return Response(serializer.data)

class CertificateViewSet(viewsets.ModelViewSet):
    queryset = Certificate.objects.all()
    serializer_class = CertificateSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        provider_id = self.request.query_params.get('provider_id')
        if provider_id:
            return Certificate.objects.filter(provider_id=provider_id)
        return Certificate.objects.none()
    
    def get_permissions(self):
        if self.action == 'list' or self.action == 'retrieve':
            return [AllowAny()]
        return [IsAuthenticated()]
    
    def perform_create(self, serializer):
        # Make sure the logged-in user is a provider
        if not hasattr(self.request.user, 'provider_profile'):
            raise ValidationError("Only providers can upload certificates")
        serializer.save(provider=self.request.user.provider_profile)
    
    @action(detail=False, methods=['get'])
    def my_certificates(self, request):
        user = request.user
        if not hasattr(user, 'provider_profile'):
            return Response({"detail": "You are not a provider"}, status=status.HTTP_400_BAD_REQUEST)
        
        certificates = Certificate.objects.filter(provider=user.provider_profile)
        serializer = self.get_serializer(certificates, many=True)
        return Response(serializer.data)

class ReviewViewSet(viewsets.ModelViewSet):
    queryset = Review.objects.all()
    serializer_class = ReviewSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = StandardResultsSetPagination
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['provider', 'service']
    
    def get_permissions(self):
        if self.action == 'list' or self.action == 'retrieve':
            return [AllowAny()]
        return [IsAuthenticated()]
    
    def perform_create(self, serializer):
        serializer.save(client=self.request.user)
    
    @action(detail=False, methods=['get'])
    def my_reviews(self, request):
        reviews = Review.objects.filter(client=request.user)
        page = self.paginate_queryset(reviews)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(reviews, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def provider_reviews(self, request):
        user = request.user
        if not hasattr(user, 'provider_profile'):
            return Response({"detail": "You are not a provider"}, status=status.HTTP_400_BAD_REQUEST)
        
        reviews = Review.objects.filter(provider=user.provider_profile)
        page = self.paginate_queryset(reviews)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(reviews, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    
    def top_reviews(self, request):
        """Endpoint pour récupérer les avis les mieux notés"""
        from django.db.models import Q
        queryset = Review.objects.filter(
            Q(overall_rating__gte=4.0) & Q(is_verified=True)
        ).order_by('-overall_rating', '-created_at')[:10]
        
        serializer = self.get_serializer(queryset, many=True)
        print("les reviews sont:")
        print(serializer.data)
        return Response(serializer.data)

    # @action(detail=False, methods=['get'])
    # def top_reviews(self, request):
    #     """Endpoint pour récupérer les avis les mieux notés"""
    #     from django.db.models import Q
    #     queryset = Review.objects.filter(
    #         Q(overall_rating__gte=4.0) & Q(is_verified=True)
    #     ).order_by('-created_at')[:10]
        
    #     serializer = self.get_serializer(queryset, many=True)
    #     return Response(serializer.data)

class FavoriteViewSet(viewsets.ModelViewSet):
    queryset = Favorite.objects.all()
    serializer_class = FavoriteSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Favorite.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
    
    @action(detail=False, methods=['post'])
    def toggle(self, request):
        provider_id = request.data.get('provider_id')
        if not provider_id:
            return Response({"detail": "provider_id is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        provider = get_object_or_404(Provider, id=provider_id)
        favorite = Favorite.objects.filter(user=request.user, provider=provider).first()
        
        if favorite:
            favorite.delete()
            return Response({"status": "removed from favorites"})
        else:
            Favorite.objects.create(user=request.user, provider=provider)
            return Response({"status": "added to favorites"})

class ConversationViewSet(viewsets.ModelViewSet):
    queryset = Conversation.objects.all().order_by('-updated_at')
    serializer_class = ConversationSerializer
    permission_classes = [AllowAny]  # Pour accepter les requêtes avec userId
    
    def get_queryset(self):
        # Récupérer l'ID utilisateur de la requête
        user_id = self.request.query_params.get('user_id')
        
        if not user_id:
            return Conversation.objects.none()
            
        try:
            user_id = int(user_id)
            user = User.objects.get(id=user_id)
        except (ValueError, User.DoesNotExist):
            return Conversation.objects.none()
            
        # Vérifier si l'utilisateur est un prestataire ou un client
        if hasattr(user, 'provider_profile'):
            return Conversation.objects.filter(provider=user.provider_profile)
        else:
            return Conversation.objects.filter(client=user)
    
    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        page = self.paginate_queryset(queryset)
        
        user_id = request.query_params.get('user_id')
        if user_id:
            context = {'user_id': user_id}
        else:
            context = {}
        
        if page is not None:
            serializer = self.get_serializer(page, many=True, context=context)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True, context=context)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'])
    def messages(self, request, pk=None):
        user_id = request.query_params.get('user_id')
        
        if not user_id:
            return Response({"detail": "user_id est requis"}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            user_id = int(user_id)
            user = User.objects.get(id=user_id)
        except (ValueError, User.DoesNotExist):
            return Response({"detail": "Utilisateur non trouvé"}, status=status.HTTP_404_NOT_FOUND)
            
        conversation = self.get_object()
        
        # Vérifier que l'utilisateur fait partie de la conversation
        if conversation.client.id != user.id and (
            not hasattr(user, 'provider_profile') or 
            conversation.provider.id != user.provider_profile.id
        ):
            return Response({"detail": "Accès non autorisé"}, status=status.HTTP_403_FORBIDDEN)
        
        # Marquer les messages comme lus pour cet utilisateur
        # (tous les messages envoyés par l'autre personne)
        if hasattr(user, 'provider_profile') and conversation.provider.id == user.provider_profile.id:
            # L'utilisateur est le prestataire, marquer les messages du client comme lus
            Message.objects.filter(
                conversation=conversation,
                sender=conversation.client,
                is_read=False
            ).update(is_read=True)
        else:
            # L'utilisateur est le client, marquer les messages du prestataire comme lus
            Message.objects.filter(
                conversation=conversation,
                sender=conversation.provider.user,
                is_read=False
            ).update(is_read=True)
        
        # Mettre à jour la date de la conversation
        conversation.updated_at = timezone.now()
        conversation.save()
        
        # Récupérer les messages
        messages = conversation.messages.all().order_by('created_at')
        page = self.paginate_queryset(messages)
        
        if page is not None:
            serializer = MessageSerializer(page, many=True, context={'user_id': user_id})
            return self.get_paginated_response(serializer.data)
        
        serializer = MessageSerializer(messages, many=True, context={'user_id': user_id})
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def send_message(self, request, pk=None):
        user_id = request.data.get('user_id')
        content = request.data.get('content')
        
        if not user_id or not content:
            return Response(
                {"detail": "user_id et content sont requis"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
            
        try:
            user_id = int(user_id)
            user = User.objects.get(id=user_id)
        except (ValueError, User.DoesNotExist):
            return Response({"detail": "Utilisateur non trouvé"}, status=status.HTTP_404_NOT_FOUND)
            
        conversation = self.get_object()
        
        # Vérifier que l'utilisateur fait partie de la conversation
        if conversation.client.id != user.id and (
            not hasattr(user, 'provider_profile') or 
            conversation.provider.id != user.provider_profile.id
        ):
            return Response({"detail": "Accès non autorisé"}, status=status.HTTP_403_FORBIDDEN)
        
        # Créer le message
        message = Message.objects.create(
            conversation=conversation,
            sender=user,
            content=content
        )
        
        # Mettre à jour la date de la conversation
        conversation.updated_at = timezone.now()
        conversation.save()
        
        serializer = MessageSerializer(message, context={'user_id': user_id})
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        user_id = request.data.get('user_id')
        
        if not user_id:
            return Response({"detail": "user_id est requis"}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            user_id = int(user_id)
            user = User.objects.get(id=user_id)
        except (ValueError, User.DoesNotExist):
            return Response({"detail": "Utilisateur non trouvé"}, status=status.HTTP_404_NOT_FOUND)
            
        conversation = self.get_object()
        
        # Vérifier que l'utilisateur fait partie de la conversation
        if conversation.client.id != user.id and (
            not hasattr(user, 'provider_profile') or 
            conversation.provider.id != user.provider_profile.id
        ):
            return Response({"detail": "Accès non autorisé"}, status=status.HTTP_403_FORBIDDEN)
        
        # Marquer les messages comme lus
        if hasattr(user, 'provider_profile') and conversation.provider.id == user.provider_profile.id:
            # L'utilisateur est le prestataire, marquer les messages du client comme lus
            count = Message.objects.filter(
                conversation=conversation,
                sender=conversation.client,
                is_read=False
            ).update(is_read=True)
        else:
            # L'utilisateur est le client, marquer les messages du prestataire comme lus
            count = Message.objects.filter(
                conversation=conversation,
                sender=conversation.provider.user,
                is_read=False
            ).update(is_read=True)
        
        return Response({"count": count, "status": "success"})
    
    @action(detail=False, methods=['post'])
    def start(self, request):
        user_id = request.data.get('user_id')
        provider_id = request.data.get('provider_id')
        initial_message = request.data.get('message')
        
        if not user_id or not provider_id:
            return Response(
                {"detail": "user_id et provider_id sont requis"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
            
        try:
            user_id = int(user_id)
            provider_id = int(provider_id)
            user = User.objects.get(id=user_id)
            provider = Provider.objects.get(id=provider_id)
        except (ValueError, User.DoesNotExist, Provider.DoesNotExist):
            return Response({"detail": "Utilisateur ou prestataire non trouvé"}, status=status.HTTP_404_NOT_FOUND)
        
        # Vérifier que l'utilisateur n'est pas le prestataire lui-même
        if hasattr(user, 'provider_profile') and user.provider_profile.id == provider.id:
            return Response(
                {"detail": "Vous ne pouvez pas démarrer une conversation avec vous-même"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Vérifier si une conversation existe déjà
        existing_conversation = Conversation.objects.filter(client=user, provider=provider).first()
        
        if existing_conversation:
            conversation = existing_conversation
        else:
            # Créer une nouvelle conversation
            conversation = Conversation.objects.create(client=user, provider=provider)
        
        # Ajouter un message initial si fourni
        if initial_message:
            Message.objects.create(
                conversation=conversation,
                sender=user,
                content=initial_message
            )
            # Mettre à jour la date de la conversation
            conversation.updated_at = timezone.now()
            conversation.save()
        
        serializer = ConversationSerializer(conversation, context={'user_id': user_id})
        return Response(serializer.data)
    
@api_view(['GET'])
@permission_classes([AllowAny])
def get_notification_count(request):
    user_id = request.query_params.get('user_id')
    
    if not user_id:
        return Response({"count": 0}, status=status.HTTP_200_OK)
    
    try:
        user_id = int(user_id)
        user = User.objects.get(id=user_id)
        
        # Compte les notifications non lues pour cet utilisateur
        count = Notification.objects.filter(user=user, is_read=False).count()
        
        return Response({"count": count}, status=status.HTTP_200_OK)
    except (ValueError, User.DoesNotExist):
        return Response({"count": 0}, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([AllowAny])
def mark_all_notifications_read(request):
    user_id = request.data.get('user_id')
    
    if not user_id:
        return Response({"detail": "user_id est requis"}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        user_id = int(user_id)
        user = User.objects.get(id=user_id)
        
        # Marque toutes les notifications comme lues
        count = Notification.objects.filter(user=user, is_read=False).update(is_read=True)
        
        return Response({"count": count, "status": "success"}, status=status.HTTP_200_OK)
    except (ValueError, User.DoesNotExist):
        return Response({"detail": "Utilisateur non trouvé"}, status=status.HTTP_404_NOT_FOUND)

  
class DisputeViewSet(viewsets.ModelViewSet):
    queryset = Dispute.objects.all()
    serializer_class = DisputeSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = StandardResultsSetPagination
    
    def get_queryset(self):
        user = self.request.user
        if user.is_staff:
            return Dispute.objects.all()
        elif hasattr(user, 'provider_profile'):
            return Dispute.objects.filter(provider=user.provider_profile)
        else:
            return Dispute.objects.filter(client=user)
    
    def perform_create(self, serializer):
        serializer.save(client=self.request.user)
    
    @action(detail=True, methods=['post'])
    def add_evidence(self, request, pk=None):
        dispute = self.get_object()
        description = request.data.get('description')
        file = request.data.get('file')
        
        if not description or not file:
            return Response({"detail": "Description and file are required"}, status=status.HTTP_400_BAD_REQUEST)
        
        evidence = DisputeEvidence.objects.create(
            dispute=dispute,
            user=request.user,
            description=description,
            file=file
        )
        
        serializer = DisputeEvidenceSerializer(evidence)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def update_status(self, request, pk=None):
        if not request.user.is_staff:
            return Response({"detail": "Only staff can update dispute status"}, status=status.HTTP_403_FORBIDDEN)
        
        dispute = self.get_object()
        status_value = request.data.get('status')
        resolution_note = request.data.get('resolution_note', '')
        
        if not status_value or status_value not in [s[0] for s in Dispute.STATUS_CHOICES]:
            return Response({"detail": "Valid status is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        dispute.status = status_value
        dispute.resolution_note = resolution_note
        dispute.save()
        
        serializer = self.get_serializer(dispute)
        return Response(serializer.data)

class NotificationViewSet(viewsets.ModelViewSet):
    queryset = Notification.objects.all()
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user).order_by('-created_at')
    
    @action(detail=True, methods=['post'])
    def mark_as_read(self, request, pk=None):
        notification = self.get_object()
        notification.is_read = True
        notification.save()
        return Response({"status": "marked as read"})
    
    @action(detail=False, methods=['post'])
    def mark_all_as_read(self, request):
        notifications = self.get_queryset().filter(is_read=False)
        notifications.update(is_read=True)
        return Response({"status": "all notifications marked as read"})
    
    @action(detail=False, methods=['get'])
    def unread_count(self, request):
        count = self.get_queryset().filter(is_read=False).count()
        return Response({"count": count})

class ReportViewSet(viewsets.ModelViewSet):
    queryset = Report.objects.all()
    serializer_class = ReportSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        if self.request.user.is_staff:
            return Report.objects.all()
        return Report.objects.filter(reporter=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(reporter=self.request.user)
    
    @action(detail=True, methods=['post'])
    def update_status(self, request, pk=None):
        if not request.user.is_staff:
            return Response({"detail": "Only staff can update report status"}, status=status.HTTP_403_FORBIDDEN)
        
        report = self.get_object()
        status_value = request.data.get('status')
        admin_notes = request.data.get('admin_notes', '')
        
        if not status_value or status_value not in [s[0] for s in Report.STATUS_CHOICES]:
            return Response({"detail": "Valid status is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        report.status = status_value
        report.admin_notes = admin_notes
        report.save()
        
        serializer = self.get_serializer(report)
        return Response(serializer.data)
    
class QuoteRequestViewSet(viewsets.ModelViewSet):
    queryset = QuoteRequest.objects.all()
    serializer_class = QuoteRequestSerializer
    # permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        print("Le user est:" + str(user))
        if user.is_staff:
            return QuoteRequest.objects.all()
        elif hasattr(user, 'provider_profile'):
            print('oui')
            print(user.id)
            print(user.provider_profile)
            return QuoteRequest.objects.filter(provider=user.provider_profile)
        else:
            return QuoteRequest.objects.filter(client=user)
    
    def perform_create(self, serializer):
        provider_id = self.request.data.get('provider')
        try:
            provider = Provider.objects.get(id=provider_id)
            serializer.save(client=self.request.user, provider=provider)
        except Provider.DoesNotExist:
            raise ValidationError("Provider not found")
    
    @action(detail=True, methods=['post'])
    def update_status(self, request, pk=None):
        quote_request = self.get_object()
        status_value = request.data.get('status')
        
        if not status_value or status_value not in [s[0] for s in QuoteRequest.STATUS_CHOICES]:
            return Response({"detail": "Valid status is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        # Vérifier que l'utilisateur est autorisé à modifier le statut
        user = request.user
        if hasattr(user, 'provider_profile') and quote_request.provider == user.provider_profile:
            quote_request.status = status_value
            quote_request.save()
            serializer = self.get_serializer(quote_request)
            return Response(serializer.data)
        else:
            return Response({"detail": "You are not authorized to update this quote request"}, 
                           status=status.HTTP_403_FORBIDDEN)
        
class ProviderByCategoryView(generics.ListAPIView):
    serializer_class = ProviderListSerializer
    permission_classes = [AllowAny]
    
    def get_queryset(self):
        category_id = self.request.query_params.get('category_id')
        if not category_id:
            return Provider.objects.none()
            
        # Récupérer les prestataires qui ont des services dans cette catégorieCategorieEpi
        return Provider.objects.filter(
            provider_services__subcategory__category_id=category_id
        ).distinct()

class ProviderBySubcategoryView(generics.ListAPIView):
    serializer_class = ProviderListSerializer
    permission_classes = [AllowAny]
    
    def get_queryset(self):
        subcategory_id = self.request.query_params.get('subcategory_id')
        if not subcategory_id:
            return Provider.objects.none()
            
        return Provider.objects.filter(
            provider_services__subcategory_id=subcategory_id
        ).distinct()

class NearbyProvidersView(generics.ListAPIView):
    serializer_class = ProviderListSerializer
    permission_classes = [AllowAny]
    
    def get_queryset(self):
        latitude = self.request.query_params.get('latitude')
        longitude = self.request.query_params.get('longitude')
        radius = self.request.query_params.get('radius', 10.0)
        
        if not latitude or not longitude:
            return Provider.objects.none()
            
        try:
            latitude = float(latitude)
            longitude = float(longitude)
            radius = float(radius)
        except (ValueError, TypeError):
            return Provider.objects.none()
        
        # Si vous utilisez PostgreSQL avec PostGIS, vous pouvez utiliser une requête géospatiale.
        # Sinon, vous pouvez faire une approximation avec des calculs sur les coordonnées.
        
        # Filtrer les prestataires avec latitude et longitude non nulles
        providers = Provider.objects.filter(
            longitude__isnull=False,
            latitude__isnull=False
        )
        
        # Calculer une zone approximative basée sur le rayon (approche simplifiée)
        # 1 degré de latitude ≈ 111 km
        # 1 degré de longitude ≈ 111 km * cos(latitude)
        import math
        lat_radius = radius / 111.0
        lng_radius = radius / (111.0 * math.cos(math.radians(latitude)))
        
        return providers.filter(
            latitude__gte=latitude - lat_radius,
            latitude__lte=latitude + lat_radius,
            longitude__gte=longitude - lng_radius,
            longitude__lte=longitude + lng_radius
        )
 
class ClientProjectViewSet(viewsets.ModelViewSet):
    """ViewSet pour la gestion des projets clients"""
    serializer_class = ClientProjectListSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'description', 'location']
    ordering_fields = ['created_at', 'deadline', 'budget_range']
    ordering = ['-created_at']
    
    def get_permissions(self):
        """
        Définir les permissions selon l'action
        """
        if self.action in ['list', 'retrieve']:
            # Lecture publique pour la liste et le détail des projets
            permission_classes = [AllowAny]
        else:
            # Authentification requise pour création, modification, suppression
            permission_classes = [IsAuthenticated]
        
        return [permission() for permission in permission_classes]
    
    def get_queryset(self):
        queryset = ClientProject.objects.select_related(
            'client', 'category', 'subcategory'
        ).prefetch_related('required_skills').annotate(
            total_offers=Count('project_offers')
        )
        
        # Pour les utilisateurs non authentifiés, masquer certaines informations sensibles
        if not self.request.user.is_authenticated:
            # On peut ajouter des filtres pour ne montrer que les projets ouverts
            queryset = queryset.filter(status='open')
        
        # Filtrage basé sur les paramètres de requête
        category = self.request.query_params.get('category')
        if category:
            queryset = queryset.filter(category_id=category)
        
        subcategory = self.request.query_params.get('subcategory')
        if subcategory:
            queryset = queryset.filter(subcategory_id=subcategory)
        
        budget_min = self.request.query_params.get('budget_min')
        budget_max = self.request.query_params.get('budget_max')
        if budget_min:
            queryset = queryset.filter(
                Q(min_budget__gte=budget_min) | Q(budget_range='sur_devis')
            )
        if budget_max:
            queryset = queryset.filter(
                Q(max_budget__lte=budget_max) | Q(budget_range='sur_devis')
            )
        
        location = self.request.query_params.get('location')
        if location:
            queryset = queryset.filter(
                Q(location__icontains=location) | Q(remote_possible=True)
            )
        
        remote_only = self.request.query_params.get('remote_only')
        if remote_only and remote_only.lower() == 'true':
            queryset = queryset.filter(remote_possible=True)
        
        urgency = self.request.query_params.get('urgency')
        if urgency:
            queryset = queryset.filter(urgency=urgency)
        
        posted_within_days = self.request.query_params.get('posted_within_days')
        if posted_within_days:
            cutoff_date = timezone.now() - timedelta(days=int(posted_within_days))
            queryset = queryset.filter(created_at__gte=cutoff_date)
        
        # Filtrage pour les projets ouverts par défaut pour les non-authentifiés
        if not self.request.user.is_authenticated:
            show_all = self.request.query_params.get('show_all')
            if not show_all or show_all.lower() != 'true':
                queryset = queryset.filter(status='open')
        print(queryset)
        return queryset
    
    def get_serializer_class(self):
        if self.action == 'create':
            return ClientProjectCreateSerializer
        elif self.action == 'retrieve':
            return ClientProjectDetailSerializer
        return ClientProjectListSerializer
    
    def perform_create(self, serializer):
        # La création nécessite toujours une authentification
        if not self.request.user.is_authenticated:
            raise PermissionDenied("Authentification requise pour créer un projet")
        serializer.save(client=self.request.user)
    
    def retrieve(self, request, *args, **kwargs):
        """Récupération d'un projet avec comptage des vues"""
        instance = self.get_object()
        
        # Incrémenter le compteur de vues
        ClientProject.objects.filter(pk=instance.pk).update(
            views_count=models.F('views_count') + 1
        )
        
        # Enregistrer la vue pour les statistiques (seulement si authentifié)
        if request.user.is_authenticated:
            ProjectView.objects.get_or_create(
                project=instance,
                viewer=request.user,
                ip_address=self.get_client_ip(request),
                defaults={'user_agent': request.META.get('HTTP_USER_AGENT', '')}
            )
        
        serializer = self.get_serializer(instance)
        return Response(serializer.data)
    
    def get_client_ip(self, request):
        """Obtenir l'IP du client"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip
    
    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def my_projects(self, request):
        """Récupérer les projets de l'utilisateur connecté"""
        queryset = self.get_queryset().filter(client=request.user)
        
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def stats(self, request):
        """Statistiques des projets pour le dashboard client"""
        user_projects = ClientProject.objects.filter(client=request.user)
        
        stats = {
            'total_projects': user_projects.count(),
            'open_projects': user_projects.filter(status='open').count(),
            'completed_projects': user_projects.filter(status='completed').count(),
            'total_offers': ProjectOffer.objects.filter(project__client=request.user).count(),
        }
        
        # Calculer la moyenne d'offres par projet
        projects_with_offers = user_projects.annotate(
            offers_count=Count('project_offers')
        ).aggregate(avg_offers=Avg('offers_count'))
        
        stats['average_offers_per_project'] = round(
            projects_with_offers['avg_offers'] or 0, 1
        )
        
        return Response(stats)
    
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def toggle_favorite(self, request, pk=None):
        """Ajouter/retirer un projet des favoris"""
        if not hasattr(request.user, 'provider_profile'):
            return Response(
                {'error': 'Seuls les prestataires peuvent mettre des projets en favori'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        project = self.get_object()
        provider = request.user.provider_profile
        
        favorite, created = ProjectFavorite.objects.get_or_create(
            project=project,
            provider=provider
        )
        
        if not created:
            favorite.delete()
            return Response({'favorited': False})
        else:
            return Response({'favorited': True})

    @action(detail=True, methods=['patch'], permission_classes=[IsAuthenticated])
    def close_project(self, request, pk=None):
        """Clôturer un projet"""
        try:
            project = self.get_object()
            
            # Vérifier que l'utilisateur est bien le propriétaire du projet
            if project.client != request.user:
                return Response(
                    {'error': 'Vous n\'avez pas les permissions pour clôturer ce projet'},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Vérifier que le projet peut être clôturé
            if project.status in ['closed', 'completed']:
                return Response(
                    {'error': 'Ce projet est déjà clôturé ou terminé'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Effectuer la clôture dans une transaction
            with transaction.atomic():
                # Mettre à jour le statut
                project.status = 'closed'
                project.closed_at = timezone.now()  # Ajouter ce champ au modèle si nécessaire
                project.save()
                
                # Notifier les prestataires qui ont fait des offres
                active_offers = ProjectOffer.objects.filter(
                    project=project,
                    status='pending'
                )
                
                for offer in active_offers:
                    # Créer une notification pour chaque prestataire
                    Notification.objects.create(
                        user=offer.provider.user,
                        title="Projet clôturé",
                        message=f"Le projet '{project.title}' a été clôturé par le client.",
                        notification_type='project_closed',
                        related_object_id=project.id
                    )
                    
                    # Optionnel : Mettre à jour le statut des offres
                    offer.status = 'rejected'
                    offer.save()
            
            # Sérialiser et retourner le projet mis à jour
            serializer = self.get_serializer(project)
            
            return Response({
                'message': 'Projet clôturé avec succès',
                'project': serializer.data,
                'notifications_sent': active_offers.count()
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response(
                {'error': f'Erreur lors de la clôture du projet: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['patch'], permission_classes=[IsAuthenticated])
    def update_status(self, request, pk=None):
        """Mettre à jour le statut d'un projet"""
        try:
            project = self.get_object()
            new_status = request.data.get('status')
            
            # Vérifier que l'utilisateur est bien le propriétaire du projet
            if project.client != request.user:
                return Response(
                    {'error': 'Vous n\'avez pas les permissions pour modifier ce projet'},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Vérifier que le nouveau statut est valide
            valid_statuses = [choice[0] for choice in ClientProject.STATUS_CHOICES]
            if new_status not in valid_statuses:
                return Response(
                    {'error': f'Statut invalide. Statuts valides: {valid_statuses}'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Vérifications de logique métier
            if project.status == 'completed' and new_status != 'completed':
                return Response(
                    {'error': 'Un projet terminé ne peut pas changer de statut'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Mettre à jour le statut
            old_status = project.status
            project.status = new_status
            
            # Ajouter des timestamps selon le statut
            if new_status == 'closed':
                project.closed_at = timezone.now()
            elif new_status == 'completed':
                project.completed_at = timezone.now()
            elif new_status == 'in_progress':
                project.started_at = timezone.now()
            
            project.save()
            
            # Log de l'activité
            print(f"Projet {project.id} - Statut changé de '{old_status}' vers '{new_status}' par {request.user.email}")
            
            serializer = self.get_serializer(project)
            return Response({
                'message': f'Statut du projet mis à jour vers "{new_status}"',
                'project': serializer.data
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response(
                {'error': f'Erreur lors de la mise à jour: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def increment_view(self, request, pk=None):
        """Incrémenter le compteur de vues d'un projet"""
        try:
            project = self.get_object()
            
            # Éviter de compter les vues du propriétaire du projet
            if project.client == request.user:
                serializer = self.get_serializer(project)
                return Response(serializer.data, status=status.HTTP_200_OK)
            
            # Vérifier si l'utilisateur a déjà vu ce projet récemment (dans les dernières 24h)
            recent_view = ProjectView.objects.filter(
                project=project,
                viewer=request.user,
                created_at__gte=timezone.now() - timezone.timedelta(hours=24)
            ).first()
            
            if not recent_view:
                # Incrémenter le compteur atomiquement
                with transaction.atomic():
                    ClientProject.objects.filter(pk=project.pk).update(
                        views_count=models.F('views_count') + 1
                    )
                    
                    # Enregistrer la vue pour les statistiques
                    ProjectView.objects.create(
                        project=project,
                        viewer=request.user,
                        ip_address=self.get_client_ip(request),
                        user_agent=request.META.get('HTTP_USER_AGENT', '')[:255]
                    )
                
                # Récupérer le projet mis à jour
                project.refresh_from_db()
                
                print(f"Vue ajoutée pour le projet {project.id} par {request.user.email}")
            
            serializer = self.get_serializer(project)
            return Response(serializer.data, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response(
                {'error': f'Erreur lors de l\'incrémentation des vues: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['get'], permission_classes=[IsAuthenticated])
    @action(detail=True, methods=['get'], permission_classes=[IsAuthenticated])
    def view_statistics(self, request, pk=None):
        """Obtenir les statistiques de vues d'un projet"""
        try:
            project = self.get_object()
            
            # Vérifier que l'utilisateur est bien le propriétaire du projet
            if project.client != request.user:
                return Response(
                    {'error': 'Vous n\'avez pas les permissions pour voir ces statistiques'},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Statistiques des vues
            total_views = project.views_count
            unique_viewers = ProjectView.objects.filter(project=project).values('viewer').distinct().count()
            
            # Vues par jour (7 derniers jours)
            from django.db.models import Count
            seven_days_ago = timezone.now() - timezone.timedelta(days=7)
            views_by_day = ProjectView.objects.filter(
                project=project,
                created_at__gte=seven_days_ago
            ).extra({
                'day': 'date(created_at)'
            }).values('day').annotate(count=Count('id')).order_by('day')
            
            # Top viewers (si applicable)
            top_viewers = ProjectView.objects.filter(
                project=project
            ).values(
                'viewer__first_name', 
                'viewer__last_name'
            ).annotate(
                view_count=Count('id')
            ).order_by('-view_count')[:5]
            
            return Response({
                'project_id': project.id,
                'total_views': total_views,
                'unique_viewers': unique_viewers,
                'views_by_day': list(views_by_day),
                'top_viewers': list(top_viewers),
                'offers_count': project.project_offers.count(),
                'created_at': project.created_at,
                'status': project.status
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response(
                {'error': f'Erreur lors de la récupération des statistiques: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        

class ProjectOfferViewSet(viewsets.ModelViewSet):
    """ViewSet pour la gestion des offres sur les projets"""
    serializer_class = ProjectOfferSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = ProjectOffer.objects.select_related(
            'project', 'provider__user'
        ).prefetch_related('provider__reviews_received')
        
        # Filtrage basé sur le rôle de l'utilisateur
        if hasattr(self.request.user, 'provider_profile'):
            # Prestataire : voir ses propres offres
            queryset = queryset.filter(provider=self.request.user.provider_profile)
        else:
            # Client : voir les offres sur ses projets
            queryset = queryset.filter(project__client=self.request.user)
        
        return queryset
    
    def get_serializer_class(self):
        if self.action == 'create':
            return ProjectOfferCreateSerializer
        return ProjectOfferSerializer
    
    @action(detail=False, methods=['get'])
    def by_project(self, request):
        """Récupérer les offres pour un projet spécifique"""
        print("exemple exmepl")
        project_id = request.query_params.get('project_id')
        print(project_id)
        if not project_id:
            return Response(
                {'error': 'project_id requis'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            project = ClientProject.objects.get(id=project_id)
        except ClientProject.DoesNotExist:
            return Response(
                {'error': 'Projet non trouvé'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Vérifier les permissions
        if project.client != request.user and not hasattr(request.user, 'provider_profile'):
            return Response(
                {'error': 'Permission refusée'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        queryset = self.get_queryset().filter(project=project)
        
        # Marquer les offres comme vues si c'est le client
        if project.client == request.user:
            queryset.update(viewed_by_client=True)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['patch'])
    def update_status(self, request, pk=None):
        """Mettre à jour le statut d'une offre (accepter/rejeter)"""
        offer = self.get_object()
        
        # Seul le client propriétaire du projet peut modifier le statut
        if offer.project.client != request.user:
            return Response(
                {'error': 'Permission refusée'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        new_status = request.data.get('status')
        if new_status not in ['accepted', 'rejected']:
            return Response(
                {'error': 'Statut invalide. Utilisez "accepted" ou "rejected"'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        with transaction.atomic():
            # Si l'offre est acceptée, rejeter toutes les autres offres du projet
            if new_status == 'accepted':
                ProjectOffer.objects.filter(
                    project=offer.project
                ).exclude(id=offer.id).update(status='rejected')
                
                # Mettre le projet en cours
                offer.project.status = 'in_progress'
                offer.project.save()
        
            offer.status = new_status
            offer.client_notes = request.data.get('notes', '')
            offer.save()
        
        serializer = self.get_serializer(offer)
        return Response(serializer.data)
    
    @action(detail=True, methods=['delete'])
    def withdraw(self, request, pk=None):
        """Retirer une offre (prestataire uniquement)"""
        offer = self.get_object()
        
        # Seul le prestataire peut retirer son offre
        if offer.provider != request.user.provider_profile:
            return Response(
                {'error': 'Permission refusée'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # On ne peut retirer une offre que si elle est en attente
        if offer.status != 'pending':
            return Response(
                {'error': 'Impossible de retirer une offre déjà traitée'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        offer.status = 'withdrawn'
        offer.save()
        
        return Response({'message': 'Offre retirée avec succès'})


class ProjectFavoriteViewSet(viewsets.ModelViewSet):
    """ViewSet pour la gestion des projets favoris"""
    serializer_class = ProjectFavoriteSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['get', 'post', 'delete']
    
    def get_queryset(self):
        if not hasattr(self.request.user, 'provider_profile'):
            return ProjectFavorite.objects.none()
        
        return ProjectFavorite.objects.filter(
            provider=self.request.user.provider_profile
        ).select_related('project__client', 'project__category')
    
    def create(self, request, *args, **kwargs):
        """Ajouter un projet aux favoris"""
        if not hasattr(request.user, 'provider_profile'):
            return Response(
                {'error': 'Seuls les prestataires peuvent avoir des favoris'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        project_id = request.data.get('project_id')
        if not project_id:
            return Response(
                {'error': 'project_id requis'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            project = ClientProject.objects.get(id=project_id)
        except ClientProject.DoesNotExist:
            return Response(
                {'error': 'Projet non trouvé'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        favorite, created = ProjectFavorite.objects.get_or_create(
            project=project,
            provider=request.user.provider_profile
        )
        
        if created:
            serializer = self.get_serializer(favorite)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        else:
            return Response(
                {'message': 'Projet déjà en favoris'},
                status=status.HTTP_200_OK
            )