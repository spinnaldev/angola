# angola_api/operation/fcm_service.py - Service pour envoyer les notifications FCM

import json
import logging
from typing import List, Dict, Optional, Union
from django.conf import settings
from django.utils import timezone
from firebase_admin import messaging, credentials, initialize_app
from .models import User, FCMToken, NotificationHistory, NotificationPreference

logger = logging.getLogger(__name__)

class FCMService:
    """
    Service pour gérer l'envoi de notifications Firebase Cloud Messaging
    """
    
    _initialized = False
    
    @classmethod
    def initialize(cls):
        """
        Initialiser Firebase Admin SDK
        """
        if cls._initialized:
            return
        
        try:
            # Initialiser Firebase avec les credentials
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
            initialize_app(cred)
            cls._initialized = True
            logger.info("✅ Firebase Admin SDK initialisé")
        except Exception as e:
            logger.error(f"❌ Erreur initialisation Firebase: {e}")
            raise
    
    @classmethod
    def send_notification_to_user(
        cls, 
        user: User, 
        title: str, 
        body: str, 
        notification_type: str = 'general',
        data: Optional[Dict] = None,
        click_action: Optional[str] = None
    ) -> bool:
        """
        Envoyer une notification à un utilisateur spécifique
        """
        cls.initialize()
        
        if not user.has_fcm_tokens():
            logger.warning(f"Aucun token FCM pour l'utilisateur {user.email}")
            return False
        
        # Vérifier les préférences de notification
        preferences = user.get_notification_preferences()
        if not cls._should_send_notification(preferences, notification_type):
            logger.info(f"Notification {notification_type} désactivée pour {user.email}")
            return False
        
        # Récupérer les tokens actifs
        fcm_tokens = user.get_active_fcm_tokens()
        tokens = [token.token for token in fcm_tokens]
        
        if not tokens:
            logger.warning(f"Aucun token FCM actif pour {user.email}")
            return False
        
        return cls._send_to_tokens(
            tokens=tokens,
            title=title,
            body=body,
            notification_type=notification_type,
            data=data,
            click_action=click_action,
            user=user
        )
    
    @classmethod
    def send_notification_to_users(
        cls,
        users: List[User],
        title: str,
        body: str,
        notification_type: str = 'general',
        data: Optional[Dict] = None,
        click_action: Optional[str] = None
    ) -> Dict[str, int]:
        """
        Envoyer une notification à plusieurs utilisateurs
        """
        cls.initialize()
        
        results = {'success': 0, 'failed': 0}
        
        for user in users:
            try:
                success = cls.send_notification_to_user(
                    user=user,
                    title=title,
                    body=body,
                    notification_type=notification_type,
                    data=data,
                    click_action=click_action
                )
                if success:
                    results['success'] += 1
                else:
                    results['failed'] += 1
            except Exception as e:
                logger.error(f"Erreur envoi notification à {user.email}: {e}")
                results['failed'] += 1
        
        return results
    
    @classmethod
    def send_topic_notification(
        cls,
        topic: str,
        title: str,
        body: str,
        notification_type: str = 'general',
        data: Optional[Dict] = None,
        click_action: Optional[str] = None
    ) -> bool:
        """
        Envoyer une notification à un topic
        """
        cls.initialize()
        
        try:
            # Préparer le message
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data or {},
                topic=topic,
                android=messaging.AndroidConfig(
                    notification=messaging.AndroidNotification(
                        icon='ic_notification',
                        color='#142FE2',
                        sound='default',
                        click_action=click_action,
                    ),
                    priority='high',
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            alert=messaging.ApsAlert(
                                title=title,
                                body=body,
                            ),
                            badge=1,
                            sound='default',
                        ),
                    ),
                ),
            )
            
            # Envoyer le message
            response = messaging.send(message)
            logger.info(f"✅ Notification topic envoyée: {response}")
            return True
            
        except Exception as e:
            logger.error(f"❌ Erreur envoi notification topic {topic}: {e}")
            return False
    
    @classmethod
    def _send_to_tokens(
        cls,
        tokens: List[str],
        title: str,
        body: str,
        notification_type: str,
        data: Optional[Dict] = None,
        click_action: Optional[str] = None,
        user: Optional[User] = None
    ) -> bool:
        """
        Envoyer une notification à une liste de tokens
        """
        try:
            # Préparer les données
            notification_data = data or {}
            notification_data.update({
                'type': notification_type,
                'timestamp': str(timezone.now().timestamp()),
                'click_action': click_action or 'FLUTTER_NOTIFICATION_CLICK',
            })
            
            # Créer le message
            message = messaging.MulticastMessage(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data={k: str(v) for k, v in notification_data.items()},  # FCM n'accepte que des strings
                tokens=tokens,
                android=messaging.AndroidConfig(
                    notification=messaging.AndroidNotification(
                        icon='ic_notification',
                        color='#142FE2',
                        sound='default',
                        click_action=click_action or 'FLUTTER_NOTIFICATION_CLICK',
                        channel_id='teyago_high_importance',
                    ),
                    priority='high',
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            alert=messaging.ApsAlert(
                                title=title,
                                body=body,
                            ),
                            badge=1,
                            sound='default',
                            category=notification_type,
                        ),
                    ),
                ),
            )
            
            # Envoyer le message
            response = messaging.send_multicast(message)
            
            # Logger les résultats
            logger.info(f"✅ Notification envoyée: {response.success_count}/{len(tokens)}")
            
            # Traiter les échecs
            if response.failure_count > 0:
                cls._handle_failed_tokens(response, tokens, user)
            
            # Enregistrer dans l'historique
            if user:
                cls._save_notification_history(
                    user=user,
                    title=title,
                    body=body,
                    notification_type=notification_type,
                    data=notification_data,
                    status='sent' if response.success_count > 0 else 'failed',
                    firebase_message_id=str(response.responses[0].message_id) if response.responses else None
                )
            
            return response.success_count > 0
            
        except Exception as e:
            logger.error(f"❌ Erreur envoi notifications: {e}")
            
            # Enregistrer l'échec dans l'historique
            if user:
                cls._save_notification_history(
                    user=user,
                    title=title,
                    body=body,
                    notification_type=notification_type,
                    data=data or {},
                    status='failed',
                    error_message=str(e)
                )
            
            return False
    
    @classmethod
    def _handle_failed_tokens(cls, response, tokens: List[str], user: Optional[User] = None):
        """
        Gérer les tokens qui ont échoué
        """
        try:
            for idx, resp in enumerate(response.responses):
                if not resp.success:
                    token = tokens[idx]
                    error = resp.exception
                    
                    logger.warning(f"❌ Échec token {token[:20]}...: {error}")
                    
                    # Si le token est invalide, le désactiver
                    if error and 'registration-token-not-registered' in str(error):
                        FCMToken.objects.filter(token=token).update(is_active=False)
                        logger.info(f"🗑️ Token désactivé: {token[:20]}...")
                        
        except Exception as e:
            logger.error(f"❌ Erreur traitement tokens échecs: {e}")
    
    @classmethod
    def _save_notification_history(
        cls,
        user: User,
        title: str,
        body: str,
        notification_type: str,
        data: Dict,
        status: str,
        firebase_message_id: Optional[str] = None,
        error_message: Optional[str] = None
    ):
        """
        Sauvegarder l'historique de notification
        """
        try:
            NotificationHistory.objects.create(
                user=user,
                title=title,
                body=body,
                notification_type=notification_type,
                data=data,
                status=status,
                firebase_message_id=firebase_message_id,
                error_message=error_message,
                sent_at=timezone.now() if status == 'sent' else None
            )
        except Exception as e:
            logger.error(f"❌ Erreur sauvegarde historique: {e}")
    
    @classmethod
    def _should_send_notification(cls, preferences: NotificationPreference, notification_type: str) -> bool:
        """
        Vérifier si on doit envoyer la notification selon les préférences
        """
        if not preferences.push_notifications:
            return False
        
        type_mapping = {
            'new_message': preferences.messages_enabled,
            'new_offer': preferences.offers_enabled,
            'project_update': preferences.projects_enabled,
            'new_review': preferences.reviews_enabled,
            'system': preferences.system_enabled,
        }
        
        return type_mapping.get(notification_type, True)
    
    @classmethod
    def send_test_notification(cls, user: User) -> bool:
        """
        Envoyer une notification de test
        """
        return cls.send_notification_to_user(
            user=user,
            title="🧪 Test Notification",
            body="Ceci est une notification de test de Teyago Services",
            notification_type="test",
            data={
                'test': 'true',
                'timestamp': str(timezone.now().timestamp())
            }
        )
    
    @classmethod
    def clean_inactive_tokens(cls, days: int = 30):
        """
        Nettoyer les tokens inactifs
        """
        cutoff_date = timezone.now() - timezone.timedelta(days=days)
        deleted_count = FCMToken.objects.filter(
            last_used__lt=cutoff_date,
            is_active=False
        ).delete()[0]
        
        logger.info(f"🧹 {deleted_count} tokens inactifs supprimés")
        return deleted_count