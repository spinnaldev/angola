from rest_framework import permissions
from rest_framework.permissions import BasePermission


class IsAdminUser(BasePermission):
    """
    Permission personnalisée pour les administrateurs
    """
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and request.user.is_staff


class IsClientOwner(BasePermission):
    """
    Permission pour les clients - accès à leurs propres données
    """
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated
    
    def has_object_permission(self, request, view, obj):
        if hasattr(obj, 'client'):
            return obj.client == request.user
        return obj == request.user


class IsProjectOwnerOrProvider(BasePermission):
    """
    Permission pour les projets - propriétaire ou prestataire avec offre
    """
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated
    
    def has_object_permission(self, request, view, obj):
        # Le client propriétaire peut tout faire
        if hasattr(obj, 'client') and obj.client == request.user:
            return True
        
        # Un prestataire peut voir les projets sur lesquels il a fait une offre
        if hasattr(request.user, 'provider_profile'):
            from .models import ProjectOffer
            return ProjectOffer.objects.filter(
                project=obj,
                provider=request.user.provider_profile
            ).exists()
        
        return False


class IsDisputeParty(BasePermission):
    """
    Permission pour les litiges - parties impliquées seulement
    """
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated
    
    def has_object_permission(self, request, view, obj):
        # Le client ou le prestataire impliqué dans le litige
        return (obj.client == request.user or 
                (obj.provider and obj.provider.user == request.user) or
                request.user.is_staff)


class CanCreateDispute(BasePermission):
    """
    Permission pour créer un litige
    """
    def has_permission(self, request, view):
        if not (request.user and request.user.is_authenticated):
            return False
        
        # Seuls les clients peuvent créer des litiges
        if request.method == 'POST':
            return not hasattr(request.user, 'provider_profile')
        
        return True


class CanModerateContent(BasePermission):
    """
    Permission pour modérer le contenu (admins et modérateurs)
    """
    def has_permission(self, request, view):
        return (request.user and 
                request.user.is_authenticated and 
                (request.user.is_staff or request.user.is_superuser))


class IsVerifiedProvider(BasePermission):
    """
    Permission pour les prestataires vérifiés
    """
    def has_permission(self, request, view):
        if not (request.user and request.user.is_authenticated):
            return False
        
        if hasattr(request.user, 'provider_profile'):
            return request.user.provider_profile.is_verified
        
        return False


class IsActiveUser(BasePermission):
    """
    Permission pour les utilisateurs actifs
    """
    def has_permission(self, request, view):
        return (request.user and 
                request.user.is_authenticated and 
                request.user.is_active)


# Permissions composées pour l'admin
class AdminProjectPermissions(BasePermission):
    """
    Permissions pour l'administration des projets
    """
    def has_permission(self, request, view):
        return (request.user and 
                request.user.is_authenticated and 
                request.user.is_staff)
    
    def has_object_permission(self, request, view, obj):
        # Les admins peuvent tout faire
        if request.user.is_staff:
            return True
        
        # Sinon, utiliser les permissions normales
        if hasattr(obj, 'client'):
            return obj.client == request.user
        
        return False


class AdminDisputePermissions(BasePermission):
    """
    Permissions pour l'administration des litiges
    """
    def has_permission(self, request, view):
        return (request.user and 
                request.user.is_authenticated and 
                request.user.is_staff)
    
    def has_object_permission(self, request, view, obj):
        # Les admins peuvent tout faire
        return request.user.is_staff


# Mixins de permissions réutilisables
class AdminRequiredMixin:
    """
    Mixin pour les vues qui nécessitent des droits d'admin
    """
    permission_classes = [IsAdminUser]


class OwnerOrAdminRequiredMixin:
    """
    Mixin pour les vues accessibles au propriétaire ou à l'admin
    """
    def get_permissions(self):
        if self.request.user.is_staff:
            return [IsAdminUser()]
        return [IsOwnerOrReadOnly()]


class AuthenticatedRequiredMixin:
    """
    Mixin pour les vues qui nécessitent une authentification
    """
    permission_classes = [permissions.IsAuthenticated]
class IsOwnerOrReadOnly(permissions.BasePermission):
    """
    Custom permission to only allow owners of an object to edit it.
    """
    def has_object_permission(self, request, view, obj):
        # Read permissions are allowed to any request
        if request.method in permissions.SAFE_METHODS:
            return True

        # Write permissions are only allowed to the owner
        return obj == request.user

# class IsProviderOwner(permissions.BasePermission):
#     """
#     Custom permission to only allow owners of a provider profile to edit it.
#     """
#     def has_object_permission(self, request, view, obj):
#         # Read permissions are allowed to any request
#         if request.method in permissions.SAFE_METHODS:
#             return True

#         # Write permissions are only allowed to the owner
#         if hasattr(request.user, 'provider_profile'):
#             return obj == request.user.provider_profile
#         return False

class IsProviderOwner(permissions.BasePermission):
    """
    Permission pour vérifier que l'utilisateur est propriétaire du profil prestataire
    """
    message = "Vous devez être le propriétaire de ce profil prestataire"
    
    def has_permission(self, request, view):
        # L'utilisateur doit être authentifié
        if not request.user or not request.user.is_authenticated:
            return False
        
        # L'utilisateur doit avoir un profil prestataire
        return hasattr(request.user, 'provider_profile')
    
    def has_object_permission(self, request, view, obj):
        # Pour les objets ProviderVerification
        if hasattr(obj, 'provider'):
            return obj.provider.user == request.user
        return False

class IsPhoneVerificationOwner(permissions.BasePermission):
    """
    Permission pour vérifier que l'utilisateur est propriétaire de la vérification téléphone
    """
    message = "Vous ne pouvez accéder qu'à votre propre vérification téléphone"
    
    def has_object_permission(self, request, view, obj):
        return obj.user == request.user
    
class IsClientOrProviderOwner(permissions.BasePermission):
    """
    Custom permission to only allow the client or the provider owner to access the object.
    For conversations, disputes, etc.
    """
    def has_object_permission(self, request, view, obj):
        # Staff can access everything
        if request.user.is_staff:
            return True
            
        # Check if the user is the client
        if hasattr(obj, 'client') and obj.client == request.user:
            return True
            
        # Check if the user is the provider owner
        if hasattr(obj, 'provider') and hasattr(request.user, 'provider_profile'):
            return obj.provider == request.user.provider_profile
            
        return False
    
class VerificationPermissionMixin:
    """Mixin pour vérifier les permissions de vérification"""
    
    @staticmethod
    def user_needs_verification(user):
        """Vérifie si un utilisateur a besoin de vérification"""
        if not user or not user.is_authenticated:
            return True, "Non connecté", "login"
        
        if user.is_staff:
            return False, None, None
        
        if user.role == 'client':
            phone_verification = getattr(user, 'phone_verification', None)
            if not phone_verification or phone_verification.status != 'verified':
                return True, "Téléphone non vérifié", "phone"
        
        elif user.role == 'provider':
            provider = getattr(user, 'provider_profile', None)
            if not provider or not provider.is_verified:
                return True, "Profil prestataire non vérifié", "documents"
        
        return False, None, None
    
    @staticmethod
    def get_verification_error_response(user, action_description="cette action"):
        """Retourne une réponse d'erreur standardisée pour les vérifications"""
        from rest_framework.response import Response
        from rest_framework import status
        
        needs_verification, reason, verification_type = VerificationPermissionMixin.user_needs_verification(user)
        
        if not needs_verification:
            return None
        
        messages = {
            "login": f"Vous devez être connecté pour {action_description}",
            "phone": f"Vous devez vérifier votre numéro de téléphone pour {action_description}",
            "documents": f"Vous devez vérifier votre profil prestataire pour {action_description}"
        }
        
        return Response({
            "detail": messages.get(verification_type, f"Vérification requise pour {action_description}"),
            "verification_required": True,
            "verification_type": verification_type,
            "reason": reason
        }, status=status.HTTP_403_FORBIDDEN)
    

# ================================================================
# 1. PERMISSIONS ADMIN PERSONNALISÉES
# ================================================================

class IsAdminOrReadOnly(permissions.BasePermission):
    """
    Permission permettant aux admins toutes les actions
    et lecture seule pour les autres utilisateurs authentifiés
    """
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        
        if request.method in permissions.SAFE_METHODS:
            return request.user.is_staff or request.user.is_superuser
        
        return request.user.is_staff or request.user.is_superuser


class IsSuperAdminOnly(permissions.BasePermission):
    """Permission réservée aux super-admins uniquement"""
    def has_permission(self, request, view):
        return (request.user and 
                request.user.is_authenticated and 
                request.user.is_superuser)
