# angola_api/operation/signals.py - VERSION MISE À JOUR AVEC EXTRADATA

from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.utils import timezone
from asgiref.sync import async_to_sync
from .fcm import notify_user_by_fcm
from channels.layers import get_channel_layer
from .fcm_service import FCMService
from operation.models import (
    AdminAction, ClientProject, Dispute, Notification, PhoneVerification, ProjectOffer, ProviderVerification, QuoteRequest, Message
)
import logging


# Obtenir la couche de canal pour WebSocket
channel_layer = get_channel_layer()
logger = logging.getLogger(__name__)

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

def get_fcm_notification_config(notification_type, title, message, related_object_id=None):
    """
    Configurer le titre, message et données pour FCM selon le type de notification
    """
    # Configuration de base
    config = {
        'title': title,
        'body': message,
        'notification_type': notification_type,
        'data': {
            'type': notification_type,
            'timestamp': str(timezone.now().timestamp()),
        }
    }
    
    # Ajouter related_object_id si disponible
    if related_object_id:
        config['data']['related_object_id'] = str(related_object_id)
    
    # Configuration spécifique par type
    if notification_type == 'new_message':
        config['title'] = '💬 ' + title
        config['data']['click_action'] = 'OPEN_CONVERSATION'
        if related_object_id:
            config['data']['conversation_id'] = str(related_object_id)
            
    elif notification_type == 'new_offer':
        config['title'] = '💼 ' + title
        config['data']['click_action'] = 'OPEN_PROJECT'
        if related_object_id:
            config['data']['offer_id'] = str(related_object_id)
            
    elif notification_type == 'offer_accepted':
        config['title'] = '✅ ' + title
        config['data']['click_action'] = 'OPEN_PROJECT'
        
    elif notification_type == 'offer_rejected':
        config['title'] = '❌ ' + title
        config['data']['click_action'] = 'OPEN_PROJECT'
        
    elif notification_type == 'quote_request':
        config['title'] = '📋 ' + title
        config['data']['click_action'] = 'OPEN_QUOTE'
        if related_object_id:
            config['data']['quote_id'] = str(related_object_id)
            
    elif notification_type == 'quote_accepted':
        config['title'] = '✅ ' + title
        config['data']['click_action'] = 'OPEN_QUOTE'
        
    elif notification_type == 'quote_rejected':
        config['title'] = '❌ ' + title
        config['data']['click_action'] = 'OPEN_QUOTE'
        
    elif notification_type == 'quote_completed':
        config['title'] = '🎉 ' + title
        config['data']['click_action'] = 'OPEN_QUOTE'
        
    elif notification_type == 'dispute':
        config['title'] = '⚖️ ' + title
        config['data']['click_action'] = 'OPEN_DISPUTE'
        
    elif notification_type == 'profile_verified':
        config['title'] = '✅ ' + title
        config['data']['click_action'] = 'OPEN_PROFILE'
        
    elif notification_type == 'profile_rejected':
        config['title'] = '❌ ' + title
        config['data']['click_action'] = 'OPEN_VERIFICATION'
        
    elif notification_type == 'phone_verified':
        config['title'] = '📱 ' + title
        config['data']['click_action'] = 'OPEN_PROFILE'
        
    return config

# ✅ FONCTION UTILITAIRE MISE À JOUR AVEC SUPPORT DES EXTRA_DATA
def create_and_send_notification(user, title, message, notification_type, related_object_id=None, extra_data=None):
    """
    Fonction utilitaire pour créer une notification et l'envoyer via WebSocket + FCM
    ROBUSTE : Ne lève jamais d'exception, continue toujours
    NOUVEAU : Support des extra_data pour la navigation précise
    """

    logger.info(f"🔔 NOTIFICATION: user={user.email}, type={notification_type}, title={title[:30]}...")
    logger.info(f"🔔 user {user}")
    logger.info(f"🔔 title {title} ")
    logger.info(f"🔔 related_object_id {related_object_id}")
    logger.info(f"🔔 extra_data {extra_data} ")
    logger.info(f"🔔 notification_type {notification_type}")
    
    try:
        # Créer la notification en base avec extra_data
        notification = Notification.objects.create(
            user=user,
            title=title,
            message=message,
            notification_type=notification_type,
            related_object_id=related_object_id,
            extra_data=extra_data  # ✅ NOUVEAU : Support des données supplémentaires
        )
        
        logger.info(f"✅ DB NOTIFICATION: id={notification.id}")
        
        # Préparer les données pour WebSocket
        notification_data = {
            'id': notification.id,
            'title': notification.title,
            'message': notification.message,
            'notification_type': notification.notification_type,
            'related_object_id': notification.related_object_id,
            'is_read': notification.is_read,
            'extra_data': notification.extra_data,  # ✅ NOUVEAU : Inclure les données supplémentaires
            'created_at': notification.created_at.isoformat(),
        }
        
        # ✅ ENVOYER VIA FCM (code existant conservé)
        try:
            logger.info(f"🚀 FCM START pour user {user.email}")
            
            # Vérifier tokens FCM
            fcm_tokens = user.fcm_tokens.filter(is_active=True)
            logger.info(f"🔑 FCM TOKENS: {fcm_tokens.count()} actifs")
            
            if not fcm_tokens.exists():
                logger.warning(f"⚠️ AUCUN TOKEN FCM pour {user.email}")
                return notification
            
            # Config FCM
            fcm_config = get_fcm_notification_config(
                notification_type=notification_type,
                title=title,
                message=message,
                related_object_id=related_object_id
            )
            
            # Ajouter extra_data si disponible
            if extra_data:
                fcm_config['data'].update({'extra_data': str(extra_data)})
            
            # Envoi FCM
            logger.info(f"🔑 FCM TOKENS:{fcm_config['title']}")
            logger.info(f"🔑 FCM TOKENS: {fcm_config['body']}")
            logger.info(f"🔑 FCM TOKENS: {fcm_config['notification_type']}")
            logger.info(f"🔑 FCM TOKENS: {fcm_config['data']}")
            logger.info(f"🔑 FCM TOKENS: {fcm_config['data'].get('click_action', 'FLUTTER_NOTIFICATION_CLICK')}")
            logger.info(f"🔑 USER {user.id}")

            # 🆕 AJOUT DE DEBUG AVANT L'APPEL
            logger.info(f"🚀 AVANT APPEL FCMService.send_notification_to_user")
            logger.info(f"🚀 Type FCMService: {type(FCMService)}")
            logger.info(f"🚀 Méthode existe?: {hasattr(FCMService, 'send_notification_to_user')}")

            # 🆕 TEST AVEC TRY/EXCEPT DÉTAILLÉ
            try:
                logger.info(f"🚀 APPEL EN COURS...")
                fcm_success = FCMService.send_notification_to_user(
                    user.id,
                    fcm_config['title'],
                    fcm_config['body'],
                    fcm_config['notification_type'],
                    fcm_config['data'],
                    fcm_config['data'].get('click_action', 'FLUTTER_NOTIFICATION_CLICK')
                )
                logger.info(f"🚀 APPEL TERMINÉ - Résultat: {fcm_success}")
            except Exception as call_error:
                logger.error(f"🚀 EXCEPTION LORS DE L'APPEL: {call_error}")
                logger.error(f"🚀 Type erreur: {type(call_error)}")
                import traceback
                logger.error(f"🚀 Traceback: {traceback.format_exc()}")
                fcm_success = False

            logger.info(f"🎯 FCM RESULT: {fcm_success}")
            
        except Exception as fcm_error:
            logger.error(f"❌ FCM ERROR pour {user.email}: {fcm_error}")
        

        # Envoyer via WebSocket (avec gestion d'erreur)
        try:
            send_notification_to_user(user.id, notification_data)
            print(f"✅ Notification WebSocket envoyée pour user {user.id}")
        except Exception as ws_error:
            print(f"⚠️ Erreur WebSocket notification (continue quand même): {ws_error}")
        
        # Mettre à jour le compteur (avec gestion d'erreur)
        try:
            unread_count = Notification.objects.filter(user=user, is_read=False).count()
            send_unread_count_update(user.id, unread_count)
            print(f"✅ Compteur mis à jour pour user {user.id}: {unread_count}")
        except Exception as count_error:
            print(f"⚠️ Erreur compteur notifications (continue quand même): {count_error}")
        
        print(f"✅ Notification complète envoyée avec succès: {notification.id}")
        return notification
        
    except Exception as e:
        print(f"❌ Erreur création notification (continue quand même): {e}")
        return None



# def create_and_send_notification(user, title, message, notification_type, related_object_id=None, extra_data=None):
#     """
#     Fonction utilitaire pour créer une notification et l'envoyer via WebSocket + FCM
#     ROBUSTE : Ne lève jamais d'exception, continue toujours
#     NOUVEAU : Support des extra_data pour la navigation précise
#     """

#     logger.info(f"🔔 NOTIFICATION: user={user.email}, type={notification_type}, title={title[:30]}...")
#     logger.info(f"🔔 user {user}")
#     logger.info(f"🔔 title {title} ")
#     logger.info(f"🔔 related_object_id {related_object_id}")
#     logger.info(f"🔔 extra_data {extra_data} ")
#     logger.info(f"🔔 notification_type {notification_type}")
    
#     try:
#         # Créer la notification en base avec extra_data
#         notification = Notification.objects.create(
#             user=user,
#             title=title,
#             message=message,
#             notification_type=notification_type,
#             related_object_id=related_object_id,
#             # extra_data=extra_data  # ✅ NOUVEAU : Support des données supplémentaires
#         )
        
#         logger.info(f"✅ DB NOTIFICATION: id={notification.id}")
        
#         # Préparer les données pour WebSocket
#         notification_data = {
#             'id': notification.id,
#             'title': notification.title,
#             'message': notification.message,
#             'notification_type': notification.notification_type,
#             'related_object_id': notification.related_object_id,
#             'is_read': notification.is_read,
#             # 'extra_data': notification.extra_data,  # ✅ NOUVEAU : Inclure les données supplémentaires
#             'created_at': notification.created_at.isoformat(),
#         }
        

        
#         # ESSAYER UN NOUVEL ENVOI DE NOTIFICATION FCM
#         logger.info(f"🗑️ On tente le second envoi")
#         data= {
#                 "type": notification_type,
#                 "notification_id": str(notification.id),
#                 **notification_data
#             }
#         logger.info(f"🔔 user {user}")
#         logger.info(f"🔔 title {title} ")
#         logger.info(f"🔔 body {notification.message[:100] + "..." if len(notification.message) > 100 else notification.message,}")
#         logger.info(f"🔔 data {data} ")
#         logger.info(f"🔔 notification_type {notification_type}")

#         try:
#             fcm_result= notify_user_by_fcm(
#                 user,
#                 notification.title,
#                 notification.message[:100] + "..." if len(notification.message) > 100 else notification.message,
#                 data
#             )
#             logger.info(f"Seconde tentative terminée")
#             if fcm_result:
#                 logger.info(f"✅ [NOTIF] FCM envoyé avec succès pour notification {notification.id}")
#             else:
#                 logger.warning(f"⚠️ [NOTIF] Échec de l'envoi FCM pour notification {notification.id}")
#                 # return notification
#         except Exception as fcm_error:
#             logger.error(f"❌ FCM secondaire ERROR: {fcm_error}")
       

#         # ✅ ENVOYER VIA FCM (code existant conservé)
#         try:
#             logger.info(f"🚀 FCM START pour user {user.email}")
            
#             # Vérifier tokens FCM
#             fcm_tokens = user.fcm_tokens.filter(is_active=True)
#             logger.info(f"🔑 FCM TOKENS: {fcm_tokens.count()} actifs")
            
#             if not fcm_tokens.exists():
#                 logger.warning(f"⚠️ AUCUN TOKEN FCM pour {user.email}")
#                 return notification
            
#             # Config FCM
#             fcm_config = get_fcm_notification_config(
#                 notification_type=notification_type,
#                 title=title,
#                 message=message,
#                 related_object_id=related_object_id
#             )
            
#             # Ajouter extra_data si disponible
#             # if extra_data:
#             #     fcm_config['data'].update({'extra_data': str(extra_data)})
            
#             # Envoi FCM
#             logger.info(f"🔑 FCM TOKENS:{fcm_config['title']}")
#             logger.info(f"🔑 FCM TOKENS: {fcm_config['body']}")
#             logger.info(f"🔑 FCM TOKENS: {fcm_config['notification_type']}")
#             logger.info(f"🔑 FCM TOKENS: {fcm_config['data']}")
#             logger.info(f"🔑 FCM TOKENS: {fcm_config['data'].get('click_action', 'FLUTTER_NOTIFICATION_CLICK')}")
#             logger.info(f"🔑 USER {user.id}")

#             # 🆕 AJOUT DE DEBUG AVANT L'APPEL
#             logger.info(f"🚀 AVANT APPEL FCMService.send_notification_to_user")
#             logger.info(f"🚀 Type FCMService: {type(FCMService)}")
#             logger.info(f"🚀 Méthode existe?: {hasattr(FCMService, 'send_notification_to_user')}")

#             # 🆕 TEST AVEC TRY/EXCEPT DÉTAILLÉ
#             try:
#                 logger.info(f"🚀 APPEL EN COURS...")
#                 fcm_success = FCMService.send_notification_to_user(
#                     user.id,
#                     fcm_config['title'],
#                     fcm_config['body'],
#                     fcm_config['notification_type'],
#                     fcm_config['data'],
#                     fcm_config['data'].get('click_action', 'FLUTTER_NOTIFICATION_CLICK')
#                 )
#                 logger.info(f"🚀 APPEL TERMINÉ - Résultat: {fcm_success}")
#             except Exception as call_error:
#                 logger.error(f"🚀 EXCEPTION LORS DE L'APPEL: {call_error}")
#                 logger.error(f"🚀 Type erreur: {type(call_error)}")
#                 import traceback
#                 logger.error(f"🚀 Traceback: {traceback.format_exc()}")
#                 fcm_success = False

#             logger.info(f"🎯 FCM RESULT: {fcm_success}")
            
#         except Exception as fcm_error:
#             logger.error(f"❌ FCM ERROR pour {user.email}: {fcm_error}")
        

#         # Envoyer via WebSocket (avec gestion d'erreur)
#         try:
#             send_notification_to_user(user.id, notification_data)
#             print(f"✅ Notification WebSocket envoyée pour user {user.id}")
#         except Exception as ws_error:
#             print(f"⚠️ Erreur WebSocket notification (continue quand même): {ws_error}")
        
#         # Mettre à jour le compteur (avec gestion d'erreur)
#         try:
#             unread_count = Notification.objects.filter(user=user, is_read=False).count()
#             send_unread_count_update(user.id, unread_count)
#             print(f"✅ Compteur mis à jour pour user {user.id}: {unread_count}")
#         except Exception as count_error:
#             print(f"⚠️ Erreur compteur notifications (continue quand même): {count_error}")
        
#         print(f"✅ Notification complète envoyée avec succès: {notification.id}")
#         return notification
        
#     except Exception as e:
#         print(f"❌ Erreur création notification (continue quand même): {e}")
#         return None
# ================================================================
# ✅ NOUVELLES FONCTIONS SPÉCIALISÉES POUR CRÉER LES EXTRADATA
# ================================================================

def create_message_notification_with_extradata(message, conversation):
    """Créer une notification de message avec les bonnes extraData"""
    
    # Déterminer qui est l'expéditeur et le destinataire
    if message.sender == conversation.client:
        # Message de client vers prestataire
        recipient = conversation.provider.user
        sender = conversation.client
        sender_company_name = None
    else:
        # Message de prestataire vers client
        recipient = conversation.client
        sender = message.sender
        sender_company_name = getattr(conversation.provider, 'company_name', None)
    
    # Créer les extraData adaptées à votre classe Person
    extra_data = {
        'conversation_id': conversation.id,
        'sender_id': sender.id,
        'sender_username': sender.username,
        'sender_first_name': sender.first_name,
        'sender_last_name': sender.last_name,
        'sender_avatar': sender.profile_picture.url if sender.profile_picture else None,
        'sender_company_name': sender_company_name,
    }
    
    # Déterminer le nom d'affichage
    if sender_company_name:
        sender_display = sender_company_name
    else:
        sender_display = sender.get_full_name() or sender.username
    
    # Créer la notification avec extraData
    create_and_send_notification(
        user=recipient,
        title="Nouveau message",
        message=f"Vous avez reçu un nouveau message de {sender_display}",
        notification_type='new_message',
        related_object_id=conversation.id,
        extra_data=extra_data  # ✅ NOUVEAU
    )

def create_project_offer_notification_with_extradata(offer, project):
    """Créer une notification d'offre de projet avec les bonnes extraData"""
    
    provider_user = offer.provider.user
    
    # Créer les extraData pour la navigation
    extra_data = {
        'project_id': project.id,
        'offer_id': offer.id,
        'provider_id': offer.provider.id,
        'provider_username': provider_user.username,
        'provider_first_name': provider_user.first_name,
        'provider_last_name': provider_user.last_name,
        'provider_avatar': provider_user.profile_picture.url if provider_user.profile_picture else None,
        'provider_company_name': getattr(offer.provider, 'company_name', None),
        'offer_price': str(offer.proposed_price),
        'offer_delivery_time': offer.delivery_time,
    }
    
    # Déterminer le nom d'affichage du prestataire
    company_name = getattr(offer.provider, 'company_name', None)
    provider_display = company_name if company_name else (provider_user.get_full_name() or provider_user.username)
    
    # Créer la notification avec extraData
    create_and_send_notification(
        user=project.client,
        title="Nouvelle offre reçue",
        message=f"Vous avez reçu une nouvelle offre de {provider_display} pour votre projet '{project.title}'.",
        notification_type='new_offer',
        related_object_id=offer.id,
        extra_data=extra_data  # ✅ NOUVEAU
    )

def create_quote_request_notification_with_extradata(quote_request):
    """Créer une notification de demande de devis avec les bonnes extraData"""
    
    client = quote_request.client
    
    # Créer les extraData pour la navigation
    extra_data = {
        'quote_id': quote_request.id,
        'client_id': client.id,
        'client_username': client.username,
        'client_first_name': client.first_name,
        'client_last_name': client.last_name,
        'client_avatar': client.profile_picture.url if client.profile_picture else None,
        'service_id': quote_request.service.id if quote_request.service else None,
        'budget': str(quote_request.budget) if quote_request.budget else None,
    }
    
    client_display = client.get_full_name() or client.username
    
    # Créer la notification avec extraData
    create_and_send_notification(
        user=quote_request.provider.user,
        title="Nouvelle demande de devis",
        message=f"Vous avez reçu une nouvelle demande de devis pour '{quote_request.subject}' de la part de {client_display}.",
        notification_type='quote_request',
        related_object_id=quote_request.id,
        extra_data=extra_data  # ✅ NOUVEAU
    )

def create_quote_status_notification_with_extradata(quote_request, status):
    """Créer une notification de changement de statut de devis avec extraData"""
    
    provider_user = quote_request.provider.user
    
    # Créer les extraData pour la navigation
    extra_data = {
        'quote_id': quote_request.id,
        'provider_id': quote_request.provider.id,
        'provider_username': provider_user.username,
        'provider_first_name': provider_user.first_name,
        'provider_last_name': provider_user.last_name,
        'provider_avatar': provider_user.profile_picture.url if provider_user.profile_picture else None,
        'provider_company_name': getattr(quote_request.provider, 'company_name', None),
        'service_id': quote_request.service.id if quote_request.service else None,
    }
    
    company_name = getattr(quote_request.provider, 'company_name', None)
    provider_display = company_name if company_name else (provider_user.get_full_name() or provider_user.username)
    
    if status == 'accepted':
        create_and_send_notification(
            user=quote_request.client,
            title="Devis accepté",
            message=f"Votre demande de devis '{quote_request.subject}' a été acceptée par {provider_display}. Vous pouvez maintenant contacter le prestataire.",
            notification_type='quote_accepted',
            related_object_id=quote_request.id,
            extra_data=extra_data  # ✅ NOUVEAU
        )
    elif status == 'rejected':
        create_and_send_notification(
            user=quote_request.client,
            title="Devis rejeté",
            message=f"Votre demande de devis '{quote_request.subject}' a été rejetée par {provider_display}.",
            notification_type='quote_rejected',
            related_object_id=quote_request.id,
            extra_data=extra_data  # ✅ NOUVEAU
        )
    elif status == 'completed':
        # Notification pour le client
        create_and_send_notification(
            user=quote_request.client,
            title="Prestation terminée",
            message=f"La prestation '{quote_request.subject}' a été marquée comme terminée. N'oubliez pas de laisser un avis !",
            notification_type='quote_completed',
            related_object_id=quote_request.id,
            extra_data=extra_data  # ✅ NOUVEAU
        )
        
        # Notification pour le prestataire
        create_and_send_notification(
            user=provider_user,
            title="Prestation terminée",
            message=f"Vous avez marqué la prestation '{quote_request.subject}' comme terminée.",
            notification_type='quote_completed',
            related_object_id=quote_request.id,
            extra_data=extra_data  # ✅ NOUVEAU
        )

def create_offer_status_notification_with_extradata(offer, status):
    """Créer une notification de changement de statut d'offre avec extraData"""
    
    # Créer les extraData pour la navigation
    extra_data = {
        'project_id': offer.project.id,
        'offer_id': offer.id,
        'client_id': offer.project.client.id,
        'client_username': offer.project.client.username,
        'client_first_name': offer.project.client.first_name,
        'client_last_name': offer.project.client.last_name,
        'client_avatar': offer.project.client.profile_picture.url if offer.project.client.profile_picture else None,
    }
    
    if status == 'accepted':
        create_and_send_notification(
            user=offer.provider.user,
            title="Offre acceptée",
            message=f"Votre offre pour le projet '{offer.project.title}' a été acceptée ! Le client va vous contacter.",
            notification_type='offer_accepted',
            related_object_id=offer.id,
            extra_data=extra_data  # ✅ NOUVEAU
        )
    elif status == 'rejected':
        create_and_send_notification(
            user=offer.provider.user,
            title="Offre rejetée",
            message=f"Votre offre pour le projet '{offer.project.title}' a été rejetée.",
            notification_type='offer_rejected',
            related_object_id=offer.id,
            extra_data=extra_data  # ✅ NOUVEAU
        )

# ================================================================
# ✅ SIGNAUX MODIFIÉS POUR UTILISER LES NOUVELLES FONCTIONS EXTRADATA
# ================================================================

@receiver(post_save, sender=Message)
def message_created(sender, instance, created, **kwargs):
    """Signal pour les nouveaux messages - MISE À JOUR AVEC EXTRADATA"""

    logger.info(f"📨 SIGNAL MESSAGE: created={created}, id={instance.id}, sender={instance.sender.email}")

    if created:
        conversation = instance.conversation
        
        logger.info(f"💬 CONVERSATION: id={conversation.id}, client={conversation.client.email}, provider={conversation.provider.user.email}")
        
        # ✅ NOUVEAU : Utiliser la fonction avec extraData
        try:
            # ✅ Appel fonction notification
            create_message_notification_with_extradata(instance, conversation)
            logger.info(f"✅ NOTIFICATION CRÉÉE pour message {instance.id}")
        except Exception as e:
            logger.error(f"❌ ERREUR NOTIFICATION message {instance.id}: {e}")
        
        # Déterminer qui doit recevoir la notification pour les WebSockets classiques
        if instance.sender == conversation.client:
            recipient = conversation.provider.user
            sender_name = conversation.client.get_full_name() or conversation.client.username
        else:
            recipient = conversation.client
            sender_name = conversation.provider.user.get_full_name() or conversation.provider.user.username
        
        # 📱 ENVOYER AUSSI LA NOTIFICATION DE MESSAGE (WebSocket existant - conservé)
        message_data = {
            'id': instance.id,
            'conversation_id': conversation.id,
            'content': instance.content,
            'sender_id': instance.sender.id,
            'sender_name': sender_name,
            'created_at': instance.created_at.isoformat(),
            'is_read': instance.is_read
        }
        
        # ✅ ENVOYER AVEC GESTION D'ERREUR (code existant conservé)
        try:
            send_message_notification(recipient.id, message_data)
        except Exception as e:
            print(f"⚠️ Erreur envoi message WebSocket (continue quand même): {e}")
        
        # Envoyer aussi dans le groupe de la conversation (code existant conservé)
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

@receiver(post_save, sender=QuoteRequest)
def quote_request_status_changed(sender, instance, created, **kwargs):
    """Signal pour les changements de statut des demandes de devis - MISE À JOUR AVEC EXTRADATA"""
    if created:
        # ✅ NOUVEAU : Utiliser la fonction avec extraData
        create_quote_request_notification_with_extradata(instance)
    else:
        # Notifications pour les changements de statut
        if instance.status in ['accepted', 'rejected', 'completed']:
            # ✅ NOUVEAU : Utiliser la fonction avec extraData
            create_quote_status_notification_with_extradata(instance, instance.status)

@receiver(post_save, sender=ProjectOffer)
def project_offer_status_changed(sender, instance, created, **kwargs):
    """Signal pour les changements de statut des offres sur les projets - MISE À JOUR AVEC EXTRADATA"""
    if created:
        # ✅ NOUVEAU : Utiliser la fonction avec extraData
        create_project_offer_notification_with_extradata(instance, instance.project)
    else:
        # Notifications pour les changements de statut d'offre
        if instance.status in ['accepted', 'rejected']:
            # ✅ NOUVEAU : Utiliser la fonction avec extraData
            create_offer_status_notification_with_extradata(instance, instance.status)

# ================================================================
# SIGNAUX EXISTANTS CONSERVÉS (PAS DE CHANGEMENT)
# ================================================================

@receiver(post_save, sender=Dispute)
def dispute_status_changed(sender, instance, created, **kwargs):
    """Signal quand le statut d'un litige change"""
    if not created and instance.status == 'resolved':
        # ✅ NOUVEAU : Ajouter des extraData pour les litiges
        extra_data = {
            'dispute_id': instance.id,
            'dispute_title': instance.title,
            'related_type': 'quote_request' if hasattr(instance, 'quote_request') else 'project',
            'related_id': getattr(instance, 'quote_request_id', None) or getattr(instance, 'project_id', None),
        }
        
        create_and_send_notification(
            user=instance.client,
            title="Litige résolu",
            message=f"Votre litige '{instance.title}' a été résolu.",
            notification_type='dispute',
            related_object_id=instance.id,
            extra_data=extra_data  # ✅ NOUVEAU
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
# ✅ FONCTIONS UTILITAIRES CONSERVÉES (code existant)
# ================================================================

def send_test_fcm_notification(user, notification_type='test'):
    """
    Fonction utilitaire pour envoyer une notification FCM de test
    Utile pour débugger ou tester les notifications
    """
    try:
        test_messages = {
            'test': {
                'title': 'Test FCM',
                'message': 'Ceci est une notification de test FCM depuis les signaux'
            },
            'new_message': {
                'title': 'Test nouveau message',
                'message': 'Test d\'un nouveau message via FCM'
            },
            'new_offer': {
                'title': 'Test nouvelle offre',
                'message': 'Test d\'une nouvelle offre via FCM'
            }
        }
        
        config = test_messages.get(notification_type, test_messages['test'])
        
        return create_and_send_notification(
            user=user,
            title=config['title'],
            message=config['message'],
            notification_type=notification_type
        )
        
    except Exception as e:
        print(f"❌ Erreur test FCM: {e}")
        return None

def send_bulk_notification(users, title, message, notification_type='general'):
    """
    Envoyer une notification à plusieurs utilisateurs
    Utile pour les annonces système
    """
    success_count = 0
    error_count = 0
    
    for user in users:
        try:
            notification = create_and_send_notification(
                user=user,
                title=title,
                message=message,
                notification_type=notification_type
            )
            if notification:
                success_count += 1
            else:
                error_count += 1
        except Exception as e:
            print(f"❌ Erreur notification bulk pour user {user.id}: {e}")
            error_count += 1
    
    print(f"📊 Notifications en masse: {success_count} succès, {error_count} erreurs")
    return {'success': success_count, 'errors': error_count}