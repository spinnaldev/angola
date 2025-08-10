
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.utils import timezone
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

from operation.models import (
    AdminAction, ClientProject, Dispute, Notification, PhoneVerification, ProjectOffer, ProviderVerification, QuoteRequest, Message
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

# ✅ FONCTION UTILITAIRE ROBUSTE - Ne lève jamais d'exception
def create_and_send_notification(user, title, message, notification_type, related_object_id=None):
    """
    Fonction utilitaire pour créer une notification et l'envoyer via WebSocket
    ROBUSTE : Ne lève jamais d'exception, continue toujours
    """
    try:
        # Créer la notification en base
        notification = Notification.objects.create(
            user=user,
            title=title,
            message=message,
            notification_type=notification_type,
            related_object_id=related_object_id
        )
        
        print(f"✅ Notification créée: {notification.id} pour user {user.id}")
        
        # Préparer les données pour WebSocket
        notification_data = {
            'id': notification.id,
            'title': notification.title,
            'message': notification.message,
            'notification_type': notification.notification_type,
            'related_object_id': notification.related_object_id,
            'is_read': notification.is_read,
            'created_at': notification.created_at.isoformat(),
        }
        
        # Envoyer via WebSocket (avec gestion d'erreur)
        try:
            send_notification_to_user(user.id, notification_data)
        except Exception as ws_error:
            print(f"⚠️ Erreur WebSocket notification (continue quand même): {ws_error}")
        
        # Mettre à jour le compteur (avec gestion d'erreur)
        try:
            unread_count = Notification.objects.filter(user=user, is_read=False).count()
            send_unread_count_update(user.id, unread_count)
        except Exception as count_error:
            print(f"⚠️ Erreur compteur notifications (continue quand même): {count_error}")
        
        print(f"✅ Notification envoyée avec succès: {notification.id}")
        return notification
        
    except Exception as e:
        print(f"❌ Erreur création notification (continue quand même): {e}")
        return None  # ✅ TOUJOURS retourner None en cas d'erreur

# ================================================================
# SIGNAUX REFACTORISÉS AVEC LA FONCTION UTILITAIRE
# ================================================================

@receiver(post_save, sender=Dispute)
def dispute_status_changed(sender, instance, created, **kwargs):
    """Signal quand le statut d'un litige change"""
    if not created and instance.status == 'resolved':
        # ✅ REFACTORISÉ : Utiliser la fonction utilitaire
        create_and_send_notification(
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
        # ✅ REFACTORISÉ : Nouvelle demande de devis
        create_and_send_notification(
            user=instance.provider.user,
            title="Nouvelle demande de devis",
            message=f"Vous avez reçu une nouvelle demande de devis pour '{instance.subject}' de la part de {instance.client.get_full_name() or instance.client.username}.",
            notification_type='quote_request',
            related_object_id=instance.id
        )
        
    else:
        # Notifications pour les changements de statut
        if instance.status == 'accepted':
            # ✅ REFACTORISÉ : Devis accepté
            create_and_send_notification(
                user=instance.client,
                title="Devis accepté",
                message=f"Votre demande de devis '{instance.subject}' a été acceptée par {instance.provider.user.get_full_name() or instance.provider.user.username}. Vous pouvez maintenant contacter le prestataire.",
                notification_type='quote_accepted',
                related_object_id=instance.id
            )
            
        elif instance.status == 'rejected':
            # ✅ REFACTORISÉ : Devis rejeté
            create_and_send_notification(
                user=instance.client,
                title="Devis rejeté",
                message=f"Votre demande de devis '{instance.subject}' a été rejetée par {instance.provider.user.get_full_name() or instance.provider.user.username}.",
                notification_type='quote_rejected',
                related_object_id=instance.id
            )
            
        elif instance.status == 'completed':
            # ✅ REFACTORISÉ : Prestation terminée - deux notifications
            # Notification pour le client
            create_and_send_notification(
                user=instance.client,
                title="Prestation terminée",
                message=f"La prestation '{instance.subject}' a été marquée comme terminée. N'oubliez pas de laisser un avis !",
                notification_type='quote_completed',
                related_object_id=instance.id
            )
            
            # Notification pour le prestataire
            create_and_send_notification(
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
        # ✅ REFACTORISÉ : Nouvelle offre reçue
        create_and_send_notification(
            user=instance.project.client,
            title="Nouvelle offre reçue",
            message=f"Vous avez reçu une nouvelle offre de {instance.provider.user.get_full_name() or instance.provider.user.username} pour votre projet '{instance.project.title}'.",
            notification_type='new_offer',
            related_object_id=instance.id
        )
        
    else:
        # Notifications pour les changements de statut d'offre
        if instance.status == 'accepted':
            # ✅ REFACTORISÉ : Offre acceptée
            create_and_send_notification(
                user=instance.provider.user,
                title="Offre acceptée",
                message=f"Votre offre pour le projet '{instance.project.title}' a été acceptée ! Le client va vous contacter.",
                notification_type='offer_accepted',
                related_object_id=instance.id
            )
            
        elif instance.status == 'rejected':
            # ✅ REFACTORISÉ : Offre rejetée
            create_and_send_notification(
                user=instance.provider.user,
                title="Offre rejetée",
                message=f"Votre offre pour le projet '{instance.project.title}' a été rejetée.",
                notification_type='offer_rejected',
                related_object_id=instance.id
            )

@receiver(post_save, sender=Message)
def message_created(sender, instance, created, **kwargs):
    """Signal pour les nouveaux messages"""
    if created:
        conversation = instance.conversation
        
        # Déterminer qui doit recevoir la notification
        if instance.sender == conversation.client:
            # Message envoyé par le client → notifier le prestataire
            recipient = conversation.provider.user
            sender_name = conversation.client.get_full_name() or conversation.client.username
        else:
            # Message envoyé par le prestataire → notifier le client
            recipient = conversation.client
            sender_name = conversation.provider.user.get_full_name() or conversation.provider.user.username
        
        # ✅ REFACTORISÉ : Créer notification avec fonction utilitaire
        create_and_send_notification(
            user=recipient,
            title="Nouveau message",
            message=f"Vous avez reçu un nouveau message de {sender_name}",
            notification_type='new_message',
            related_object_id=conversation.id
        )
        
        # 📱 ENVOYER AUSSI LA NOTIFICATION DE MESSAGE (WebSocket existant)
        message_data = {
            'id': instance.id,
            'conversation_id': conversation.id,
            'content': instance.content,
            'sender_id': instance.sender.id,
            'sender_name': sender_name,
            'created_at': instance.created_at.isoformat(),
            'is_read': instance.is_read
        }
        
        # ✅ ENVOYER AVEC GESTION D'ERREUR
        try:
            send_message_notification(recipient.id, message_data)
        except Exception as e:
            print(f"⚠️ Erreur envoi message WebSocket (continue quand même): {e}")
        
        # Envoyer aussi dans le groupe de la conversation
        try:
            if channel_layer:
                async_to_sync(channel_layer.group_send)(
                    f'chat_{conversation.id}',
                    {
                        'type': 'chat_message',
                        'message': message_data
                    }
                )
        except Exception as e:
            print(f"⚠️ Erreur chat WebSocket (continue quand même): {e}")


@receiver(post_save, sender=ProviderVerification)
def provider_verification_status_changed(sender, instance, created, **kwargs):
    """Signal pour les changements de vérification prestataire"""
    if not created:
        # Vérification du changement de statut
        if instance.verification_status == 'verified':
            create_and_send_notification(
                user=instance.provider.user,
                title="Profil vérifié",
                message="Félicitations ! Votre profil a été vérifié. Vous pouvez maintenant proposer vos services.",
                notification_type='profile_verified',
                related_object_id=instance.id
            )
        elif instance.verification_status == 'rejected':
            create_and_send_notification(
                user=instance.provider.user,
                title="Vérification rejetée",
                message=f"Votre demande de vérification a été rejetée. Raison: {instance.rejection_reason or 'Non spécifiée'}",
                notification_type='profile_rejected',
                related_object_id=instance.id
            )

@receiver(post_save, sender=PhoneVerification)
def phone_verification_status_changed(sender, instance, created, **kwargs):
    """Signal pour les changements de vérification téléphone"""
    if not created and instance.status == 'verified':
        create_and_send_notification(
            user=instance.user,
            title="Téléphone vérifié",
            message="Votre numéro de téléphone a été vérifié avec succès ! Vous pouvez maintenant utiliser toutes les fonctionnalités.",
            notification_type='phone_verified',
            related_object_id=instance.id
        )
# ================================================================
# SIGNAUX POUR LES VÉRIFICATIONS (commentés mais prêts)
# ================================================================

# @receiver(post_save, sender=ProviderVerification)
# def provider_verification_status_changed(sender, instance, created, **kwargs):
#     """Signal pour les changements de vérification prestataire"""
#     if not created:
#         if instance.verification_status == 'verified':
#             create_and_send_notification(
#                 user=instance.provider.user,
#                 title="Profil vérifié",
#                 message="Félicitations ! Votre profil a été vérifié. Vous pouvez maintenant proposer vos services.",
#                 notification_type='profile_verified'
#             )
#         elif instance.verification_status == 'rejected':
#             create_and_send_notification(
#                 user=instance.provider.user,
#                 title="Vérification rejetée",
#                 message=f"Votre demande de vérification a été rejetée. Raison: {instance.rejection_reason or 'Non spécifiée'}",
#                 notification_type='profile_rejected'
#             )

# @receiver(post_save, sender=PhoneVerification)
# def phone_verification_status_changed(sender, instance, created, **kwargs):
#     """Signal pour les changements de vérification téléphone"""
#     if not created and instance.status == 'verified':
#         create_and_send_notification(
#             user=instance.user,
#             title="Téléphone vérifié",
#             message="Votre numéro de téléphone a été vérifié avec succès !",
#             notification_type='phone_verified'
#         )
#         return None
    
# from django.db.models.signals import post_save, pre_save
# from django.dispatch import receiver

# # @receiver(post_save, sender=ProviderVerification)
# # def log_provider_verification_change(sender, instance, created, **kwargs):
# #     """Log automatique des changements de vérification prestataire"""
# #     if created:
# #         # Log de création
# #         AdminAction.objects.create(
# #             admin_user=instance.verified_by if instance.verified_by else None,
# #             action_type='provider_verification_create',
# #             target_model='ProviderVerification',
# #             target_id=instance.id,
# #             description=f"Nouvelle demande de vérification pour {instance.provider.user.username}"
# #         )
# #     else:
# #         # Log des changements de statut
# #         if instance.verification_status == 'verified':
# #             AdminAction.objects.create(
# #                 admin_user=instance.verified_by,
# #                 action_type='provider_verification_approve',
# #                 target_model='ProviderVerification',
# #                 target_id=instance.id,
# #                 description=f"Vérification approuvée pour {instance.provider.user.username}"
# #             )
# #         elif instance.verification_status == 'rejected':
# #             AdminAction.objects.create(
# #                 admin_user=instance.verified_by if instance.verified_by else None,
# #                 action_type='provider_verification_reject',
# #                 target_model='ProviderVerification',
# #                 target_id=instance.id,
# #                 description=f"Vérification rejetée pour {instance.provider.user.username}: {instance.rejection_reason}"
# #             )

# @receiver(post_save, sender=PhoneVerification)
# def log_phone_verification_change(sender, instance, created, **kwargs):
#     """Log automatique des changements de vérification téléphone"""
#     if instance.status == 'verified' and instance.verified_at:
#         AdminAction.objects.create( 
#             admin_user=None,  # Action automatique
#             action_type='phone_verification_success',
#             target_model='PhoneVerification',
#             target_id=instance.id,
#             description=f"Vérification téléphone réussie pour {instance.user.username} ({instance.phone_number})"
#         )
