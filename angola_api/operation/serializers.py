import random
from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.db.models import Avg
from .models import *
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    profile_picture = serializers.SerializerMethodField()
    company_name = serializers.SerializerMethodField()
    full_name = serializers.SerializerMethodField()

    verification_status = serializers.SerializerMethodField()
    verification_details = serializers.SerializerMethodField()
    is_phone_verified = serializers.SerializerMethodField()
    is_provider_verified = serializers.SerializerMethodField()
    needs_verification = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name', 'phone_number', 
                 'bio', 'profile_picture', 'role', 'is_verified', 'location', 'date_joined',
                 'company_name' , 'full_name', 'verification_status', 'verification_details', 'is_phone_verified', 
                'is_provider_verified', 'needs_verification' )
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
                # base_url = "http://10.0.2.2:8001"  # Pour l'émulateur Android
                base_url = "https://angola.onrender.com/api"  # Pour la production
                return f"{base_url}{obj.profile_picture.url}"
        return None
    
    def create(self, validated_data):
        password = validated_data.pop('password', None)
        user = User.objects.create(**validated_data)
        if password:
            user.set_password(password)
            user.save()
        return user

    def get_full_name(self, obj):
        return f"{obj.first_name} {obj.last_name}"
    
    def get_verification_status(self, obj):
        """Statut de vérification global"""
        if obj.role == 'client':
            phone_verification = getattr(obj, 'phone_verification', None)
            if phone_verification:
                return phone_verification.status
            return 'not_started'
        elif obj.role == 'provider':
            provider = getattr(obj, 'provider_profile', None)
            if provider and hasattr(provider, 'verification'):
                return provider.verification.verification_status
            return 'not_started'
        return 'not_applicable'
    
    def get_verification_details(self, obj):
        """Détails de la vérification selon le rôle"""
        if obj.role == 'client':
            phone_verification = getattr(obj, 'phone_verification', None)
            if phone_verification:
                return {
                    'type': 'phone',
                    'phone_number': phone_verification.phone_number,
                    'verified_at': phone_verification.verified_at,
                    'status': phone_verification.status
                }
        elif obj.role == 'provider':
            provider = getattr(obj, 'provider_profile', None)
            if provider and hasattr(provider, 'verification'):
                verification = provider.verification
                return {
                    'type': 'documents',
                    'is_business': verification.is_business,
                    'document_type': verification.document_type,
                    'submitted_at': verification.submitted_at,
                    'verified_at': verification.verified_at,
                    'status': verification.verification_status,
                    'rejection_reason': verification.rejection_reason
                }
        return None
    
    def get_is_phone_verified(self, obj):
        """Vérifie si le téléphone est vérifié"""
        if obj.role == 'client':
            phone_verification = getattr(obj, 'phone_verification', None)
            return phone_verification and phone_verification.status == 'verified'
        return obj.role != 'client'  # Les non-clients n'ont pas besoin de vérification téléphone
    
    def get_is_provider_verified(self, obj):
        """Vérifie si le profil prestataire est vérifié"""
        if obj.role == 'provider':
            provider = getattr(obj, 'provider_profile', None)
            return provider and provider.is_verified
        return obj.role != 'provider'  # Les non-prestataires n'ont pas besoin de vérification documents
    
    def get_needs_verification(self, obj):
        """Vérifie si l'utilisateur a besoin de vérification"""
        if obj.is_staff:
            return False
        
        if obj.role == 'client':
            return not self.get_is_phone_verified(obj)
        elif obj.role == 'provider':
            return not self.get_is_provider_verified(obj)
        
        return False
    
    def get_company_name(self, obj):
        """
        Récupérer le nom de l'entreprise pour les prestataires
        """
        if obj.role == 'provider' and hasattr(obj, 'provider_profile'):
            return obj.provider_profile.company_name
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
        



# ================================================================
# 4. SERIALIZERS POUR LES STATISTIQUES ET RAPPORTS
# ================================================================

class VerificationStatsSerializer(serializers.Serializer):
    """
    Serializer pour les statistiques de vérification (admin)
    """
    
    # Statistiques prestataires
    provider_verifications = serializers.DictField(read_only=True)
    provider_pending_count = serializers.IntegerField(read_only=True)
    provider_verified_count = serializers.IntegerField(read_only=True)
    provider_rejected_count = serializers.IntegerField(read_only=True)
    
    # Statistiques clients
    phone_verifications = serializers.DictField(read_only=True)
    phone_verified_count = serializers.IntegerField(read_only=True)
    phone_pending_count = serializers.IntegerField(read_only=True)
    
    # Statistiques globales
    total_users = serializers.IntegerField(read_only=True)
    verified_users_percentage = serializers.FloatField(read_only=True)
    
    # Tendances (optionnel)
    weekly_verifications = serializers.ListField(read_only=True)
    average_approval_time = serializers.FloatField(read_only=True)


# ================================================================
# 5. SERIALIZERS POUR LES PERMISSIONS ET BLOCAGES
# ================================================================

class VerificationRequiredSerializer(serializers.Serializer):
    """
    Serializer pour les réponses de blocage de vérification
    """
    detail = serializers.CharField(help_text="Message d'erreur")
    verification_required = serializers.BooleanField(default=True)
    verification_type = serializers.ChoiceField(
        choices=[('phone', 'Téléphone'), ('documents', 'Documents'), ('login', 'Connexion')]
    )
    reason = serializers.CharField(help_text="Raison du blocage")
    redirect_url = serializers.CharField(required=False, help_text="URL de redirection suggérée")


class ActionBlockedSerializer(serializers.Serializer):
    """
    Serializer pour les actions bloquées
    """
    action = serializers.CharField(help_text="Action tentée")
    blocked = serializers.BooleanField(default=True)
    reason = serializers.CharField(help_text="Raison du blocage")
    required_verification = serializers.CharField(help_text="Type de vérification requis")
    user_role = serializers.CharField(help_text="Rôle de l'utilisateur")
    suggestions = serializers.ListField(
        child=serializers.CharField(),
        help_text="Suggestions pour débloquer l'action"
    )
    
class UserUpdateSerializer(serializers.ModelSerializer):
    profile_picture = serializers.ImageField(required=False)
    company_name = serializers.CharField(required=False, allow_blank=True)
    
    class Meta:
        model = User
        fields = ('first_name', 'last_name', 'phone_number', 'bio', 'location', 'profile_picture', 'company_name')
        
    def update(self, instance, validated_data):
        # ✅ GESTION DU COMPANY_NAME
        company_name = validated_data.pop('company_name', None)
        
        # Gérer l'upload de l'image de profil
        profile_picture = validated_data.pop('profile_picture', None)
        
        # Mettre à jour les autres champs utilisateur
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        
        # Gérer l'image de profil
        if profile_picture:
            # Supprimer l'ancienne image si elle existe
            if instance.profile_picture:
                try:
                    instance.profile_picture.delete(save=False)
                except Exception:
                    pass
            instance.profile_picture = profile_picture
        
        instance.save()
        
        # ✅ GESTION SPÉCIALE POUR LE COMPANY_NAME DES PRESTATAIRES
        if company_name is not None and instance.role == 'provider':
            # Créer ou mettre à jour le profil prestataire
            provider_profile, created = Provider.objects.get_or_create(
                user=instance,
                defaults={'company_name': company_name}
            )
            if not created:
                provider_profile.company_name = company_name
                provider_profile.save()
        
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
        fields = '__all__'

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
    review_count = serializers.SerializerMethodField()
    image_url = serializers.SerializerMethodField()
    gallery_images = ServiceGalleryImageSerializer(many=True, read_only=True)
    options = ServiceOptionSerializer(many=True, read_only=True)
    is_available = serializers.BooleanField(default=True)

    class Meta:
        model = ProviderService
        fields = ('id', 'title', 'description', 'price', 'price_type', 'is_available',
                 'subcategory', 'subcategory_name', 'category_name', 'category_id',
                 'avg_rating', 'review_count' ,'image', 'image_url', 'provider_id','gallery_images', 'options')
        # read_only_fields = ('provider',)
    
    # def get_rating(self, obj):
    #     """Calculer la note moyenne de CE service spécifique"""
    #     avg_rating = obj.reviews.aggregate(
    #         avg_rating=Avg('overall_rating')
    #     )['avg_rating']
    #     return round(avg_rating, 1) if avg_rating else 0.0
    
    def get_review_count(self, obj):
        """Compter le nombre d'avis de CE service spécifique"""
        return obj.reviews.count()
    
    def get_avg_rating(self, obj):
        """Calculer la note moyenne de CE service spécifique"""
        from django.db.models import Avg
        avg_rating = obj.reviews.aggregate(avg=Avg('overall_rating'))['avg']
        result = round(avg_rating, 1) if avg_rating else 0.0
        print(f"🔍 Service {obj.id} - Note calculée: {result} (basée sur {obj.reviews.count()} avis)")
        return result

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
    client_company_name = serializers.SerializerMethodField()
    provider_name = serializers.CharField(source='provider.company_name', read_only=True)
    images = ReviewImageSerializer(many=True, read_only=True)
    uploaded_images = serializers.ListField(
        child=serializers.ImageField(max_length=1000000, allow_empty_file=False, use_url=False),
        write_only=True, required=False
    )
    
    class Meta:
        model = Review
        fields = ('id', 'client', 'client_name', 'client_picture', 'provider', 'service',
                 'quality_rating', 'punctuality_rating', 'value_rating', 'overall_rating',
                 'comment','review_title', 'is_verified', 'created_at', 'images', 'uploaded_images' , "client_company_name")
        read_only_fields = ('client', 'is_verified', 'overall_rating')
    
    def get_client_company_name(self, obj):
        """Récupérer le nom de l'entreprise du client"""
        client = obj.client
        
        # Si le client a un profil prestataire, prendre le nom de son entreprise
        if hasattr(client, 'provider_profile'):
            return client.provider_profile.company_name
        
        # Sinon, essayer de prendre depuis les informations utilisateur
        # (vous pouvez ajouter un champ company_name au modèle User si nécessaire)
        return getattr(client, 'company_name', None)
    
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
        read_only_fields = ('client','provider', 'status')   

        
class DisputeEvidenceSerializer(serializers.ModelSerializer):
    user_name = serializers.StringRelatedField(source='user.username', read_only=True)
    # ✅ NOUVEAU CHAMP : URL du fichier avec gestion du cas null
    file_url = serializers.SerializerMethodField()
    # ✅ NOUVEAU CHAMP : Indicateur de présence de fichier
    has_file = serializers.SerializerMethodField()
    
    class Meta:
        model = DisputeEvidence
        fields = (
            'id', 'user', 'user_name', 'description', 'file', 'file_url', 
            'has_file', 'evidence_type', 'created_at'
        )
        read_only_fields = ('user', 'evidence_type')
    
    def get_file_url(self, obj):
        """
        ✅ MODIFICATION : Retourner l'URL du fichier ou une chaîne vide
        """
        if obj.file and hasattr(obj.file, 'url'):
            # Construire l'URL complète si elle est relative
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.file.url)
            return obj.file.url
        return ""  # Chaîne vide pour les commentaires sans fichier
    
    def get_has_file(self, obj):
        """
        ✅ NOUVEAU : Indicateur boolean pour savoir s'il y a un fichier
        """
        return bool(obj.file)
    
    def validate(self, data):
        """
        ✅ VALIDATION : Au moins description requise, fichier optionnel
        """
        if not data.get('description', '').strip():
            raise serializers.ValidationError({
                'description': 'La description est obligatoire'
            })
        
        return data

class DisputeSerializer(serializers.ModelSerializer):
    client_name = serializers.StringRelatedField(source='client.username', read_only=True)
    provider_name = serializers.StringRelatedField(source='provider.user.username', read_only=True)
    service_title = serializers.StringRelatedField(source='service.title', read_only=True)
    evidence = DisputeEvidenceSerializer(many=True, read_only=True)
    
    days_since_created = serializers.SerializerMethodField()
    is_urgent = serializers.SerializerMethodField()

    class Meta:
        model = Dispute
        fields = ('id', 'client', 'client_name', 'provider', 'provider_name', 
                 'service', 'service_title', 'title', 'description', 'status',
                 'resolution_note', 'created_at', 'evidence' , 'days_since_created', 'is_urgent')
        read_only_fields = ('client', 'status', 'resolution_note' , 'provider')

    def get_days_since_created(self, obj):
        delta = timezone.now() - obj.created_at
        return delta.days
    
    def get_is_urgent(self, obj):
        days_since = self.get_days_since_created(obj)
        return (obj.priority in ['high', 'urgent'] or 
                (obj.status == 'open' and days_since > 7))

class NotificationSerializer(serializers.ModelSerializer):
    """Serializer pour les notifications"""
    
    class Meta:
        model = Notification
        fields = [
            'id', 
            'title', 
            'message', 
            'notification_type', 
            'related_object_id', 
            'is_read', 
            'extra_data', 
            'created_at'
        ]
        read_only_fields = ['id', 'created_at']

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
        fields = ('username', 'password', 'email', 'first_name', 'last_name', 
                 'phone_number', 'role', 'location', 'categories', 'access', 'refresh', 'user')
        extra_kwargs = {
            'first_name': {'required': True},
            'last_name': {'required': True},
            'email': {'required': True}
        }

    def validate_email(self, value):
        """
        Validation personnalisée pour l'email
        """
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError(
                "Un compte avec cette adresse email existe déjà."
            )
        return value
    def validate_username(self, value):
        """
        Validation personnalisée pour le username
        """
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError(
                "Ce nom d'utilisateur est déjà pris."
            )
        return value
    def create(self, validated_data):
        # Extraire les catégories (si présentes)
        categories = validated_data.pop('categories', [])
        
        try:
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
            
        except Exception as e:
            # Gérer les erreurs de base de données
            if 'email' in str(e).lower():
                raise serializers.ValidationError({
                    'email': 'Cette adresse email est déjà utilisée.'
                })
            elif 'username' in str(e).lower():
                raise serializers.ValidationError({
                    'username': 'Ce nom d\'utilisateur est déjà pris.'
                })
            else:
                raise serializers.ValidationError({
                    'non_field_errors': 'Erreur lors de la création du compte.'
                })
    
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
    client_picture = serializers.SerializerMethodField() 
    category_name = serializers.CharField(source='category.name', read_only=True)
    subcategory_name = serializers.CharField(source='subcategory.name', read_only=True)
    offers_count = serializers.IntegerField(read_only=True)
    time_since_posted = serializers.SerializerMethodField()
    is_favorited = serializers.SerializerMethodField()
    has_user_offered = serializers.SerializerMethodField()
    budget_display = serializers.SerializerMethodField()

    offers_count = serializers.IntegerField(read_only=True)
    favorites_count = serializers.IntegerField(read_only=True)
    views_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = ClientProject
        fields = [
            'id', 'title', 'description', 'client_name', 'category_name', 
            'subcategory_name', 'budget_range', 'budget_display', 'location',
            'urgency', 'status', 'offers_count', 'views_count', 'created_at',
            'time_since_posted', 'deadline', 'remote_possible', 'is_favorited',
            'has_user_offered','min_budget', 'max_budget','offers_count', 'favorites_count', 'views_count',
            'admin_notes', 'client_picture'
        ]
    
    def get_client_name(self, obj):
        """Masquer le nom du client pour les utilisateurs non authentifiés"""
        # request = self.context.get('request')
        # if request and request.user.is_authenticated:
        return obj.client.first_name or obj.client.username
        # return "Client anonyme"
    
    def get_client_picture(self, obj):  # NOUVELLE MÉTHODE
        """Retourner la photo du client ou None"""
        request = self.context.get('request')
        if request and request.user.is_authenticated and obj.client.profile_picture:
            return request.build_absolute_uri(obj.client.profile_picture.url)
        return None
    
    def get_budget_display(self, obj):
        """Génère l'affichage formaté du budget"""
        budget_ranges = {
            'moins_500': 'Moins de 500 AOA',
            '500_1000': '500 à 1 000 AOA',
            '1000_10000': '1 000 à 10 000 AOA',
            '10000_plus': '10 000 AOA et plus',
            'sur_devis': 'Sur devis'
        }
        
        # Si on a des valeurs min/max budget définies
        if obj.min_budget is not None and obj.max_budget is not None:
            if obj.min_budget == obj.max_budget:
                return f"{int(obj.min_budget)} AOA"
            else:
                return f"{int(obj.min_budget)} AOA - {int(obj.max_budget)} AOA"
        
        # Si on a seulement un budget minimum
        elif obj.min_budget is not None:
            return f"À partir de {int(obj.min_budget)} AOA"
        
        # Si on a seulement un budget maximum
        elif obj.max_budget is not None:
            return f"Jusqu'à {int(obj.max_budget)} AOA"
        
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
    

# ================================================================
# 1. SERIALIZERS POUR VÉRIFICATION DES PRESTATAIRES
# ================================================================c
class ProviderVerificationSerializer(serializers.ModelSerializer):
    """
    Serializer principal pour la vérification des prestataires
    Utilisé pour la création et la mise à jour des demandes de vérification
    """
    
    # Champs calculés en lecture seule
    provider_name = serializers.CharField(source='provider.user.username', read_only=True)
    provider_email = serializers.CharField(source='provider.user.email', read_only=True)
    company_name = serializers.CharField(source='provider.company_name', read_only=True)
    days_since_submission = serializers.SerializerMethodField()
    can_be_modified = serializers.SerializerMethodField()
    documents_provided = serializers.SerializerMethodField()
    verification_progress = serializers.SerializerMethodField()
    
    class Meta:
        model = ProviderVerification
        fields = [
            # Champs de base
            'id', 'provider', 'provider_name', 'provider_email', 'company_name',
            
            # Configuration de la vérification
            'is_business', 'document_type',
            
            # Informations d'entreprise
            'business_name', 'business_nif', 'business_registration_number',
            
            # Documents
            'id_card_front', 'id_card_back', 'passport_image', 'business_registration_doc',
            
            # Statut et dates
            'verification_status', 'submitted_at', 'verified_at', 'verified_by',
            'rejection_reason', 'admin_notes',
            
            # Champs calculés
            'days_since_submission', 'can_be_modified', 'documents_provided',
            'verification_progress', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'verification_status', 'submitted_at', 'verified_at', 'verified_by',
            'rejection_reason', 'admin_notes', 'created_at', 'updated_at'
        ]
    
    def get_days_since_submission(self, obj):
        """Calcule le nombre de jours depuis la soumission"""
        if obj.submitted_at:
            return (timezone.now() - obj.submitted_at).days
        return None
    
    def get_can_be_modified(self, obj):
        """Vérifie si la vérification peut être modifiée"""
        return obj.can_be_modified()
    
    def get_documents_provided(self, obj):
        """Liste des documents fournis"""
        return obj.get_documents_list()
    
    def get_verification_progress(self, obj):
        """Pourcentage de progression de la vérification"""
        required_fields = []
        provided_fields = []
        
        # Documents d'identité obligatoires
        if obj.document_type == 'id_card':
            required_fields.extend(['id_card_front', 'id_card_back'])
            if obj.id_card_front:
                provided_fields.append('id_card_front')
            if obj.id_card_back:
                provided_fields.append('id_card_back')
        else:  # passport
            required_fields.append('passport_image')
            if obj.passport_image:
                provided_fields.append('passport_image')
        
        # Informations d'entreprise si applicable
        if obj.is_business:
            required_fields.append('business_name')
            if obj.business_name:
                provided_fields.append('business_name')
        
        if not required_fields:
            return 0
        
        return int((len(provided_fields) / len(required_fields)) * 100)
    
    def validate(self, attrs):
        """Validation globale des données"""
        document_type = attrs.get('document_type', self.instance.document_type if self.instance else 'id_card')
        is_business = attrs.get('is_business', self.instance.is_business if self.instance else False)
        
        # Validation des documents selon le type
        if document_type == 'id_card':
            if not (attrs.get('id_card_front') or (self.instance and self.instance.id_card_front)):
                raise serializers.ValidationError({
                    'id_card_front': 'La face avant de la carte d\'identité est requise'
                })
            if not (attrs.get('id_card_back') or (self.instance and self.instance.id_card_back)):
                raise serializers.ValidationError({
                    'id_card_back': 'La face arrière de la carte d\'identité est requise'
                })
        elif document_type == 'passport':
            if not (attrs.get('passport_image') or (self.instance and self.instance.passport_image)):
                raise serializers.ValidationError({
                    'passport_image': 'L\'image du passeport est requise'
                })
        
        # Validation des informations d'entreprise
        if is_business:
            if not attrs.get('business_name') and not (self.instance and self.instance.business_name):
                raise serializers.ValidationError({
                    'business_name': 'Le nom de l\'entreprise est requis pour les entreprises'
                })
        
        return attrs
    
    def create(self, validated_data):
        """Création d'une nouvelle demande de vérification"""
        request = self.context.get('request')
        if not request or not hasattr(request.user, 'provider_profile'):
            raise serializers.ValidationError("Profil prestataire requis")
        
        # Associer automatiquement au prestataire connecté
        validated_data['provider'] = request.user.provider_profile
        
        return super().create(validated_data)
    
    def update(self, instance, validated_data):
        """Mise à jour d'une demande de vérification"""
        
        # Vérifier si la modification est autorisée
        if not instance.can_be_modified():
            raise serializers.ValidationError(
                "Cette vérification ne peut plus être modifiée car elle est déjà en cours de traitement ou approuvée"
            )
        
        # Si on modifie des documents, remettre le statut à pending
        document_fields = ['id_card_front', 'id_card_back', 'passport_image', 'business_registration_doc']
        if any(field in validated_data for field in document_fields):
            validated_data['verification_status'] = 'pending'
            validated_data['submitted_at'] = timezone.now()
            # Effacer les données de rejet précédentes
            validated_data['rejection_reason'] = ''
            validated_data['verified_by'] = None
            validated_data['verified_at'] = None
        
        return super().update(instance, validated_data)


class ProviderVerificationListSerializer(serializers.ModelSerializer):
    """
    Serializer allégé pour les listes de vérifications (admin)
    """
    provider_name = serializers.CharField(source='provider.user.username', read_only=True)
    provider_email = serializers.CharField(source='provider.user.email', read_only=True)
    company_name = serializers.CharField(source='provider.company_name', read_only=True)
    days_pending = serializers.SerializerMethodField()
    status_badge = serializers.SerializerMethodField()
    
    class Meta:
        model = ProviderVerification
        fields = [
            'id', 'provider_name', 'provider_email', 'company_name',
            'verification_status', 'is_business', 'submitted_at',
            'days_pending', 'status_badge'
        ]
    
    def get_days_pending(self, obj):
        """Nombre de jours en attente"""
        if obj.submitted_at and obj.verification_status == 'pending':
            return (timezone.now() - obj.submitted_at).days
        return None
    
    def get_status_badge(self, obj):
        """Informations pour l'affichage du badge de statut"""
        status_info = {
            'not_started': {'color': 'grey', 'text': 'Non commencé'},
            'pending': {'color': 'orange', 'text': 'En attente'},
            'verified': {'color': 'green', 'text': 'Vérifié'},
            'rejected': {'color': 'red', 'text': 'Rejeté'},
        }
        return status_info.get(obj.verification_status, {'color': 'grey', 'text': 'Inconnu'})


class ProviderVerificationAdminSerializer(serializers.ModelSerializer):
    """
    Serializer pour les actions admin (approbation/rejet)
    """
    provider_info = serializers.SerializerMethodField()
    
    class Meta:
        model = ProviderVerification
        fields = [
            'id', 'provider_info', 'verification_status', 'verified_by',
            'verified_at', 'rejection_reason', 'admin_notes'
        ]
    
    def get_provider_info(self, obj):
        """Informations du prestataire pour l'admin"""
        return {
            'id': obj.provider.id,
            'username': obj.provider.user.username,
            'email': obj.provider.user.email,
            'company_name': obj.provider.company_name,
            'phone_number': obj.provider.user.phone_number,
        }
    
    def update(self, instance, validated_data):
        """Mise à jour avec logique admin"""
        request = self.context.get('request')
        
        # Si changement de statut vers verified ou rejected
        if 'verification_status' in validated_data:
            new_status = validated_data['verification_status']
            
            if new_status == 'verified':
                validated_data['verified_by'] = request.user if request else None
                validated_data['verified_at'] = timezone.now()
                validated_data['rejection_reason'] = ''  # Effacer raison rejet précédente
            
            elif new_status == 'rejected':
                validated_data['verified_by'] = request.user if request else None
                validated_data['verified_at'] = None
                # La rejection_reason doit être fournie dans les données
        
        return super().update(instance, validated_data)
    


# ================================================================
# 2. SERIALIZERS POUR VÉRIFICATION PAR TÉLÉPHONE
# ================================================================

class PhoneVerificationSerializer(serializers.ModelSerializer):
    """
    Serializer principal pour la vérification par téléphone
    """
    
    # Champs calculés
    time_remaining = serializers.SerializerMethodField()
    can_resend = serializers.SerializerMethodField()
    attempts_remaining = serializers.SerializerMethodField()
    
    class Meta:
        model = PhoneVerification
        fields = [
            'id', 'user', 'phone_number', 'status', 'attempts',
            'max_attempts', 'expires_at', 'verified_at', 'last_code_sent_at',
            'time_remaining', 'can_resend', 'attempts_remaining',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'user', 'status', 'attempts', 'verified_at', 'last_code_sent_at',
            'created_at', 'updated_at', 'expires_at'
        ]
        extra_kwargs = {
            'phone_number': {'write_only': False, 'required': True}
        }
    
    def get_time_remaining(self, obj):
        """Temps restant avant expiration en secondes"""
        if obj.expires_at and not obj.is_expired():
            remaining = obj.expires_at - timezone.now()
            return max(0, int(remaining.total_seconds()))
        return 0
    
    def get_can_resend(self, obj):
        """Vérifie si un nouveau code peut être envoyé"""
        return obj.can_resend_code()
    
    def get_attempts_remaining(self, obj):
        """Tentatives restantes"""
        return max(0, obj.max_attempts - obj.attempts)
    
    def validate_phone_number(self, value):
        """Validation du numéro de téléphone"""
        # Validation basique du format
        if not value or len(value) < 8:
            raise serializers.ValidationError(
                "Le numéro de téléphone doit contenir au moins 8 caractères"
            )
        
        # Supprimer les espaces et caractères spéciaux
        cleaned_number = ''.join(filter(str.isdigit, value))
        if len(cleaned_number) < 8:
            raise serializers.ValidationError(
                "Format de numéro de téléphone invalide"
            )
        
        return value
    
    def create(self, validated_data):
        """Création d'une nouvelle vérification téléphone"""
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            raise serializers.ValidationError("Utilisateur non authentifié")
        
        # Associer à l'utilisateur connecté
        validated_data['user'] = request.user
        
        # Générer le code et définir l'expiration
        validated_data['verification_code'] = PhoneVerification.generate_code()
        validated_data['expires_at'] = timezone.now() + timedelta(minutes=10)
        
        return super().create(validated_data)


class PhoneVerificationCodeSerializer(serializers.Serializer):
    """
    Serializer pour la vérification du code SMS
    """
    code = serializers.CharField(
        max_length=6, 
        min_length=6,
        help_text="Code de vérification à 6 chiffres"
    )
    
    def validate_code(self, value):
        """Validation du code"""
        if not value.isdigit():
            raise serializers.ValidationError("Le code doit contenir uniquement des chiffres")
        return value


class PhoneVerificationSendCodeSerializer(serializers.Serializer):
    """
    Serializer pour l'envoi d'un nouveau code
    """
    phone_number = serializers.CharField(
        max_length=20,
        help_text="Numéro de téléphone pour recevoir le code"
    )
    
    def validate_phone_number(self, value):
        """Validation du numéro de téléphone"""
        if not value or len(value) < 8:
            raise serializers.ValidationError(
                "Le numéro de téléphone doit contenir au moins 8 caractères"
            )
        return value
    




class FCMTokenSerializer(serializers.ModelSerializer):
    """
    Serializer pour les tokens FCM
    """
    user_email = serializers.CharField(source='user.email', read_only=True)
    
    class Meta:
        model = FCMToken
        fields = [
            'id',
            'user_email',
            'device_type',
            'app_version',
            'is_active',
            'created_at',
            'updated_at',
            'last_used'
        ]
        read_only_fields = ['id', 'user_email', 'created_at', 'updated_at', 'last_used']

class FCMTokenCreateSerializer(serializers.Serializer):
    """
    Serializer pour créer/enregistrer un token FCM
    """
    fcm_token = serializers.CharField(max_length=500, required=True)
    device_type = serializers.ChoiceField(
        choices=[('android', 'Android'), ('ios', 'iOS'), ('web', 'Web')],
        default='android'
    )
    app_version = serializers.CharField(max_length=20, default='1.0.0')
    
    def validate_fcm_token(self, value):
        """
        Valider le format du token FCM
        """
        if len(value) < 10:
            raise serializers.ValidationError("Token FCM invalide")
        return value

class NotificationPreferenceSerializer(serializers.ModelSerializer):
    """
    Serializer pour les préférences de notification
    """
    user_email = serializers.CharField(source='user.email', read_only=True)
    
    class Meta:
        model = NotificationPreference
        fields = [
            'id',
            'user_email',
            'messages_enabled',
            'offers_enabled',
            'projects_enabled',
            'reviews_enabled',
            'system_enabled',
            'push_notifications',
            'email_notifications',
            'sms_notifications',
            'quiet_hours_start',
            'quiet_hours_end',
            'created_at',
            'updated_at'
        ]
        read_only_fields = ['id', 'user_email', 'created_at', 'updated_at']

class NotificationPreferenceUpdateSerializer(serializers.Serializer):
    """
    Serializer pour mettre à jour les préférences
    """
    preferences = serializers.DictField(
        child=serializers.BooleanField(),
        required=True,
        help_text="Dictionnaire des préférences à mettre à jour"
    )
    
    def validate_preferences(self, value):
        """
        Valider les clés des préférences
        """
        valid_keys = {
            'messages_enabled',
            'offers_enabled', 
            'projects_enabled',
            'reviews_enabled',
            'system_enabled',
            'push_notifications',
            'email_notifications',
            'sms_notifications'
        }
        
        invalid_keys = set(value.keys()) - valid_keys
        if invalid_keys:
            raise serializers.ValidationError(
                f"Clés invalides: {', '.join(invalid_keys)}"
            )
        
        return value

class NotificationHistorySerializer(serializers.ModelSerializer):
    """
    Serializer pour l'historique des notifications
    """
    user_email = serializers.CharField(source='user.email', read_only=True)
    
    class Meta:
        model = NotificationHistory
        fields = [
            'id',
            'user_email',
            'title',
            'body',
            'notification_type',
            'data',
            'status',
            'firebase_message_id',
            'error_message',
            'created_at',
            'sent_at',
            'delivered_at',
            'clicked_at'
        ]
        read_only_fields = '__all__'

class TestNotificationSerializer(serializers.Serializer):
    """
    Serializer pour envoyer une notification de test
    """
    title = serializers.CharField(max_length=255, default="🧪 Test Notification")
    body = serializers.CharField(max_length=500, default="Ceci est une notification de test")
    notification_type = serializers.CharField(max_length=50, default="test")
    
class BulkNotificationSerializer(serializers.Serializer):
    """
    Serializer pour envoyer des notifications en masse
    """
    user_ids = serializers.ListField(
        child=serializers.IntegerField(),
        required=False,
        help_text="Liste des IDs utilisateurs (optionnel si topic fourni)"
    )
    topic = serializers.CharField(
        max_length=100,
        required=False,
        help_text="Topic Firebase (optionnel si user_ids fourni)"
    )
    title = serializers.CharField(max_length=255, required=True)
    body = serializers.CharField(max_length=500, required=True)
    notification_type = serializers.CharField(max_length=50, default="general")
    data = serializers.DictField(
        child=serializers.CharField(),
        required=False,
        help_text="Données additionnelles (optionnel)"
    )
    
    def validate(self, data):
        """
        Valider qu'au moins user_ids ou topic est fourni
        """
        if not data.get('user_ids') and not data.get('topic'):
            raise serializers.ValidationError(
                "Vous devez fournir soit 'user_ids' soit 'topic'"
            )
        return data

class NotificationStatsSerializer(serializers.Serializer):
    """
    Serializer pour les statistiques de notifications
    """
    total_notifications = serializers.IntegerField(read_only=True)
    sent = serializers.IntegerField(read_only=True)
    delivered = serializers.IntegerField(read_only=True)
    failed = serializers.IntegerField(read_only=True)
    clicked = serializers.IntegerField(read_only=True)
    success_rate = serializers.SerializerMethodField()
    click_rate = serializers.SerializerMethodField()
    
    def get_success_rate(self, obj):
        """
        Calculer le taux de succès
        """
        total = obj.get('total_notifications', 0)
        sent = obj.get('sent', 0)
        return round((sent / total * 100), 2) if total > 0 else 0
    
    def get_click_rate(self, obj):
        """
        Calculer le taux de clic
        """
        sent = obj.get('sent', 0)
        clicked = obj.get('clicked', 0)
        return round((clicked / sent * 100), 2) if sent > 0 else 0
    

class AdminNotificationSerializer(serializers.ModelSerializer):
    """Serializer pour les notifications admin"""
    type_display = serializers.CharField(source='get_type_display', read_only=True)
    priority_display = serializers.CharField(source='get_priority_display', read_only=True)
    time_since_created = serializers.SerializerMethodField()
    related_user_name = serializers.SerializerMethodField()
    
    class Meta:
        model = AdminNotification
        fields = [
            'id', 'type', 'type_display', 'title', 'message', 
            'priority', 'priority_display', 'related_object_id',
            'related_object_type', 'is_read', 'read_at', 
            'created_at', 'time_since_created', 'related_user_name',
            'extra_data'
        ]
        read_only_fields = ['created_at', 'read_at']
    
    def get_time_since_created(self, obj):
        """Temps écoulé depuis la création"""
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
    
    def get_related_user_name(self, obj):
        """Nom de l'utilisateur concerné"""
        if obj.related_user:
            return f"{obj.related_user.first_name} {obj.related_user.last_name}".strip() or obj.related_user.email
        return None
