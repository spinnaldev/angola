# angola_api/operation/fcm_service.py - Service pour envoyer les notifications FCM

import json
import logging
from typing import List, Dict, Optional, Union
from django.conf import settings
from django.utils import timezone
from firebase_admin import messaging, credentials, initialize_app
from .models import User, FCMToken, NotificationHistory, NotificationPreference


import logging
logger = logging.getLogger('operation.signals') 

class FCMService:
    """
    Service pour gérer l'envoi de notifications Firebase Cloud Messaging
    """
    
    _initialized = False
    
    
    @classmethod
    def initialize(cls):
        """
        Initialiser Firebase Admin SDK - VERSION DEBUG
        """
        if cls._initialized:
            logger.info(f"🔥 Firebase already initialized")
            return
        
        try:
            logger.info(f"🔥 Initializing Firebase Admin SDK...")
            logger.info(f"📁 FIREBASE_CREDENTIALS_PATH: {getattr(settings, 'FIREBASE_CREDENTIALS_PATH', 'NOT SET')}")
            
            # Vérifier que le fichier existe
            import os
            credentials_path = settings.FIREBASE_CREDENTIALS_PATH
            
            if not os.path.exists(credentials_path):
                logger.error(f"❌ Firebase credentials file not found: {credentials_path}")
                raise FileNotFoundError(f"Firebase credentials file not found: {credentials_path}")
                
            logger.info(f"✅ Firebase credentials file found")
            
            # Initialiser Firebase avec les credentials
            cred = credentials.Certificate(credentials_path)
            logger.info(f"✅ Certificate created from file")
            
            initialize_app(cred)
            cls._initialized = True
            logger.info(f"✅ Firebase Admin SDK initialized successfully")
            
        except Exception as e:
            logger.error(f"❌ Firebase initialization error: {str(e)}")
            logger.error(f"❌ Exception type: {type(e)}")
            
            import traceback
            logger.error(f"❌ Traceback: {traceback.format_exc()}")
            raise

    
    @classmethod
    def send_notification_to_user(
        cls,  
        user: int, 
        title: str, 
        body: str, 
        notification_type: str = 'general',
        data: Optional[Dict] = None,
        click_action: Optional[str] = None
    ) -> bool:
        """
        Envoyer une notification à un utilisateur spécifique
        """
        logger.info(f"L'id est {user}")  # ✅ Corrigé le f-string

        user_obj = User.objects.filter(id=user).first()  # ✅ Renommé pour éviter confusion
        
        if not user_obj:  # ✅ AJOUTÉ : Vérifier que l'utilisateur existe
            logger.error(f"❌ Utilisateur avec ID {user} introuvable")
            return False
        
        logger.info(f"🎯 FCM START - User: {user_obj.email}, Type: {notification_type}")

        # ❌ SUPPRIMÉ : cls= FCMService() (incorrect pour classmethod)
        
        try:
            cls.initialize()  # ✅ Utilisation correcte de cls
            logger.info(f"✅ FCM initialized successfully")
        except Exception as init_error:
            logger.error(f"❌ FCM initialization failed: {init_error}")
            return False
        
        if not user_obj.has_fcm_tokens():  # ✅ Utiliser user_obj
            logger.warning(f"❌ Aucun token FCM pour l'utilisateur {user_obj.email}")
            return False
        
        logger.info(f"✅ User has FCM tokens")
        
        # Vérifier les préférences de notification
        try:
            preferences = user_obj.get_notification_preferences()  # ✅ Utiliser user_obj
            logger.info(f"✅ Preferences retrieved: push_enabled={preferences.push_notifications}")
        except Exception as pref_error:
            logger.error(f"❌ Error getting preferences: {pref_error}")
            return False
        
        if not cls._should_send_notification(preferences, notification_type):
            logger.info(f"❌ Notification {notification_type} désactivée pour {user_obj.email}")
            return False
        
        logger.info(f"✅ Notification allowed by preferences")
        
        # Récupérer les tokens actifs
        try:
            fcm_tokens = user_obj.get_active_fcm_tokens()  # ✅ Utiliser user_obj
            tokens = [token.token for token in fcm_tokens]
            logger.info(f"✅ Retrieved {len(tokens)} active tokens")
            logger.info(f"🔑 First token preview: {tokens[0][:20] if tokens else 'NONE'}...")
        except Exception as token_error:
            logger.error(f"❌ Error getting tokens: {token_error}")
            return False
        
        if not tokens:
            logger.warning(f"❌ Aucun token FCM actif pour {user_obj.email}")
            return False
        
        # Appeler _send_to_tokens avec logging détaillé
        try:
            logger.info(f"🚀 Calling _send_to_tokens...")
            result = cls._send_to_tokens(
                tokens=tokens,
                title=title,
                body=body,
                notification_type=notification_type,
                data=data,
                click_action=click_action,
                user=user_obj  # ✅ Utiliser user_obj
            )
            logger.info(f"🎯 _send_to_tokens result: {result}")
            return result
        except Exception as send_error:
            logger.error(f"❌ Error in _send_to_tokens: {send_error}")
            return False
    
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
        Envoyer une notification à une liste de tokens - VERSION COMPATIBLE
        """
        logger.info(f"📤 _send_to_tokens START")
        logger.info(f"📝 Tokens: {len(tokens)}")
        logger.info(f"📝 Title: {title}")
        logger.info(f"📝 Body: {body}")
        logger.info(f"📝 Type: {notification_type}")
        
        # Préparer les données
        notification_data = data or {}
        notification_data.update({
            'type': notification_type,
            'timestamp': str(timezone.now().timestamp()),
            'click_action': click_action or 'FLUTTER_NOTIFICATION_CLICK',
        })
        
        logger.info(f"📝 Notification data prepared: {notification_data}")
        
        # ✅ UTILISER send() POUR CHAQUE TOKEN (compatible toutes versions)
        success_count = 0
        failure_count = 0
        failed_tokens = []
        message_ids = []
        
        for token in tokens:
            try:
                logger.info(f"🚀 Sending to token: {token[:20]}...")
                
                # Créer un message individuel
                message = messaging.Message(
                    notification=messaging.Notification(
                        title=title,
                        body=body,
                    ),
                    data={k: str(v) for k, v in notification_data.items()},
                    token=token,  # ✅ Un seul token au lieu de tokens=
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
                
                # Envoyer le message (compatible toutes versions)
                message_id = messaging.send(message)
                
                logger.info(f"✅ Token SUCCESS - Message ID: {message_id}")
                success_count += 1
                message_ids.append(message_id)
                
            except Exception as token_error:
                logger.error(f"❌ Token FAILED - Error: {token_error}")
                failure_count += 1
                failed_tokens.append(token)
                
                # Désactiver les tokens invalides
                if 'registration-token-not-registered' in str(token_error):
                    FCMToken.objects.filter(token=token).update(is_active=False)
                    logger.info(f"🗑️ Token désactivé: {token[:20]}...")
        
        # Logger les résultats finaux
        logger.info(f"📨 Firebase response completed:")
        logger.info(f"   - Success count: {success_count}")
        logger.info(f"   - Failure count: {failure_count}")
        
        # Enregistrer dans l'historique (avec gestion du firebase_message_id optionnel)
        if user:
            status = 'sent' if success_count > 0 else 'failed'
            logger.info(f"💾 Saving notification history with status: {status}")
            
            try:
                NotificationHistory.objects.create(
                    user=user,
                    title=title,
                    body=body,
                    notification_type=notification_type,
                    data=notification_data,
                    status=status,
                    firebase_message_id=message_ids[0] if message_ids else None,  # ✅ Peut être null maintenant
                    error_message=f"{failure_count} tokens failed" if failure_count > 0 else None,
                    sent_at=timezone.now() if status == 'sent' else None
                )
                logger.info(f"✅ Notification history saved successfully")
            except Exception as history_error:
                logger.error(f"❌ Erreur sauvegarde historique: {history_error}")
        
        result = success_count > 0
        logger.info(f"🏁 _send_to_tokens END - Result: {result}")
        return result
            
        # except Exception as e:
        #     logger.error(f"❌ EXCEPTION in _send_to_tokens: {str(e)}")
        #     logger.error(f"❌ Exception type: {type(e)}")
            
        #     import traceback
        #     logger.error(f"❌ Traceback: {traceback.format_exc()}")
            
        #     # Enregistrer l'échec dans l'historique
        #     if user:
        #         logger.info(f"💾 Saving failed notification in history")
        #         cls._save_notification_history(
        #             user=user,
        #             title=title,
        #             body=body,
        #             notification_type=notification_type,
        #             data=data or {},
        #             status='failed',
        #             error_message=str(e)
        #         )
            
        #     return False
    
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