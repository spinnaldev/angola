"""
URL configuration for angola_api project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
    
)
from operation import views
from django.conf import settings
from django.conf.urls.static import static
from operation.admin_views import (
    AdminNotificationViewSet, AdminProjectViewSet, AdminDisputeViewSet,
    admin_dashboard_stats, admin_recent_activity
)
from operation.views import (
    FCMViewSet, 
    NotificationPreferenceViewSet,
    NotificationHistoryViewSet
)

from operation.admin_auth_views import *

router = DefaultRouter()
router.register(r'api/users', views.UserViewSet)
router.register(r'api/categories', views.CategoryViewSet)
router.register(r'api/subcategories', views.SubCategoryViewSet)
router.register(r'api/providers', views.ProviderViewSet)
router.register(r'api/services', views.ProviderServiceViewSet)
router.register(r'api/portfolio', views.PortfolioViewSet)
router.register(r'api/certificates', views.CertificateViewSet)
router.register(r'api/reviews', views.ReviewViewSet)
router.register(r'api/favorites', views.FavoriteViewSet , basename='favorites')
router.register(r'api/favorits/providers', views.FavoriteProviderViewSet, basename='favorits-providers')
router.register(r'api/provider/(?P<provider_id>\d+)/reviews', views.ProviderReviewsViewSet, basename='provider-reviews')
router.register(r'api/conversations', views.ConversationViewSet, basename='conversation')
router.register(r'api/messages', views.MessageViewSet, basename='message')
router.register(r'api/disputes', views.DisputeViewSet)
router.register(r'api/notifications', views.NotificationViewSet)
router.register(r'api/reports', views.ReportViewSet)
# router.register(r'reports', views.ReportViewSet)
router.register(r'api/quote-requests', views.QuoteRequestViewSet)

# Projets clients
router.register(r'api/projects', views.ClientProjectViewSet, basename='clientproject')

# Offres sur projets
router.register(r'api/project-offers', views.ProjectOfferViewSet, basename='projectoffer')

# Favoris projets
router.register(r'api/project-favorites', views.ProjectFavoriteViewSet, basename='projectfavorite')

# # NOUVEAUX ENDPOINTS ADMIN

router.register(r'api/provider-verification', views.ProviderVerificationViewSet, basename='provider-verification')
router.register(r'api/phone-verification', views.PhoneVerificationViewSet, basename='phone-verification')
router.register(r'api/client-verification', views.ClientVerificationViewSet, basename='client-verification')

router.register(r'api/admin/projects', AdminProjectViewSet, basename='admin-projects')
router.register(r'api/admin/disputes', AdminDisputeViewSet, basename='admin-disputes')

router.register(r'api/admin/conversations', AdminConversationViewSet, basename='admin-conversations')

# router.register(r'api/admin/notifications', AdminNotificationViewSet, basename='admin-notifications')

router.register(r'api/admin/provider-verification', AdminProviderVerificationViewSet, basename='admin-provider-verification')

router.register(r'api/admin/client-verification', AdminClientVerificationViewSet, basename='admin-client-verification')

router.register(r'api/admin/phone-verification', AdminPhoneVerificationViewSet, basename='admin-phone-verification')

router.register(r'api/fcm', FCMViewSet, basename='fcm')
router.register(r'api/notification-preferences', NotificationPreferenceViewSet, basename='notification-preferences')
router.register(r'api/notification-history', NotificationHistoryViewSet, basename='notification-history')
router.register(r'api/admin/notifications', AdminNotificationViewSet, basename='admin-notifications')
urlpatterns = [
    path('django-admin/', admin.site.urls),
    
    path('api/auth/admin-login/', admin_login, name='admin_login'),
    path('api/auth/check-admin-status/', check_admin_status, name='check_admin_status'),
    path('api/auth/admin-setup-status/', admin_setup_status, name='admin_setup_status'),
    
    path('api/auth/login/', views.LoginView.as_view(), name='login'),  # Nouveau: endpoint de connexion
    path('api/auth/register/', views.RegisterView.as_view(), name='register'),
    path('api/auth/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/current-user/', views.CurrentUserView.as_view(), name='current-user'),
    path('api/user/<int:user_id>/', views.GetUserByIdView.as_view(), name='user-by-id'),
    
    # Password reset endpoints
    path('api/auth/password-reset-request/', views.PasswordResetRequestView.as_view(), name='password_reset_request'),
    path('api/auth/verify-reset-code/', views.VerifyResetCodeView.as_view(), name='verify_reset_code'),
    path('api/auth/password-reset-confirm/', views.PasswordResetConfirmView.as_view(), name='password_reset_confirm'),

    path('api/user/force-refresh-profile/', views.force_refresh_profile, name='force_refresh_profile'),
    path('api/user/profile-detailed/', views.get_current_user_detailed, name='get_current_user_detailed'),
    
    path('api/user/update-location/', views.update_user_location, name='update-location'),
    path('api/clients/nearby/', views.nearby_clients, name='nearby-clients'),
    
    # Notifications endpoints
    # path('api/notifications/count/', views.get_notification_count, name='notification-count'),
    path('api/notifications/mark_all_read/', views.mark_all_notifications_read, name='mark-all-notifications-read'),

    # path('providers/', views.ProviderViewSet.as_view(), name='provider-list'),
    path('api/providers/by_category/', views.ProviderByCategoryView.as_view(), name='provider-by-category'),
    path('api/providers/by_subcategory/', views.ProviderBySubcategoryView.as_view(), name='provider-by-subcategory'),
    path('api/providers/nearby/', views.NearbyProvidersView.as_view(), name='nearby-providers'),
    path('api/users/profile_stats/', views.get_profile_stats, name='profile-stats'),
    path('api/projects/<int:pk>/offers/', views.ClientProjectViewSet.as_view({'get': 'offers', 'post': 'offers'}), name='project-offers'),

    # path('api/providers-public/<int:pk>/stats/', views.stats, name='provider-stats'),
    path('api/providers-public/<int:pk>/stats/', views.provider_public_stats, name='provider-stats'),

    # path('api/projects/<int:project_id>/offers/', views.ProjectOfferViewSet.as_view({'get': 'by_project', 'post': 'create'}), name='project-offers-by-project'),
    
    path('api/projects/categories/<int:category_id>/', views.ClientProjectViewSet.as_view({'get': 'list'}),name='projects-by-category'),

    path('api/admin/dashboard/stats/', admin_dashboard_stats, name='admin-dashboard-stats'),
    path('api/admin/dashboard/recent-activity/', admin_recent_activity, name='admin-recent-activity'),


    # URLs Admin Conversations
    path('api/admin/conversations/overview/', conversation_overview, name='admin-conversations-overview'),
    path('api/admin/conversations/stats/', AdminConversationViewSet.as_view({'get': 'stats'}), name='admin-conversations-stats'),
    path('api/admin/messages/<int:message_id>/delete/', delete_message, name='admin-delete-message'),
    path('api/admin/conversations/bulk-mark-read/', bulk_mark_read, name='admin-bulk-mark-read'),

    # path('api/admin/notifications/', AdminNotificationViewSet.as_view(), name='admin-notifications'),
    path('api/admin/notifications/stats/', AdminNotificationViewSet.as_view({'get': 'stats'}), name='admin-notification-stats'),
    path('api/admin/notifications/send/', send_notification_to_user, name='send-notification'),
    path('api/admin/broadcast/notifications', broadcast_notification, name='broadcast-notification'),
    
    # Vérification du statut global
    path('api/verification/status/', views.check_verification_status, name='verification-status'),
    
    path('api/verification/check-action/', views.check_action_permission, name='check-action-permission' ),

    path('api/dashboard/', verification_dashboard,  name='admin-verification-dashboard'),
    
    # Rapports détaillés
    path('api/reports/', verification_reports, name='admin-verification-reports'),
    
    # Export des données
    path('api/export/', export_verifications, name='admin-export-verifications'),

    path('api/test/fcm-signals/', views.test_fcm_signals, name='test_fcm_signals'),
    path('api/test/bulk-fcm/', views.test_bulk_fcm, name='test_bulk_fcm'),

    path('', include(router.urls)),
]
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
# urlpatterns = [
    
# ]

