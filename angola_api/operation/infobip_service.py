# utils/infobip_service.py (nouveau fichier)
import requests
from django.conf import settings
import logging

logger = logging.getLogger(__name__)

def send_sms_infobip(phone_number, message):
    """
    Envoyer un SMS via Infobip
    """
    if not settings.SMS_ENABLED:
        logger.info("SMS désactivés, simulation...")
        return True
    
    url = f"{settings.INFOBIP_BASE_URL}/sms/2/text/advanced"
    
    headers = {
        'Authorization': f'App {settings.INFOBIP_API_KEY}',
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
    
    payload = {
        "messages": [
            {
                "from": settings.INFOBIP_SENDER,
                "destinations": [
                    {
                        "to": phone_number
                    }
                ],
                "text": message
            }
        ]
    }
    
    try:
        logger.info(f"Envoi SMS via Infobip vers {phone_number}")
        response = requests.post(url, headers=headers, json=payload)
        response.raise_for_status()
            
        result = response.json()
        logger.info(f"Réponse Infobip: {result}")
        
        # Vérifier le statut
        if result.get('messages') and len(result['messages']) > 0:
            message_status = result['messages'][0].get('status', {})
            if message_status.get('groupId') == 1:  # Success
                logger.info("SMS envoyé avec succès via Infobip")
                return True
            else:
                logger.error(f"Erreur Infobip: {message_status}")
                return False
        
        return False
        
    except requests.exceptions.RequestException as e:
        logger.error(f"Erreur réseau Infobip: {str(e)}")
        return False
    except Exception as e:
        logger.error(f"Erreur inattendue Infobip: {str(e)}")
        return False