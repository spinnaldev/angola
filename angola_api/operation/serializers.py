from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.db.models import Avg
from .models import (
    Category, SubCategory, Provider, ProviderService, Portfolio, 
    Certificate, Review, ReviewImage, Favorite, Conversation, 
    Message, Attachment, Dispute, DisputeEvidence, Notification, Report
)

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name', 'phone_number', 
                 'bio', 'profile_picture', 'role', 'is_verified', 'location', 'date_joined')
        read_only_fields = ('date_joined', 'is_verified')
        extra_kwargs = {'password': {'write_only': True}}
    
    def create(self, validated_data):
        password = validated_data.pop('password', None)
        user = User.objects.create(**validated_data)
        if password:
            user.set_password(password)
            user.save()
        return user

class UserUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('first_name', 'last_name', 'phone_number', 'bio', 'profile_picture', 'location')

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = '__all__'

class SubCategorySerializer(serializers.ModelSerializer):
    category_name = serializers.StringRelatedField(source='category.name', read_only=True)
    
    class Meta:
        model = SubCategory
        fields = ('id', 'name', 'description', 'icon', 'category', 'category_name')

class ProviderServiceSerializer(serializers.ModelSerializer):
    subcategory_name = serializers.StringRelatedField(source='subcategory.name', read_only=True)
    category_name = serializers.StringRelatedField(source='subcategory.category.name', read_only=True)
    avg_rating = serializers.SerializerMethodField()
    
    class Meta:
        model = ProviderService
        fields = ('id', 'title', 'description', 'price', 'price_type', 'is_available',
                 'subcategory', 'subcategory_name', 'category_name', 'avg_rating')
        read_only_fields = ('provider',)
    
    def get_avg_rating(self, obj):
        return obj.reviews.aggregate(avg=Avg('overall_rating')).get('avg') or 0

class PortfolioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Portfolio
        fields = ('id', 'title', 'description', 'image', 'created_at')
        read_only_fields = ('provider',)

class CertificateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Certificate
        fields = ('id', 'title', 'issuing_organization', 'issue_date', 'expiry_date', 
                 'file', 'is_verified', 'created_at')
        read_only_fields = ('provider', 'is_verified')

class ReviewImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReviewImage
        fields = ('id', 'image')

class ReviewSerializer(serializers.ModelSerializer):
    client_name = serializers.StringRelatedField(source='client.username', read_only=True)
    client_picture = serializers.ImageField(source='client.profile_picture', read_only=True)
    images = ReviewImageSerializer(many=True, read_only=True)
    uploaded_images = serializers.ListField(
        child=serializers.ImageField(max_length=1000000, allow_empty_file=False, use_url=False),
        write_only=True, required=False
    )
    
    class Meta:
        model = Review
        fields = ('id', 'client', 'client_name', 'client_picture', 'provider', 'service',
                 'quality_rating', 'punctuality_rating', 'value_rating', 'overall_rating',
                 'comment', 'is_verified', 'created_at', 'images', 'uploaded_images')
        read_only_fields = ('client', 'is_verified', 'overall_rating')
    
    def create(self, validated_data):
        uploaded_images = validated_data.pop('uploaded_images', [])
        review = Review.objects.create(**validated_data)
        
        for image in uploaded_images:
            ReviewImage.objects.create(review=review, image=image)
        
        return review

class ProviderListSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    full_name = serializers.SerializerMethodField()
    services_count = serializers.SerializerMethodField()
    reviews_count = serializers.SerializerMethodField()
    main_category = serializers.SerializerMethodField()
    
    class Meta:
        model = Provider
        fields = ('id', 'username', 'full_name', 'company_name', 'avg_rating', 
                 'is_verified', 'is_featured', 'services_count', 'reviews_count',
                 'main_category', 'address', 'latitude', 'longitude')
    
    def get_full_name(self, obj):
        return f"{obj.user.first_name} {obj.user.last_name}".strip() or obj.user.username
    
    def get_services_count(self, obj):
        return obj.provider_services.count()
    
    def get_reviews_count(self, obj):
        return obj.reviews_received.count()
    
    def get_main_category(self, obj):
        # Returns the most used category by this provider
        service = obj.provider_services.first()
        if service:
            return {
                'category_id': service.subcategory.category.id,
                'category_name': service.subcategory.category.name
            }
        return None

class ProviderDetailSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    services = ProviderServiceSerializer(source='provider_services', many=True, read_only=True)
    portfolio = PortfolioSerializer(many=True, read_only=True)
    certificates = CertificateSerializer(many=True, read_only=True)
    reviews = serializers.SerializerMethodField()
    is_favorited = serializers.SerializerMethodField()
    
    class Meta:
        model = Provider
        fields = ('id', 'user', 'company_name', 'is_verified', 'is_featured', 
                 'avg_rating', 'trust_score', 'address', 'latitude', 'longitude',
                 'services', 'portfolio', 'certificates', 'reviews', 'is_favorited')
    
    def get_reviews(self, obj):
        reviews = obj.reviews_received.all().order_by('-created_at')[:5]
        return ReviewSerializer(reviews, many=True).data
    
    def get_is_favorited(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.favorited_by.filter(user=request.user).exists()
        return False

class FavoriteSerializer(serializers.ModelSerializer):
    provider_details = ProviderListSerializer(source='provider', read_only=True)
    
    class Meta:
        model = Favorite
        fields = ('id', 'provider', 'created_at', 'provider_details')
        read_only_fields = ('user',)

class MessageSerializer(serializers.ModelSerializer):
    sender_name = serializers.StringRelatedField(source='sender.username', read_only=True)
    attachments = serializers.SerializerMethodField()
    
    class Meta:
        model = Message
        fields = ('id', 'sender', 'sender_name', 'content', 'is_read', 
                 'created_at', 'attachments')
        read_only_fields = ('sender', 'is_read')
    
    def get_attachments(self, obj):
        return [{'id': attachment.id, 'file': attachment.file.url, 'file_name': attachment.file_name}
                for attachment in obj.attachments.all()]

class ConversationSerializer(serializers.ModelSerializer):
    client_details = UserSerializer(source='client', read_only=True)
    provider_details = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Conversation
        fields = ('id', 'client', 'provider', 'client_details', 'provider_details',
                 'last_message', 'unread_count', 'created_at')
    
    def get_provider_details(self, obj):
        return {
            'id': obj.provider.id,
            'user_id': obj.provider.user.id,
            'username': obj.provider.user.username,
            'full_name': f"{obj.provider.user.first_name} {obj.provider.user.last_name}".strip(),
            'company_name': obj.provider.company_name,
            'profile_picture': obj.provider.user.profile_picture.url if obj.provider.user.profile_picture else None
        }
    
    def get_last_message(self, obj):
        message = obj.messages.order_by('-created_at').first()
        if message:
            return {
                'content': message.content,
                'sender_id': message.sender.id,
                'created_at': message.created_at,
                'is_read': message.is_read
            }
        return None
    
    def get_unread_count(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.messages.filter(is_read=False).exclude(sender=request.user).count()
        return 0

class DisputeEvidenceSerializer(serializers.ModelSerializer):
    user_name = serializers.StringRelatedField(source='user.username', read_only=True)
    
    class Meta:
        model = DisputeEvidence
        fields = ('id', 'user', 'user_name', 'description', 'file', 'created_at')
        read_only_fields = ('user',)

class DisputeSerializer(serializers.ModelSerializer):
    client_name = serializers.StringRelatedField(source='client.username', read_only=True)
    provider_name = serializers.StringRelatedField(source='provider.user.username', read_only=True)
    service_title = serializers.StringRelatedField(source='service.title', read_only=True)
    evidence = DisputeEvidenceSerializer(many=True, read_only=True)
    
    class Meta:
        model = Dispute
        fields = ('id', 'client', 'client_name', 'provider', 'provider_name', 
                 'service', 'service_title', 'title', 'description', 'status',
                 'resolution_note', 'created_at', 'evidence')
        read_only_fields = ('client', 'status', 'resolution_note')

class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ('id', 'title', 'content', 'type', 'related_object_id', 
                 'is_read', 'created_at')
        read_only_fields = ('user',)

class ReportSerializer(serializers.ModelSerializer):
    reporter_name = serializers.StringRelatedField(source='reporter.username', read_only=True)
    reported_user_name = serializers.StringRelatedField(source='reported_user.username', read_only=True)
    reported_provider_name = serializers.SerializerMethodField()
    
    class Meta:
        model = Report
        fields = ('id', 'reporter', 'reporter_name', 'reported_user', 'reported_user_name',
                 'reported_provider', 'reported_provider_name', 'reported_review',
                 'reason', 'status', 'type', 'created_at')
        read_only_fields = ('reporter', 'status', 'admin_notes')
    
    def get_reported_provider_name(self, obj):
        if obj.reported_provider:
            return obj.reported_provider.user.username
        return None

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    password2 = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    
    class Meta:
        model = User
        fields = ('username', 'password', 'password2', 'email', 'first_name', 'last_name', 
                 'phone_number', 'role', 'location')
        extra_kwargs = {
            'first_name': {'required': True},
            'last_name': {'required': True},
            'email': {'required': True}
        }
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        return attrs
    
    def create(self, validated_data):
        validated_data.pop('password2')
        user = User.objects.create(
            username=validated_data['username'],
            email=validated_data['email'],
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name'],
            phone_number=validated_data.get('phone_number', ''),
            role=validated_data.get('role', 'client'),
            location=validated_data.get('location', '')
        )
        user.set_password(validated_data['password'])
        user.save()
        
        # Create provider profile if role is provider
        if validated_data.get('role') == 'provider':
            Provider.objects.create(user=user)
        
        return user