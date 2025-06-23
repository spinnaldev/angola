import random
from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.db.models import Avg
from .models import *
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    profile_picture = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name', 'phone_number', 
                 'bio', 'profile_picture', 'role', 'is_verified', 'location', 'date_joined')
        read_only_fields = ('date_joined', 'is_verified')
        extra_kwargs = {'password': {'write_only': True}}
    
    def get_profile_picture(self, obj):
        """
        Retourne l'URL complète de l'image de profil
        """
        if obj.profile_picture:
            request = self.context.get('request')
            if request:
                # Construire l'URL complète avec le domaine
                print(request.build_absolute_uri(obj.profile_picture.url))
                return request.build_absolute_uri(obj.profile_picture.url)
            else:
                # Fallback si pas de request dans le contexte
                # Remplacez par votre domaine de production
                base_url = "http://10.0.2.2:8001"  # Pour l'émulateur Android
                # base_url = "https://votre-domaine.com"  # Pour la production
                return f"{base_url}{obj.profile_picture.url}"
        return None
    
    def create(self, validated_data):
        password = validated_data.pop('password', None)
        user = User.objects.create(**validated_data)
        if password:
            user.set_password(password)
            user.save()
        return user

# class UserUpdateSerializer(serializers.ModelSerializer):
#     class Meta:
#         model = User
#         fields = ['first_name', 'last_name', 'phone_number', 'bio', 'location', 'profile_picture']
        
    
    
class UserUpdateSerializer(serializers.ModelSerializer):
    profile_picture = serializers.ImageField(required=False)
    
    class Meta:
        model = User
        fields = ('first_name', 'last_name', 'phone_number', 'bio', 'location', 'profile_picture')
        
    def update(self, instance, validated_data):
        # Gérer l'upload de l'image de profil
        profile_picture = validated_data.pop('profile_picture', None)
        
        # Mettre à jour les autres champs
        for field, value in validated_data.items():
            setattr(instance, field, value)
        
        # Traiter l'image de profil
        if profile_picture:
            # Supprimer l'ancienne image
            if instance.profile_picture:
                try:
                    instance.profile_picture.delete(save=False)
                except:
                    pass
            instance.profile_picture = profile_picture
        
        instance.save()
        print("on enregistre")
        print(instance)
        return instance
    # def validate_phone_number(self, value):
    #     if value and len(value) < 8:
    #         raise serializers.ValidationError("Le numéro de téléphone doit contenir au moins 8 caractères")
    #     return value
class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = '__all__'

class SubCategorySerializer(serializers.ModelSerializer):
    category_name = serializers.StringRelatedField(source='category.name', read_only=True)
    
    class Meta:
        model = SubCategory
        fields = ('id', 'name', 'description', 'icon', 'category', 'category_name')

class ServiceOptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceOption
        fields = ('id', 'name', 'description', 'price', 'is_included')

class ServiceGalleryImageSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()
    
    class Meta:
        model = ServiceGalleryImage
        fields = ('id', 'image', 'image_url', 'caption', 'order')
    
    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get('request')
            return request.build_absolute_uri(obj.image.url) if request else obj.image.url
        return ""
    
class ProviderServiceSerializer(serializers.ModelSerializer):
    subcategory_name = serializers.StringRelatedField(source='subcategory.name', read_only=True)
    category_name = serializers.StringRelatedField(source='subcategory.category.name', read_only=True)
    category_id = serializers.SerializerMethodField()
    avg_rating = serializers.SerializerMethodField()
    image_url = serializers.SerializerMethodField()
    gallery_images = ServiceGalleryImageSerializer(many=True, read_only=True)
    options = ServiceOptionSerializer(many=True, read_only=True)
    is_available = serializers.BooleanField(default=True)

    class Meta:
        model = ProviderService
        fields = ('id', 'title', 'description', 'price', 'price_type', 'is_available',
                 'subcategory', 'subcategory_name', 'category_name', 'category_id',
                 'avg_rating', 'image', 'image_url', 'provider_id','gallery_images', 'options')
        # read_only_fields = ('provider',)
    
    def get_avg_rating(self, obj):
        return obj.reviews.aggregate(avg=Avg('overall_rating')).get('avg') or 0

    def get_category_id(self, obj):
        if obj.subcategory and obj.subcategory.category:
            return obj.subcategory.category.id
        return None
    
    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get('request')
            return request.build_absolute_uri(obj.image.url) if request else obj.image.url
        return ""
    
    

    def create(self, validated_data):
        # Créer le service
        service = ProviderService.objects.create(**validated_data)
        
        # Traiter les images de galerie
        gallery_data = self.context.get('gallery_images', [])
        for img_data in gallery_data:
            ServiceGalleryImage.objects.create(service=service, **img_data)
            
        # Traiter les options
        options_data = self.context.get('options', [])
        for opt_data in options_data:
            ServiceOption.objects.create(service=service, **opt_data)
            
        return service
        
    def update(self, instance, validated_data):
        # Mettre à jour les champs de base
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        # Mettre à jour les images de galerie
        gallery_data = self.context.get('gallery_images')
        if gallery_data is not None:
            # Supprimer les images existantes
            instance.gallery_images.all().delete()
            # Créer les nouvelles images
            for img_data in gallery_data:
                ServiceGalleryImage.objects.create(service=instance, **img_data)
                
        # Mettre à jour les options
        options_data = self.context.get('options')
        if options_data is not None:
            # Supprimer les options existantes
            instance.options.all().delete()
            # Créer les nouvelles options
            for opt_data in options_data:
                ServiceOption.objects.create(service=instance, **opt_data)
                
        return instance
    

    
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
        
    def update(self, instance, validated_data):
        # Permettre la mise à jour de company_name
        for field, value in validated_data.items():
            setattr(instance, field, value)
        instance.save()
        return instance

class FavoriteSerializer(serializers.ModelSerializer):
    provider_details = ProviderListSerializer(source='provider', read_only=True)
    
    class Meta:
        model = Favorite
        fields = ('id', 'provider', 'created_at', 'provider_details')
        read_only_fields = ('user',)

class MessageSerializer(serializers.ModelSerializer):
    sender_id = serializers.IntegerField(source='sender.id')
    sender_name = serializers.SerializerMethodField()
    sender_picture = serializers.SerializerMethodField()
    is_mine = serializers.SerializerMethodField()
    
    class Meta:
        model = Message
        fields = ('id', 'sender_id', 'sender_name', 'sender_picture', 'content', 
                 'is_read', 'created_at', 'is_mine')
    
    def get_sender_name(self, obj):
        return f"{obj.sender.first_name} {obj.sender.last_name}".strip() or obj.sender.username
    
    def get_sender_picture(self, obj):
        if obj.sender.profile_picture:
            return obj.sender.profile_picture.url
        return None
    
    def get_is_mine(self, obj):
        user_id = self.context.get('user_id')
        if user_id:
            return obj.sender.id == int(user_id)
        return False

class ConversationSerializer(serializers.ModelSerializer):
    client = UserSerializer()
    provider = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    is_online = serializers.SerializerMethodField()
    
    class Meta:
        model = Conversation
        fields = ('id', 'client', 'provider', 'last_message', 
                 'unread_count', 'created_at', 'updated_at', 'is_online')
    
    def get_provider(self, obj):
        provider_data = {
            'user_id': obj.provider.user.id,
            'username': obj.provider.user.username,
            'first_name': obj.provider.user.first_name,
            'last_name': obj.provider.user.last_name,
            'profile_picture': obj.provider.user.profile_picture.url if obj.provider.user.profile_picture else None,
            'company_name': obj.provider.company_name,
        }
        return provider_data
    
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
        user_id = self.context.get('user_id')
        if user_id:
            try:
                user = User.objects.get(id=int(user_id))
                if hasattr(user, 'provider_profile') and obj.provider.id == user.provider_profile.id:
                    # L'utilisateur est le prestataire
                    return Message.objects.filter(
                        conversation=obj,
                        sender=obj.client,
                        is_read=False
                    ).count()
                else:
                    # L'utilisateur est le client
                    return Message.objects.filter(
                        conversation=obj,
                        sender=obj.provider.user,
                        is_read=False
                    ).count()
            except (ValueError, User.DoesNotExist):
                pass
        return 0
    
    def get_is_online(self, obj):
        # Simuler un statut en ligne
        # À remplacer par une vraie logique de statut en ligne dans une application de production
        return random.choice([True, False])

class QuoteRequestSerializer(serializers.ModelSerializer):
    client_name = serializers.StringRelatedField(source='client.username', read_only=True)
    provider_name = serializers.StringRelatedField(source='provider.user.username', read_only=True)
    service_name = serializers.StringRelatedField(source='service.title', read_only=True)
    
    class Meta:
        model = QuoteRequest
        fields = ('id', 'client', 'client_name', 'provider', 'provider_name', 
                 'service', 'service_name', 'subject', 'budget', 'description', 
                 'status', 'created_at')
        read_only_fields = ('client', 'status')   

        
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
    categories = serializers.ListField(
        child=serializers.IntegerField(),
        required=False,
        write_only=True
    )
    # Champs de réponse
    access = serializers.CharField(read_only=True)
    refresh = serializers.CharField(read_only=True)
    user = serializers.SerializerMethodField()
    class Meta:
        model = User
        fields = ('username', 'password',  'email', 'first_name', 'last_name', 
                 'phone_number', 'role', 'location' ,'categories','access', 'refresh', 'user')
        extra_kwargs = {
            'first_name': {'required': True},
            'last_name': {'required': True},
            'email': {'required': True}
        }
    def create(self, validated_data):
        # Extraire les catégories (si présentes)
        categories = validated_data.pop('categories', [])
        print(categories)
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
        
        # Créer un profil prestataire si le rôle est provider
        if validated_data.get('role') == 'provider':
            provider = Provider.objects.create(user=user)
            
            # Ajouter les catégories d'expertise
            if categories:
                category_objects = Category.objects.filter(id__in=categories)
                provider.expertise_categories.set(category_objects)
        
        return user
    
    def get_user(self, obj):
        """Retourne les données utilisateur sérialisées"""
        return UserSerializer(obj).data
    
    def to_representation(self, instance):
        """Personnalise la réponse pour inclure les tokens et les données utilisateur"""
        # Générer les tokens
        refresh = RefreshToken.for_user(instance)
        
        return {
            'user': UserSerializer(instance).data,
            'access': str(refresh.access_token),
            'refresh': str(refresh),
        }
    # def validate(self, attrs):
    #     if attrs['password'] != attrs['password2']:
    #         raise serializers.ValidationError({"password": "Password fields didn't match."})
    #     return attrs

class ProviderSkillSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProviderSkill
        fields = ['id', 'name', 'level', 'years_experience']

class ProjectSkillSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProjectSkill
        fields = ['id', 'name', 'is_required']

class ClientProjectListSerializer(serializers.ModelSerializer):
    """Serializer pour la liste des projets (vue d'ensemble)"""
    client_name = serializers.SerializerMethodField()
    category_name = serializers.CharField(source='category.name', read_only=True)
    subcategory_name = serializers.CharField(source='subcategory.name', read_only=True)
    offers_count = serializers.IntegerField(read_only=True)
    time_since_posted = serializers.SerializerMethodField()
    is_favorited = serializers.SerializerMethodField()
    has_user_offered = serializers.SerializerMethodField()
    budget_display = serializers.SerializerMethodField()

    class Meta:
        model = ClientProject
        fields = [
            'id', 'title', 'description', 'client_name', 'category_name', 
            'subcategory_name', 'budget_range', 'budget_display', 'location',
            'urgency', 'status', 'offers_count', 'views_count', 'created_at',
            'time_since_posted', 'deadline', 'remote_possible', 'is_favorited',
            'has_user_offered','min_budget', 'max_budget'
        ]
    
    def get_client_name(self, obj):
        """Masquer le nom du client pour les utilisateurs non authentifiés"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.client.first_name or obj.client.username
        return "Client anonyme"
    
    def get_budget_display(self, obj):
        """Génère l'affichage formaté du budget"""
        budget_ranges = {
            'moins_500': 'Moins de 500 €',
            '500_1000': '500 à 1 000 €',
            '1000_10000': '1 000 à 10 000 €',
            '10000_plus': '10 000 € et plus',
            'sur_devis': 'Sur devis'
        }
        
        # Si on a des valeurs min/max budget définies
        if obj.min_budget is not None and obj.max_budget is not None:
            if obj.min_budget == obj.max_budget:
                return f"{int(obj.min_budget)} €"
            else:
                return f"{int(obj.min_budget)} € - {int(obj.max_budget)} €"
        
        # Si on a seulement un budget minimum
        elif obj.min_budget is not None:
            return f"À partir de {int(obj.min_budget)} €"
        
        # Si on a seulement un budget maximum
        elif obj.max_budget is not None:
            return f"Jusqu'à {int(obj.max_budget)} €"
        
        # Sinon utiliser la plage prédéfinie
        return budget_ranges.get(obj.budget_range, 'Budget à discuter')
    
    def get_is_favorited(self, obj):
        """Vérifie si le projet est en favori pour l'utilisateur actuel - TOUJOURS retourner un booléen"""
        request = self.context.get('request')
        
        # Si pas de requête ou utilisateur non authentifié
        if not request or not request.user.is_authenticated:
            return False
        
        # Si l'utilisateur n'est pas un prestataire
        if not hasattr(request.user, 'provider_profile'):
            return False
            
        try:
            # Vérifier si le projet est en favori
            return ProjectFavorite.objects.filter(
                project=obj,
                provider=request.user.provider_profile
            ).exists()
        except Exception as e:
            # En cas d'erreur, toujours retourner False plutôt que None
            print(f"Erreur dans get_is_favorited: {e}")
            return False
    
    def get_has_user_offered(self, obj):
        """Vérifie si l'utilisateur actuel a déjà fait une offre - TOUJOURS retourner un booléen"""
        request = self.context.get('request')
        
        # Si pas de requête ou utilisateur non authentifié
        if not request or not request.user.is_authenticated:
            return False
            
        # Si l'utilisateur n'est pas un prestataire
        if not hasattr(request.user, 'provider_profile'):
            return False
            
        try:
            return ProjectOffer.objects.filter(
                project=obj, 
                provider=request.user.provider_profile
            ).exists()
        except Exception as e:
            # En cas d'erreur, toujours retourner False plutôt que None
            print(f"Erreur dans get_has_user_offered: {e}")
            return False
        
    def get_time_since_posted(self, obj):
        """Calcul du temps écoulé depuis la publication"""
        from django.utils import timezone
        from datetime import timedelta
        
        try:
            now = timezone.now()
            diff = now - obj.created_at
            
            if diff.days > 0:
                return f"Il y a {diff.days} jour{'s' if diff.days > 1 else ''}"
            elif diff.seconds > 3600:
                hours = diff.seconds // 3600
                return f"Il y a {hours} heure{'s' if hours > 1 else ''}"
            elif diff.seconds > 60:
                minutes = diff.seconds // 60
                return f"Il y a {minutes} minute{'s' if minutes > 1 else ''}"
            else:
                return "À l'instant"
        except Exception as e:
            print(f"Erreur dans get_time_since_posted: {e}")
            return "Récemment"


class ClientProjectDetailSerializer(serializers.ModelSerializer):
    """Serializer détaillé pour un projet spécifique"""
    client = UserSerializer(read_only=True)
    category = CategorySerializer(read_only=True)
    subcategory = SubCategorySerializer(read_only=True)
    required_skills = ProjectSkillSerializer(many=True, read_only=True)
    offers_count = serializers.SerializerMethodField()
    budget_display = serializers.CharField(read_only=True)
    is_favorited = serializers.SerializerMethodField()
    has_user_offered = serializers.SerializerMethodField()
    
    class Meta:
        model = ClientProject
        fields = [
            'id', 'title', 'description', 'client', 'category', 'subcategory',
            'budget_range', 'min_budget', 'max_budget', 'budget_display',
            'location', 'remote_possible', 'deadline', 'urgency', 'status',
            'contact_via_platform', 'show_email', 'show_phone',
            'required_skills', 'offers_count', 'views_count', 'created_at',
            'is_favorited', 'has_user_offered', 'attachment1', 'attachment2', 'attachment3'
        ]
    
    def get_is_favorited(self, obj):
        """Vérifie si le projet est en favori pour l'utilisateur actuel"""
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
            
        if not hasattr(request.user, 'provider_profile'):
            return False
            
        try:
            return ProjectFavorite.objects.filter(
                project=obj, 
                provider=request.user.provider_profile
            ).exists()
        except Exception as e:
            print(f"Erreur dans get_is_favorited (detail): {e}")
            return False
    
    def get_offers_count(self, obj):
        """Compte le nombre d'offres pour ce projet"""
        try:
            return getattr(obj, 'total_offers', obj.project_offers.count())
        except Exception as e:
            print(f"Erreur dans get_offers_count: {e}")
            return 0
    
    def get_has_user_offered(self, obj):
        """Vérifie si l'utilisateur actuel a déjà fait une offre"""
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
            
        if not hasattr(request.user, 'provider_profile'):
            return False
            
        try:
            return ProjectOffer.objects.filter(
                project=obj, 
                provider=request.user.provider_profile
            ).exists()
        except Exception as e:
            print(f"Erreur dans get_has_user_offered (detail): {e}")
            return False

class ClientProjectCreateSerializer(serializers.ModelSerializer):
    """Serializer pour la création d'un projet"""
    required_skills = ProjectSkillSerializer(many=True, required=False)
    
    class Meta:
        model = ClientProject
        fields = [
            'title', 'description', 'category', 'subcategory',
            'budget_range', 'min_budget', 'max_budget', 'location',
            'remote_possible', 'deadline', 'urgency',
            'contact_via_platform', 'show_email', 'show_phone',
            'required_skills', 'attachment1', 'attachment2', 'attachment3'
        ]
    
    def create(self, validated_data):
        skills_data = validated_data.pop('required_skills', [])
        request = self.context.get('request')
        validated_data['client'] = request.user
        
        project = ClientProject.objects.create(**validated_data)
        
        # Créer les compétences requises
        for skill_data in skills_data:
            ProjectSkill.objects.create(project=project, **skill_data)
        
        return project

class ProjectOfferSerializer(serializers.ModelSerializer):
    """Serializer pour les offres sur les projets"""
    provider_name = serializers.CharField(source='provider.user.get_full_name', read_only=True)
    provider_business_type = serializers.CharField(source='provider.business_type', read_only=True)
    # provider_rating = serializers.SerializerMethodField()
    provider_avatar = serializers.SerializerMethodField()
    provider_location = serializers.CharField(source='provider.user.location', read_only=True)
    provider_verified = serializers.BooleanField(source='provider.is_verified', read_only=True)
    project_title = serializers.CharField(source='project.title', read_only=True)
    
    class Meta:
        model = ProjectOffer
        fields = [
            'id', 'project', 'project_title', 'provider', 'provider_name',
            'provider_business_type', 'provider_avatar',
            'provider_location', 'provider_verified', 'proposed_price',
            'delivery_time', 'message', 'includes_materials', 'warranty_period',
            'travel_costs_included', 'status', 'viewed_by_client', 'created_at'
        ]
        read_only_fields = ['provider', 'viewed_by_client']
    
    # def get_provider_rating(self, obj):
    #     """Calculer la note moyenne du prestataire"""
    #     from django.db.models import Avg
    #     avg_rating = obj.provider.reviews_received.aggregate(
    #         avg_rating=Avg('rating')
    #     )['avg_rating']
    #     return round(avg_rating, 1) if avg_rating else 0
    
    def get_provider_avatar(self, obj):
        """Obtenir l'avatar du prestataire"""
        if obj.provider.user.profile_picture:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.provider.user.profile_picture.url)
        return None
    
    def create(self, validated_data):
        request = self.context.get('request')
        provider = request.user.provider_profile
        validated_data['provider'] = provider
        return super().create(validated_data)

class ProjectOfferCreateSerializer(serializers.ModelSerializer):
    """Serializer pour créer une offre"""
    class Meta:
        model = ProjectOffer
        fields = [
            'project', 'proposed_price', 'delivery_time', 'message',
            'includes_materials', 'warranty_period', 'travel_costs_included'
        ]
    
    def validate(self, data):
        """Validation personnalisée"""
        request = self.context.get('request')
        provider = request.user.provider_profile
        project = data['project']
        
        # Vérifier si le prestataire a déjà fait une offre
        if ProjectOffer.objects.filter(project=project, provider=provider).exists():
            raise serializers.ValidationError(
                "Vous avez déjà fait une offre pour ce projet."
            )
        
        # Vérifier si le projet est encore ouvert
        if project.status != 'open':
            raise serializers.ValidationError(
                "Ce projet n'accepte plus d'offres."
            )
        
        return data
    
    def create(self, validated_data):
        request = self.context.get('request')
        provider = request.user.provider_profile
        validated_data['provider'] = provider
        return super().create(validated_data)

class ProjectFavoriteSerializer(serializers.ModelSerializer):
    """Serializer pour les projets favoris"""
    project = ClientProjectListSerializer(read_only=True)
    
    class Meta:
        model = ProjectFavorite
        fields = ['id', 'project', 'created_at']

# Serializer pour les statistiques des projets
class ProjectStatsSerializer(serializers.Serializer):
    """Statistiques pour le dashboard client"""
    total_projects = serializers.IntegerField()
    open_projects = serializers.IntegerField()
    completed_projects = serializers.IntegerField()
    total_offers = serializers.IntegerField()
    average_offers_per_project = serializers.FloatField()

# Serializer pour les filtres de recherche
class ProjectFilterSerializer(serializers.Serializer):
    """Filtres pour la recherche de projets"""
    category = serializers.IntegerField(required=False)
    subcategory = serializers.IntegerField(required=False)
    budget_min = serializers.DecimalField(max_digits=10, decimal_places=2, required=False)
    budget_max = serializers.DecimalField(max_digits=10, decimal_places=2, required=False)
    location = serializers.CharField(max_length=255, required=False)
    remote_only = serializers.BooleanField(required=False)
    urgency = serializers.ChoiceField(choices=ClientProject.URGENCY_CHOICES, required=False)
    posted_within_days = serializers.IntegerField(required=False, min_value=1, max_value=365)
    search = serializers.CharField(max_length=255, required=False)
    