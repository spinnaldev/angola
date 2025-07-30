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
from django.utils import timezone
from datetime import timedelta
from .models import Conversation, Message, User
from .serializers import ConversationSerializer, MessageSerializer
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from django.db.models import Q, Count, Prefetch
from rest_framework import viewsets, status, filters
from rest_framework.decorators import action, api_view, permission_classes
import logging

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