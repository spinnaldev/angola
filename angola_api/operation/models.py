from django.db import models

# Create your models here.
from django.db import models
from django.contrib.auth.models import AbstractUser
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils.translation import gettext_lazy as _
import uuid
from datetime import datetime

class TimeStampMixin(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True

class User(AbstractUser, TimeStampMixin):
    ROLE_CHOICES = (
        ('client', 'Client'),
        ('provider', 'Prestataire'),
        ('admin', 'Administrateur'),
    )
    
    phone_number = models.CharField(max_length=20, blank=True)
    bio = models.TextField(blank=True)
    profile_picture = models.ImageField(upload_to='profile_pictures/', blank=True, null=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='client')
    is_verified = models.BooleanField(default=False)
    location = models.CharField(max_length=255, blank=True)
    
    def __str__(self):
        return self.username

class ResetPasswordCode(models.Model):
    """
    Modèle pour stocker les codes de réinitialisation de mot de passe
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reset_codes')
    code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    
    def __str__(self):
        return f"Code de réinitialisation pour {self.user.email}"
    
class Category(TimeStampMixin):
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    icon = models.CharField(max_length=50, blank=True)  # Font Awesome icon class or similar
    image_url = models.URLField(blank=True, help_text="URL de l'image de catégorie")
    class Meta:
        verbose_name_plural = "Categories"
    
    def __str__(self):
        return self.name

class SubCategory(TimeStampMixin):
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='subcategories')
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    icon = models.CharField(max_length=50, blank=True)
    
    class Meta:
        verbose_name_plural = "Sub Categories"
    
    def __str__(self):
        return f"{self.name} ({self.category.name})"

class Provider(TimeStampMixin):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='provider_profile')
    company_name = models.CharField(max_length=100, blank=True)
    services = models.ManyToManyField(SubCategory, through='ProviderService')
    is_verified = models.BooleanField(default=False)
    is_featured = models.BooleanField(default=False)
    avg_rating = models.DecimalField(max_digits=3, decimal_places=2, default=0.0)
    expertise_categories = models.ManyToManyField(Category, related_name='providers_with_expertise')
    trust_score = models.DecimalField(max_digits=3, decimal_places=2, default=0.0)
    verification_documents = models.FileField(upload_to='verification_docs/', blank=True, null=True)
    address = models.CharField(max_length=255, blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)

    def __str__(self):
        return self.company_name or self.user.username

class ProviderService(TimeStampMixin):
    provider = models.ForeignKey(Provider, on_delete=models.CASCADE, related_name='provider_services')
    subcategory = models.ForeignKey(SubCategory, on_delete=models.CASCADE)
    title = models.CharField(max_length=100)
    description = models.TextField()
    price = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    price_type = models.CharField(max_length=50, choices=[
        ('fixed', 'Prix fixe'),
        ('hourly', 'Prix horaire'),
        ('daily', 'Prix journalier'),
        ('negotiable', 'Prix négociable'),
        ('quote', 'Sur devis')
    ], default='quote')
    is_available = models.BooleanField(default=True)
    
    # Ajout du champ pour stocker l'image principale du service
    image = models.ImageField(upload_to='service_images/', blank=True, null=True)

    def __str__(self):
        return f"{self.title} - {self.provider.user.username}"
    

class ServiceGalleryImage(models.Model):
    service = models.ForeignKey(ProviderService, related_name='gallery_images', on_delete=models.CASCADE)
    image = models.ImageField(upload_to='services/gallery/')
    caption = models.CharField(max_length=255, blank=True)
    order = models.PositiveIntegerField(default=0)
    
    class Meta:
        ordering = ['order']

class ServiceOption(models.Model):
    service = models.ForeignKey(ProviderService, related_name='options', on_delete=models.CASCADE)
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    is_included = models.BooleanField(default=True)
    
    class Meta:
        ordering = ['id']
        
class Portfolio(TimeStampMixin):
    provider = models.ForeignKey(Provider, on_delete=models.CASCADE, related_name='portfolio')
    title = models.CharField(max_length=100)
    description = models.TextField()
    image = models.ImageField(upload_to='portfolio/', blank=True, null=True)
    
    def __str__(self):
        return f"{self.title} - {self.provider.user.username}"

class QuoteRequest(TimeStampMixin):
    STATUS_CHOICES = (
        ('pending', 'En attente'),
        ('accepted', 'Accepté'),
        ('rejected', 'Rejeté'),
        ('completed', 'Complété'),
    )
    
    client = models.ForeignKey(User, on_delete=models.CASCADE, related_name='quote_requests')
    provider = models.ForeignKey(Provider, on_delete=models.CASCADE, related_name='quote_requests')
    service = models.ForeignKey(ProviderService, on_delete=models.CASCADE, related_name='quote_requests', null=True, blank=True)
    subject = models.CharField(max_length=200)
    budget = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    description = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    def __str__(self):
        return f"Demande de devis {self.id}: {self.subject} - {self.client.username} à {self.provider.user.username}"
    
class Certificate(TimeStampMixin):
    provider = models.ForeignKey(Provider, on_delete=models.CASCADE, related_name='certificates')
    title = models.CharField(max_length=100)
    issuing_organization = models.CharField(max_length=100)
    issue_date = models.DateField()
    expiry_date = models.DateField(null=True, blank=True)
    file = models.FileField(upload_to='certificates/')
    is_verified = models.BooleanField(default=False)
    
    def __str__(self):
        return f"{self.title} - {self.provider.user.username}"

class Review(TimeStampMixin):
    client = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reviews_given')
    provider = models.ForeignKey(Provider, on_delete=models.CASCADE, related_name='reviews_received')
    service = models.ForeignKey(ProviderService, on_delete=models.CASCADE, related_name='reviews', null=True, blank=True)
    quality_rating = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    punctuality_rating = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    value_rating = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    overall_rating = models.DecimalField(max_digits=3, decimal_places=2)
    comment = models.TextField()
    is_verified = models.BooleanField(default=False)
    
    def save(self, *args, **kwargs):
        # Calculate overall rating
        self.overall_rating = (self.quality_rating + self.punctuality_rating + self.value_rating) / 3.0
        super().save(*args, **kwargs)
        
        # Update provider's average rating
        provider = self.provider
        avg = Review.objects.filter(provider=provider).aggregate(models.Avg('overall_rating'))['overall_rating__avg']
        provider.avg_rating = avg or 0.0
        provider.save()
    
    def __str__(self):
        return f"Review by {self.client.username} for {self.provider.user.username}"

class ReviewImage(TimeStampMixin):
    review = models.ForeignKey(Review, on_delete=models.CASCADE, related_name='images')
    image = models.ImageField(upload_to='review_images/')
    
    def __str__(self):
        return f"Image for review {self.review.id}"

class Favorite(TimeStampMixin):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='favorites')
    provider = models.ForeignKey(Provider, on_delete=models.CASCADE, related_name='favorited_by')
    
    class Meta:
        unique_together = ('user', 'provider')
    
    def __str__(self):
        return f"{self.user.username} favorited {self.provider.user.username}"

class Conversation(TimeStampMixin):
    client = models.ForeignKey(User, on_delete=models.CASCADE, related_name='client_conversations')
    provider = models.ForeignKey(Provider, on_delete=models.CASCADE, related_name='provider_conversations')
    updated_at = models.DateTimeField(auto_now=True)  # Pour trier par date du dernier message
    
    class Meta:
        ordering = ['-updated_at']
    
    def __str__(self):
        return f"Conversation entre {self.client.username} et {self.provider.user.username}"
    
    def unread_count_for_user(self, user):
        """Retourne le nombre de messages non lus pour un utilisateur donné"""
        if hasattr(user, 'provider_profile') and self.provider.id == user.provider_profile.id:
            # L'utilisateur est le prestataire
            return self.messages.filter(sender=self.client, is_read=False).count()
        else:
            # L'utilisateur est le client
            return self.messages.filter(sender=self.provider.user, is_read=False).count()

class Message(TimeStampMixin):
    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name='messages')
    sender = models.ForeignKey(User, on_delete=models.CASCADE, related_name='messages_sent')
    content = models.TextField()
    is_read = models.BooleanField(default=False)
    
    class Meta:
        ordering = ['created_at']
    
    def __str__(self):
        return f"Message de {self.sender.username} dans conversation {self.conversation.id}"
    
    def save(self, *args, **kwargs):
        # Mettre à jour la date de la conversation
        self.conversation.save()
        super().save(*args, **kwargs)

class Attachment(TimeStampMixin):
    message = models.ForeignKey(Message, on_delete=models.CASCADE, related_name='attachments')
    file = models.FileField(upload_to='message_attachments/')
    file_name = models.CharField(max_length=100)
    
    def __str__(self):
        return self.file_name

class Dispute(TimeStampMixin):
    STATUS_CHOICES = (
        ('open', 'Ouvert'),
        ('under_review', 'En cours d\'examen'),
        ('resolved', 'Résolu'),
        ('closed', 'Fermé'),
    )
    
    client = models.ForeignKey(User, on_delete=models.CASCADE, related_name='disputes_opened')
    provider = models.ForeignKey(Provider, on_delete=models.CASCADE, related_name='disputes_received')
    service = models.ForeignKey(ProviderService, on_delete=models.CASCADE, related_name='disputes', null=True, blank=True)
    title = models.CharField(max_length=100)
    description = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')
    resolution_note = models.TextField(blank=True)
    
    def __str__(self):
        return f"Dispute #{self.id}: {self.title}"

class DisputeEvidence(TimeStampMixin):
    dispute = models.ForeignKey(Dispute, on_delete=models.CASCADE, related_name='evidence')
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    description = models.TextField()
    file = models.FileField(upload_to='dispute_evidence/')
    
    def __str__(self):
        return f"Evidence for dispute #{self.dispute.id} by {self.user.username}"

class Notification(TimeStampMixin):
    TYPE_CHOICES = (
        ('message', 'Nouveau message'),
        ('review', 'Nouvel avis'),
        ('favorite', 'Nouveau favoris'),
        ('dispute', 'Litige'),
        ('system', 'Notification système'),
    )
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=100)
    content = models.TextField()
    type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    related_object_id = models.IntegerField(null=True, blank=True)
    is_read = models.BooleanField(default=False)
    
    def __str__(self):
        return f"{self.title} - {self.user.username}"

class Report(TimeStampMixin):
    STATUS_CHOICES = (
        ('pending', 'En attente'),
        ('under_review', 'En cours d\'examen'),
        ('resolved', 'Résolu'),
        ('dismissed', 'Rejeté'),
    )
    
    TYPE_CHOICES = (
        ('provider', 'Prestataire'),
        ('review', 'Avis'),
        ('user', 'Utilisateur'),
    )
    
    reporter = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reports_made')
    reported_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reports_received', null=True, blank=True)
    reported_provider = models.ForeignKey(Provider, on_delete=models.CASCADE, related_name='reports', null=True, blank=True)
    reported_review = models.ForeignKey(Review, on_delete=models.CASCADE, related_name='reports', null=True, blank=True)
    reason = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    admin_notes = models.TextField(blank=True)
    
    def __str__(self):
        return f"Report #{self.id} - {self.type}"