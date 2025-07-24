from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from operation.models import User
from django.db import transaction
from django.utils import timezone
from datetime import timedelta
import logging

logger = logging.getLogger(__name__)

@api_view(['POST'])
@permission_classes([AllowAny])
def admin_login(request):
    """
    Endpoint de connexion spécifique pour les administrateurs
    Vérifie que l'utilisateur est admin (is_staff=True) avant de se connecter
    """
    email = request.data.get('email')
    password = request.data.get('password')
    
    if not email or not password:
        return Response({
            'error': 'Email et mot de passe requis',
            'code': 'MISSING_CREDENTIALS'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        # 1. Vérifier si l'utilisateur existe
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            logger.warning(f"Tentative de connexion admin avec email inexistant: {email}")
            return Response({
                'error': 'Utilisateur non trouvé ou non autorisé',
                'code': 'ADMIN_NOT_FOUND'
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        # 2. Vérifier que l'utilisateur est admin AVANT l'authentification
        if not user.is_staff:
            logger.warning(f"Tentative de connexion admin par utilisateur non-admin: {email}")
            return Response({
                'error': 'Accès administrateur requis',
                'code': 'NOT_ADMIN'
            }, status=status.HTTP_403_FORBIDDEN)
        
        # 3. Vérifier que le compte est actif
        if not user.is_active:
            logger.warning(f"Tentative de connexion admin avec compte inactif: {email}")
            return Response({
                'error': 'Compte administrateur désactivé',
                'code': 'ACCOUNT_DISABLED'
            }, status=status.HTTP_403_FORBIDDEN)
        
        # 4. Authentifier avec le mot de passe
        authenticated_user = authenticate(username=user.username, password=password)
        if not authenticated_user:
            logger.warning(f"Échec d'authentification admin pour: {email}")
            return Response({
                'error': 'Email ou mot de passe incorrect',
                'code': 'INVALID_CREDENTIALS'
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        # 5. Générer les tokens JWT
        refresh = RefreshToken.for_user(authenticated_user)
        access_token = refresh.access_token
        
        # 6. Ajouter des claims spécifiques admin au token
        access_token['is_admin'] = True
        access_token['user_type'] = 'admin'
        access_token['permissions'] = ['admin_panel', 'manage_users', 'manage_projects', 'manage_disputes']
        
        # 7. Logger la connexion réussie
        logger.info(f"Connexion admin réussie pour: {email}")
        
        # 8. Mettre à jour la dernière connexion
        authenticated_user.last_login = timezone.now()
        authenticated_user.save(update_fields=['last_login'])
        
        return Response({
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
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(f"Erreur lors de la connexion admin: {str(e)}")
        return Response({
            'error': 'Erreur interne du serveur',
            'code': 'INTERNAL_ERROR'
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