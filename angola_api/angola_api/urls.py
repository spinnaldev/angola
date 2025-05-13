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

router = DefaultRouter()
router.register(r'api/users', views.UserViewSet)
router.register(r'api/categories', views.CategoryViewSet)
router.register(r'api/subcategories', views.SubCategoryViewSet)
router.register(r'api/providers', views.ProviderViewSet)
router.register(r'api/services', views.ProviderServiceViewSet)
router.register(r'api/portfolio', views.PortfolioViewSet)
router.register(r'api/certificates', views.CertificateViewSet)
router.register(r'api/reviews', views.ReviewViewSet)
router.register(r'api/favorites', views.FavoriteViewSet)
router.register(r'api/conversations', views.ConversationViewSet)
router.register(r'api/disputes', views.DisputeViewSet)
router.register(r'api/notifications', views.NotificationViewSet)
router.register(r'api/reports', views.ReportViewSet)
# router.register(r'reports', views.ReportViewSet)
router.register(r'api/quote-requests', views.QuoteRequestViewSet)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include(router.urls)),
    path('api/auth/login/', views.LoginView.as_view(), name='login'),  # Nouveau: endpoint de connexion
    path('api/auth/register/', views.RegisterView.as_view(), name='register'),
    path('api/auth/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # Password reset endpoints
    path('api/password-reset-request/', views.PasswordResetRequestView.as_view(), name='password_reset_request'),
    path('api/verify-reset-code/', views.VerifyResetCodeView.as_view(), name='verify_reset_code'),
    path('api/password-reset-confirm/', views.PasswordResetConfirmView.as_view(), name='password_reset_confirm'),
    path('notifications/count/', views.get_notification_count, name='notification-count'),
    path('notifications/mark_all_read/', views.mark_all_notifications_read, name='mark-all-notifications-read'),

    # path('providers/', views.ProviderViewSet.as_view(), name='provider-list'),
    path('providers/by_category/', views.ProviderByCategoryView.as_view(), name='provider-by-category'),
    path('providers/by_subcategory/', views.ProviderBySubcategoryView.as_view(), name='provider-by-subcategory'),
    path('providers/nearby/', views.NearbyProvidersView.as_view(), name='nearby-providers'),
]
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
# urlpatterns = [
    
# ]

