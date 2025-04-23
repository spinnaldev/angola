from django.forms import ValidationError
from django.shortcuts import render

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
from django.contrib.gis.geos import Point
from django.contrib.gis.measure import D
from django.contrib.gis.db.models.functions import Distance

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

class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (AllowAny,)
    serializer_class = RegisterSerializer

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
    
    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAdminUser()]
        return [AllowAny()]

class SubCategoryViewSet(viewsets.ModelViewSet):
    queryset = SubCategory.objects.all()
    serializer_class = SubCategorySerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['category']
    search_fields = ['name', 'description']
    
    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAdminUser()]
        return [AllowAny()]

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
        
        # Create a point from the coordinates
        user_location = Point(lng, lat, srid=4326)
        
        # Find providers within the radius
        providers = Provider.objects.filter(
            longitude__isnull=False,
            latitude__isnull=False
        ).extra(
            select={'distance': 'ST_Distance_Sphere(POINT(longitude, latitude), POINT(%s, %s))'},
            select_params=[lng, lat]
        ).order_by('distance')
        
        # Filter by radius (in meters)
        providers = providers.filter(distance__lte=radius * 1000)
        
        page = self.paginate_queryset(providers)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(providers, many=True)
        return Response(serializer.data)

class ProviderServiceViewSet(viewsets.ModelViewSet):
    queryset = ProviderService.objects.all()
    serializer_class = ProviderServiceSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = StandardResultsSetPagination
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['subcategory', 'is_available', 'price_type']
    search_fields = ['title', 'description']
    
    def get_queryset(self):
        provider_id = self.request.query_params.get('provider_id')
        if provider_id:
            return ProviderService.objects.filter(provider_id=provider_id)
        return ProviderService.objects.all()
    
    def get_permissions(self):
        if self.action == 'list' or self.action == 'retrieve':
            return [AllowAny()]
        return [IsAuthenticated()]
    
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
    queryset = Conversation.objects.all()
    serializer_class = ConversationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if hasattr(user, 'provider_profile'):
            # If user is a provider, get conversations where they are the provider
            provider_conversations = Conversation.objects.filter(provider=user.provider_profile)
            return provider_conversations
        else:
            # If user is a client, get conversations where they are the client
            return Conversation.objects.filter(client=user)
    
    @action(detail=True, methods=['get'])
    def messages(self, request, pk=None):
        conversation = self.get_object()
        messages = conversation.messages.all().order_by('created_at')
        
        # Mark messages as read
        unread_messages = messages.filter(is_read=False).exclude(sender=request.user)
        for message in unread_messages:
            message.is_read = True
            message.save()
        
        serializer = MessageSerializer(messages, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def send_message(self, request, pk=None):
        conversation = self.get_object()
        content = request.data.get('content')
        if not content:
            return Response({"detail": "Content is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        message = Message.objects.create(
            conversation=conversation,
            sender=request.user,
            content=content
        )
        
        # Handle attachments if any
        files = request.FILES.getlist('files')
        for file in files:
            Attachment.objects.create(
                message=message,
                file=file,
                file_name=file.name
            )
        
        serializer = MessageSerializer(message)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'])
    def start(self, request):
        provider_id = request.data.get('provider_id')
        if not provider_id:
            return Response({"detail": "provider_id is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        provider = get_object_or_404(Provider, id=provider_id)
        user = request.user
        
        # Check if the user is not trying to start a conversation with themselves
        if hasattr(user, 'provider_profile') and user.provider_profile.id == provider.id:
            return Response({"detail": "You cannot start a conversation with yourself"}, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if there's already a conversation between the user and the provider
        existing_conversation = Conversation.objects.filter(client=user, provider=provider).first()
        if existing_conversation:
            serializer = self.get_serializer(existing_conversation)
            return Response(serializer.data)
        
        # Create a new conversation
        conversation = Conversation.objects.create(client=user, provider=provider)
        
        # Add an initial message if provided
        initial_message = request.data.get('message')
        if initial_message:
            Message.objects.create(
                conversation=conversation,
                sender=user,
                content=initial_message
            )
        
        serializer = self.get_serializer(conversation)
        return Response(serializer.data)

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