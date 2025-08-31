import json
import requests
from django.conf import settings
import logging
import firebase_admin
from firebase_admin import credentials, messaging

logger = logging.getLogger(__name__)

# Initialisation unique de Firebase Admin
if not firebase_admin._apps:
    try:
        cred = credentials.Certificate(settings.FIREBASE_CREDENTIAL_PATH)
        firebase_admin.initialize_app(cred)
        logger.info("✅ Firebase Admin SDK initialisé")
    except Exception as e:
        logger.error(f"Erreur d'initialisation Firebase : {e}")


def send_fcm_notification(token, title, body, data=None):
    logger.info("🚀 [FCM] Tentative d'envoi de notification FCM")
    try:
        # Convertir toutes les valeurs du dictionnaire data en strings
        string_data = {}
        if data:
            for key, value in data.items():
                if value is not None:
                    if isinstance(value, (dict, list)):
                        string_data[key] = json.dumps(value)
                    else:
                        string_data[key] = str(value)
        
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            token=token,
            data=string_data,  # Utiliser les données converties
        )
        response = messaging.send(message)
        logger.info(f"✅ [FCM] Notification envoyée avec succès: {response}")
        return response
    except Exception as e:
        logger.error(f"❌ [FCM] Erreur lors de l'envoi FCM: {e}")
        import traceback
        logger.error(f"❌ [FCM] Traceback: {traceback.format_exc()}")
        return None
    
def notify_user_by_fcm(user, title, body, data=None):
    """
    Wrapper pour envoyer une notification FCM à un utilisateur avec attribut `fcm_token`.
    """
    logger.info(f"📱 [FCM] notify_user_by_fcm appelée pour: {user.email}")
    
    if not hasattr(user, 'fcm_token') or not user.fcm_token:
        logger.warning("⚠️ [FCM] Utilisateur sans fcm_token")
        return None
    
    logger.info(f"🔑 [FCM] Token FCM trouvé, envoi en cours...")
    
    result = send_fcm_notification(
        token=user.fcm_token,
        title=title,
        body=body,
        data=data or {}
    )
    
    if result:
        logger.info(f"✅ [FCM] Notification envoyée avec succès à {user.email}")
    else:
        logger.error(f"❌ [FCM] Échec de l'envoi de notification à {user.email}")
    
    return result