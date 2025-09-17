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

from .signals import send_bulk_notification, send_test_fcm_notification ,create_offer_status_notification_with_extradata

from .sms_service import InfobipSMSService, check_sms_rate_limit, increment_sms_rate_limit
from .permissions import VerificationPermissionMixin
from operation.decorators import require_verification
from .models import *
from rest_framework.views import APIView
from django.core.mail import send_mail
import random
import string
from django.conf import settings
from rest_framework_simplejwt.tokens import RefreshToken
from django.db import transaction
from django.db.models import Sum
import logging
from django.utils.translation import gettext_lazy as _
from django.utils.translation import get_language_from_request
from django.core.cache import cache

from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from rest_framework.parsers import MultiPartParser, FormParser

from .models import FCMToken, NotificationPreference, NotificationHistory
from .fcm_service import FCMService
from .serializers import (
    FCMTokenSerializer, 
    NotificationPreferenceSerializer,
    NotificationHistorySerializer
)

logger = logging.getLogger(__name__)

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
                {"detail": _("Email et mot de passe sont requis")}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Chercher l'utilisateur par email
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response(
                {"detail": _("Aucun compte trouvé avec cet email")}, 
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Vérifier le mot de passe
        if not user.check_password(password):
            return Response(
                {"detail": _("Mot de passe incorrect")}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Si l'utilisateur n'est pas actif
        if not user.is_active:
            return Response(
                {"detail": _("Ce compte a été désactivé")}, 
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
        try:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            
            # Créer l'utilisateur
            user = serializer.save()
            
            # Le serializer s'occupe déjà de retourner le bon format
            response_data = serializer.to_representation(user)
            
            return Response(response_data, status=status.HTTP_201_CREATED)
            
        except serializers.ValidationError as e:
            # Personnaliser les messages d'erreur
            errors = e.detail
            
            # Transformer les erreurs pour les rendre plus conviviales
            friendly_errors = {}
            
            if 'email' in errors:
                friendly_errors['email'] = "Cette adresse email est déjà utilisée par un autre compte."
                
            if 'username' in errors:
                friendly_errors['username'] = "Ce nom d'utilisateur est déjà pris."
                
            # Garder les autres erreurs telles quelles
            for field, message in errors.items():
                if field not in friendly_errors:
                    friendly_errors[field] = message
            
            return Response(friendly_errors, status=status.HTTP_400_BAD_REQUEST)
            
        except Exception as e:
            logger.error(f"Erreur inattendue lors de l'inscription: {str(e)}")
            return Response(
                {"detail": "Une erreur inattendue s'est produite. Veuillez réessayer."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
class PasswordResetRequestView(APIView):
    """
    Vue pour demander un code de réinitialisation de mot de passe
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        try:
            logger.debug("Début de la demande de réinitialisation de mot de passe")
            
            email = request.data.get('email')
            logger.info(f"Email reçu: {email}")
            
            if not email:
                return Response(
                    {"detail": _("Email requis")}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Vérifier si l'utilisateur existe
            try:
                user = User.objects.get(email=email)
                logger.debug(f"Utilisateur trouvé: {user.username}")
                
                # Générer un code à 6 chiffres
                code = ''.join(random.choices(string.digits, k=6))
                logger.debug(f"Code généré: {code}")
                
                # Supprimer les anciens codes pour cet utilisateur
                deleted_count = ResetPasswordCode.objects.filter(user=user).delete()[0]
                logger.debug(f"Anciens codes supprimés: {deleted_count}")
                
                # Créer un nouveau code
                expiration = timezone.now() + timedelta(minutes=15)
                reset_code = ResetPasswordCode.objects.create(
                    user=user,
                    code=code,
                    expires_at=expiration
                )
                logger.debug(f"Nouveau code créé avec expiration: {expiration}")
                
                # Envoyer l'email
                subject = 'Code de réinitialisation - Teyago Services'
                message = f"""
                Bonjour {user.first_name or user.username},

                Vous avez demandé la réinitialisation de votre mot de passe pour votre compte Teyago Services.

                Votre code de réinitialisation est : {code}

                ⚠️ Important :
                • Ce code est valable pendant 15 minutes uniquement
                • Si vous n'avez pas demandé cette réinitialisation, ignorez cet email
                • Ne partagez jamais ce code avec personne

                Cordialement,
                L'équipe Teyago Services
                                """
                
                try:
                    logger.debug("Tentative d'envoi d'email...")
                    send_mail(
                        subject,
                        message,
                        settings.DEFAULT_FROM_EMAIL,
                        [email],
                        fail_silently=False,
                    )
                    logger.info(f"Email envoyé avec succès à {email} avec le code {code}")
                    
                    return Response(
                        {"detail": _("Code de réinitialisation envoyé")}, 
                        status=status.HTTP_200_OK
                    )
                    
                except Exception as e:
                    logger.error(f"Erreur envoi email: {str(e)}")
                    # Même en cas d'erreur d'email, on retourne une réponse positive pour la sécurité
                    return Response(
                        {"detail": _("Si cet email existe, un code de réinitialisation a été envoyé")}, 
                        status=status.HTTP_200_OK
                    )
                
            except User.DoesNotExist:
                logger.warning(f"Tentative de reset pour email inexistant: {email}")
                # Pour des raisons de sécurité, ne pas révéler que l'email n'existe pas
                return Response(
                    {"detail": _("Si cet email existe, un code de réinitialisation a été envoyé")}, 
                    status=status.HTTP_200_OK
                )
                
        except Exception as e:
            logger.error(f"Erreur inattendue dans PasswordResetRequestView: {str(e)}")
            logger.error(f"Type d'erreur: {type(e)}")
            import traceback
            logger.error(f"Traceback: {traceback.format_exc()}")
            
            return Response(
                {"detail": "Erreur interne du serveur"}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class VerifyResetCodeView(APIView):
    """
    Vue pour vérifier le code de réinitialisation
    """
    permission_classes = [AllowAny] 

    def post(self, request):
        email = request.data.get('email')
        code = request.data.get('code')
        
        if not email or not code:
            return Response(
                {"detail": _("Email et code sont requis")}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Vérifier si l'utilisateur existe
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response(
                {"detail": _("Code invalide")}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Vérifier si le code existe et est valide
        try:
            reset_code = ResetPasswordCode.objects.get(user=user, code=code)
            
            # Vérifier si le code a expiré
            if reset_code.expires_at < timezone.now():
                reset_code.delete()
                return Response(
                    {"detail": _("Code expiré")}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
                
        except ResetPasswordCode.DoesNotExist:
            return Response(
                {"detail": _("Code invalide")}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        return Response(
            {"detail": _("Code vérifié avec succès")}, 
            status=status.HTTP_200_OK
        )

class PasswordResetConfirmView(APIView):
    """
    Vue pour réinitialiser le mot de passe avec le code
    """
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email')
        code = request.data.get('code')
        new_password = request.data.get('new_password')
        
        if not email or not code or not new_password:
            return Response(
                {"detail": _("Email, code et nouveau mot de passe sont requis")}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Vérifier si l'utilisateur existe
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response(
                {"detail": _("Code invalide")}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Vérifier si le code existe et est valide
        try:
            reset_code = ResetPasswordCode.objects.get(user=user, code=code)
            
            # Vérifier si le code a expiré
            if reset_code.expires_at < timezone.now():
                reset_code.delete()
                return Response(
                    {"detail": _("Code expiré")}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
                
        except ResetPasswordCode.DoesNotExist:
            return Response(
                {"detail": _("Code invalide")}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Changer le mot de passe
        user.set_password(new_password)
        user.save()
        
        # Supprimer le code
        reset_code.delete()
        
        return Response(
            {"detail": _("Mot de passe réinitialisé avec succès")}, 
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
    
    # @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    # def me(self, request):
    #     """Récupérer le profil de l'utilisateur connecté"""
    #     try:
    #         logger.debug("=== ACTION ME DEBUG ===")
    #         logger.debug(f"Request: {request}")
    #         logger.debug(f"Request user: {request.user}")
    #         logger.debug(f"User type: {type(request.user)}")
    #         logger.debug(f"Is authenticated: {request.user.is_authenticated}")
    #         logger.debug(f"Is anonymous: {request.user.is_anonymous}")
    #         logger.debug(f"User ID: {getattr(request.user, 'id', 'None')}")
    #         logger.debug(f"Username: {getattr(request.user, 'username', 'None')}")
            
    #         # Vérifier les headers
    #         auth_header = request.META.get('HTTP_AUTHORIZATION', 'None')
    #         logger.debug(f"Authorization header: {auth_header[:50] if auth_header != 'None' else 'None'}...")
            
    #         # Debug des métadonnées de la requête
    #         logger.debug(f"Request META keys: {list(request.META.keys())}")
            
    #         # Vérification explicite de l'authentification
    #         if not hasattr(request, 'user'):
    #             logger.error("❌ request.user n'existe pas")
    #             return Response(
    #                 {"detail": "Authentication error: no user in request"}, 
    #                 status=status.HTTP_401_UNAUTHORIZED
    #             )
            
    #         if request.user is None:
    #             logger.error("❌ request.user est None")
    #             return Response(
    #                 {"detail": "Authentication error: user is None"}, 
    #                 status=status.HTTP_401_UNAUTHORIZED
    #             )
            
    #         if not request.user.is_authenticated:
    #             logger.warning("❌ Utilisateur non authentifié dans l'action me")
    #             return Response(
    #                 {"detail": "Authentication credentials were not provided."}, 
    #                 status=status.HTTP_401_UNAUTHORIZED
    #             )
            
    #         if request.user.is_anonymous:
    #             logger.warning("❌ Utilisateur anonyme dans l'action me")
    #             return Response(
    #                 {"detail": "Anonymous user not allowed."}, 
    #                 status=status.HTTP_401_UNAUTHORIZED
    #             )
            
    #         # Vérifier que l'utilisateur existe en base
    #         try:
    #             user = User.objects.get(id=request.user.id)
    #             logger.debug(f"✅ Utilisateur trouvé en base: {user}")
    #         except User.DoesNotExist:
    #             logger.error(f"❌ Utilisateur {request.user.id} non trouvé en base")
    #             return Response(
    #                 {"detail": "User not found in database"}, 
    #                 status=status.HTTP_404_NOT_FOUND
    #             )
            
    #         logger.debug(f"✅ Sérialisation de l'utilisateur: {request.user}")
    #         serializer = self.get_serializer(request.user)
    #         logger.debug(f"✅ Données sérialisées: {serializer.data}")
            
    #         return Response(serializer.data)
            
    #     except Exception as e:
    #         logger.error(f"❌ Erreur dans l'action me: {str(e)}")
    #         logger.error(f"Type d'erreur: {type(e)}")
    #         import traceback
    #         logger.error(f"Traceback: {traceback.format_exc()}")
            
    #         return Response(
    #             {"detail": f"Internal server error: {str(e)}"}, 
    #             status=status.HTTP_500_INTERNAL_SERVER_ERROR
    #         )
    
    @action(detail=False, methods=['put', 'patch'])
    def update_me(self, request):
        """Mettre à jour le profil de l'utilisateur connecté"""
        user = request.user
        
        # ✅ AJOUT DE LOGS POUR DEBUG
        logger.info(f"🔄 Mise à jour profil pour utilisateur: {user.id} ({user.email})")
        logger.info(f"📋 Données reçues: {request.data}")
        logger.info(f"📎 Fichiers reçus: {request.FILES}")
        
        # ✅ VALIDATION DE L'UTILISATEUR
        if not user.is_authenticated:
            logger.error("❌ Utilisateur non authentifié")
            return Response(
                {"detail": "Authentication required"}, 
                status=status.HTTP_401_UNAUTHORIZED
            )
        
        serializer = UserUpdateSerializer(user, data=request.data, partial=True, context={'request': request})
        
        if serializer.is_valid():
            logger.info("✅ Données valides, mise à jour en cours...")
            
            try:
                # Sauvegarder les modifications
                updated_user = serializer.save()
                logger.info(f"✅ Utilisateur mis à jour: {updated_user.id}")
                
                # ✅ RETOURNER LES DONNÉES COMPLÈTES AVEC COMPANY_NAME
                response_serializer = UserSerializer(updated_user, context={'request': request})
                response_data = response_serializer.data
                
                logger.info(f"📤 Données de réponse: {response_data}")
                
                return Response(response_data, status=status.HTTP_200_OK)
                
            except Exception as e:
                logger.error(f"❌ Erreur lors de la sauvegarde: {str(e)}")
                return Response(
                    {"detail": f"Erreur lors de la mise à jour: {str(e)}"}, 
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        else:
            logger.error(f"❌ Erreurs de validation: {serializer.errors}")
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

class GetUserByIdView(APIView):
    """
    Vue pour récupérer un utilisateur par son ID
    """
    permission_classes = [AllowAny]  # Pas d'auth pour éviter les problèmes
    
    def get(self, request, user_id):
        """Récupérer un utilisateur par son ID"""
        try:
            logger.debug(f"=== GET USER BY ID: {user_id} ===")
            
            # Vérifier que l'ID est valide
            try:
                user_id = int(user_id)
            except (ValueError, TypeError):
                return Response(
                    {"detail": "ID utilisateur invalide"}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Chercher l'utilisateur
            try:
                user = User.objects.get(id=user_id)
                logger.debug(f"✅ Utilisateur trouvé: {user.username}")
            except User.DoesNotExist:
                return Response(
                    {"detail": "Utilisateur non trouvé"}, 
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Sérialiser les données
            serializer = UserSerializer(user)
            
            return Response({
                "success": True,
                "user": serializer.data,
                "message": f"Utilisateur {user.username} récupéré avec succès"
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"❌ Erreur dans GetUserByIdView: {str(e)}")
            import traceback
            logger.error(f"Traceback: {traceback.format_exc()}")
            
            return Response(
                {"detail": f"Erreur serveur: {str(e)}"}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
class CurrentUserView(APIView):
    """
    Vue simple pour récupérer les informations de l'utilisateur connecté
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        """Récupérer le profil de l'utilisateur connecté"""
        try:
            logger.debug("=== CURRENT USER VIEW DEBUG ===")
            logger.debug(f"Request user: {request.user}")
            logger.debug(f"Is authenticated: {request.user.is_authenticated}")
            logger.debug(f"User ID: {getattr(request.user, 'id', 'None')}")
            logger.debug(f"Username: {getattr(request.user, 'username', 'None')}")
            
            # Vérifier les headers
            auth_header = request.META.get('HTTP_AUTHORIZATION', 'None')
            logger.debug(f"Authorization header: {auth_header[:50] if auth_header != 'None' else 'None'}...")
            
            if not request.user.is_authenticated:
                logger.warning("❌ Utilisateur non authentifié")
                return Response(
                    {"detail": "Authentication credentials were not provided."}, 
                    status=status.HTTP_401_UNAUTHORIZED
                )
            
            if request.user.is_anonymous:
                logger.warning("❌ Utilisateur anonyme")
                return Response(
                    {"detail": "Anonymous user not allowed."}, 
                    status=status.HTTP_401_UNAUTHORIZED
                )
            
            # Sérialiser les données utilisateur
            serializer = UserSerializer(request.user)
            logger.debug(f"✅ Données sérialisées: {serializer.data}")
            
            return Response({
                "success": True,
                "user": serializer.data
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"❌ Erreur dans CurrentUserView: {str(e)}")
            import traceback
            logger.error(f"Traceback: {traceback.format_exc()}")
            
            return Response(
                {"detail": f"Internal server error: {str(e)}"}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
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
        
        # Calculer les prestations de ce mois
        from django.utils import timezone
        from datetime import datetime
        current_month = timezone.now().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        
        # Prestations terminées ce mois
        prestations_completed_this_month = provider.quote_requests.filter(
            status='completed',
            completed_at__gte=current_month
        ).count()
        
        # Prestations en cours
        prestations_in_progress = provider.quote_requests.filter(
            status__in=['accepted', 'in_progress']
        ).count()
        
        # Messages non lus (supposant un modèle Message)
        try:
            from operation.models import Message, Conversation
            unread_messages = Message.objects.filter(
                conversation__provider=provider,  # Conversations du prestataire
                sender=models.F('conversation__client'),  # Messages envoyés par le client
                is_read=False  # Non lus
            ).count()
            logger.info(f"Pour les messages non lus on a  {unread_messages}")
        except:
            
            logger.info(f"erreur Pour les messages non lus on a donc 0")
            unread_messages = 0 
        
        # Revenus de ce mois (supposant un champ price dans QuoteRequest)
        try:
            total_earnings_this_month = provider.quote_requests.filter(
                status='completed',
                completed_at__gte=current_month
            ).aggregate(
                total=models.Sum('price')
            )['total'] or 0.0
        except:
            total_earnings_this_month = 0.0
        
        # Note moyenne et total des avis
        avg_rating = provider.avg_rating or 0.0
        total_reviews = provider.reviews_received.count()
        
        stats = {
            'user_type': 'provider',
            'prestations_completed_this_month': prestations_completed_this_month,
            'prestations_in_progress': prestations_in_progress,
            'unread_messages': unread_messages,
            'total_earnings_this_month': float(total_earnings_this_month),
            'avg_rating': float(avg_rating),
            'total_reviews': total_reviews,
            
            # Garder les anciennes données pour compatibilité
            'services_count': provider.provider_services.count(),
            'reviews_count': total_reviews,
            'total_quotes': provider.quote_requests.count(),
            'pending_quotes': provider.quote_requests.filter(status='pending').count(),
        }
    else:
        # Statistiques pour client
        from django.utils import timezone
        current_month = timezone.now().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        
        total_projects = user.client_projects.count()
        active_projects = user.client_projects.filter(status='open').count()
        completed_projects = user.client_projects.filter(status='completed').count()
        reviews_given = user.reviews_given.count()
        
        # Messages non lus pour client
        try:
            from operation.models import Message, Conversation
            unread_messages = Message.objects.filter(
                conversation__client=user,
                is_read=False
            ).exclude(sender=user).count()
        except:
            unread_messages = 0
        
        # Projets créés ce mois
        projects_this_month = user.client_projects.filter(
            created_at__gte=current_month
        ).count()
        
        stats = {
            'user_type': 'client',
            'total_projects': total_projects,
            'active_projects': active_projects,
            'completed_projects': completed_projects,
            'reviews_given': reviews_given,
            'unread_messages': unread_messages,
            'projects_this_month': projects_this_month,
            
            # Garder les anciennes données pour compatibilité
            'pending_projects': user.client_projects.filter(status='open').count(),
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

@action(detail=True, methods=['get'])
def stats(self, request, pk=None):
    """Statistiques publiques d'un prestataire"""
    provider = self.get_object()
    
    # Compter les projets terminés
    total_completed_projects = ProjectOffer.objects.filter(
        provider=provider,
        status='completed'
    ).count()
    
    # Autres statistiques
    avg_rating = provider.avg_rating or 0.0
    total_reviews = provider.reviews_received.count()
    
    return Response({
        'total_completed_projects': total_completed_projects,
        'avg_rating': float(avg_rating),
        'total_reviews': total_reviews,
    })

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
        """Endpoint optimisé pour récupérer les prestataires à proximité"""
        latitude = request.query_params.get('latitude')
        longitude = request.query_params.get('longitude')
        radius =min(float(request.query_params.get('radius', 10.0)) , 70)
        
        if not (latitude and longitude):
            # Fallback vers les prestataires récents
            queryset = Provider.objects.filter(
                is_active=True,
                latitude__isnull=False,
                longitude__isnull=False
            ).order_by('-created_at')[:20]
            serializer = self.get_serializer(queryset, many=True)
            return Response({"results": serializer.data, "count": len(serializer.data)})
        
        try:
            latitude = float(latitude)
            longitude = float(longitude)
        except (ValueError, TypeError):
            return Response(
                {"detail": "Coordonnées invalides"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Calcul optimisé de la zone de recherche
        import math
        lat_radius = radius / 111.0  # 1° latitude ≈ 111 km
        lng_radius = radius / (111.0 * math.cos(math.radians(latitude)))
        
        # Filtrer les prestataires dans la zone
        providers = Provider.objects.filter(
            # is_active=True,
            latitude__isnull=False,
            longitude__isnull=False,
            latitude__gte=latitude - lat_radius,
            latitude__lte=latitude + lat_radius,
            longitude__gte=longitude - lng_radius,
            longitude__lte=longitude + lng_radius
        )
        
        # Calculer les distances exactes
        providers_with_distance = []
        for provider in providers:
            if provider.latitude and provider.longitude:
                # Calcul de distance avec la formule de Haversine
                distance = self._calculate_distance(
                    latitude, longitude,
                    float(provider.latitude), float(provider.longitude)
                )
                if distance <= radius:
                    providers_with_distance.append((provider, distance))
        
        # Trier par distance
        providers_with_distance.sort(key=lambda x: x[1])
        sorted_providers = [p[0] for p in providers_with_distance[:20]]
        
        serializer = self.get_serializer(sorted_providers, many=True)
        return Response({"results": serializer.data, "count": len(serializer.data)})

    def _calculate_distance(self, lat1, lon1, lat2, lon2):
        """Calcul de distance avec la formule de Haversine"""
        from math import radians, cos, sin, asin, sqrt
        
        # Convertir en radians
        lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
        
        # Formule de Haversine
        dlat = lat2 - lat1
        dlon = lon2 - lon1
        a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
        c = 2 * asin(sqrt(a))
        r = 6371  # Rayon de la Terre en kilomètres
        
        return c * r
    
    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def stats(self, request):
        """Statistiques du prestataire"""
        if not hasattr(request.user, 'provider_profile'):
            return Response({'error': 'User is not a provider'}, status=400)
        
        provider = request.user.provider_profile
        
        # Calculer les statistiques
        this_month = timezone.now().replace(day=1)
        
        # Compter les offres acceptées ce mois-ci
        accepted_offers_this_month = ProjectOffer.objects.filter(
            provider=provider,
            status='accepted',
            created_at__gte=this_month
        ).count()
        
        # Compter les offres en cours (acceptées mais pas encore terminées)
        offers_in_progress = ProjectOffer.objects.filter(
            provider=provider,
            status='accepted',
            project__status='in_progress'
        ).count()
        
        # Compter les messages non lus
        try:
            unread_messages = Message.objects.filter(
                recipient=request.user,
                is_read=False
            ).count()
        except:
            # Si le modèle Message n'existe pas encore
            unread_messages = 0
        
        # Calculer les gains totaux basés sur les offres acceptées ce mois-ci
        total_earnings_this_month = ProjectOffer.objects.filter(
            provider=provider,
            status='accepted',
            created_at__gte=this_month
        ).aggregate(
            total=Sum('proposed_price')
        )['total'] or 0
        
        # Calculer la note moyenne
        try:
            avg_rating = Review.objects.filter(
                provider=provider
            ).aggregate(
                avg=Avg('rating')
            )['avg'] or 0
        except:
            # Si le modèle Review n'existe pas encore
            avg_rating = provider.avg_rating or 0
        
        # Compter le total des avis
        try:
            total_reviews = Review.objects.filter(
                provider=provider
            ).count()
        except:
            # Si le modèle Review n'existe pas encore
            total_reviews = 0
        
        stats = {
            'prestations_completed_this_month': accepted_offers_this_month,
            'prestations_in_progress': offers_in_progress,
            'unread_messages': unread_messages,
            'total_earnings_this_month': float(total_earnings_this_month),
            'avg_rating': float(avg_rating),
            'total_reviews': total_reviews,
            'total_offers_sent': ProjectOffer.objects.filter(provider=provider).count(),
            'pending_offers': ProjectOffer.objects.filter(provider=provider, status='pending').count(),
        }
        
        return Response(stats)


    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def recent_projects(self, request):
        """Récupérer les 5 derniers projets de la plateforme"""
        # if not hasattr(request.user, 'provider_profile'):
        #     return Response({'error': 'User is not a provider'}, status=400)
        
        # Récupérer les 5 derniers projets de toute la plateforme
        recent_projects = ClientProject.objects.filter(
            status='open'  # Seulement les projets ouverts
        ).order_by('-created_at')[:5]
        
        results = []
        for project in recent_projects:
            # Vérifier si l'utilisateur actuel a déjà fait une offre (si c'est un prestataire)
            has_offered = False
            if hasattr(request.user, 'provider_profile'):
                has_offered = ProjectOffer.objects.filter(
                    project=project,
                    provider=request.user.provider_profile
                ).exists()
            
            results.append({
                'id': project.id,
                'title': project.title,
                'status': project.status,
                'client_name': project.client.get_full_name() if project.client else 'Client anonyme',
                'client_id': project.client.id if project.client else None,
                
                # CORRECTION : Utiliser budget_display au lieu de budget
                'budget_display': project.budget_display,
                'min_budget': float(project.min_budget) if project.min_budget else None,
                'max_budget': float(project.max_budget) if project.max_budget else None,
                'budget_range': project.budget_range,
                
                'created_at': project.created_at.isoformat(),
                'description': project.description,  # Ce champ existe dans votre modèle
                'location': project.location,        # Ce champ existe dans votre modèle
                'urgency': project.urgency,          # Ce champ existe dans votre modèle
                'deadline': project.deadline.isoformat() if project.deadline else None,
                'remote_possible': project.remote_possible,
                'offers_count': project.offers_count,  # Propriété définie dans votre modèle
                'time_since_posted': project.time_since_posted,  # Propriété définie dans votre modèle
                'has_user_offered': has_offered,
                
                # Informations sur la catégorie
                'category_name': project.category.name if project.category else '',
                'subcategory_name': project.subcategory.name if project.subcategory else '',
            })
        
        return Response({'results': results})

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
        
        logger.info(queryset)
        return queryset
    
    def perform_create(self, serializer):
        """
        Sets the provider to the current user when creating a service.
        """
        logger.info(self.request.user)
        serializer.save(provider=self.request.user.provider_profile)
    
    #@require_verification("créer un service")
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
    
    #@require_verification("modifier un service")
    def update(self, request, *args, **kwargs):
        # ✅ AJOUT: Extraire les données des fichiers et du formulaire (similaire à create)
        gallery_images = []
        options_data = []
        
        # ✅ AJOUT: Traiter les images de galerie
        gallery_images_count = int(request.data.get('gallery_images_count', 0))
        logger.info("Le nombre d'image est:")
        logger.info(gallery_images_count)
        for i in range(gallery_images_count):
            prefix = f'gallery_image_{i}_'
            if f'{prefix}image' in request.FILES:
                gallery_images.append({
                    'image': request.FILES[f'{prefix}image'],
                    'caption': request.data.get(f'{prefix}caption', ''),
                    'order': i
                })
        
        # ✅ AJOUT: Traiter les options
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
        
        # ✅ AJOUT: Validation des images
        if gallery_images_count > 10:
            return Response(
                {'error': 'Vous ne pouvez pas ajouter plus de 10 images'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Code existant pour la mise à jour
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=kwargs.get('partial', False))
        serializer.is_valid(raise_exception=True)
        
        # ✅ MAINTENANT: Les variables sont définies
        logger.info("Les images sont")
        logger.info(gallery_images)
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


    @action(detail=True, methods=['put'], permission_classes=[IsAuthenticated])
    def toggle_availability(self, request, pk=None):
        """Endpoint spécialisé pour changer la disponibilité d'un service"""
        try:
            service = self.get_object()
            
            # Vérifier que l'utilisateur est bien le propriétaire
            if not hasattr(request.user, 'provider_profile') or service.provider != request.user.provider_profile:
                return Response(
                    {"detail": "Vous n'êtes pas autorisé à modifier ce service"}, 
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Récupérer la nouvelle valeur de disponibilité
            is_available = request.data.get('is_available')
            if is_available is None:
                return Response(
                    {"detail": "Le champ 'is_available' est requis"}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Mettre à jour la disponibilité
            service.is_available = bool(is_available)
            service.save(update_fields=['is_available'])
            
            # Retourner la réponse
            serializer = self.get_serializer(service)
            return Response({
                "detail": f"Service {'activé' if is_available else 'désactivé'} avec succès",
                "service": serializer.data
            })
            
        except Exception as e:
            return Response(
                {"detail": f"Erreur lors de la mise à jour: {str(e)}"}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        

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
    def search(self, request):
        """Recherche de services"""
        query = request.query_params.get('q', '')
        
        if not query:
            return Response({'results': []})
        
        # Recherche dans les titres et descriptions des services
        services = ProviderService.objects.filter(
            Q(title__icontains=query) | 
            Q(description__icontains=query) |
            Q(subcategory__name__icontains=query) |
            Q(subcategory__category__name__icontains=query),
            is_available=True
        ).select_related('provider', 'subcategory')[:20]
        
        results = []
        for service in services:
            results.append({
                'id': service.id,
                'title': service.title,
                'description': service.description,
                'price': float(service.price) if service.price else None,
                'price_type': service.price_type,
                'image_url': service.image_url,
                'rating': float(service.provider.avg_rating) if service.provider.avg_rating else 0.0,
                'provider_id': service.provider.id,
                'provider_name': service.provider.user.get_full_name(),
                'category': service.subcategory.category.name,
                'subcategory': service.subcategory.name,
            })
        
        return Response({'results': results})

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
        serializer = ProviderServiceSerializer(queryset, many=True)
        print("API:Les services récents sont :" + str(queryset))
        print(queryset)
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
        if self.action in ['list', 'retrieve', 'top_reviews']:
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
        """Endpoint public pour récupérer les avis les mieux notés"""
        from django.db.models import Q
        queryset = Review.objects.filter(
            Q(overall_rating__gte=4.0) & Q(is_verified=True)
        ).order_by('-overall_rating', '-created_at')[:10]
        
        serializer = self.get_serializer(queryset, many=True)
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
    
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def send_message(self, request, pk=None):
        """Envoyer un message dans une conversation"""
        try:
            # ✅ CORRECTION : Utiliser l'utilisateur authentifié au lieu de user_id
            content = request.data.get('content', '').strip()
            
            logger.info(f"📤 Tentative d'envoi message: conversation_id={pk}")
            logger.info(f"👤 Utilisateur: {request.user.username} (ID: {request.user.id})")
            logger.info(f"📝 Contenu: {content[:50]}...")
            
            if not content:
                return Response(
                    {"detail": "content est requis"}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Récupérer la conversation
            try:
                conversation = self.get_object()
                logger.info(f"✅ Conversation trouvée: {conversation.id}")
            except Exception as e:
                logger.info(f"❌ Conversation non trouvée: {e}")
                return Response(
                    {"detail": "Conversation non trouvée"}, 
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Vérifier les permissions (utilisateur fait partie de la conversation)
            is_client = conversation.client == request.user
            is_provider = (hasattr(request.user, 'provider_profile') and 
                        conversation.provider == request.user.provider_profile)
            
            if not (is_client or is_provider):
                logger.info(f"❌ Accès refusé pour user {request.user.id}")
                logger.info(f"Client: {conversation.client.id}, Provider: {conversation.provider.id}")
                return Response(
                    {"detail": "Accès non autorisé à cette conversation"}, 
                    status=status.HTTP_403_FORBIDDEN
                )
            
            logger.info(f"✅ Permissions validées: client={is_client}, provider={is_provider}")
            
            # Créer le message
            message = Message.objects.create(
                conversation=conversation,
                sender=request.user,
                content=content
            )
            
            # Mettre à jour la date de la conversation
            conversation.updated_at = timezone.now()
            conversation.save()
            
            logger.info(f"✅ Message créé: {message.id}")
            
            # Sérialiser et retourner (utiliser l'ID de l'utilisateur actuel)
            serializer = MessageSerializer(message, context={'user_id': request.user.id})
            return Response(serializer.data, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            logger.info(f"❌ Erreur dans send_message: {e}")
            import traceback
            traceback.print_exc()
            return Response(
                {"detail": f"Erreur serveur: {str(e)}"}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
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
    
    

    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated])
    def start_conversation(self, request):
        """Démarrer une nouvelle conversation (bidirectionnelle : client ↔ prestataire)"""
        try:
            provider_id = request.data.get('provider_id')
            client_id = request.data.get('client_id')
            initial_message = request.data.get('initial_message', '')
            
            print(f"🚀 Démarrage conversation: provider_id={provider_id}, client_id={client_id}, user={request.user.id}")
            
            # Variables pour stocker les entités
            provider = None
            client = None
            
            # 🎯 LOGIQUE BIDIRECTIONNELLE
            if provider_id and not client_id:
                # CAS 1: Un client veut contacter un prestataire
                try:
                    provider = Provider.objects.get(id=provider_id)
                    client = request.user  # L'utilisateur actuel est le client
                    print(f"📞 Client {client.username} contacte prestataire {provider.user.username}")
                except Provider.DoesNotExist:
                    return Response(
                        {'error': 'Prestataire non trouvé'},
                        status=status.HTTP_404_NOT_FOUND
                    )
                    
            elif client_id and not provider_id:
                # CAS 2: Un prestataire veut contacter un client
                try:
                    client = User.objects.get(id=client_id)
                    if hasattr(request.user, 'provider_profile'):
                        provider = request.user.provider_profile
                        print(f"📞 Prestataire {provider.user.username} contacte client {client.username}")
                    else:
                        return Response(
                            {'error': 'Vous devez être un prestataire pour contacter un client'},
                            status=status.HTTP_400_BAD_REQUEST
                        )
                except User.DoesNotExist:
                    return Response(
                        {'error': 'Client non trouvé'},
                        status=status.HTTP_404_NOT_FOUND
                    )
                    
            elif provider_id and client_id:
                # CAS 3: IDs spécifiques fournis (pour admin ou cas particuliers)
                try:
                    provider = Provider.objects.get(id=provider_id)
                    client = User.objects.get(id=client_id)
                    print(f"📞 Conversation spécifique: client {client.username} ↔ prestataire {provider.user.username}")
                except (Provider.DoesNotExist, User.DoesNotExist):
                    return Response(
                        {'error': 'Prestataire ou client non trouvé'},
                        status=status.HTTP_404_NOT_FOUND
                    )
            else:
                # CAS 4: Paramètres manquants
                return Response(
                    {'error': 'Vous devez fournir soit provider_id soit client_id'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # 🚫 VÉRIFICATION : Pas de conversation avec soi-même
            if client.id == provider.user.id:
                return Response(
                    {'error': 'Vous ne pouvez pas créer une conversation avec vous-même'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # 🔍 VÉRIFIER SI UNE CONVERSATION EXISTE DÉJÀ
            print(f"🔍 Recherche conversation existante entre client {client.id} et provider {provider.id}")
            existing_conversation = Conversation.objects.filter(
                client=client,
                provider=provider
            ).first()
            
            if existing_conversation:
                print(f"✅ Conversation existante trouvée: {existing_conversation.id}")
                # Si un message initial est fourni, l'envoyer
                if initial_message.strip():
                    message = Message.objects.create(
                        conversation=existing_conversation,
                        sender=request.user,
                        content=initial_message.strip()
                    )
                    print(f"✅ Message initial ajouté: {message.id}")
                    
                    # Mettre à jour la date de modification de la conversation
                    existing_conversation.updated_at = timezone.now()
                    existing_conversation.save()
                
                serializer = ConversationSerializer(existing_conversation, context={'request': request})
                return Response(serializer.data, status=status.HTTP_200_OK)
            
            # 📝 CRÉER UNE NOUVELLE CONVERSATION
            print(f"📝 Création nouvelle conversation...")
            conversation = Conversation.objects.create(
                client=client,
                provider=provider
            )
            print(f"✅ Conversation créée: {conversation.id}")
            
            # 💬 ENVOYER LE MESSAGE INITIAL SI FOURNI
            if initial_message.strip():
                message = Message.objects.create(
                    conversation=conversation,
                    sender=request.user,
                    content=initial_message.strip()
                )
                print(f"✅ Message initial créé: {message.id}")
            
            serializer = ConversationSerializer(conversation, context={'request': request})
            return Response(serializer.data, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            print(f"❌ Erreur dans start_conversation: {e}")
            import traceback
            traceback.print_exc()
            return Response(
                {'error': f'Erreur lors de la création de la conversation: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated])
    def start_conversation_from_project(self, request):
        """Démarrer une conversation avec le propriétaire d'un projet"""
        try:
            project_id = request.data.get('project_id')
            initial_message = request.data.get('initial_message', '')
            
            if not project_id:
                return Response(
                    {'error': 'project_id est requis'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Récupérer le projet et son propriétaire
            try:
                from .models import ClientProject  # Ajustez l'import selon votre structure
                project = ClientProject.objects.get(id=project_id)
                project_owner = project.client
            except ClientProject.DoesNotExist:
                return Response(
                    {'error': 'Projet non trouvé'},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Vérifier qu'on ne contacte pas son propre projet
            if request.user.id == project_owner.id:
                return Response(
                    {'error': 'Vous ne pouvez pas contacter votre propre projet'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Vérifier que l'utilisateur actuel est un prestataire
            if not hasattr(request.user, 'provider_profile'):
                return Response(
                    {'error': 'Seuls les prestataires peuvent contacter les propriétaires de projets'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Utiliser l'endpoint start_conversation avec les bons paramètres
            provider = request.user.provider_profile
            client = project_owner
            
            # Vérifier si une conversation existe déjà
            existing_conversation = Conversation.objects.filter(
                client=client,
                provider=provider
            ).first()
            
            if existing_conversation:
                # Ajouter le message initial s'il est fourni
                if initial_message.strip():
                    Message.objects.create(
                        conversation=existing_conversation,
                        sender=request.user,
                        content=initial_message.strip()
                    )
                    existing_conversation.updated_at = timezone.now()
                    existing_conversation.save()
                
                serializer = ConversationSerializer(existing_conversation, context={'request': request})
                return Response(serializer.data, status=status.HTTP_200_OK)
            
            # Créer une nouvelle conversation
            conversation = Conversation.objects.create(
                client=client,
                provider=provider
            )
            
            # Ajouter le message initial
            if initial_message.strip():
                Message.objects.create(
                    conversation=conversation,
                    sender=request.user,
                    content=initial_message.strip()
                )
            
            serializer = ConversationSerializer(conversation, context={'request': request})
            return Response(serializer.data, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            print(f"❌ Erreur dans start_conversation_from_project: {e}")
            return Response(
                {'error': f'Erreur lors de la création de la conversation: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def create_conversation(self, request):
            """Créer une nouvelle conversation"""
            try:
                user_id = request.data.get('user_id')
                provider_id = request.data.get('provider_id')
                initial_message = request.data.get('initial_message', '')
                
                if not user_id or not provider_id:
                    return Response(
                        {'error': 'user_id et provider_id sont requis'}, 
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                try:
                    user = User.objects.get(id=user_id)
                    provider = Provider.objects.get(id=provider_id)
                except (User.DoesNotExist, Provider.DoesNotExist):
                    return Response(
                        {'error': 'Utilisateur ou prestataire non trouvé'}, 
                        status=status.HTTP_404_NOT_FOUND
                    )
                
                # ✅ CORRECTION : Utiliser client et provider
                # Vérifier si une conversation existe déjà
                existing_conversation = Conversation.objects.filter(
                    client=user,
                    provider=provider
                ).first()
                
                if existing_conversation:
                    # Si un message initial est fourni, l'envoyer
                    if initial_message:
                        Message.objects.create(
                            conversation=existing_conversation,
                            sender=user,
                            content=initial_message
                        )
                        # Mettre à jour la date de la conversation
                        existing_conversation.updated_at = timezone.now()
                        existing_conversation.save()
                    
                    serializer = ConversationSerializer(existing_conversation, context={'user_id': user_id})
                    return Response(serializer.data)
                
                # ✅ CORRECTION : Créer nouvelle conversation avec les bons champs
                conversation = Conversation.objects.create(
                    client=user,
                    provider=provider
                )
                
                # Envoyer le message initial si fourni
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
                
            except Exception as e:
                print(f"❌ Erreur dans create_conversation: {e}")
                return Response(
                    {'error': f'Erreur lors de la création de la conversation: {str(e)}'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
class MessageViewSet(viewsets.ModelViewSet):
    queryset = Message.objects.all()
    serializer_class = MessageSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = StandardResultsSetPagination
    
    def get_queryset(self):
        user = self.request.user
        # Filtrer pour ne montrer que les messages des conversations de l'utilisateur
        if hasattr(user, 'provider_profile'):
            # Si c'est un prestataire
            conversations = Conversation.objects.filter(provider=user.provider_profile)
        else:
            # Si c'est un client
            conversations = Conversation.objects.filter(client=user)
        
        return Message.objects.filter(conversation__in=conversations)
    
    def create(self, request, *args, **kwargs):
        """Créer un nouveau message"""
        try:
            conversation_id = request.data.get('conversation')
            content = request.data.get('content', '').strip()
            
            if not conversation_id or not content:
                return Response(
                    {"detail": "conversation et content sont requis"}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Vérifier que la conversation existe
            try:
                conversation = Conversation.objects.get(id=conversation_id)
            except Conversation.DoesNotExist:
                return Response(
                    {"detail": "Conversation non trouvée"}, 
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Vérifier les permissions
            is_client = conversation.client == request.user
            is_provider = (hasattr(request.user, 'provider_profile') and 
                          conversation.provider == request.user.provider_profile)
            
            if not (is_client or is_provider):
                return Response(
                    {"detail": "Accès non autorisé"}, 
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Créer le message
            message = Message.objects.create(
                conversation=conversation,
                sender=request.user,
                content=content
            )
            
            # Mettre à jour la conversation
            conversation.updated_at = timezone.now()
            conversation.save()
            
            serializer = MessageSerializer(message, context={'user_id': request.user.id})
            return Response(serializer.data, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            print(f"❌ Erreur dans create message: {e}")
            return Response(
                {"detail": f"Erreur serveur: {str(e)}"}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# @api_view(['GET'])
# @permission_classes([AllowAny])
# def get_notification_count(request):
#     user_id = request.query_params.get('user_id')
    
#     if not user_id:
#         return Response({"count": 0}, status=status.HTTP_200_OK)
    
#     try:
#         user_id = int(user_id)
#         user = User.objects.get(id=user_id)
        
#         # Compte les notifications non lues pour cet utilisateur
#         count = Notification.objects.filter(user=user, is_read=False).count()
        
#         return Response({"count": count}, status=status.HTTP_200_OK)
#     except (ValueError, User.DoesNotExist):
#         return Response({"count": 0}, status=status.HTTP_200_OK)

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
    
    #@require_verification("ouvrir un litige")
    def perform_create(self, serializer):
        service_id = self.request.data.get('service_id') or self.request.data.get('service')
        provider_id = self.request.data.get('provider_id') or self.request.data.get('provider')
        
        provider = None
        
        # 1. Si service_id fourni, récupérer le provider automatiquement
        if service_id:
            try:
                from .models import ProviderService
                service = ProviderService.objects.get(id=service_id)
                provider = service.provider
            except ProviderService.DoesNotExist:
                raise ValidationError({"service": "Service not found"})
        
        # 2. Si pas de service mais provider_id fourni
        elif provider_id:
            try:
                provider = Provider.objects.get(id=provider_id)
            except Provider.DoesNotExist:
                raise ValidationError({"provider": "Provider not found"})
        
        # 3. Si aucun des deux n'est fourni
        else:
            raise ValidationError({"error": "Either service_id or provider_id is required"})
        
        # Sauvegarder avec client et provider automatiquement définis
        serializer.save(client=self.request.user, provider=provider)
        
    @method_decorator(csrf_exempt)
    @action(detail=True, methods=['post'], parser_classes=[MultiPartParser, FormParser])
    def add_evidence(self, request, pk=None):
        """
        Ajouter une preuve/commentaire à un litige avec fichier optionnel
        ✅ MODIFICATION : Supporte maintenant les commentaires sans fichier
        """
        try:
            dispute = self.get_object()
            
            # Vérifier les droits
            if request.user != dispute.client and request.user != dispute.provider.user:
                return Response(
                    {"detail": "Vous n'avez pas l'autorisation d'ajouter des preuves à ce litige"}, 
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Log du début de traitement
            logger.info(f"Début ajout preuve/commentaire pour litige {pk} par utilisateur {request.user.id}")
            
            # Récupération sécurisée des données
            description = None
            file = None
            
            try:
                description = request.data.get('description', '').strip()
                file = request.FILES.get('file')  # ✅ MODIFICATION : Optionnel maintenant
            except Exception as e:
                logger.error(f"Erreur lecture request.data: {e}")
                return Response(
                    {"detail": "Erreur lors de la lecture des données."}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # ✅ MODIFICATION : Validation adaptée
            if not description:
                return Response(
                    {"detail": "La description est requise"}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # ✅ MODIFICATION : Le fichier n'est plus obligatoire
            # Si pas de fichier, on crée un simple commentaire
            if not file:
                logger.info(f"Création d'un commentaire textuel (sans fichier)")
            else:
                # Validation du fichier seulement s'il est présent
                # Vérification de la taille du fichier
                max_size = 10 * 1024 * 1024  # 10MB
                if file.size > max_size:
                    return Response(
                        {"detail": f"Le fichier est trop volumineux. Taille maximum autorisée: {max_size // (1024*1024)}MB"}, 
                        status=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE
                    )
                
                # Vérification du type de fichier
                allowed_types = ['image/jpeg', 'image/png', 'image/jpg', 'application/pdf']
                if hasattr(file, 'content_type') and file.content_type not in allowed_types:
                    return Response(
                        {"detail": f"Type de fichier non autorisé. Types acceptés: {', '.join(allowed_types)}"}, 
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                logger.info(f"Création d'une preuve avec fichier - Taille: {file.size} bytes")
            
            # ✅ MODIFICATION : Créer la preuve avec ou sans fichier
            try:
                evidence_data = {
                    'dispute': dispute,
                    'user': request.user,
                    'description': description,
                }
                
                # Ajouter le fichier seulement s'il est présent
                if file:
                    evidence_data['file'] = file
                
                evidence = DisputeEvidence.objects.create(**evidence_data)
                
                logger.info(f"Preuve/commentaire créé avec succès - ID: {evidence.id}, Type: {evidence.evidence_type}")
                
                # Sérialiser et retourner
                serializer = DisputeEvidenceSerializer(evidence)
                return Response(serializer.data, status=status.HTTP_201_CREATED)
                
            except Exception as create_error:
                logger.error(f"Erreur création preuve/commentaire: {create_error}")
                return Response(
                    {"detail": "Erreur lors de la sauvegarde. Veuillez réessayer."}, 
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
                
        except Exception as e:
            logger.error(f"Erreur générale add_evidence: {e}")
            
            # Messages d'erreur spécifiques
            if "timeout" in str(e).lower() or "expired" in str(e).lower():
                error_message = "Timeout: la connexion est trop lente."
            elif "permission" in str(e).lower():
                error_message = "Erreur de permissions."
            else:
                error_message = "Erreur interne du serveur."
            
            return Response(
                {"detail": error_message}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
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
    pagination_class = StandardResultsSetPagination
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['is_read', 'user']
    search_fields = ['title', 'message', 'user__username', 'user__first_name', 'user__last_name']
    ordering_fields = ['created_at', 'is_read']
    ordering = ['-created_at']
    
    def get_queryset(self):
        """
        Les admins voient toutes les notifications
        Les utilisateurs normaux voient seulement leurs notifications
        """
        user = self.request.user
        
        # Si c'est un admin, retourner toutes les notifications
        if user.is_staff or user.is_superuser:
            return Notification.objects.all().select_related('user').order_by('-created_at')
        
        # Sinon, retourner seulement les notifications de l'utilisateur
        return Notification.objects.filter(user=user).order_by('-created_at')
    
    @action(detail=True, methods=['post'], url_path='mark_read')
    def mark_read(self, request, pk=None):
        """Marquer une notification spécifique comme lue"""
        try:
            notification = self.get_object()
            
            # Vérifier les permissions
            if notification.user != request.user and not (request.user.is_staff or request.user.is_superuser):
                return Response(
                    {"detail": "Permission refusée"}, 
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Marquer comme lue
            notification.is_read = True
            notification.save()
            
            # Réponse de succès
            return Response({
                "status": "success",
                "message": "Notification marquée comme lue",
                "notification_id": notification.id,
                "is_read": True
            }, status=status.HTTP_200_OK)
            
        except Notification.DoesNotExist:
            return Response(
                {"detail": "Notification non trouvée"}, 
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {"detail": f"Erreur: {str(e)}"}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=False, methods=['post'])
    def mark_all_as_read(self, request):
        """Marquer toutes les notifications comme lues"""
        notifications = self.get_queryset().filter(is_read=False)
        count = notifications.update(is_read=True)
        return Response({"status": "all notifications marked as read", "count": count})
    
    @action(detail=False, methods=['get'])
    def unread_count(self, request):
        """Obtenir le nombre de notifications non lues"""
        count = self.get_queryset().filter(is_read=False).count()
        return Response({"count": count})
    
    @action(detail=False, methods=['get'], url_path='count')
    def count(self, request):
        """Obtenir le nombre de notifications non lues (alias pour unread_count)"""
        count = self.get_queryset().filter(is_read=False).count()
        return Response({"count": count})
    
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Statistiques des notifications (pour admins)"""
        if not (request.user.is_staff or request.user.is_superuser):
            return Response(
                {"detail": "Permission denied"}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        total_notifications = Notification.objects.count()
        unread_notifications = Notification.objects.filter(is_read=False).count()
        read_notifications = Notification.objects.filter(is_read=True).count()
        
        # Notifications par utilisateur (top 10)
        top_users = Notification.objects.values(
            'user__username', 'user__first_name', 'user__last_name'
        ).annotate(
            total=Count('id'),
            unread=Count('id', filter=Q(is_read=False))
        ).order_by('-total')[:10]
        
        # Notifications récentes (24h)
        from datetime import timedelta
        recent_notifications = Notification.objects.filter(
            created_at__gte=timezone.now() - timedelta(hours=24)
        ).count()
        
        return Response({
            "total_notifications": total_notifications,
            "unread_notifications": unread_notifications,
            "read_notifications": read_notifications,
            "recent_24h": recent_notifications,
            "top_users": list(top_users)
        })
    
    @action(detail=False, methods=['post'])
    def bulk_mark_read(self, request):
        """Marquer plusieurs notifications comme lues (pour admins)"""
        if not (request.user.is_staff or request.user.is_superuser):
            return Response(
                {"detail": "Permission denied"}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        notification_ids = request.data.get('notification_ids', [])
        if not notification_ids:
            return Response(
                {"detail": "notification_ids required"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        count = Notification.objects.filter(
            id__in=notification_ids
        ).update(is_read=True)
        
        return Response({
            "status": "success",
            "count": count,
            "message": f"{count} notifications marquées comme lues"
        })
    
    @action(detail=False, methods=['delete'])
    def bulk_delete(self, request):
        """Supprimer plusieurs notifications (pour admins seulement)"""
        if not (request.user.is_staff or request.user.is_superuser):
            return Response(
                {"detail": "Permission denied"}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        notification_ids = request.data.get('notification_ids', [])
        if not notification_ids:
            return Response(
                {"detail": "notification_ids required"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        count, _ = Notification.objects.filter(
            id__in=notification_ids
        ).delete()
        
        return Response({
            "status": "success",
            "count": count,
            "message": f"{count} notifications supprimées"
        })

class QuoteRequestViewSet(viewsets.ModelViewSet):
    """ViewSet pour les demandes de devis avec notifications automatiques"""
    queryset = QuoteRequest.objects.all()
    serializer_class = QuoteRequestSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.is_staff:
            return QuoteRequest.objects.all()
        elif hasattr(user, 'provider_profile'):
            return QuoteRequest.objects.filter(provider=user.provider_profile)
        else:
            return QuoteRequest.objects.filter(client=user)
    
    #@require_verification("faire une demande de devis")
    def perform_create(self, serializer):
        """Créer une demande de devis"""
        service_id = self.request.data.get('service_id') or self.request.data.get('service')
        provider_id = self.request.data.get('provider_id') or self.request.data.get('provider')
        
        provider = None
        service = None
        
        # Logique pour déterminer le provider et service
        if service_id:
            try:
                from .models import ProviderService
                service = ProviderService.objects.get(id=service_id)
                provider = service.provider
            except ProviderService.DoesNotExist:
                raise ValidationError({"service": "Service not found"})
        elif provider_id:
            try:
                provider = Provider.objects.get(id=provider_id)
            except Provider.DoesNotExist:
                raise ValidationError({"provider": "Provider not found"})
        else:
            raise ValidationError({"error": "Either service_id or provider_id is required"})
        
        # Sauvegarder - le signal se chargera de créer la notification
        serializer.save(client=self.request.user, provider=provider, service=service)
    
    @action(detail=True, methods=['post'])
    def update_status(self, request, pk=None):
        """Mettre à jour le statut d'une demande de devis"""
        quote_request = self.get_object()
        status_value = request.data.get('status')
        
        # Validation du statut
        if not status_value or status_value not in [s[0] for s in QuoteRequest.STATUS_CHOICES]:
            return Response(
                {"detail": "Valid status is required"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Vérifier les permissions
        user = request.user
        if not (hasattr(user, 'provider_profile') and quote_request.provider == user.provider_profile):
            return Response(
                {"detail": "You are not authorized to update this quote request"}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Mettre à jour le statut - le signal se chargera de créer la notification
        quote_request.status = status_value
        quote_request.save()
        
        serializer = self.get_serializer(quote_request)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'])
    def available_actions(self, request, pk=None):
        """Obtenir les actions disponibles pour une demande de devis"""
        quote_request = self.get_object()
        user = request.user
        
        actions = []
        
        # Actions pour le prestataire
        if hasattr(user, 'provider_profile') and quote_request.provider == user.provider_profile:
            if quote_request.status == 'pending':
                actions.extend(['accept', 'reject'])
            elif quote_request.status == 'accepted':
                actions.extend(['mark_completed', 'contact_client'])
                
        # Actions pour le client
        elif quote_request.client == user:
            if quote_request.status == 'accepted':
                actions.extend(['contact_provider', 'rate_provider'])
            elif quote_request.status == 'completed':
                actions.extend(['rate_provider', 'request_review'])
        
        return Response({"available_actions": actions})
    
    @action(detail=True, methods=['post'])
    def contact_provider(self, request, pk=None):
        """Créer une conversation avec le prestataire"""
        quote_request = self.get_object()
        
        # Vérifier que l'utilisateur est le client
        if quote_request.client != request.user:
            return Response(
                {"detail": "Only the client can contact the provider"}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Créer ou récupérer la conversation
        from .models import Conversation
        conversation, created = Conversation.objects.get_or_create(
            client=quote_request.client,
            provider=quote_request.provider,
            defaults={'project': getattr(quote_request, 'project', None)}
        )
        
        return Response({
            "conversation_id": conversation.id,
            "message": "Conversation créée avec succès" if created else "Conversation existante récupérée"
        })

# Endpoints pour les notifications (si pas déjà dans urls.py)
# @api_view(['GET'])
# @permission_classes([IsAuthenticated])
# def get_notification_count(request):
#     """Obtenir le nombre de notifications non lues"""
#     count = Notification.objects.filter(user=request.user, is_read=False).count()
#     return Response({"count": count})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_all_notifications_read(request):
    """Marquer toutes les notifications comme lues"""
    count = Notification.objects.filter(user=request.user, is_read=False).update(is_read=True)
    return Response({"count": count, "status": "success"})

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
    
# class QuoteRequestViewSet(viewsets.ModelViewSet):
#     queryset = QuoteRequest.objects.all()
#     serializer_class = QuoteRequestSerializer
#     # permission_classes = [IsAuthenticated]
    
#     def get_queryset(self):
#         user = self.request.user
#         print("Le user est:" + str(user))
#         if user.is_staff:
#             return QuoteRequest.objects.all()
#         elif hasattr(user, 'provider_profile'):
#             print('oui')
#             print(user.id)
#             print(user.provider_profile)
#             return QuoteRequest.objects.filter(provider=user.provider_profile)
#         else:
#             return QuoteRequest.objects.filter(client=user)
    
#     def perform_create(self, serializer):
#         service_id = self.request.data.get('service_id') or self.request.data.get('service')
#         provider_id = self.request.data.get('provider_id') or self.request.data.get('provider')
        
#         provider = None
#         service = None
        
#         # 1. Si service_id fourni, récupérer le provider automatiquement
#         if service_id:
#             try:
#                 from .models import ProviderService
#                 service = ProviderService.objects.get(id=service_id)
#                 provider = service.provider
#             except ProviderService.DoesNotExist:
#                 raise ValidationError({"service": "Service not found"})
        
#         # 2. Si pas de service mais provider_id fourni
#         elif provider_id:
#             try:
#                 provider = Provider.objects.get(id=provider_id)
#             except Provider.DoesNotExist:
#                 raise ValidationError({"provider": "Provider not found"})
        
#         # 3. Si aucun des deux n'est fourni
#         else:
#             raise ValidationError({"error": "Either service_id or provider_id is required"})
        
#         # Sauvegarder avec client, provider et service automatiquement définis
#         serializer.save(client=self.request.user, provider=provider, service=service)
    
#     @action(detail=True, methods=['post'])
#     def update_status(self, request, pk=None):
#         quote_request = self.get_object()
#         status_value = request.data.get('status')
        
#         if not status_value or status_value not in [s[0] for s in QuoteRequest.STATUS_CHOICES]:
#             return Response({"detail": "Valid status is required"}, status=status.HTTP_400_BAD_REQUEST)
        
#         # Vérifier que l'utilisateur est autorisé à modifier le statut
#         user = request.user
#         if hasattr(user, 'provider_profile') and quote_request.provider == user.provider_profile:
#             quote_request.status = status_value
#             quote_request.save()
#             serializer = self.get_serializer(quote_request)
#             return Response(serializer.data)
#         else:
#             return Response({"detail": "You are not authorized to update this quote request"}, 
#                            status=status.HTTP_403_FORBIDDEN)
    

#     @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
#     def recent_quote_requests(self, request):
#         """Récupérer les demandes de devis récentes pour le prestataire"""
#         if not hasattr(request.user, 'provider_profile'):
#             return Response({'error': 'User is not a provider'}, status=400)
        
#         provider = request.user.provider_profile
        
#         # Récupérer les demandes de devis récentes
#         recent_quotes = QuoteRequest.objects.filter(
#             # Filtrer selon tes critères (par exemple, par catégorie de service)
#             status='pending',
#             created_at__gte=timezone.now() - timedelta(days=7)
#         ).order_by('-created_at')[:5]
        
#         results = []
#         for quote in recent_quotes:
#             results.append({
#                 'id': quote.id,
#                 'title': quote.title,
#                 'service_title': quote.service_title,
#                 'client_name': quote.client.get_full_name(),
#                 'client_id': quote.client.id,
#                 'budget': float(quote.budget) if quote.budget else None,
#                 'created_at': quote.created_at.isoformat(),
#                 'description': quote.description,
#             })
        
#         return Response({'results': results})
    
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
    
    #@require_verification("créer un projet")
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
    
    
    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def search(self, request):
        """Recherche de projets pour les prestataires"""
        if not hasattr(request.user, 'provider_profile'):
            return Response({'error': 'User is not a provider'}, status=400)
        
        query = request.query_params.get('q', '')
        
        if not query:
            return Response({'results': []})
        
        # Recherche dans les projets ouverts
        projects = ClientProject.objects.filter(
            Q(title__icontains=query) | 
            Q(description__icontains=query) |
            Q(location__icontains=query),
            status='open'
        ).select_related('client')[:20]
        
        results = []
        for project in projects:
            results.append({
                'id': project.id,
                'title': project.title,
                'description': project.description,
                'budget': float(project.budget) if project.budget else None,
                'location': project.location,
                'status': project.status,
                'urgency': project.urgency,
                'client_name': project.client.get_full_name(),
                'client_id': project.client.id,
                'created_at': project.created_at.isoformat(),
            })
        
        return Response({'results': results})

    
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
        
    @action(detail=True, methods=['get', 'post'], permission_classes=[IsAuthenticated])
    def offers(self, request, pk=None):
        """Gérer les offres d'un projet - AVEC LOGS DEBUG"""
        
        logger.info(f"🎯 === OFFERS ENDPOINT ===")
        logger.info(f"👤 User: {request.user.email}")
        logger.info(f"📋 Project PK: {pk}")
        logger.info(f"🔄 Method: {request.method}")
        logger.info(f"📥 Request data: {request.data}")
        
        try:
            project = self.get_object()
            logger.info(f"✅ Project found: {project.id} - {project.title}")
            logger.info(f"👥 Project client: {project.client.email}")
            logger.info(f"📊 Project status: {project.status}")
            
            if request.method == 'GET':
                logger.info(f"📋 GET: Récupération des offres")
                return self._get_project_offers(request, project)
            
            elif request.method == 'POST':
                logger.info(f"✨ POST: Création nouvelle offre")
                return self._create_project_offer(request, project)
                
        except Exception as e:
            logger.error(f"❌ OFFERS ENDPOINT ERROR: {str(e)}")
            import traceback
            logger.error(f"📋 Offers traceback: {traceback.format_exc()}")
            return Response(
                {'error': f'Erreur dans offers endpoint: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def _get_project_offers(self, request, project):
        """Récupérer les offres d'un projet"""
        try:
            # Vérifier les permissions
            if project.client != request.user and not hasattr(request.user, 'provider_profile'):
                return Response(
                    {'error': 'Vous n\'avez pas accès aux offres de ce projet'},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Récupérer les offres
            offers = ProjectOffer.objects.filter(project=project).select_related(
                'provider__user', 'provider'
            ).order_by('-created_at')
            
            # Sérialiser les offres
            from .serializers import ProjectOfferSerializer  # Ajustez l'import selon votre structure
            serializer = ProjectOfferSerializer(offers, many=True, context={'request': request})
            
            return Response({
                'count': offers.count(),
                'results': serializer.data
            })
            
        except Exception as e:
            return Response(
                {'error': f'Erreur lors de la récupération des offres: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    #@require_verification
    def _create_project_offer(self, request, project):
        """Créer une nouvelle offre sur un projet - AVEC LOGS DEBUG"""
        
        logger.info(f"🚀 === CREATION OFFRE DEBUT ===")
        logger.info(f"👤 User: {request.user.email}")
        logger.info(f"📋 Project ID: {project.id}")
        logger.info(f"📋 Project Title: {project.title}")
        logger.info(f"📋 Project Status: {project.status}")
        logger.info(f"📋 Project Client: {project.client.email}")
        logger.info(f"📥 Request Data: {request.data}")
        
        try:
            # Vérifier que l'utilisateur est un prestataire
            logger.info(f"🔍 VERIFICATION 1: Prestataire check...")
            if not hasattr(request.user, 'provider_profile'):
                logger.error(f"❌ User n'est pas un prestataire")
                return Response(
                    {'error': 'Seuls les prestataires peuvent faire des offres'},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            provider = request.user.provider_profile
            logger.info(f"✅ Provider trouvé: {provider.id}")
            logger.info(f"👥 Provider User: {provider.user.email}")
            logger.info(f"🏢 Provider Company: {getattr(provider, 'company_name', 'N/A')}")
            
            # Vérifier que le projet est ouvert
            logger.info(f"🔍 VERIFICATION 2: Project status...")
            if project.status != 'open':
                logger.error(f"❌ Project status is '{project.status}', not 'open'")
                return Response(
                    {'error': 'Ce projet n\'accepte plus d\'offres'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            logger.info(f"✅ Project is open")
            
            # Vérifier que le prestataire n'a pas déjà fait d'offre
            logger.info(f"🔍 VERIFICATION 3: Existing offer check...")
            existing_offer = ProjectOffer.objects.filter(project=project, provider=provider).first()
            if existing_offer:
                logger.error(f"❌ Existing offer found: {existing_offer.id}")
                return Response(
                    {'error': 'Vous avez déjà fait une offre sur ce projet'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            logger.info(f"✅ No existing offer")
            
            # Vérifier que le prestataire ne fait pas une offre sur son propre projet
            logger.info(f"🔍 VERIFICATION 4: Own project check...")
            if project.client == request.user:
                logger.error(f"❌ User trying to bid on own project")
                return Response(
                    {'error': 'Vous ne pouvez pas faire une offre sur votre propre projet'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            logger.info(f"✅ Not own project")
            
            # Valider les données
            logger.info(f"🔍 VERIFICATION 5: Data validation...")
            required_fields = ['proposed_price', 'delivery_time', 'message']
            for field in required_fields:
                if field not in request.data:
                    logger.error(f"❌ Missing required field: {field}")
                    return Response(
                        {'error': f'Le champ {field} est requis'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                logger.info(f"✅ Field {field}: {request.data[field]}")
            
            # Validation des types de données
            logger.info(f"🔍 VERIFICATION 6: Data types validation...")
            try:
                proposed_price = float(request.data['proposed_price'])
                logger.info(f"✅ Proposed price: {proposed_price}")
            except (ValueError, TypeError) as e:
                logger.error(f"❌ Invalid proposed_price: {e}")
                return Response(
                    {'error': 'Le prix proposé doit être un nombre valide'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            try:
                delivery_time = int(request.data['delivery_time'])
                logger.info(f"✅ Delivery time: {delivery_time} jours")
            except (ValueError, TypeError) as e:
                logger.error(f"❌ Invalid delivery_time: {e}")
                return Response(
                    {'error': 'Le délai de livraison doit être un nombre entier'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Créer l'offre
            logger.info(f"💾 CREATION 1: Creating ProjectOffer...")
            with transaction.atomic():
                try:
                    offer_data = {
                        'project': project,
                        'provider': provider,
                        'proposed_price': proposed_price,
                        'delivery_time': delivery_time,
                        'message': request.data['message'],
                        'includes_materials': request.data.get('includes_materials', False),
                        'warranty_period': request.data.get('warranty_period'),
                        'travel_costs_included': request.data.get('travel_costs_included', True),
                    }
                    logger.info(f"📋 Offer data: {offer_data}")
                    
                    offer = ProjectOffer.objects.create(**offer_data)
                    logger.info(f"✅ ProjectOffer created: ID={offer.id}")
                    
                    # Créer une notification pour le client
                    logger.info(f"🔔 NOTIFICATION 1: Creating notification...")
                    try:
                        notification_data = {
                            'user': project.client,
                            'title': "Nouvelle offre reçue",
                            'message': f"Vous avez reçu une nouvelle offre de {provider.user.get_full_name()} pour votre projet '{project.title}'.",
                            'notification_type': 'new_offer',
                            'related_object_id': offer.id
                        }
                        logger.info(f"📋 Notification data: {notification_data}")
                        
                        # notification = Notification.objects.create(**notification_data)
                        # logger.info(f"✅ Notification created: ID={notification.id}")

                    except Exception as notif_error:
                        logger.error(f"❌ Erreur création notification: {notif_error}")
                        import traceback
                        logger.error(f"📋 Notification traceback: {traceback.format_exc()}")

                    # Envoyer notification FCM
                    logger.info(f"🚁 FCM 1: Sending FCM notification...")
                    try:
                        # send_new_offer_notification(project, offer)
                        logger.info(f"✅ FCM notification sent")
                    except Exception as fcm_error:
                        logger.error(f"❌ Erreur FCM notification: {fcm_error}")
                        import traceback
                        logger.error(f"📋 FCM traceback: {traceback.format_exc()}")
                    
                except Exception as creation_error:
                    logger.error(f"❌ Erreur lors de la création de l'offre: {creation_error}")
                    import traceback
                    logger.error(f"📋 Creation traceback: {traceback.format_exc()}")
                    raise
            
            # Sérialiser et retourner l'offre créée
            logger.info(f"📤 RESPONSE 1: Serializing offer...")
            try:
                from .serializers import ProjectOfferSerializer
                serializer = ProjectOfferSerializer(offer, context={'request': request})
                logger.info(f"✅ Offer serialized successfully")
                
                response_data = {
                    'message': 'Offre créée avec succès',
                    'offer': serializer.data
                }
                logger.info(f"📤 Response data keys: {response_data.keys()}")
                logger.info(f"🎉 === CREATION OFFRE SUCCESS ===")
                
                return Response(response_data, status=status.HTTP_201_CREATED)
                
            except Exception as serializer_error:
                logger.error(f"❌ Erreur serializer: {serializer_error}")
                import traceback
                logger.error(f"📋 Serializer traceback: {traceback.format_exc()}")
                raise
                
        except Exception as e:
            logger.error(f"💥 === CREATION OFFRE ERROR ===")
            logger.error(f"❌ Exception: {str(e)}")
            logger.error(f"❌ Exception type: {type(e).__name__}")
            import traceback
            logger.error(f"📋 Full traceback: {traceback.format_exc()}")
            
            return Response(
                {'error': f'Erreur lors de la création de l\'offre: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class ProjectOfferViewSet(viewsets.ModelViewSet):
    """ViewSet pour la gestion des offres sur les projets"""
    serializer_class = ProjectOfferSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['project', 'status']  # AJOUTER LE FILTRAGE PAR PROJET
    
    def get_queryset(self):
        queryset = ProjectOffer.objects.select_related(
            'project', 'provider__user'
        ).prefetch_related('provider__reviews_received')
        
        # AJOUTER : Filtrage par projet si spécifié
        project_id = self.request.query_params.get('project')
        if project_id:
            try:
                project = ClientProject.objects.get(id=project_id)
                # Vérifier les permissions
                if hasattr(self.request.user, 'provider_profile'):
                    # Prestataire : peut voir toutes les offres du projet (pour transparence)
                    queryset = queryset.filter(project=project)
                elif project.client == self.request.user:
                    # Client : peut voir les offres sur son projet
                    queryset = queryset.filter(project=project)
                else:
                    # Pas d'autorisation
                    return ProjectOffer.objects.none()
            except ClientProject.DoesNotExist:
                return ProjectOffer.objects.none()
        else:
            # Comportement par défaut : filtrer selon le rôle
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
    
    #@require_verification("faire une offre")
    def create(self, request, *args, **kwargs):
        """Créer une nouvelle offre"""
        if not hasattr(request.user, 'provider_profile'):
            return Response(
                {'error': 'Seuls les prestataires peuvent faire des offres'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Vérifier que le projet existe et est ouvert
        project_id = request.data.get('project')
        try:
            project = ClientProject.objects.get(id=project_id)
        except ClientProject.DoesNotExist:
            return Response(
                {'error': 'Projet non trouvé'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        if project.status != 'open':
            return Response(
                {'error': 'Ce projet n\'accepte plus d\'offres'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Vérifier qu'il n'y a pas déjà d'offre de ce prestataire
        existing_offer = ProjectOffer.objects.filter(
            project=project,
            provider=request.user.provider_profile
        ).first()
        
        if existing_offer:
            return Response(
                {'error': 'Vous avez déjà fait une offre pour ce projet'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Créer l'offre
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            offer = serializer.save(provider=request.user.provider_profile)
            
            # Créer une notification pour le client
            # try:
            #     from .models import Notification
            #     Notification.objects.create(
            #         user=project.client,
            #         title="Nouvelle offre reçue",
            #         message=f"Une nouvelle offre a été reçue pour votre projet '{project.title}'",
            #         notification_type='new_offer',
            #         related_object_id=offer.id
            #     )
            # except Exception as e:
            #     print(f"Erreur création notification: {e}")
            
            # return Response(
            #     self.get_serializer(offer).data,
            #     status=status.HTTP_201_CREATED
            # )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
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
    
    @action(detail=True, methods=['put'])
    def update_status(self, request, pk=None):
        """Mettre à jour le statut d'une offre (accepter/rejeter)"""
        offer = self.get_object()
        logger.info("ON modifie le satut")
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
                other_offers = ProjectOffer.objects.filter(
                    project=offer.project
                ).exclude(id=offer.id)
                
                # Rejeter les autres offres et envoyer notifications
                for other_offer in other_offers:
                    if other_offer.status == 'pending':
                        other_offer.status = 'rejected'
                        other_offer.save()
                        
                        # ✅ NOTIFICATION de rejet pour les autres prestataires
                        
                        create_offer_status_notification_with_extradata(other_offer, 'rejected')
                
                # Mettre le projet en cours
                offer.project.status = 'in_progress'
                offer.project.save()
        
            # Mettre à jour l'offre principale
            offer.status = new_status
            offer.client_notes = request.data.get('notes', '')
            offer.save()
            
            logger.info("ON a modifie")

            logger.info("NOTIFICATION pour le prestataire de l'offre modifiée")
            # ✅ NOTIFICATION pour le prestataire de l'offre modifiée
            create_offer_status_notification_with_extradata(offer, new_status)
        
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
        
class ProviderVerificationViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour gérer les vérifications de prestataires
    
    Endpoints disponibles:
    - GET /provider-verification/ : Liste des vérifications (limitée au prestataire connecté)
    - GET /provider-verification/{id}/ : Détail d'une vérification
    - POST /provider-verification/ : Créer une nouvelle demande
    - PUT/PATCH /provider-verification/{id}/ : Modifier une demande
    - DELETE /provider-verification/{id}/ : Supprimer une demande (seulement si not_started)
    
    Actions personnalisées:
    - GET /provider-verification/my-status/ : Statut de ma vérification
    - POST /provider-verification/submit-business/ : Soumettre vérification entreprise
    - POST /provider-verification/submit-individual/ : Soumettre vérification individuelle
    - POST /provider-verification/resend-documents/ : Renvoyer documents après rejet
    """
    
    serializer_class = ProviderVerificationSerializer
    permission_classes = [IsAuthenticated, IsProviderOwner]
    
    def get_queryset(self):
        """Limiter aux vérifications du prestataire connecté"""
        if not hasattr(self.request.user, 'provider_profile'):
            return ProviderVerification.objects.none()
        
        return ProviderVerification.objects.filter(
            provider=self.request.user.provider_profile
        )
    
    def perform_create(self, serializer):
        """Associer automatiquement au prestataire connecté"""
        if not hasattr(self.request.user, 'provider_profile'):
            raise ValidationError("Profil prestataire requis")
        
        serializer.save(provider=self.request.user.provider_profile)
    
    @action(detail=False, methods=['get'], url_path='my-status')
    def my_status(self, request):
        """
        Récupérer le statut de vérification du prestataire connecté
        
        Retourne:
        - Les détails de la vérification si elle existe
        - Un objet vide avec status 'not_started' sinon
        """
        try:
            provider = request.user.provider_profile
            verification = ProviderVerification.objects.get(provider=provider)
            serializer = self.get_serializer(verification)
            return Response(serializer.data)
        except ProviderVerification.DoesNotExist:
            return Response({
                'verification_status': 'not_started',
                'message': 'Aucune demande de vérification trouvée',
                'can_start': True
            })
        except AttributeError:
            return Response(
                {'detail': 'Profil prestataire requis'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
    
    @action(detail=False, methods=['post'], url_path='submit-business')
    def submit_business(self, request):
        """
        Soumettre une vérification d'entreprise
        
        Données requises:
        - business_name: Nom de l'entreprise
        - business_nif: NIF (optionnel)
        - business_registration_number: Numéro RCCM (optionnel)
        - id_card_front: Image recto carte d'identité
        - id_card_back: Image verso carte d'identité
        - business_registration_doc: Document d'entreprise (optionnel)
        """
        try:
            provider = request.user.provider_profile
        except AttributeError:
            return Response(
                {'detail': 'Profil prestataire requis'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Récupérer ou créer la vérification
        verification, created = ProviderVerification.objects.get_or_create(
            provider=provider,
            defaults={
                'is_business': True,
                'document_type': 'id_card'
            }
        )
        
        # Vérifier si modification autorisée
        if not created and not verification.can_be_modified():
            return Response({
                'detail': 'Cette vérification ne peut plus être modifiée',
                'current_status': verification.verification_status
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Valider et sauvegarder
        serializer = self.get_serializer(
            verification, 
            data=request.data, 
            partial=True
        )
        
        if serializer.is_valid():
            # Forcer les valeurs pour entreprise
            serializer.save(
                is_business=True,
                document_type='id_card',
                verification_status='pending',
                submitted_at=timezone.now(),
                # Effacer les données de rejet précédentes
                rejection_reason='',
                verified_by=None,
                verified_at=None
            )
            
            logger.info(f"Vérification entreprise soumise pour {provider.user.username}")
            
            return Response({
                'message': 'Demande de vérification soumise avec succès',
                'verification': serializer.data
            }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['post'], url_path='submit-individual')
    def submit_individual(self, request):
        """
        Soumettre une vérification individuelle
        
        Données requises (au choix):
        - Pour carte d'identité: id_card_front + id_card_back
        - Pour passeport: passport_image
        """
        try:
            provider = request.user.provider_profile
        except AttributeError:
            return Response(
                {'detail': 'Profil prestataire requis'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Déterminer le type de document basé sur les données fournies
        document_type = 'id_card'  # défaut
        if request.data.get('passport_image') and not (
            request.data.get('id_card_front') or request.data.get('id_card_back')
        ):
            document_type = 'passport'
        
        # Récupérer ou créer la vérification
        verification, created = ProviderVerification.objects.get_or_create(
            provider=provider,
            defaults={
                'is_business': False,
                'document_type': document_type
            }
        )
        
        # Vérifier si modification autorisée
        if not created and not verification.can_be_modified():
            return Response({
                'detail': 'Cette vérification ne peut plus être modifiée',
                'current_status': verification.verification_status
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Valider et sauvegarder
        serializer = self.get_serializer(
            verification, 
            data=request.data, 
            partial=True
        )
        
        if serializer.is_valid():
            # Forcer les valeurs pour individuel
            serializer.save(
                is_business=False,
                document_type=document_type,
                verification_status='pending',
                submitted_at=timezone.now(),
                # Effacer les données de rejet précédentes
                rejection_reason='',
                verified_by=None,
                verified_at=None
            )
            
            logger.info(f"Vérification individuelle soumise pour {provider.user.username}")
            
            return Response({
                'message': 'Demande de vérification soumise avec succès',
                'verification': serializer.data
            }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['post'], url_path='resend-documents')
    def resend_documents(self, request, pk=None):
        """
        Renvoyer des documents après un rejet
        Permet de modifier une vérification rejetée
        """
        verification = self.get_object()
        
        if verification.verification_status != 'rejected':
            return Response({
                'detail': 'Cette action n\'est disponible que pour les vérifications rejetées'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Utiliser la logique de mise à jour normale
        serializer = self.get_serializer(
            verification, 
            data=request.data, 
            partial=True
        )
        
        if serializer.is_valid():
            serializer.save()
            
            logger.info(f"Documents renvoyés pour {verification.provider.user.username}")
            
            return Response({
                'message': 'Nouveaux documents soumis avec succès',
                'verification': serializer.data
            })
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'], url_path='requirements')
    def requirements(self, request):
        """
        Retourner les exigences pour la vérification
        """
        return Response({
            'document_types': [
                {
                    'value': 'id_card',
                    'label': 'Carte d\'identité',
                    'description': 'Les deux faces de la carte d\'identité sont requises',
                    'required_files': ['id_card_front', 'id_card_back']
                },
                {
                    'value': 'passport',
                    'label': 'Passeport',
                    'description': 'Page principale du passeport avec photo',
                    'required_files': ['passport_image']
                }
            ],
            'business_fields': [
                {
                    'field': 'business_name',
                    'label': 'Nom de l\'entreprise',
                    'required': True,
                    'description': 'Nom officiel de votre entreprise'
                },
                {
                    'field': 'business_nif',
                    'label': 'NIF',
                    'required': False,
                    'description': 'Numéro d\'identification fiscale'
                },
                {
                    'field': 'business_registration_number',
                    'label': 'Numéro d\'enregistrement',
                    'required': False,
                    'description': 'Numéro RCCM ou équivalent'
                }
            ],
            'file_requirements': {
                'max_size_mb': 5,
                'allowed_formats': ['jpg', 'jpeg', 'png', 'pdf'],
                'image_min_resolution': '800x600'
            }
        })


# ================================================================
# 4. VIEWSET POUR VÉRIFICATION PAR TÉLÉPHONE
# ================================================================
class PhoneVerificationViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour gérer les vérifications par téléphone (clients)
    AVEC LOGS DE DEBUG DÉTAILLÉS
    """
    
    serializer_class = PhoneVerificationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Limiter aux vérifications de l'utilisateur connecté"""
        print(f"📋 get_queryset appelé pour user: {self.request.user.id}")
        queryset = PhoneVerification.objects.filter(user=self.request.user)
        print(f"📋 Queryset trouvé: {queryset.count()} vérifications")
        return queryset
    
    def get_permissions(self):
        """Permissions spécifiques par action"""
        print(f"🔐 get_permissions appelé pour action: {getattr(self, 'action', 'unknown')}")
        if hasattr(self, 'action') and self.action in ['my_status', 'send_code', 'verify_code', 'resend_code']:
            print(f"🔐 Permissions spéciales pour action: {self.action}")
            return [IsAuthenticated()]
        print(f"🔐 Permissions par défaut")
        return super().get_permissions()
    
    infos_bip = InfobipSMSService()

    @action(detail=False, methods=['get'], url_path='my-status')
    def my_status(self, request):
        """
        Récupérer le statut de vérification téléphone de l'utilisateur connecté
        """
        print(f"\n=== 📱 MY_STATUS DÉMARRÉ ===")
        print(f"🧑 User ID: {request.user.id}")
        print(f"🧑 Username: {request.user.username}")
        
        try:
            verification = PhoneVerification.objects.get(user=request.user)
            print(f"✅ Vérification trouvée:")
            print(f"   - ID: {verification.id}")
            print(f"   - Phone: {verification.phone_number}")
            print(f"   - Status: {verification.status}")
            print(f"   - Attempts: {verification.attempts}")
            print(f"   - Created: {verification.created_at}")
            print(f"   - Expires: {verification.expires_at}")
            
            serializer = self.get_serializer(verification)
            response_data = serializer.data
            print(f"📤 Réponse my_status: {response_data}")
            print(f"=== 📱 MY_STATUS TERMINÉ ===\n")
            return Response(response_data)
            
        except PhoneVerification.DoesNotExist:
            print(f"❌ Aucune vérification trouvée pour user {request.user.id}")
            response_data = {
                'status': 'not_started',
                'message': 'Aucune vérification téléphone trouvée',
                'can_start': True
            }
            print(f"📤 Réponse my_status (not found): {response_data}")
            print(f"=== 📱 MY_STATUS TERMINÉ ===\n")
            return Response(response_data)
    
    @action(detail=False, methods=['post'], url_path='send-code')
    def send_code(self, request):
        """
        Envoyer un code de vérification par SMS
        Version avec intégration Infobip
        """
        logger.info(f"\n=== 📨 SEND_CODE DÉMARRÉ ===")
        logger.info(f"🧑 User ID: {request.user.id}")
        logger.info(f"🧑 Username: {request.user.username}")
        logger.info(f"📥 Données reçues: {request.data}")
        
        serializer = PhoneVerificationSendCodeSerializer(data=request.data)
        
        if not serializer.is_valid():
            logger.info(f"❌ Données invalides: {serializer.errors}")
            logger.info(f"=== 📨 SEND_CODE TERMINÉ (INVALID_DATA) ===\n")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        phone_number = serializer.validated_data['phone_number']
        logger.info(f"📞 Numéro validé: {phone_number}")
        
        try:
            # Vérifier la limitation de taux
            rate_ok, rate_message = check_sms_rate_limit(request.user, phone_number)
            if not rate_ok:
                logger.info(f"⚠️ Limitation de taux: {rate_message}")
                return Response({
                    'detail': rate_message
                }, status=status.HTTP_429_TOO_MANY_REQUESTS)
            
            # Obtenir ou créer la vérification
            logger.info(f"🔍 Recherche/création de la vérification...")
            verification, created = PhoneVerification.objects.get_or_create(
                user=request.user,
                defaults={
                    'phone_number': phone_number,
                    'status': 'pending'
                }
            )
            
            if not created:
                logger.info(f"📋 Vérification existante trouvée, mise à jour...")
                verification.phone_number = phone_number
                verification.status = 'pending'
                verification.attempts = 0
                verification.verification_code = PhoneVerification.generate_code()
                verification.expires_at = timezone.now() + timedelta(minutes=10)
                verification.last_code_sent_at = timezone.now()
                verification.save()
            
            code = verification.verification_code
            logger.info(f"🔢 Code généré: {code}")
            
            
            
            # === ENVOI SMS RÉEL AVEC INFOBIP ===
            logger.info(f"📱 Tentative d'envoi SMS réel via Infobip...")
            
            # Vérifier si SMS est activé dans les settings
            sms_enabled = getattr(settings, 'SMS_ENABLED', True)
            if not sms_enabled:
                logger.info(f"⚠️ SMS désactivé dans les settings")
                return Response({
                    'message': 'Code envoyé par email uniquement',
                    'verification': self.get_serializer(verification).data,
                    'debug_code': code if settings.DEBUG else None
                })
            
            try:
                # Utiliser le service SMS Infobip
                sms_result = self.infos_bip.send_verification_code(phone_number, code)
                
                logger.info(f"📤 Résultat SMS: {sms_result}")
                
                if sms_result['success']:
                    logger.info(f"🎉 SMS envoyé avec succès!")
                    logger.info(f"SMS envoyé avec succès vers {phone_number} pour {request.user.username}")
                    
                    # Incrémenter les compteurs de limitation
                    increment_sms_rate_limit(request.user, phone_number)
                    
                    # En développement, logger le code
                    if settings.DEBUG:
                        logger.info(f"🐛 CODE DE VÉRIFICATION (DEV): {code}")
                        logger.info(f"CODE DE VÉRIFICATION (DEV): {code}")
                    
                    response_serializer = self.get_serializer(verification)
                    response_data = {
                        'message': 'Code envoyé avec succès par SMS et email',
                        'verification': response_serializer.data,
                        'sms_id': sms_result.get('message_id'),
                        'debug_code': code if settings.DEBUG else None
                    }
                    
                    logger.info(f"📤 Réponse de succès: {response_data}")
                    logger.info(f"=== 📨 SEND_CODE TERMINÉ (SUCCESS) ===\n")
                    return Response(response_data)
                else:
                    logger.info(f"❌ Échec envoi SMS: {sms_result.get('error')}")
                    logger.error(f"Échec envoi SMS vers {phone_number}: {sms_result.get('error')}")
                    
                    # === ENVOI EMAIL (conservé) ===
                    try:
                        logger.info(f"📧 Tentative d'envoi email à {request.user.email}...")
                        send_mail(
                            subject='Code de vérification',
                            message=f'Votre code de vérification est: {code}',
                            from_email=settings.DEFAULT_FROM_EMAIL,
                            recipient_list=[request.user.email],
                            fail_silently=False,
                        )
                        logger.info(f"✅ Email envoyé avec succès!")
                        logger.info(f"Email de vérification envoyé avec succès à {request.user.email} avec le code {code}")
                        
                    except Exception as e:
                        logger.info(f"❌ Erreur envoi email: {str(e)}")
                        logger.error(f"Erreur envoi email: {str(e)}")
                        
                        # Même en cas d'erreur d'email, on continue avec le SMS
                        # On retourne une réponse positive pour la sécurité si le SMS fonctionne
                        
                    # Fallback: retourner succès si l'email a fonctionné
                    error_response = Response({
                        'message': 'Code envoyé par email (SMS temporairement indisponible)',
                        'verification': self.get_serializer(verification).data,
                        'sms_error': sms_result.get('error'),
                        'debug_code': code if settings.DEBUG else None
                    }, status=status.HTTP_200_OK)  # 200 car email fonctionne
                    logger.info(f"📤 Réponse fallback email: {error_response.data}")
                    logger.info(f"=== 📨 SEND_CODE TERMINÉ (SMS_ERROR_EMAIL_OK) ===\n")
                    return error_response
                    
            except Exception as sms_exception:
                logger.info(f"❌ Exception SMS: {str(sms_exception)}")
                logger.error(f"Exception envoi SMS: {str(sms_exception)}")
                
                # Fallback: retourner succès si l'email a fonctionné
                return Response({
                    'message': 'Code envoyé par email (SMS temporairement indisponible)',
                    'verification': self.get_serializer(verification).data,
                    'debug_code': code if settings.DEBUG else None
                }, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.info(f"❌ ERREUR GÉNÉRALE dans send_code: {str(e)}")
            logger.error(f"Erreur envoi code pour {request.user.username}: {str(e)}")
            import traceback
            logger.info(f"❌ STACK TRACE: {traceback.format_exc()}")
            
            error_response = Response({
                'detail': 'Erreur technique lors de l\'envoi'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            logger.info(f"📤 Réponse d'erreur générale: {error_response.data}")
            logger.info(f"=== 📨 SEND_CODE TERMINÉ (GENERAL_ERROR) ===\n")
            return error_response
        
        
    @action(detail=False, methods=['post'], url_path='verify-code')
    def verify_code(self, request):
        """
        Vérifier le code SMS/Email reçu
        """
        print(f"\n=== ✅ VERIFY_CODE DÉMARRÉ ===")
        print(f"🧑 User ID: {request.user.id}")
        print(f"🧑 Username: {request.user.username}")
        print(f"📥 Données reçues: {request.data}")
        
        serializer = PhoneVerificationCodeSerializer(data=request.data)
        
        if not serializer.is_valid():
            print(f"❌ Données invalides: {serializer.errors}")
            print(f"=== ✅ VERIFY_CODE TERMINÉ (INVALID_DATA) ===\n")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        code = serializer.validated_data['code']
        print(f"🔢 Code à vérifier: '{code}'")
        
        try:
            print(f"🔍 Recherche de la vérification...")
            verification = PhoneVerification.objects.get(user=request.user)
            
            print(f"📋 Vérification trouvée:")
            print(f"   - ID: {verification.id}")
            print(f"   - Phone: {verification.phone_number}")
            print(f"   - Status: {verification.status}")
            print(f"   - Code attendu: '{verification.verification_code}'")
            print(f"   - Code reçu: '{code}'")
            print(f"   - Attempts: {verification.attempts}/{verification.max_attempts}")
            print(f"   - Expire à: {verification.expires_at}")
            print(f"   - Maintenant: {timezone.now()}")
            print(f"   - Is expired?: {verification.is_expired()}")
            print(f"   - Can verify?: {verification.can_verify()}")
            
        except PhoneVerification.DoesNotExist:
            print(f"❌ Aucune vérification trouvée pour user {request.user.id}")
            error_response = Response({
                'detail': 'Aucune vérification en cours'
            }, status=status.HTTP_404_NOT_FOUND)
            print(f"📤 Réponse not found: {error_response.data}")
            print(f"=== ✅ VERIFY_CODE TERMINÉ (NOT_FOUND) ===\n")
            return error_response
        
        # Vérifier le code
        print(f"🔍 Vérification du code...")
        print(f"   - Comparaison: '{verification.verification_code}' == '{code}' ?")
        
        # Sauvegarder les valeurs avant verify_code (qui modifie attempts)
        attempts_before = verification.attempts
        is_expired_before = verification.is_expired()
        can_verify_before = verification.can_verify()
        
        print(f"📊 État avant vérification:")
        print(f"   - Attempts avant: {attempts_before}")
        print(f"   - Expiré avant: {is_expired_before}")
        print(f"   - Peut vérifier avant: {can_verify_before}")
        
        verification_result = verification.verify_code(code)
        print(f"🎯 Résultat verify_code: {verification_result}")
        
        # Recharger pour voir les changements
        verification.refresh_from_db()
        print(f"📊 État après vérification:")
        print(f"   - Status: {verification.status}")
        print(f"   - Attempts après: {verification.attempts}")
        print(f"   - Verified_at: {verification.verified_at}")
        
        if verification_result:
            print(f"🎉 VÉRIFICATION RÉUSSIE!")
            logger.info(f"Vérification téléphone réussie pour {request.user.username}")
            
            response_serializer = self.get_serializer(verification)
            response_data = {
                'message': 'Téléphone vérifié avec succès',
                'verification': response_serializer.data,
                'user_verified': True
            }
            
            print(f"📤 Réponse de succès: {response_data}")
            print(f"=== ✅ VERIFY_CODE TERMINÉ (SUCCESS) ===\n")
            return Response(response_data)
        else:
            print(f"❌ VÉRIFICATION ÉCHOUÉE!")
            
            # Déterminer la raison de l'échec
            verification.refresh_from_db()  # Recharger pour avoir l'état actuel
            
            print(f"🔍 Analyse de l'échec:")
            print(f"   - Is expired now?: {verification.is_expired()}")
            print(f"   - Attempts now: {verification.attempts}")
            print(f"   - Max attempts: {verification.max_attempts}")
            print(f"   - Status now: {verification.status}")
            
            if verification.is_expired():
                message = 'Le code a expiré'
                print(f"⏰ Raison: Code expiré")
            elif verification.attempts >= verification.max_attempts:
                message = 'Nombre maximum de tentatives atteint'
                print(f"🚫 Raison: Trop de tentatives")
            else:
                message = 'Code incorrect'
                attempts_remaining = verification.max_attempts - verification.attempts
                message += f' ({attempts_remaining} tentatives restantes)'
                print(f"🔢 Raison: Code incorrect, {attempts_remaining} tentatives restantes")
            
            error_response = Response({
                'detail': message,
                'attempts_remaining': max(0, verification.max_attempts - verification.attempts),
                'expired': verification.is_expired()
            }, status=status.HTTP_400_BAD_REQUEST)
            
            print(f"📤 Réponse d'erreur: {error_response.data}")
            print(f"=== ✅ VERIFY_CODE TERMINÉ (FAILED) ===\n")
            return error_response
    
    @action(detail=False, methods=['post'], url_path='resend-code')
    def resend_code(self, request):
        """
        Renvoyer un code de vérification
        Version avec intégration Infobip
        """
        print(f"\n=== 🔄 RESEND_CODE DÉMARRÉ ===")
        print(f"🧑 User ID: {request.user.id}")
        print(f"🧑 Username: {request.user.username}")
        
        try:
            print(f"🔍 Recherche de la vérification existante...")
            verification = PhoneVerification.objects.get(user=request.user)
            
            print(f"📋 Vérification trouvée:")
            print(f"   - Phone: {verification.phone_number}")
            print(f"   - Status: {verification.status}")
            print(f"   - Dernnier envoi: {verification.last_code_sent_at}")
            
            # Vérifier la limitation de taux
            rate_ok, rate_message = check_sms_rate_limit(request.user, verification.phone_number)
            if not rate_ok:
                print(f"⚠️ Limitation de taux: {rate_message}")
                return Response({
                    'detail': rate_message
                }, status=status.HTTP_429_TOO_MANY_REQUESTS)
            
            # Générer un nouveau code
            verification.verification_code = PhoneVerification.generate_code()
            verification.expires_at = timezone.now() + timedelta(minutes=10)
            verification.last_code_sent_at = timezone.now()
            verification.status = 'pending'
            verification.attempts = 0
            verification.save()
            
            code = verification.verification_code
            print(f"🔢 Nouveau code généré: {code}")
            
            # Envoi SMS avec Infobip
            print(f"📱 Renvoi SMS via Infobip...")
            sms_result = self.infos_bip.send_verification_code(verification.phone_number, code)
            
            print(f"📤 Résultat renvoi SMS: {sms_result}")
            
            if sms_result['success']:
                print(f"🎉 SMS renvoyé avec succès!")
                logger.info(f"Nouveau code SMS envoyé à {request.user.username}")
                
                # Incrémenter les compteurs
                increment_sms_rate_limit(request.user, verification.phone_number)
                
                # En développement, logger le code
                if settings.DEBUG:
                    print(f"🐛 NOUVEAU CODE DE VÉRIFICATION (DEV): {code}")
                    logger.info(f"NOUVEAU CODE DE VÉRIFICATION (DEV): {code}")
                
                response_serializer = self.get_serializer(verification)
                response_data = {
                    'message': 'Nouveau code envoyé avec succès',
                    'verification': response_serializer.data,
                    'sms_id': sms_result.get('message_id'),
                    'debug_code': code if settings.DEBUG else None
                }
                
                print(f"📤 Réponse de succès: {response_data}")
                print(f"=== 🔄 RESEND_CODE TERMINÉ (SUCCESS) ===\n")
                return Response(response_data)
            else:
                print(f"❌ Échec renvoi SMS: {sms_result.get('error')}")
                error_response = Response({
                    'detail': f'Erreur lors du renvoi SMS: {sms_result.get("error")}'
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
                print(f"📤 Réponse d'erreur SMS: {error_response.data}")
                print(f"=== 🔄 RESEND_CODE TERMINÉ (SMS_ERROR) ===\n")
                return error_response
        
        except PhoneVerification.DoesNotExist:
            print(f"❌ Aucune vérification trouvée")
            error_response = Response({
                'detail': 'Aucune vérification en cours'
            }, status=status.HTTP_404_NOT_FOUND)
            print(f"📤 Réponse not found: {error_response.data}")
            print(f"=== 🔄 RESEND_CODE TERMINÉ (NOT_FOUND) ===\n")
            return error_response
        
        except Exception as e:
            print(f"❌ ERREUR GÉNÉRALE dans resend_code: {str(e)}")
            logger.error(f"Erreur renvoi SMS pour {request.user.username}: {str(e)}")
            import traceback
            print(f"❌ STACK TRACE: {traceback.format_exc()}")
            
            error_response = Response({
                'detail': 'Erreur technique lors du renvoi'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            print(f"📤 Réponse d'erreur générale: {error_response.data}")
            print(f"=== 🔄 RESEND_CODE TERMINÉ (GENERAL_ERROR) ===\n")
            return error_response


# ================================================================
# 5. VUES POUR VÉRIFIER LES BLOCAGES D'ACTIONS
# ================================================================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def check_verification_status(request):
    """
    Endpoint pour vérifier le statut de vérification global de l'utilisateur
    Utilisé par le frontend pour déterminer les actions autorisées
    """
    
    user = request.user
    needs_verification, reason, verification_type = VerificationPermissionMixin.user_needs_verification(user)
    
    response_data = {
        'user_id': user.id,
        'user_role': user.role,
        'is_verified': not needs_verification,
        'needs_verification': needs_verification,
        'verification_type': verification_type,
        'reason': reason,
        'is_staff': user.is_staff
    }
    
    # Ajouter les détails spécifiques selon le rôle
    if user.role == 'client':
        phone_verification = getattr(user, 'phone_verification', None)
        response_data['phone_verification'] = {
            'exists': phone_verification is not None,
            'status': phone_verification.status if phone_verification else 'not_started',
            'phone_number': phone_verification.phone_number if phone_verification else None,
            'verified_at': phone_verification.verified_at if phone_verification else None
        }
    
    elif user.role == 'provider':
        provider = getattr(user, 'provider_profile', None)
        if provider:
            verification = getattr(provider, 'verification', None)
            response_data['provider_verification'] = {
                'exists': verification is not None,
                'status': verification.verification_status if verification else 'not_started',
                'is_business': verification.is_business if verification else False,
                'submitted_at': verification.submitted_at if verification else None,
                'verified_at': verification.verified_at if verification else None,
                'rejection_reason': verification.rejection_reason if verification else None
            }
        else:
            response_data['provider_verification'] = {
                'exists': False,
                'status': 'no_provider_profile'
            }
    
    return Response(response_data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def check_action_permission(request):
    """
    Endpoint pour vérifier si une action spécifique est autorisée
    
    Données requises:
    - action: Description de l'action (ex: "créer un service")
    """
    action = request.data.get('action', 'cette action')
    
    
    error_response = VerificationPermissionMixin.get_verification_error_response(
        request.user, action
    )
    
    if error_response:
        return error_response
    
    return Response({
        'action': action,
        'allowed': True,
        'message': 'Action autorisée'
    })





@api_view(['POST'])
@permission_classes([IsAuthenticated])
def force_refresh_profile(request):
    """
    Endpoint pour forcer le rafraîchissement complet du profil utilisateur
    Invalide tous les caches et resynchronise les données de vérification
    """
    user = request.user
    
    try:
        with transaction.atomic():
            # 1. Invalider tous les caches liés à cet utilisateur
            cache_keys_to_delete = [
                f'user_profile_{user.id}',
                f'user_verification_{user.id}',
                f'user_services_{user.id}',
                f'user_projects_{user.id}',
                f'provider_profile_{user.id}',
            ]
            
            for key in cache_keys_to_delete:
                cache.delete(key)
            
            # 2. Recharger l'utilisateur depuis la base de données
            user.refresh_from_db()
            
            # 3. Resynchroniser le statut de vérification selon le rôle
            if user.role == 'client':
                # Vérifier le statut de vérification téléphone
                phone_verification = getattr(user, 'phone_verification', None)
                if phone_verification:
                    if phone_verification.status == 'verified' and not user.is_verified:
                        user.is_verified = True
                        user.save()
                        print(f"✅ Utilisateur {user.username} marqué comme vérifié (téléphone)")
                    elif phone_verification.status != 'verified' and user.is_verified:
                        user.is_verified = False
                        user.save()
                        print(f"❌ Utilisateur {user.username} marqué comme non vérifié (téléphone)")
            
            elif user.role == 'provider':
                # Vérifier le statut de vérification prestataire
                provider = getattr(user, 'provider_profile', None)
                if provider:
                    verification = getattr(provider, 'verification', None)
                    if verification:
                        if verification.verification_status == 'verified' and not user.is_verified:
                            user.is_verified = True
                            user.save()
                            print(f"✅ Prestataire {user.username} marqué comme vérifié (documents)")
                        elif verification.verification_status != 'verified' and user.is_verified:
                            user.is_verified = False
                            user.save()
                            print(f"❌ Prestataire {user.username} marqué comme non vérifié (documents)")
            
            # 4. Recharger encore une fois pour être sûr
            user.refresh_from_db()
            
            # 5. Sérialiser les données avec le contexte complet
            serializer = UserSerializer(user, context={'request': request})
            user_data = serializer.data
            
            # 6. Ajouter des métadonnées de debug
            debug_info = {
                'timestamp': timezone.now().isoformat(),
                'cache_cleared': True,
                'user_reloaded': True,
                'verification_synced': True,
            }
            
            # 7. Log pour debug
            print(f"🔄 Profil forcé rechargé pour {user.username}")
            print(f"   - Rôle: {user.role}")
            print(f"   - Vérifié: {user.is_verified}")
            if user.role == 'client':
                phone_verification = getattr(user, 'phone_verification', None)
                if phone_verification:
                    print(f"   - Statut téléphone: {phone_verification.status}")
            elif user.role == 'provider':
                provider = getattr(user, 'provider_profile', None)
                if provider and hasattr(provider, 'verification'):
                    print(f"   - Statut prestataire: {provider.verification.verification_status}")
            
            return Response({
                'success': True,
                'message': 'Profil utilisateur rechargé avec succès',
                'user': user_data,
                'debug': debug_info
            })
            
    except Exception as e:
        print(f"❌ Erreur lors du rechargement forcé: {str(e)}")
        return Response({
            'success': False,
            'message': f'Erreur lors du rechargement: {str(e)}',
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_current_user_detailed(request):
    """
    Endpoint amélioré pour récupérer le profil utilisateur actuel
    Avec cache-busting et synchronisation des données
    """
    user = request.user
    
    # Force reload depuis la DB (pas de cache)
    user.refresh_from_db()
    
    # Vérifier la cohérence des données de vérification
    _sync_verification_status(user)
    
    # Sérialiser avec contexte complet
    serializer = UserSerializer(user, context={'request': request})
    
    # Ajouter des informations supplémentaires selon le rôle
    response_data = {
        'user': serializer.data,
        'timestamp': timezone.now().isoformat(),
        'cache_bypassed': True,
    }
    
    # Informations spécifiques aux prestataires
    if user.role == 'provider':
        provider = getattr(user, 'provider_profile', None)
        if provider:
            response_data['provider_details'] = {
                'id': provider.id,
                'business_type': provider.business_type,
                'services_count': provider.provider_services.count(),
                'verification': None
            }
            
            # Détails de vérification prestataire
            verification = getattr(provider, 'verification', None)
            if verification:
                response_data['provider_details']['verification'] = {
                    'status': verification.verification_status,
                    'submitted_at': verification.submitted_at,
                    'verified_at': verification.verified_at,
                    'is_business': verification.is_business,
                    'rejection_reason': verification.rejection_reason,
                }
    
    # Informations spécifiques aux clients
    elif user.role == 'client':
        phone_verification = getattr(user, 'phone_verification', None)
        response_data['phone_verification_details'] = None
        
        if phone_verification:
            response_data['phone_verification_details'] = {
                'status': phone_verification.status,
                'phone_number': phone_verification.phone_number,
                'verified_at': phone_verification.verified_at,
                'attempts': phone_verification.attempts,
            }
    
    return Response(response_data)


def _sync_verification_status(user):
    """
    Fonction utilitaire pour synchroniser le statut de vérification
    """
    try:
        if user.role == 'client':
            phone_verification = getattr(user, 'phone_verification', None)
            if phone_verification:
                expected_verified = phone_verification.status == 'verified'
                if user.is_verified != expected_verified:
                    user.is_verified = expected_verified
                    user.save()
                    print(f"🔄 Statut de vérification synchronisé pour {user.username}: {expected_verified}")
        
        elif user.role == 'provider':
            provider = getattr(user, 'provider_profile', None)
            if provider and hasattr(provider, 'verification'):
                expected_verified = provider.verification.verification_status == 'verified'
                if user.is_verified != expected_verified:
                    user.is_verified = expected_verified
                    user.save()
                    print(f"🔄 Statut de vérification synchronisé pour {user.username}: {expected_verified}")
    
    except Exception as e:
        print(f"❌ Erreur synchronisation vérification: {e}")


#####################################################################################################################################
#==================================================NOTIFICATION FCM =================================================================


class FCMViewSet(viewsets.ViewSet):
    """
    ViewSet pour gérer les tokens FCM et les notifications
    """
    permission_classes = [IsAuthenticated]
    
    @action(detail=False, methods=['post'], url_path='register-token')
    def register_token(self, request):
        """
        Enregistrer un token FCM pour l'utilisateur connecté
        """
        try:
            logger.info(f"\n=== 📱 REGISTER FCM TOKEN ===")
            logger.info(f"🧑 User: {request.user.email}")
            logger.info(f"📥 Data: {request.data}")
            
            fcm_token = request.data.get('fcm_token')
            device_type = request.data.get('device_type', 'android')
            app_version = request.data.get('app_version', '1.0.0')
            
            if not fcm_token:
                return Response({
                    'detail': 'Token FCM requis'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Vérifier si le token existe déjà
            existing_token = FCMToken.objects.filter(token=fcm_token).first()
            
            if existing_token:
                # Mettre à jour le token existant
                existing_token.user = request.user
                existing_token.device_type = device_type
                existing_token.app_version = app_version
                existing_token.is_active = True
                existing_token.last_used = timezone.now()
                existing_token.save()
                
                logger.info(f"✅ Token FCM mis à jour")
                serializer = FCMTokenSerializer(existing_token)
                
            else:
                # Créer un nouveau token
                new_token = FCMToken.objects.create(
                    user=request.user,
                    token=fcm_token,
                    device_type=device_type,
                    app_version=app_version,
                    is_active=True,
                    last_used=timezone.now()
                )
                
                logger.info(f"✅ Nouveau token FCM créé")
                serializer = FCMTokenSerializer(new_token)
            
            # Envoyer une notification de bienvenue
            try:
                FCMService.send_test_notification(request.user)
                logger.info(f"✅ Notification de bienvenue envoyée")
            except Exception as e:
                logger.info(f"⚠️ Erreur notification bienvenue: {e}")
            
            response_data = {
                'message': 'Token FCM enregistré avec succès',
                'token': serializer.data
            }
            logger.info(f"📤 Response: {response_data}")
            logger.info(f"=== 📱 REGISTER FCM TOKEN TERMINÉ ===\n")
            
            return Response(response_data, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            logger.info(f"❌ Erreur register token: {e}")
            logger.error(f"Erreur register FCM token pour {request.user.email}: {e}")
            return Response({
                'detail': 'Erreur lors de l\'enregistrement du token'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    @action(detail=False, methods=['delete'], url_path='remove-token')
    def remove_token(self, request):
        """
        Supprimer un token FCM
        """
        try:
            logger.info(f"\n=== 🗑️ REMOVE FCM TOKEN ===")
            logger.info(f"🧑 User: {request.user.email}")
            logger.info(f"📥 Data: {request.data}")
            
            fcm_token = request.data.get('fcm_token')
            
            if not fcm_token:
                return Response({
                    'detail': 'Token FCM requis'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Désactiver le token
            deleted_count = FCMToken.objects.filter(
                token=fcm_token,
                user=request.user
            ).update(is_active=False)
            
            if deleted_count > 0:
                logger.info(f"✅ Token FCM désactivé")
                message = 'Token FCM supprimé avec succès'
            else:
                logger.info(f"⚠️ Token FCM non trouvé")
                message = 'Token FCM non trouvé'
            
            response_data = {'message': message}
            logger.info(f"📤 Response: {response_data}")
            logger.info(f"=== 🗑️ REMOVE FCM TOKEN TERMINÉ ===\n")
            
            return Response(response_data)
            
        except Exception as e:
            logger.info(f"❌ Erreur remove token: {e}")
            logger.error(f"Erreur remove FCM token pour {request.user.email}: {e}")
            return Response({
                'detail': 'Erreur lors de la suppression du token'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    @action(detail=False, methods=['get'], url_path='my-tokens')
    def my_tokens(self, request):
        """
        Récupérer les tokens FCM de l'utilisateur connecté
        """
        try:
            tokens = FCMToken.objects.filter(
                user=request.user,
                is_active=True
            ).order_by('-created_at')
            
            serializer = FCMTokenSerializer(tokens, many=True)
            return Response({
                'tokens': serializer.data,
                'count': len(serializer.data)
            })
            
        except Exception as e:
            logger.error(f"Erreur récupération tokens FCM: {e}")
            return Response({
                'detail': 'Erreur lors de la récupération des tokens'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    @action(detail=False, methods=['post'], url_path='test-notification')
    def test_notification(self, request):
        """
        Envoyer une notification de test à l'utilisateur connecté
        """
        try:
            logger.info(f"\n=== 🧪 TEST NOTIFICATION ===")
            logger.info(f"🧑 User: {request.user.email}")
            
            # Vérifier si l'utilisateur a des tokens FCM
            if not request.user.has_fcm_tokens():
                return Response({
                    'detail': 'Aucun token FCM trouvé pour cet utilisateur'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Envoyer la notification de test
            success = FCMService.send_test_notification(request.user)
            
            if success:
                logger.info(f"✅ Notification de test envoyée")
                response_data = {
                    'message': 'Notification de test envoyée avec succès',
                    'success': True
                }
            else:
                logger.info(f"❌ Échec envoi notification de test")
                response_data = {
                    'message': 'Erreur lors de l\'envoi de la notification de test',
                    'success': False
                }
            
            logger.info(f"📤 Response: {response_data}")
            logger.info(f"=== 🧪 TEST NOTIFICATION TERMINÉ ===\n")
            
            return Response(response_data)
            
        except Exception as e:
            logger.info(f"❌ Erreur test notification: {e}")
            logger.error(f"Erreur test notification pour {request.user.email}: {e}")
            return Response({
                'detail': 'Erreur lors de l\'envoi de la notification de test'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class NotificationPreferenceViewSet(viewsets.ViewSet):
    """
    ViewSet pour gérer les préférences de notification
    """
    permission_classes = [IsAuthenticated]
    
    @action(detail=False, methods=['get'], url_path='my-preferences')
    def my_preferences(self, request):
        """
        Récupérer les préférences de notification de l'utilisateur
        """
        try:
            preferences = request.user.get_notification_preferences()
            serializer = NotificationPreferenceSerializer(preferences)
            return Response(serializer.data)
            
        except Exception as e:
            logger.error(f"Erreur récupération préférences: {e}")
            return Response({
                'detail': 'Erreur lors de la récupération des préférences'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    @action(detail=False, methods=['post'], url_path='update-preferences')
    def update_preferences(self, request):
        """
        Mettre à jour les préférences de notification
        """
        try:
            logger.info(f"\n=== ⚙️ UPDATE PREFERENCES ===")
            logger.info(f"🧑 User: {request.user.email}")
            logger.info(f"📥 Data: {request.data}")
            
            preferences = request.user.get_notification_preferences()
            
            # Mettre à jour les champs fournis
            preferences_data = request.data.get('preferences', {})
            
            for field, value in preferences_data.items():
                if hasattr(preferences, field):
                    setattr(preferences, field, value)
            
            preferences.save()
            
            logger.info(f"✅ Préférences mises à jour")
            serializer = NotificationPreferenceSerializer(preferences)
            
            response_data = {
                'message': 'Préférences mises à jour avec succès',
                'preferences': serializer.data
            }
            logger.info(f"📤 Response: {response_data}")
            logger.info(f"=== ⚙️ UPDATE PREFERENCES TERMINÉ ===\n")
            
            return Response(response_data)
            
        except Exception as e:
            logger.info(f"❌ Erreur update preferences: {e}")
            logger.error(f"Erreur update préférences pour {request.user.email}: {e}")
            return Response({
                'detail': 'Erreur lors de la mise à jour des préférences'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class NotificationHistoryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet pour consulter l'historique des notifications
    """
    permission_classes = [IsAuthenticated]
    serializer_class = NotificationHistorySerializer
    
    def get_queryset(self):
        """
        Retourner l'historique des notifications de l'utilisateur connecté
        """
        return NotificationHistory.objects.filter(
            user=self.request.user
        ).order_by('-created_at')
    
    @action(detail=False, methods=['get'], url_path='stats')
    def stats(self, request):
        """
        Statistiques des notifications de l'utilisateur
        """
        try:
            queryset = self.get_queryset()
            
            stats = {
                'total_notifications': queryset.count(),
                'sent': queryset.filter(status='sent').count(),
                'delivered': queryset.filter(status='delivered').count(),
                'failed': queryset.filter(status='failed').count(),
                'clicked': queryset.filter(status='clicked').count(),
            }
            
            return Response(stats)
            
        except Exception as e:
            logger.error(f"Erreur stats notifications: {e}")
            return Response({
                'detail': 'Erreur lors de la récupération des statistiques'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# =================================================================
# AJOUTS AUX VIEWSETS EXISTANTS POUR DÉCLENCHER DES NOTIFICATIONS
# =================================================================

# Modifiez vos ViewSets existants pour envoyer des notifications FCM

def send_new_message_notification(conversation, message, sender):
    """
    Envoyer une notification pour un nouveau message
    """
    try:
        # Déterminer le destinataire
        recipient = conversation.client if sender != conversation.client else conversation.provider.user
        
        FCMService.send_notification_to_user(
            user=recipient,
            title=f"💬 Nouveau message de {sender.first_name}",
            body=message.content[:100] + ('...' if len(message.content) > 100 else ''),
            notification_type='new_message',
            data={
                'conversation_id': str(conversation.id),
                'sender_id': str(sender.id),
                'message_id': str(message.id),
            },
            click_action='FLUTTER_NOTIFICATION_CLICK'
        )
        
    except Exception as e:
        logger.error(f"Erreur notification nouveau message: {e}")

def send_new_offer_notification(project, offer):
    """
    Envoyer une notification pour une nouvelle offre
    """
    try:
        FCMService.send_notification_to_user(
            user=project.client,
            title=f"💼 Nouvelle offre reçue",
            body=f"{offer.provider.user.first_name} a fait une offre sur votre projet",
            notification_type='new_offer',
            data={
                'project_id': str(project.id),
                'offer_id': str(offer.id),
                'provider_id': str(offer.provider.id),
            },
            click_action='FLUTTER_NOTIFICATION_CLICK'
        )
        
    except Exception as e:
        logger.error(f"Erreur notification nouvelle offre: {e}")

def send_project_update_notification(project, update_type, message):
    """
    Envoyer une notification pour une mise à jour de projet
    """
    try:
        FCMService.send_notification_to_user(
            user=project.client,
            title=f"📋 Mise à jour de projet",
            body=message,
            notification_type='project_update',
            data={
                'project_id': str(project.id),
                'update_type': update_type,
            },
            click_action='FLUTTER_NOTIFICATION_CLICK'
        )
        
    except Exception as e:
        logger.error(f"Erreur notification projet: {e}")


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_verification_status(request):
    """
    Endpoint unifié pour obtenir le statut de vérification de l'utilisateur
    Évite les confusions entre types de vérification
    """
    user = request.user
    
    try:
        # Synchroniser les statuts avant de répondre
        _sync_all_verification_statuses(user)
        
        response_data = {
            'user_id': user.id,
            'user_role': user.role,
            'is_verified': user.is_verified,
        }
        
        # Détails selon le rôle
        if user.role == 'client':
            phone_verification = getattr(user, 'phone_verification', None)
            response_data['phone_verification'] = {
                'exists': phone_verification is not None,
                'status': phone_verification.status if phone_verification else 'not_started',
                'phone_number': phone_verification.phone_number if phone_verification else None,
                'verified_at': phone_verification.verified_at if phone_verification else None,
                'can_verify': True,
                'message': _('Phone verification required for client actions') if not phone_verification or phone_verification.status != 'verified' else _('Phone verified successfully')
            }
            
        elif user.role == 'provider':
            provider = getattr(user, 'provider_profile', None)
            if provider:
                verification = getattr(provider, 'verification', None)
                response_data['provider_verification'] = {
                    'exists': verification is not None,
                    'status': verification.verification_status if verification else 'not_started',
                    'submitted_at': verification.submitted_at if verification else None,
                    'verified_at': verification.verified_at if verification else None,
                    'rejection_reason': verification.rejection_reason if verification else None,
                    'can_verify': verification is None or verification.verification_status in ['not_started', 'rejected'],
                    'message': _get_verification_message(verification.verification_status if verification else 'not_started')
                }
            else:
                response_data['provider_verification'] = {
                    'exists': False,
                    'status': 'no_provider_profile',
                    'message': _('Provider profile not found')
                }
        
        return Response(response_data, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"❌ Erreur get_verification_status: {e}")
        return Response({
            'error': _('Verification service temporarily unavailable'),
            'detail': str(e)
        }, status=status.HTTP_503_SERVICE_UNAVAILABLE)

def _get_verification_message(verification_status):
    """Obtenir le message approprié selon le statut de vérification"""
    messages = {
        'not_started': _('Provider verification not started'),
        'pending': _('Provider verification under review'),
        'verified': _('Provider profile verified successfully'),
        'rejected': _('Provider verification rejected - new documents required'),
    }
    return messages.get(verification_status, _('Unknown verification status'))

def _sync_all_verification_statuses(user):
    """
    Synchroniser tous les statuts de vérification pour éviter les incohérences
    """
    try:
        if user.role == 'client':
            # Synchroniser avec phone_verification
            phone_verification = getattr(user, 'phone_verification', None)
            expected_verified = phone_verification and phone_verification.status == 'verified'
            
            if user.is_verified != expected_verified:
                user.is_verified = expected_verified
                user.save()
                print(f"🔄 Client {user.username} statut synchronisé: {expected_verified}")
        
        elif user.role == 'provider':
            # Synchroniser avec provider verification
            provider = getattr(user, 'provider_profile', None)
            if provider:
                verification = getattr(provider, 'verification', None)
                expected_verified = verification and verification.verification_status == 'verified'
                
                if user.is_verified != expected_verified:
                    user.is_verified = expected_verified
                    user.save()
                    print(f"🔄 Provider {user.username} statut synchronisé: {expected_verified}")
            else:
                # Pas de profil prestataire = pas vérifié
                if user.is_verified:
                    user.is_verified = False
                    user.save()
                    print(f"🔄 Provider {user.username} sans profil -> non vérifié")
                    
    except Exception as e:
        print(f"❌ Erreur synchronisation statuts: {e}")



@api_view(['POST'])
@permission_classes([IsAuthenticated])
def test_fcm_signals(request):
    """
    Tester les notifications FCM via les signaux
    """
    try:
        notification_type = request.data.get('type', 'test')
        
        # Envoyer une notification de test via les signaux
        notification = send_test_fcm_notification(
            user=request.user,
            notification_type=notification_type
        )
        
        if notification:
            return Response({
                'success': True,
                'message': f'Notification FCM {notification_type} envoyée avec succès',
                'notification_id': notification.id
            })
        else:
            return Response({
                'success': False,
                'message': 'Erreur lors de l\'envoi de la notification'
            })
            
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        })

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def test_bulk_fcm(request):
    """
    Tester les notifications FCM en masse
    """
    try:
        from .models import User
        
        title = request.data.get('title', 'Test en masse')
        message = request.data.get('message', 'Notification de test envoyée à tous')
        
        # Envoyer à tous les utilisateurs (limitez pour le test)
        users = User.objects.all()[:5]  # Limiter à 5 pour le test
        
        results = send_bulk_notification(
            users=users,
            title=title,
            message=message,
            notification_type='system'
        )
        
        return Response({
            'success': True,
            'results': results,
            'message': f'Notifications envoyées à {results["success"]} utilisateurs'
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        })

@action(detail=False, methods=['get'])
def profile(self, request):
    """
    Vue profil utilisateur corrigée avec gestion d'erreurs
    """
    user = request.user
    
    try:
        # Synchroniser les statuts
        _sync_all_verification_statuses(user)
        
        # Données de base
        response_data = {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'phone_number': user.phone_number,
            'role': user.role,
            'is_verified': user.is_verified,
            'profile_picture': user.profile_picture.url if user.profile_picture else None,
            'bio': user.bio,
            'location': user.location,
            'company_name': user.company_name,
            'created_at': user.created_at,
            'verification_service_available': True,  # Toujours vrai maintenant
        }
        
        # Détails selon le rôle
        if user.role == 'client':
            phone_verification = getattr(user, 'phone_verification', None)
            response_data['phone_verification_details'] = {
                'status': phone_verification.status if phone_verification else 'not_started',
                'phone_number': phone_verification.phone_number if phone_verification else None,
                'verified_at': phone_verification.verified_at if phone_verification else None,
            } if phone_verification else None
            
        elif user.role == 'provider':
            provider = getattr(user, 'provider_profile', None)
            if provider:
                response_data['provider_details'] = {
                    'business_type': provider.business_type,
                    'description': provider.description,
                    'experience_years': provider.experience_years,
                    'rating': provider.rating,
                    'total_reviews': provider.total_reviews,
                    'services_count': provider.provider_services.count(),
                    'verification': None
                }
                
                # Détails de vérification
                verification = getattr(provider, 'verification', None)
                if verification:
                    response_data['provider_details']['verification'] = {
                        'status': verification.verification_status,
                        'submitted_at': verification.submitted_at,
                        'verified_at': verification.verified_at,
                        'is_business': verification.is_business,
                        'rejection_reason': verification.rejection_reason,
                        'message': _get_verification_message(verification.verification_status)
                    }
        
        return Response(response_data, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"❌ Erreur vue profile: {e}")
        return Response({
            'error': _('Profile service temporarily unavailable'),
            'detail': _('Please try again later or contact support'),
            'verification_service_available': False,
        }, status=status.HTTP_503_SERVICE_UNAVAILABLE)


class ServiceFavoriteViewSet(viewsets.ModelViewSet):
    """ViewSet pour la gestion des services favoris"""
    serializer_class = FavoriteSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['get', 'post', 'delete']
    
    def get_queryset(self):
        return Favorite.objects.filter(user=self.request.user)
    
    def create(self, request, *args, **kwargs):
        provider_id = request.data.get('provider_id')
        if not provider_id:
            return Response(
                {'error': 'provider_id requis'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            provider = Provider.objects.get(id=provider_id)
        except Provider.DoesNotExist:
            return Response(
                {'error': 'Prestataire non trouvé'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        favorite, created = Favorite.objects.get_or_create(
            user=request.user,
            provider=provider
        )
        
        if created:
            serializer = self.get_serializer(favorite)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        else:
            return Response(
                {'message': 'Prestataire déjà en favoris'},
                status=status.HTTP_200_OK
            )