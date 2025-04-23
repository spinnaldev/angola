from rest_framework import permissions

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

class IsProviderOwner(permissions.BasePermission):
    """
    Custom permission to only allow owners of a provider profile to edit it.
    """
    def has_object_permission(self, request, view, obj):
        # Read permissions are allowed to any request
        if request.method in permissions.SAFE_METHODS:
            return True

        # Write permissions are only allowed to the owner
        if hasattr(request.user, 'provider_profile'):
            return obj == request.user.provider_profile
        return False

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