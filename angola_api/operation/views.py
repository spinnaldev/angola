from django.forms import ValidationError
from django.shortcuts import render
import math
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
from .models import ResetPasswordCode
from rest_framework.views import APIView
from django.core.mail import send_mail
import random
import string
from django.conf import settings
from rest_framework_simplejwt.tokens import RefreshToken
# from django.contrib.gis.geos import Point
# from django.contrib.gis.measure import D
# from django.contrib.gis.db.models.functions import Distance

from .models import (
    Category, SubCategory, Provider, ProviderService, Portfolio, 
    Certificate, Review, ReviewImage, Favorite, Conversation, 
    Message, Attachment, Dispute, DisputeEvidence, Notification, Report
)
from .serializers import (
    UserSerializer, UserUpdateSerializer, CategorySerializer, SubCategorySerializer,
    ProviderListSerializer, ProviderDetailSerializer, ProviderServiceSerializer,
    PortfolioSerializer, CertificateSerializer, ReviewSerializer,
    FavoriteSerializer, ConversationSerializer, MessageSerializer,
    DisputeSerializer, DisputeEvidenceSerializer, NotificationSerializer,
    ReportSerializer, RegisterSerializer
)
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
    
    def get_permissions(self):
        if self.action == 'create':
            return [AllowAny()]
        elif self.action in ['update', 'partial_update', 'destroy']:
            return [IsOwnerOrReadOnly()]
        return [IsAuthenticated()]
    
    def get_serializer_class(self):
        if self.action in ['update', 'partial_update']:
            return UserUpdateSerializer
        return UserSerializer
    
    @action(detail=False, methods=['get'])
    def me(self, request):
        serializer = self.get_serializer(request.user)
        return Response(serializer.data)
    
    @action(detail=False, methods=['put'])
    def update_me(self, request):
        serializer = UserUpdateSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

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
    
    @action(detail=False, methods=['put'])
    def update_me(self, request):
        user = request.user
        if not hasattr(user, 'provider_profile'):
            return Response({"detail": "You are not a provider"}, status=status.HTTP_400_BAD_REQUEST)
        
        provider = user.provider_profile
        serializer = ProviderDetailSerializer(provider, data=request.data, partial=True, context={'request': request})
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
    
    def get_queryset(self):
        provider_id = self.request.query_params.get('provider_id')
        if provider_id:
            return ProviderService.objects.filter(provider_id=provider_id)
        return ProviderService.objects.all()
    
    # def get_permissions(self):
    #     if self.action == 'list' or self.action == 'retrieve':
    #         return [AllowAny()]
    #     return [IsAuthenticated()]
    
    def perform_create(self, serializer):
        # Make sure the logged-in user is a provider
        if not hasattr(self.request.user, 'provider_profile'):
            raise ValidationError("Only providers can create services")
        serializer.save(provider=self.request.user.provider_profile)
    
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