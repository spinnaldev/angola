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

router = DefaultRouter()
router.register(r'users', views.UserViewSet)
router.register(r'categories', views.CategoryViewSet)
router.register(r'subcategories', views.SubCategoryViewSet)
router.register(r'providers', views.ProviderViewSet)
router.register(r'services', views.ProviderServiceViewSet)
router.register(r'portfolio', views.PortfolioViewSet)
router.register(r'certificates', views.CertificateViewSet)
router.register(r'reviews', views.ReviewViewSet)
router.register(r'favorites', views.FavoriteViewSet)
router.register(r'conversations', views.ConversationViewSet)
router.register(r'disputes', views.DisputeViewSet)
router.register(r'notifications', views.NotificationViewSet)
router.register(r'reports', views.ReportViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('auth/register/', views.RegisterView.as_view(), name='register'),
    path('auth/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]
urlpatterns = [
    path('admin/', admin.site.urls),
]

