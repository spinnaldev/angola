
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver

from angola_api.operation.models import ClientProject, Dispute, Notification, ProjectOffer

@receiver(post_save, sender=Dispute)
def dispute_status_changed(sender, instance, created, **kwargs):
    if not created and instance.status == 'resolved':
        # Créer une notification automatique
        Notification.objects.create(
            user=instance.client,
            title="Litige résolu",
            content=f"Votre litige '{instance.title}' a été résolu.",
            type='dispute'
        )

@receiver(post_save, sender=ClientProject)
def project_status_changed(sender, instance, created, **kwargs):
    if not created and instance.status == 'cancelled':
        # Rejeter toutes les offres en attente
        ProjectOffer.objects.filter(
            project=instance,
            status='pending'
        ).update(status='rejected')
