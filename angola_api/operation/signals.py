
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.utils import timezone
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

from operation.models import (
    ClientProject, Dispute, Notification, ProjectOffer, QuoteRequest, Message
)

# Obtenir la couche de canal pour WebSocket
channel_layer = get_channel_layer()

def send_notification_to_user(user_id, notification_data):
    """Helper pour envoyer une notification via WebSocket"""
    if channel_layer:
        async_to_sync(channel_layer.group_send)(
            f'notifications_{user_id}',
            {
                'type': 'notification_message',
                'notification': notification_data
            }
        )
        
        # Envoyer aussi via le consumer général
        async_to_sync(channel_layer.group_send)(
            f'user_{user_id}',
            {
                'type': 'notification_update',
                'event_type': 'new_notification',
                'notification': notification_data
            }
        )

def send_unread_count_update(user_id, count):
    """Helper pour envoyer la mise à jour du compteur"""
    if channel_layer:
        async_to_sync(channel_layer.group_send)(
            f'notifications_{user_id}',
            {
                'type': 'unread_count_update',
                'count': count
            }
        )
        
        async_to_sync(channel_layer.group_send)(
            f'user_{user_id}',
            {
                'type': 'counts_update',
                'event_type': 'notification_count_update',
                'notification_count': count
            }
        )

def send_message_notification(user_id, message_data):
    """Helper pour envoyer une notification de nouveau message"""
    if channel_layer:
        async_to_sync(channel_layer.group_send)(
            f'user_{user_id}',
            {
                'type': 'message_update',
                'event_type': 'new_message',
                'message': message_data
            }
        )

@receiver(post_save, sender=Dispute)
def dispute_status_changed(sender, instance, created, **kwargs):
    """Signal quand le statut d'un litige change"""
    if not created and instance.status == 'resolved':
        # Créer une notification automatique
        notification = Notification.objects.create(
            user=instance.client,
            title="Litige résolu",
            message=f"Votre litige '{instance.title}' a été résolu.",
            notification_type='dispute'
        )
        
        # Envoyer via WebSocket
        notification_data = {
            'id': notification.id,
            'title': notification.title,
            'message': notification.message,
            'notification_type': notification.notification_type,
            'is_read': notification.is_read,
            'created_at': notification.created_at.isoformat(),
        }
        
        send_notification_to_user(instance.client.id, notification_data)
        
        # Mettre à jour le compteur
        unread_count = Notification.objects.filter(
            user=instance.client, 
            is_read=False
        ).count()
        send_unread_count_update(instance.client.id, unread_count)

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
        notification = Notification.objects.create(
            user=instance.provider.user,
            title="Nouvelle demande de devis",
            message=f"Vous avez reçu une nouvelle demande de devis pour '{instance.subject}' de la part de {instance.client.get_full_name() or instance.client.username}.",
            notification_type='quote_request',
            related_object_id=instance.id
        )
        
        # 🔔 ENVOYER VIA WEBSOCKET
        notification_data = {
            'id': notification.id,
            'title': notification.title,
            'message': notification.message,
            'notification_type': notification.notification_type,
            'related_object_id': notification.related_object_id,
            'is_read': notification.is_read,
            'created_at': notification.created_at.isoformat(),
        }
        
        send_notification_to_user(instance.provider.user.id, notification_data)
        
        # Mettre à jour le compteur
        unread_count = Notification.objects.filter(
            user=instance.provider.user, 
            is_read=False
        ).count()
        send_unread_count_update(instance.provider.user.id, unread_count)
        
    else:
        # Notifications pour les changements de statut
        if instance.status == 'accepted':
            # Notification pour le client quand le devis est accepté
            notification = Notification.objects.create(
                user=instance.client,
                title="Devis accepté",
                message=f"Votre demande de devis '{instance.subject}' a été acceptée par {instance.provider.user.get_full_name() or instance.provider.user.username}. Vous pouvez maintenant contacter le prestataire.",
                notification_type='quote_accepted',
                related_object_id=instance.id
            )
            
            # 🔔 ENVOYER VIA WEBSOCKET
            notification_data = {
                'id': notification.id,
                'title': notification.title,
                'message': notification.message,
                'notification_type': notification.notification_type,
                'related_object_id': notification.related_object_id,
                'is_read': notification.is_read,
                'created_at': notification.created_at.isoformat(),
            }
            
            send_notification_to_user(instance.client.id, notification_data)
            
            # Mettre à jour le compteur
            unread_count = Notification.objects.filter(
                user=instance.client, 
                is_read=False
            ).count()
            send_unread_count_update(instance.client.id, unread_count)
            
        elif instance.status == 'rejected':
            # Notification pour le client quand le devis est rejeté
            notification = Notification.objects.create(
                user=instance.client,
                title="Devis rejeté",
                message=f"Votre demande de devis '{instance.subject}' a été rejetée par {instance.provider.user.get_full_name() or instance.provider.user.username}.",
                notification_type='quote_rejected',
                related_object_id=instance.id
            )
            
            # 🔔 ENVOYER VIA WEBSOCKET
            notification_data = {
                'id': notification.id,
                'title': notification.title,
                'message': notification.message,
                'notification_type': notification.notification_type,
                'related_object_id': notification.related_object_id,
                'is_read': notification.is_read,
                'created_at': notification.created_at.isoformat(),
            }
            
            send_notification_to_user(instance.client.id, notification_data)
            
            # Mettre à jour le compteur
            unread_count = Notification.objects.filter(
                user=instance.client, 
                is_read=False
            ).count()
            send_unread_count_update(instance.client.id, unread_count)
            
        elif instance.status == 'completed':
            # Notifications pour les deux parties quand le devis est terminé
            # Notification pour le client
            client_notification = Notification.objects.create(
                user=instance.client,
                title="Prestation terminée",
                message=f"La prestation '{instance.subject}' a été marquée comme terminée. N'oubliez pas de laisser un avis !",
                notification_type='quote_completed',
                related_object_id=instance.id
            )
            
            # Notification pour le prestataire
            provider_notification = Notification.objects.create(
                user=instance.provider.user,
                title="Prestation terminée",
                message=f"Vous avez marqué la prestation '{instance.subject}' comme terminée.",
                notification_type='quote_completed',
                related_object_id=instance.id
            )
            
            # 🔔 ENVOYER VIA WEBSOCKET pour les deux
            for notification, user in [(client_notification, instance.client), 
                                     (provider_notification, instance.provider.user)]:
                notification_data = {
                    'id': notification.id,
                    'title': notification.title,
                    'message': notification.message,
                    'notification_type': notification.notification_type,
                    'related_object_id': notification.related_object_id,
                    'is_read': notification.is_read,
                    'created_at': notification.created_at.isoformat(),
                }
                
                send_notification_to_user(user.id, notification_data)
                
                # Mettre à jour le compteur
                unread_count = Notification.objects.filter(
                    user=user, 
                    is_read=False
                ).count()
                send_unread_count_update(user.id, unread_count)

@receiver(post_save, sender=ProjectOffer)
def project_offer_status_changed(sender, instance, created, **kwargs):
    """Signal pour les changements de statut des offres sur les projets"""
    if created:
        # Notification pour le client quand une nouvelle offre arrive
        notification = Notification.objects.create(
            user=instance.project.client,
            title="Nouvelle offre reçue",
            message=f"Vous avez reçu une nouvelle offre de {instance.provider.user.get_full_name() or instance.provider.user.username} pour votre projet '{instance.project.title}'.",
            notification_type='new_offer',
            related_object_id=instance.id
        )
        
        # 🔔 ENVOYER VIA WEBSOCKET
        notification_data = {
            'id': notification.id,
            'title': notification.title,
            'message': notification.message,
            'notification_type': notification.notification_type,
            'related_object_id': notification.related_object_id,
            'is_read': notification.is_read,
            'created_at': notification.created_at.isoformat(),
        }
        
        send_notification_to_user(instance.project.client.id, notification_data)
        
        # Mettre à jour le compteur
        unread_count = Notification.objects.filter(
            user=instance.project.client, 
            is_read=False
        ).count()
        send_unread_count_update(instance.project.client.id, unread_count)
        
    else:
        # Notifications pour les changements de statut d'offre
        if instance.status == 'accepted':
            # Notification pour le prestataire quand l'offre est acceptée
            notification = Notification.objects.create(
                user=instance.provider.user,
                title="Offre acceptée",
                message=f"Votre offre pour le projet '{instance.project.title}' a été acceptée ! Le client va vous contacter.",
                notification_type='offer_accepted',
                related_object_id=instance.id
            )
            
            # 🔔 ENVOYER VIA WEBSOCKET
            notification_data = {
                'id': notification.id,
                'title': notification.title,
                'message': notification.message,
                'notification_type': notification.notification_type,
                'related_object_id': notification.related_object_id,
                'is_read': notification.is_read,
                'created_at': notification.created_at.isoformat(),
            }
            
            send_notification_to_user(instance.provider.user.id, notification_data)
            
            # Mettre à jour le compteur
            unread_count = Notification.objects.filter(
                user=instance.provider.user, 
                is_read=False
            ).count()
            send_unread_count_update(instance.provider.user.id, unread_count)
            
        elif instance.status == 'rejected':
            # Notification pour le prestataire quand l'offre est rejetée
            notification = Notification.objects.create(
                user=instance.provider.user,
                title="Offre rejetée",
                message=f"Votre offre pour le projet '{instance.project.title}' a été rejetée.",
                notification_type='offer_rejected',
                related_object_id=instance.id
            )
            
            # 🔔 ENVOYER VIA WEBSOCKET
            notification_data = {
                'id': notification.id,
                'title': notification.title,
                'message': notification.message,
                'notification_type': notification.notification_type,
                'related_object_id': notification.related_object_id,
                'is_read': notification.is_read,
                'created_at': notification.created_at.isoformat(),
            }
            
            send_notification_to_user(instance.provider.user.id, notification_data)
            
            # Mettre à jour le compteur
            unread_count = Notification.objects.filter(
                user=instance.provider.user, 
                is_read=False
            ).count()
            send_unread_count_update(instance.provider.user.id, unread_count)

@receiver(post_save, sender=Message)
def message_created(sender, instance, created, **kwargs):
    """Signal pour les nouveaux messages"""
    if created:
        conversation = instance.conversation
        
        # Déterminer qui doit recevoir la notification
        if instance.sender == conversation.client:
            # Message envoyé par le client → notifier le prestataire
            recipient = conversation.provider.user
        else:
            # Message envoyé par le prestataire → notifier le client
            recipient = conversation.client
        
        # Envoyer la notification de nouveau message via WebSocket
        message_data = {
            'id': instance.id,
            'conversation_id': conversation.id,
            'content': instance.content,
            'sender_id': instance.sender.id,
            'sender_name': instance.sender.get_full_name() or instance.sender.username,
            'created_at': instance.created_at.isoformat(),
            'is_read': instance.is_read
        }
        
        send_message_notification(recipient.id, message_data)
        
        # Envoyer aussi dans le groupe de la conversation
        if channel_layer:
            async_to_sync(channel_layer.group_send)(
                f'chat_{conversation.id}',
                {
                    'type': 'chat_message',
                    'message': message_data
                }
            )