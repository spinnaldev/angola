import random
import string
from django.db import models
from django.utils import timezone
# Create your models here.
from django.db import models
from django.contrib.auth.models import AbstractUser
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils.translation import gettext_lazy as _
import uuid
from datetime import datetime, timedelta

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
    
    email = models.EmailField(unique=True, blank=False, null=False)
    phone_number = models.CharField(max_length=20, blank=True)
    bio = models.TextField(blank=True)
    profile_picture = models.ImageField(upload_to='profile_pictures/', blank=True, null=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='client')
    is_verified = models.BooleanField(default=False)
    location = models.CharField(max_length=255, blank=True)
    company_name = models.CharField(max_length=100, blank=True, null=True)
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    def __str__(self):
        return self.email

    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"
    
    def get_active_fcm_tokens(self):
        """Obtenir tous les tokens FCM actifs de l'utilisateur"""
        return self.fcm_tokens.filter(is_active=True)

    def has_fcm_tokens(self):
        """Vérifier si l'utilisateur a des tokens FCM actifs"""
        return self.fcm_tokens.filter(is_active=True).exists()

    def get_notification_preferences(self):
        """Obtenir les préférences de notification de l'utilisateur"""
        return NotificationPreference.get_or_create_for_user(self)

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
    
class Category(models.Model):
    name = models.CharField(max_length=100)
    name_en = models.CharField(max_length=100, blank=True, null=True)
    name_fr = models.CharField(max_length=100, blank=True, null=True)
    description = models.TextField(blank=True)
    description_en = models.TextField(blank=True, null=True)
    description_fr = models.TextField(blank=True, null=True)
    icon = models.CharField(max_length=50, blank=True)
    image_url = models.URLField(blank=True, help_text="URL de l'image de catégorie")
    
    class Meta:
        verbose_name_plural = "Categories"
    
    def __str__(self):
        return self.name

class SubCategory(TimeStampMixin):
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='subcategories')
    name = models.CharField(max_length=100)
    name_en = models.CharField(max_length=100, blank=True, null=True)
    name_fr = models.CharField(max_length=100, blank=True, null=True)
    description = models.TextField(blank=True)
    description_en = models.TextField(blank=True, null=True)
    description_fr = models.TextField(blank=True, null=True)
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
    
    review_title = models.CharField(max_length=200, blank=True, null=True)
    
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
    
    # class Meta:
    #     unique_together = ('user', 'provider')
    
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
    priority = models.CharField(
        max_length=20,
        choices=(
            ('low', 'Faible'),
            ('medium', 'Moyenne'),
            ('high', 'Élevée'),
            ('urgent', 'Urgent'),
        ),
        default='medium',
        verbose_name="Priorité"
    )
    resolved_at = models.DateTimeField(
        null=True, 
        blank=True,
        verbose_name="Date de résolution"
    )
    def save(self, *args, **kwargs):
        # Marquer la date de résolution automatiquement
        if self.status == 'resolved' and not self.resolved_at:
            self.resolved_at = timezone.now()
        elif self.status != 'resolved':
            self.resolved_at = None
        super().save(*args, **kwargs)

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
        ('quote_request', 'Demande de devis'),
        ('quote_accepted', 'Devis accepté'),
        ('quote_rejected', 'Devis rejeté'),
        ('quote_completed', 'Devis terminé'),
        ('new_offer', 'Nouvelle offre'),
        ('offer_accepted', 'Offre acceptée'),
        ('offer_rejected', 'Offre rejetée'),
        ('profile_rejected', 'Vérification rejetée'),
        ('profile_verified', 'Profil vérifié'),
        ('phone_verified', 'Téléphone vérifié'),

        ('new_message', 'Nouveau message'),  # ✅ AJOUTÉ pour cohérence
        ('project_created', 'Projet créé'),  # ✅ AJOUTÉ
        ('project_completed', 'Projet terminé'),  # ✅ AJOUTÉ
        ('project_update', 'Mise à jour projet')
    )
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=100)
    message = models.TextField()  # Utiliser 'message' de manière cohérente
    notification_type = models.CharField(max_length=20, choices=TYPE_CHOICES , null= True) 
    related_object_id = models.IntegerField(null=True, blank=True)
    is_read = models.BooleanField(default=False)
    
    extra_data = models.JSONField(null=True, blank=True, help_text="Données supplémentaires pour navigation précise")
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.title} - {self.user.username}"

    def get_extra_data_dict(self):
        """Retourner extra_data sous forme de dictionnaire"""
        if self.extra_data:
            if isinstance(self.extra_data, str):
                import json
                try:
                    return json.loads(self.extra_data)
                except json.JSONDecodeError:
                    return {}
            return self.extra_data
        return {}
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
    


class ClientProject(TimeStampMixin):
    """Modèle pour les projets des clients - Version mise à jour"""
    BUDGET_CHOICES = (
        ('moins_500', 'Moins de 500 AOA'),
        ('500_1000', '500 à 1000 AOA'),
        ('1000_10000', '1000 à 10 000 AOA'),
        ('10000_plus', '10 000 AOA et plus'),
        ('sur_devis', 'Demande de devis'),
    )
    
    # STATUS_CHOICES = (
    #     ('open', 'Ouvert'),
    #     ('in_progress', 'En cours'),
    #     ('completed', 'Terminé'),
    #     ('cancelled', 'Annulé'),
    # )
    STATUS_CHOICES = (
        ('open', 'Ouvert'),
        ('in_progress', 'En cours'),
        ('completed', 'Terminé'),
        ('closed', 'Clôturé'),
        ('paused', 'En pause'),
        ('cancelled', 'Annulé'),
    )
    
    # BUDGET_CHOICES = (
    #     ('sur_devis', 'Sur devis'),
    #     ('0_500', 'Moins de 500AOA'),
    #     ('500_1000', '500AOA - 1000AOA'),
    #     ('1000_5000', '1000AOA - 5000AOA'),
    #     ('5000_15000', '5000AOA - 15000AOA'),
    #     ('15000_plus', 'Plus de 15000AOA'),
    # )
    
    URGENCY_CHOICES = (
        ('low', 'Pas urgent'),
        ('medium', 'Modérément urgent'),
        ('high', 'Urgent'),
        ('very_high', 'Très urgent'),
    )
    
    
    # Informations de base
    title = models.CharField(max_length=200, verbose_name="Titre du projet")
    description = models.TextField(verbose_name="Description détaillée")
    client = models.ForeignKey(User, on_delete=models.CASCADE, related_name='client_projects')
    
    # Catégorisation
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='client_projects')
    subcategory = models.ForeignKey(SubCategory, on_delete=models.SET_NULL, null=True, blank=True, related_name='client_projects')
    
    # Budget et délais
    budget_range = models.CharField(max_length=20, choices=BUDGET_CHOICES)
    min_budget = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    max_budget = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    
    # Localisation
    location = models.CharField(max_length=255, verbose_name="Lieu d'intervention")
    remote_possible = models.BooleanField(default=False, verbose_name="Télétravail possible")
    
    # Délais et urgence
    deadline = models.DateField(null=True, blank=True, verbose_name="Date limite souhaitée")
    urgency = models.CharField(max_length=20, choices=URGENCY_CHOICES, default='medium')
    
    # Statut et gestion
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')
    is_featured = models.BooleanField(default=False, verbose_name="Projet mis en avant")
    views_count = models.PositiveIntegerField(default=0, verbose_name="Nombre de vues")
    
    # NOUVEAUX CHAMPS pour le tracking des statuts
    started_at = models.DateTimeField(null=True, blank=True, verbose_name="Date de début")
    closed_at = models.DateTimeField(null=True, blank=True, verbose_name="Date de clôture")
    completed_at = models.DateTimeField(null=True, blank=True, verbose_name="Date de completion")
    
    # Préférences de contact
    contact_via_platform = models.BooleanField(default=True, verbose_name="Contact via la plateforme")
    show_email = models.BooleanField(default=False, verbose_name="Afficher l'email")
    show_phone = models.BooleanField(default=False, verbose_name="Afficher le téléphone")
    
    # Fichiers joints (optionnel)
    attachment1 = models.FileField(upload_to='project_attachments/', null=True, blank=True)
    attachment2 = models.FileField(upload_to='project_attachments/', null=True, blank=True)
    attachment3 = models.FileField(upload_to='project_attachments/', null=True, blank=True)
    admin_notes = models.TextField(
        blank=True, 
        verbose_name="Notes administratives",
        help_text="Notes internes pour l'administration"
    )
    class Meta:
        ordering = ['-created_at']
        verbose_name = "Projet Client"
        verbose_name_plural = "Projets Clients"
    
    def __str__(self):
        return f"{self.title} - {self.client.get_full_name()}"
    
    @property
    def offers_count(self):
        """Retourne le nombre d'offres reçues"""
        return self.project_offers.count()
    
    @property
    def time_since_posted(self):
        """Retourne le temps écoulé depuis la publication"""
        now = timezone.now()
        diff = now - self.created_at
        
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
    
    @property
    def is_active(self):
        """Indique si le projet accepte encore des offres"""
        return self.status == 'open'
    
    @property
    def can_be_closed(self):
        """Indique si le projet peut être clôturé"""
        return self.status in ['open', 'in_progress', 'paused']
    
    @property
    def budget_display(self):
        """Génère l'affichage formaté du budget"""
        budget_ranges = {
            'moins_500': 'Moins de 500 AOA',
            '500_1000': '500 à 1 000 AOA',
            '1000_10000': '1 000 à 10 000 AOA',
            '10000_plus': '10 000 AOA et plus',
            'sur_devis': 'Sur devis'
        }
        
        # Si on a des valeurs min/max budget définies
        if self.min_budget is not None and self.max_budget is not None:
            if self.min_budget == self.max_budget:
                return f"{int(self.min_budget)} AOA"
            else:
                return f"{int(self.min_budget)} - {int(self.max_budget)} AOA"
        
        # Si on a seulement un budget minimum
        elif self.min_budget is not None:
            return f"À partir de {int(self.min_budget)} AOA"
        
        # Si on a seulement un budget maximum
        elif self.max_budget is not None:
            return f"Jusqu'à {int(self.max_budget)} AOA"
        
        # Sinon utiliser la plage prédéfinie
        return budget_ranges.get(self.budget_range, 'Budget à discuter')
    
    def close_project(self, user=None):
        """Méthode pour clôturer le projet"""
        if self.can_be_closed:
            self.status = 'closed'
            self.closed_at = timezone.now()
            self.save()
            
            # Log de l'action
            if user:
                print(f"Projet {self.id} clôturé par {user.email} le {self.closed_at}")




class ProjectOffer(TimeStampMixin):
    """Modèle pour les offres des prestataires sur les projets"""
    STATUS_CHOICES = (
        ('pending', 'En attente'),
        ('accepted', 'Acceptée'),
        ('rejected', 'Rejetée'),
        ('withdrawn', 'Retirée'),
    )
    
    # Relations
    project = models.ForeignKey(ClientProject, on_delete=models.CASCADE, related_name='project_offers')
    provider = models.ForeignKey(Provider, on_delete=models.CASCADE, related_name='project_offers')
    
    # Détails de l'offre
    proposed_price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="Prix proposé")
    delivery_time = models.PositiveIntegerField(verbose_name="Délai de livraison (en jours)")
    message = models.TextField(verbose_name="Message d'accompagnement")
    
    # Options et garanties
    includes_materials = models.BooleanField(default=False, verbose_name="Matériaux inclus")
    warranty_period = models.PositiveIntegerField(null=True, blank=True, verbose_name="Période de garantie (mois)")
    travel_costs_included = models.BooleanField(default=True, verbose_name="Frais de déplacement inclus")
    
    # Statut
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    # Métadonnées
    viewed_by_client = models.BooleanField(default=False)
    client_notes = models.TextField(blank=True, verbose_name="Notes du client")
    
    class Meta:
        ordering = ['-created_at']
        unique_together = ('project', 'provider')  # Un prestataire ne peut faire qu'une offre par projet
        verbose_name = "Offre de Prestataire"
        verbose_name_plural = "Offres de Prestataires"
    
    def __str__(self):
        return f"Offre de {self.provider.user.username} pour {self.project.title}"


class ProjectSkill(TimeStampMixin):
    """Compétences requises pour un projet"""
    project = models.ForeignKey(ClientProject, on_delete=models.CASCADE, related_name='required_skills')
    name = models.CharField(max_length=100, verbose_name="Nom de la compétence")
    is_required = models.BooleanField(default=True, verbose_name="Compétence obligatoire")
    
    class Meta:
        verbose_name = "Compétence Projet"
        verbose_name_plural = "Compétences Projets"
    
    def __str__(self):
        return f"{self.name} ({'Obligatoire' if self.is_required else 'Optionnelle'})"


class ProjectView(TimeStampMixin):
    """Suivi des vues des projets"""
    project = models.ForeignKey(ClientProject, on_delete=models.CASCADE, related_name='project_views')
    viewer = models.ForeignKey(User, on_delete=models.CASCADE, null=True, blank=True)
    ip_address = models.GenericIPAddressField()
    user_agent = models.TextField(blank=True)
    
    class Meta:
        unique_together = ('project', 'viewer', 'ip_address')
        verbose_name = "Vue Projet"
        verbose_name_plural = "Vues Projets"


class ProjectFavorite(TimeStampMixin):
    """Projets favoris des prestataires"""
    project = models.ForeignKey(ClientProject, on_delete=models.CASCADE, related_name='favorites')
    provider = models.ForeignKey(Provider, on_delete=models.CASCADE, related_name='favorite_projects')
    
    class Meta:
        unique_together = ('project', 'provider')
        verbose_name = "Projet Favori"
        verbose_name_plural = "Projets Favoris"
    
    def __str__(self):
        return f"{self.provider.user.username} - {self.project.title}"


class ProviderSkill(TimeStampMixin):
    """Compétences des prestataires"""
    provider = models.ForeignKey(Provider, on_delete=models.CASCADE, related_name='skills')
    name = models.CharField(max_length=100, verbose_name="Nom de la compétence")
    level = models.CharField(max_length=20, choices=(
        ('beginner', 'Débutant'),
        ('intermediate', 'Intermédiaire'),
        ('advanced', 'Avancé'),
        ('expert', 'Expert'),
    ), default='intermediate')
    years_experience = models.PositiveIntegerField(null=True, blank=True, verbose_name="Années d'expérience")
    
    class Meta:
        unique_together = ('provider', 'name')
        verbose_name = "Compétence Prestataire"
        verbose_name_plural = "Compétences Prestataires"
    
    def __str__(self):
        return f"{self.provider.user.username} - {self.name} ({self.level})"

class AdminAction(models.Model):
    """
    Modèle pour tracer les actions administratives
    """
    ACTION_TYPES = (
        ('project_status_change', 'Changement statut projet'),
        ('project_close', 'Fermeture projet'),
        ('project_reopen', 'Réouverture projet'),
        ('dispute_status_change', 'Changement statut litige'),
        ('dispute_resolve', 'Résolution litige'),
        ('user_suspend', 'Suspension utilisateur'),
        ('provider_verify', 'Vérification prestataire'),
        ('bulk_action', 'Action groupée'),
        ('provider_verification_approve', 'Approbation vérification prestataire'),
        ('provider_verification_reject', 'Rejet vérification prestataire'),
        ('phone_verification_reset', 'Reset vérification téléphone'),
        ('verification_bulk_action', 'Action groupée vérifications'),
    )
    
    admin_user = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='admin_actions',
        verbose_name="Administrateur"
    )
    action_type = models.CharField(
        max_length=50, 
        choices=ACTION_TYPES,
        verbose_name="Type d'action"
    )
    target_model = models.CharField(
        max_length=50,
        verbose_name="Modèle cible"
    )
    target_id = models.PositiveIntegerField(
        verbose_name="ID de l'objet"
    )
    description = models.TextField(
        verbose_name="Description de l'action"
    )
    old_value = models.JSONField(
        null=True, 
        blank=True,
        verbose_name="Ancienne valeur"
    )
    new_value = models.JSONField(
        null=True, 
        blank=True,
        verbose_name="Nouvelle valeur"
    )
    ip_address = models.GenericIPAddressField(
        null=True, 
        blank=True,
        verbose_name="Adresse IP"
    )
    user_agent = models.TextField(
        blank=True,
        verbose_name="User Agent"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name="Date de création"
    )
    
    class Meta:
        verbose_name = "Action Administrateur"
        verbose_name_plural = "Actions Administrateurs"
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.admin_user.username} - {self.get_action_type_display()}"


class SystemSettings(models.Model):
    """
    Paramètres système pour l'administration
    """
    SETTING_TYPES = (
        ('string', 'Texte'),
        ('integer', 'Nombre entier'),
        ('float', 'Nombre décimal'),
        ('boolean', 'Booléen'),
        ('json', 'JSON'),
    )
    
    key = models.CharField(
        max_length=100, 
        unique=True,
        verbose_name="Clé"
    )
    value = models.TextField(
        verbose_name="Valeur"
    )
    setting_type = models.CharField(
        max_length=20, 
        choices=SETTING_TYPES,
        default='string',
        verbose_name="Type de paramètre"
    )
    description = models.TextField(
        blank=True,
        verbose_name="Description"
    )
    is_public = models.BooleanField(
        default=False,
        verbose_name="Visible publiquement"
    )
    updated_by = models.ForeignKey(
        User, 
        on_delete=models.SET_NULL, 
        null=True,
        verbose_name="Modifié par"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name="Dernière modification"
    )
    
    class Meta:
        verbose_name = "Paramètre Système"
        verbose_name_plural = "Paramètres Système"
    
    def __str__(self):
        return f"{self.key}: {self.value[:50]}"
    
    def get_typed_value(self):
        """Retourne la valeur dans le bon type"""
        if self.setting_type == 'integer':
            return int(self.value)
        elif self.setting_type == 'float':
            return float(self.value)
        elif self.setting_type == 'boolean':
            return self.value.lower() in ['true', '1', 'yes', 'on']
        elif self.setting_type == 'json':
            import json
            return json.loads(self.value)
        else:
            return self.value
        

##########################################################################################################
########################################## VERIFICATIO PROFIL ##################################

class ProviderVerification(TimeStampMixin):
    """
    Modèle pour la vérification des prestataires avec documents
    Gère la vérification par carte d'identité (2 faces) ou passeport
    """
    
    VERIFICATION_STATUS_CHOICES = (
        ('not_started', 'Non commencé'),
        ('pending', 'En attente'),
        ('verified', 'Vérifié'),
        ('rejected', 'Rejeté'),
    )
    
    DOCUMENT_TYPE_CHOICES = (
        ('id_card', 'Carte d\'identité'),
        ('passport', 'Passeport'),
    )
    
    provider = models.OneToOneField(
        Provider, 
        on_delete=models.CASCADE, 
        related_name='verification',
        verbose_name="Prestataire"
    )
    
  
    is_business = models.BooleanField(
        default=False,
        verbose_name="Est une entreprise"
    )
    
    document_type = models.CharField(
        max_length=20, 
        choices=DOCUMENT_TYPE_CHOICES, 
        default='id_card',
        verbose_name="Type de document"
    )
  
    business_name = models.CharField(
        max_length=200, 
        blank=True,
        verbose_name="Nom de l'entreprise"
    )
    business_nif = models.CharField(
        max_length=50, 
        blank=True,
        verbose_name="NIF de l'entreprise",
        help_text="Numéro d'identification fiscale"
    )
    business_registration_number = models.CharField(
        max_length=100, 
        blank=True,
        verbose_name="Numéro d'enregistrement",
        help_text="Numéro RCCM ou équivalent"
    )
    

    id_card_front = models.ImageField(
        upload_to='verifications/id_cards/front/', 
        null=True, 
        blank=True,
        verbose_name="Carte d'identité (recto)"
    )
    id_card_back = models.ImageField(
        upload_to='verifications/id_cards/back/', 
        null=True, 
        blank=True,
        verbose_name="Carte d'identité (verso)"
    )
    passport_image = models.ImageField(
        upload_to='verifications/passports/', 
        null=True, 
        blank=True,
        verbose_name="Photo du passeport"
    )
   
    business_registration_doc = models.FileField(
        upload_to='verifications/business_docs/', 
        null=True, 
        blank=True,
        verbose_name="Document d'enregistrement d'entreprise"
    )
    

    verification_status = models.CharField(
        max_length=20, 
        choices=VERIFICATION_STATUS_CHOICES, 
        default='not_started',
        verbose_name="Statut de vérification"
    )
    
    # Dates importantes
    submitted_at = models.DateTimeField(
        null=True, 
        blank=True,
        verbose_name="Date de soumission"
    )
    verified_at = models.DateTimeField(
        null=True, 
        blank=True,
        verbose_name="Date de vérification"
    )
    
    # Admin qui a validé
    verified_by = models.ForeignKey(
        User, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='verified_providers',
        verbose_name="Vérifié par"
    )
    
    # Raison de rejet et notes admin
    rejection_reason = models.TextField(
        blank=True,
        verbose_name="Raison du rejet"
    )
    admin_notes = models.TextField(
        blank=True,
        verbose_name="Notes administratives"
    )
    
    
    class Meta:
        verbose_name = "Vérification Prestataire"
        verbose_name_plural = "Vérifications Prestataires"
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Vérification {self.provider.user.username} - {self.get_verification_status_display()}"
    
    
    def clean(self):
        """Validation personnalisée"""
        from django.core.exceptions import ValidationError
        
        # Vérifier que les documents requis sont fournis
        if self.document_type == 'id_card':
            if not self.id_card_front or not self.id_card_back:
                raise ValidationError({
                    'id_card_front': 'Les deux faces de la carte d\'identité sont requises',
                    'id_card_back': 'Les deux faces de la carte d\'identité sont requises'
                })
        elif self.document_type == 'passport':
            if not self.passport_image:
                raise ValidationError({
                    'passport_image': 'L\'image du passeport est requise'
                })
        
        # Vérifier les informations entreprise si nécessaire
        if self.is_business:
            if not self.business_name:
                raise ValidationError({
                    'business_name': 'Le nom de l\'entreprise est requis pour les entreprises'
                })
    
    def save(self, *args, **kwargs):
        """Logique personnalisée lors de la sauvegarde"""
        
        # Mettre à jour la date de soumission si le statut passe à pending
        if (self.verification_status == 'pending' and 
            self.submitted_at is None):
            self.submitted_at = timezone.now()
        
        # Mettre à jour la date de vérification si approuvé
        if (self.verification_status == 'verified' and 
            self.verified_at is None):
            self.verified_at = timezone.now()
        
        # Sauvegarder d'abord
        super().save(*args, **kwargs)
        
        # Mettre à jour le statut is_verified du Provider
        self._update_provider_verification_status()
    
    def _update_provider_verification_status(self):
        """Met à jour le statut is_verified du Provider"""
        if self.verification_status == 'verified':
            self.provider.is_verified = True
        else:
            self.provider.is_verified = False
        
        # Éviter la récursion infinie
        Provider.objects.filter(id=self.provider.id).update(
            is_verified=self.provider.is_verified
        )
    
    def is_pending(self):
        """Vérifie si la vérification est en attente"""
        return self.verification_status == 'pending'
    
    def is_verified(self):
        """Vérifie si la vérification est approuvée"""
        return self.verification_status == 'verified'
    
    def is_rejected(self):
        """Vérifie si la vérification est rejetée"""
        return self.verification_status == 'rejected'
    
    def can_be_modified(self):
        """Vérifie si la vérification peut être modifiée"""
        return self.verification_status in ['not_started', 'rejected']
    
    def get_documents_list(self):
        """Retourne la liste des documents fournis"""
        documents = []
        if self.id_card_front:
            documents.append('Carte d\'identité (recto)')
        if self.id_card_back:
            documents.append('Carte d\'identité (verso)')
        if self.passport_image:
            documents.append('Passeport')
        if self.business_registration_doc:
            documents.append('Document d\'entreprise')
        return documents


# ================================================================
# 2. MODÈLE DE VÉRIFICATION PAR TÉLÉPHONE (CLIENTS)
# ================================================================

class PhoneVerification(TimeStampMixin):
    """
    Modèle pour la vérification par SMS des clients
    Gère l'envoi et la vérification des codes SMS
    """
    
    VERIFICATION_STATUS_CHOICES = (
        ('pending', 'En attente'),
        ('verified', 'Vérifié'),
        ('expired', 'Expiré'),
        ('failed', 'Échec'),
    )
    
   
    user = models.OneToOneField(
        User, 
        on_delete=models.CASCADE, 
        related_name='phone_verification',
        verbose_name="Utilisateur"
    )
    
    
    phone_number = models.CharField(
        max_length=20,
        verbose_name="Numéro de téléphone"
    )
    verification_code = models.CharField(
        max_length=6,
        verbose_name="Code de vérification"
    )
    
    
    status = models.CharField(
        max_length=20, 
        choices=VERIFICATION_STATUS_CHOICES, 
        default='pending',
        verbose_name="Statut"
    )
    
    attempts = models.PositiveIntegerField(
        default=0,
        verbose_name="Nombre de tentatives"
    )
    max_attempts = models.PositiveIntegerField(
        default=3,
        verbose_name="Tentatives maximales"
    )
    
    
    expires_at = models.DateTimeField(
        verbose_name="Expire le"
    )
    verified_at = models.DateTimeField(
        null=True, 
        blank=True,
        verbose_name="Vérifié le"
    )
    last_code_sent_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name="Dernier code envoyé le"
    )
    
   
    class Meta:
        verbose_name = "Vérification Téléphone"
        verbose_name_plural = "Vérifications Téléphone"
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Vérification téléphone {self.user.username} ({self.phone_number}) - {self.get_status_display()}"
    
 
    # ============================================================
    @classmethod
    def generate_code(cls):
        """Génère un code de vérification à 6 chiffres"""
        return ''.join(random.choices(string.digits, k=6))
    
    def is_expired(self):
        """Vérifie si le code a expiré"""
        return timezone.now() > self.expires_at
    
    def can_verify(self):
        """Vérifie si la vérification peut encore être tentée"""
        return (
            self.status == 'pending' and 
            not self.is_expired() and 
            self.attempts < self.max_attempts
        )
    
    def can_resend_code(self):
        """Vérifie si un nouveau code peut être envoyé"""
        # Empêcher l'envoi trop fréquent (1 minute minimum)
        if self.last_code_sent_at:
            time_since_last = timezone.now() - self.last_code_sent_at
            return time_since_last.total_seconds() >= 1
        return True
    
    def increment_attempt(self):
        """Incrémente le nombre de tentatives"""
        self.attempts += 1
        if self.attempts >= self.max_attempts:
            self.status = 'failed'
        self.save()
    
    def verify_code(self, provided_code):
        """Vérifie le code fourni"""
        if not self.can_verify():
            return False
        
        self.increment_attempt()
        
        if self.verification_code == provided_code:
            self.status = 'verified'
            self.verified_at = timezone.now()
            self.save()
            
            # Mettre à jour le statut utilisateur
            self._update_user_verification_status()
            return True
        
        return False
    
    def _update_user_verification_status(self):
        """Met à jour le statut is_verified de l'utilisateur"""
        if self.status == 'verified':
            self.user.is_verified = True
            self.user.save()
    
    def regenerate_code(self):
        """Génère un nouveau code et prolonge l'expiration"""
        if not self.can_resend_code():
            raise ValueError("Vous devez attendre avant de demander un nouveau code")
        
        self.verification_code = self.generate_code()
        self.expires_at = timezone.now() + timedelta(minutes=10)
        self.attempts = 0  # Reset les tentatives
        self.status = 'pending'
        self.last_code_sent_at = timezone.now()
        self.save()
        
        return self.verification_code
    
    def save(self, *args, **kwargs):
        """Logique personnalisée lors de la sauvegarde"""
        
        # Générer un code si c'est une nouvelle instance
        if not self.pk and not self.verification_code:
            self.verification_code = self.generate_code()
        
        # Définir l'expiration si pas déjà définie
        if not self.expires_at:
            self.expires_at = timezone.now() + timedelta(minutes=10)
        
        # Marquer comme expiré si nécessaire
        if self.is_expired() and self.status == 'pending':
            self.status = 'expired'
        
        super().save(*args, **kwargs)


class FCMToken(models.Model):
    """
    Modèle pour stocker les tokens FCM des utilisateurs
    """
    DEVICE_TYPES = (
        ('android', 'Android'),
        ('ios', 'iOS'),
        ('web', 'Web'),
    )
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='fcm_tokens')
    token = models.TextField(unique=True)
    device_type = models.CharField(max_length=10, choices=DEVICE_TYPES)
    app_version = models.CharField(max_length=20, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_used = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Token FCM"
        verbose_name_plural = "Tokens FCM"
        indexes = [
            models.Index(fields=['user', 'is_active']),
            models.Index(fields=['token']),
        ]
    
    def __str__(self):
        return f"Token {self.device_type} pour {self.user.email}"
    
class NotificationPreference(models.Model):
    """
    Modèle pour les préférences de notification des utilisateurs
    """
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='notification_preferences')
    
    # Types de notifications
    messages_enabled = models.BooleanField(default=True)
    offers_enabled = models.BooleanField(default=True)
    projects_enabled = models.BooleanField(default=True)
    reviews_enabled = models.BooleanField(default=True)
    system_enabled = models.BooleanField(default=True)
    
    # Canaux de notification
    push_notifications = models.BooleanField(default=True)
    email_notifications = models.BooleanField(default=True)
    sms_notifications = models.BooleanField(default=False)
    
    # Horaires de notification (optionnel)
    quiet_hours_start = models.TimeField(null=True, blank=True, help_text="Début des heures silencieuses")
    quiet_hours_end = models.TimeField(null=True, blank=True, help_text="Fin des heures silencieuses")
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Préférence de notification"
        verbose_name_plural = "Préférences de notification"
    
    def __str__(self):
        return f"Préférences de {self.user.email}"
    
    @classmethod
    def get_or_create_for_user(cls, user):
        """Obtenir ou créer les préférences pour un utilisateur"""
        preferences, created = cls.objects.get_or_create(
            user=user,
            defaults={
                'messages_enabled': True,
                'offers_enabled': True,
                'projects_enabled': True,
                'reviews_enabled': True,
                'system_enabled': True,
                'push_notifications': True,
                'email_notifications': True,
                'sms_notifications': False,
            }
        )
        return preferences

# NOUVEAU MODÈLE : Historique des notifications
class NotificationHistory(models.Model):
    """
    Modèle pour l'historique des notifications envoyées
    """
    STATUS_CHOICES = (
        ('pending', 'En attente'),
        ('sent', 'Envoyée'),
        ('delivered', 'Livrée'),
        ('failed', 'Échouée'),
        ('clicked', 'Cliquée'),
    )
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notification_history')
    fcm_token = models.ForeignKey(FCMToken, on_delete=models.SET_NULL, null=True, blank=True)
    
    # Contenu de la notification
    title = models.CharField(max_length=255)
    body = models.TextField()
    notification_type = models.CharField(max_length=50)
    
    # Données additionnelles (JSON)
    data = models.JSONField(default=dict, blank=True)
    
    # Statut et métadonnées
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    firebase_message_id = models.CharField(max_length=255, blank=True , null=True)
    error_message = models.TextField(blank=True , null=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    sent_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    clicked_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        verbose_name = "Historique de notification"
        verbose_name_plural = "Historiques de notification"
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['notification_type']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"{self.title} - {self.user.email} ({self.status})"