from functools import wraps
from rest_framework.response import Response
from rest_framework import status
from .permissions import VerificationPermissionMixin
# def require_verification(view_func):
#     """
#     Décorateur qui vérifie la vérification avant d'exécuter une action
#     """
#     @wraps(view_func)
#     def wrapper(request, *args, **kwargs):
#         user = request.user
        
#         if not user.is_authenticated:
#             return Response(
#                 {"detail": "Authentification requise"}, 
#                 status=status.HTTP_401_UNAUTHORIZED
#             )
        
#         # Admins passent toujours
#         if user.is_staff:
#             return view_func(request, *args, **kwargs)
        
#         # Vérifier selon le rôle
#         if user.role == 'client':
#             phone_verification = getattr(user, 'phone_verification', None)
#             if not phone_verification or phone_verification.status != 'verified':
#                 return Response({
#                     "detail": "Vous devez vérifier votre numéro de téléphone pour effectuer cette action",
#                     "verification_required": True,
#                     "verification_type": "phone"
#                 }, status=status.HTTP_403_FORBIDDEN)
        
#         elif user.role == 'provider':
#             provider = getattr(user, 'provider_profile', None)
#             if not provider or not provider.is_verified:
#                 return Response({
#                     "detail": "Votre profil prestataire doit être vérifié pour effectuer cette action",
#                     "verification_required": True,
#                     "verification_type": "documents"
#                 }, status=status.HTTP_403_FORBIDDEN)
        
#         return view_func(request, *args, **kwargs)
    
#     return wrapper

def require_verification(action_description="cette action"):
    """
    Décorateur pour bloquer les actions non autorisées
    """
    def decorator(view_func):
        def wrapper(self, request, *args, **kwargs):
            
            
            # Vérifier si l'utilisateur peut accéder
            error_response = VerificationPermissionMixin.get_verification_error_response(
                request.user, action_description
            )
            
            if error_response:
                return error_response
            
            # Continuer avec la vue originale
            return view_func(self, request, *args, **kwargs)
        
        return wrapper
    return decorator