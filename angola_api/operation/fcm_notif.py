


import logging
from .fcm_service import FCMService

logger = logging.getLogger(__name__)

def send_new_message_notification(conversation, message, sender):
    """
    Envoyer une notification pour un nouveau message
    """
    try:
        # Déterminer le destinataire
        recipient = conversation.client if sender != conversation.client else conversation.provider.user
        
        FCMService.send_notification_to_user(
            user=recipient,
            title=f"💬 Nouveau message de {sender.first_name}",
            body=message.content[:100] + ('...' if len(message.content) > 100 else ''),
            notification_type='new_message',
            data={
                'conversation_id': str(conversation.id),
                'sender_id': str(sender.id),
                'message_id': str(message.id),
            },
            click_action='FLUTTER_NOTIFICATION_CLICK'
        )
        
    except Exception as e:
        logger.error(f"Erreur notification nouveau message: {e}")

def send_new_offer_notification(project, offer):
    """
    Envoyer une notification pour une nouvelle offre
    """
    try:
        FCMService.send_notification_to_user(
            user=project.client,
            title=f"💼 Nouvelle offre reçue",
            body=f"{offer.provider.user.first_name} a fait une offre sur votre projet",
            notification_type='new_offer',
            data={
                'project_id': str(project.id),
                'offer_id': str(offer.id),
                'provider_id': str(offer.provider.id),
            },
            click_action='FLUTTER_NOTIFICATION_CLICK'
        )
        
    except Exception as e:
        logger.error(f"Erreur notification nouvelle offre: {e}")

def send_project_update_notification(project, update_type, message):
    """
    Envoyer une notification pour une mise à jour de projet
    """
    try:
        FCMService.send_notification_to_user(
            user=project.client,
            title=f"📋 Mise à jour de projet",
            body=message,
            notification_type='project_update',
            data={
                'project_id': str(project.id),
                'update_type': update_type,
            },
            click_action='FLUTTER_NOTIFICATION_CLICK'
        )
        
    except Exception as e:
        logger.error(f"Erreur notification projet: {e}")