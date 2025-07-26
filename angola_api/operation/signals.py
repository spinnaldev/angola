
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver

from operation.models import ClientProject, Dispute, Notification, ProjectOffer ,QuoteRequest

@receiver(post_save, sender=Dispute)
def dispute_status_changed(sender, instance, created, **kwargs):
    """Signal quand le statut d'un litige change"""
    if not created and instance.status == 'resolved':
        # Créer une notification automatique
        Notification.objects.create(
            user=instance.client,
            title="Litige résolu",
            message=f"Votre litige '{instance.title}' a été résolu.",
            notification_type='dispute'
        )

@receiver(post_save, sender=ClientProject)
def project_status_changed(sender, instance, created, **kwargs):
    """Signal quand le statut d'un projet change"""
    if not created and instance.status == 'cancelled':
        # Rejeter toutes les offres en attente
        ProjectOffer.objects.filter(
            project=instance,
            status='pending'
        ).update(status='rejected')

@receiver(post_save, sender=QuoteRequest)
def quote_request_status_changed(sender, instance, created, **kwargs):
    """Signal pour les changements de statut des demandes de devis"""
    if created:
        # Notification pour le prestataire quand une nouvelle demande arrive
        Notification.objects.create(
            user=instance.provider.user,
            title="Nouvelle demande de devis",
            message=f"Vous avez reçu une nouvelle demande de devis pour '{instance.subject}' de la part de {instance.client.get_full_name() or instance.client.username}.",
            notification_type='quote_request',
            related_object_id=instance.id
        )
    else:
        # Notifications pour les changements de statut
        if instance.status == 'accepted':
            # Notification pour le client quand le devis est accepté
            Notification.objects.create(
                user=instance.client,
                title="Devis accepté",
                message=f"Votre demande de devis '{instance.subject}' a été acceptée par {instance.provider.user.get_full_name() or instance.provider.user.username}. Vous pouvez maintenant contacter le prestataire.",
                notification_type='quote_accepted',
                related_object_id=instance.id
            )
            
        elif instance.status == 'rejected':
            # Notification pour le client quand le devis est rejeté
            Notification.objects.create(
                user=instance.client,
                title="Devis rejeté",
                message=f"Votre demande de devis '{instance.subject}' a été rejetée par {instance.provider.user.get_full_name() or instance.provider.user.username}.",
                notification_type='quote_rejected',
                related_object_id=instance.id
            )
            
        elif instance.status == 'completed':
            # Notifications pour les deux parties quand le devis est terminé
            Notification.objects.create(
                user=instance.client,
                title="Prestation terminée",
                message=f"La prestation '{instance.subject}' a été marquée comme terminée. N'oubliez pas de laisser un avis !",
                notification_type='quote_completed',
                related_object_id=instance.id
            )
            
            Notification.objects.create(
                user=instance.provider.user,
                title="Prestation terminée",
                message=f"Vous avez marqué la prestation '{instance.subject}' comme terminée.",
                notification_type='quote_completed',
                related_object_id=instance.id
            )

@receiver(post_save, sender=ProjectOffer)
def project_offer_status_changed(sender, instance, created, **kwargs):
    """Signal pour les changements de statut des offres sur les projets"""
    if created:
        # Notification pour le client quand une nouvelle offre arrive
        Notification.objects.create(
            user=instance.project.client,
            title="Nouvelle offre reçue",
            message=f"Vous avez reçu une nouvelle offre de {instance.provider.user.get_full_name() or instance.provider.user.username} pour votre projet '{instance.project.title}'.",
            notification_type='new_offer',
            related_object_id=instance.id
        )
    else:
        # Notifications pour les changements de statut
        if instance.status == 'accepted':
            # Notification pour le prestataire quand l'offre est acceptée
            Notification.objects.create(
                user=instance.provider.user,
                title="Offre acceptée",
                message=f"Votre offre pour le projet '{instance.project.title}' a été acceptée ! Le client va vous contacter.",
                notification_type='offer_accepted',
                related_object_id=instance.id
            )
            
        elif instance.status == 'rejected':
            # Notification pour le prestataire quand l'offre est rejetée
            Notification.objects.create(
                user=instance.provider.user,
                title="Offre rejetée",
                message=f"Votre offre pour le projet '{instance.project.title}' a été rejetée.",
                notification_type='offer_rejected',
                related_object_id=instance.id
            )