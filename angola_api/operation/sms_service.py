# operation/services/sms_service.py

import http.client
import json
import logging
from django.conf import settings
from typing import Optional, Dict, Any

from django.core.cache import cache
logger = logging.getLogger(__name__)

class InfobipSMSService:
    """
    Service pour l'envoi de SMS via l'API Infobip
    """
    
    def __init__(self):
        # Configuration depuis les settings Django
        self.api_host = getattr(settings, 'INFOBIP_API_HOST', '1g43wn.api.infobip.com')
        self.api_key = getattr(settings, 'INFOBIP_API_KEY', '')
        self.from_number = getattr(settings, 'INFOBIP_FROM_NUMBER', '+41798070047')
        
        if not self.api_key:
            logger.error("❌ INFOBIP_API_KEY non configuré dans les settings")
            raise ValueError("Configuration Infobip manquante")
    
    def send_sms(self, to_number: str, message: str) -> Dict[str, Any]:
        """
        Envoyer un SMS via l'API Infobip
        from operation.sms_service import InfobipSMSService,
        Args:
            to_number (str): Numéro de destination (format international)
            message (str): Contenu du message
            
        Returns:
            dict: Résultat de l'envoi avec statut et détails
        """
        try:
            print(f"📱 Tentative d'envoi SMS vers {to_number}")
            logger.info(f"Envoi SMS vers {to_number}")
            
            # Nettoyer le numéro de téléphone
            to_number = self._clean_phone_number(to_number)
            
            # Créer la connexion HTTPS
            conn = http.client.HTTPSConnection(self.api_host)
            
            # Préparer le payload
            payload = json.dumps({
                "messages": [
                    {
                        "destinations": [{"to": to_number}],
                        "from": self.from_number,
                        "text": message
                    }
                ]
            })
            
            # Headers
            headers = {
                'Authorization': f'App {self.api_key}',
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            }
            
            print(f"🔗 Connexion à: {self.api_host}")
            print(f"📤 Payload: {payload}")
            
            # Faire la requête
            conn.request("POST", "/sms/2/text/advanced", payload, headers)
            res = conn.getresponse()
            data = res.read()
            
            # Parser la réponse
            response_text = data.decode("utf-8")
            print(f"📥 Réponse brute: {response_text}")
            
            try:
                response_data = json.loads(response_text)
            except json.JSONDecodeError:
                logger.error(f"Erreur parsing JSON: {response_text}")
                return {
                    'success': False,
                    'error': 'Réponse invalide du serveur SMS',
                    'raw_response': response_text
                }
            
            # Vérifier le statut HTTP
            if res.status == 200:
                # Analyser la réponse Infobip
                messages = response_data.get('messages', [])
                if messages:
                    message_status = messages[0].get('status', {})
                    status_group_id = message_status.get('groupId')
                    status_name = message_status.get('name', 'Unknown')
                    
                    print(f"✅ Statut SMS: {status_name} (Group: {status_group_id})")
                    
                    # Group ID 1 = PENDING (succès initial)
                    # Group ID 3 = DELIVERED 
                    if status_group_id in [1, 3]:
                        logger.info(f"SMS envoyé avec succès vers {to_number}")
                        return {
                            'success': True,
                            'message_id': messages[0].get('messageId'),
                            'status': status_name,
                            'to': to_number
                        }
                    else:
                        logger.warning(f"SMS statut inattendu: {status_name}")
                        return {
                            'success': False,
                            'error': f'Statut SMS: {status_name}',
                            'response': response_data
                        }
                else:
                    logger.error("Aucun message dans la réponse")
                    return {
                        'success': False,
                        'error': 'Réponse SMS vide',
                        'response': response_data
                    }
            else:
                logger.error(f"Erreur HTTP {res.status}: {response_text}")
                return {
                    'success': False,
                    'error': f'Erreur serveur: {res.status}',
                    'response': response_data if 'response_data' in locals() else response_text
                }
                
        except Exception as e:
            logger.error(f"Erreur envoi SMS: {str(e)}")
            print(f"❌ Exception lors de l'envoi SMS: {str(e)}")
            return {
                'success': False,
                'error': f'Erreur technique: {str(e)}'
            }
        finally:
            try:
                conn.close()
            except:
                pass
    
    def send_verification_code(self, to_number: str, code: str) -> Dict[str, Any]:
        """
        Envoyer un code de vérification par SMS
        
        Args:
            to_number (str): Numéro de destination
            code (str): Code de vérification
            
        Returns:
            dict: Résultat de l'envoi
        """
        message = f"Votre code de vérification est: {code}. Ne le partagez avec personne."
        return self.send_sms(to_number, message)
    
    def _clean_phone_number(self, phone_number: str) -> str:
        """
        Nettoyer et formater le numéro de téléphone
        
        Args:
            phone_number (str): Numéro brut
            
        Returns:
            str: Numéro formaté
        """
        # Supprimer les espaces et caractères spéciaux
        cleaned = ''.join(filter(str.isdigit, phone_number.replace('+', '')))
        
        # S'assurer qu'il commence par +
        if not phone_number.startswith('+'):
            cleaned = '+' + cleaned
        else:
            cleaned = '+' + cleaned
            
        print(f"📞 Numéro nettoyé: {phone_number} -> {cleaned}")
        return cleaned
    
    def get_message_status(self, message_id: str) -> Dict[str, Any]:
        """
        Vérifier le statut d'un message envoyé
        
        Args:
            message_id (str): ID du message Infobip
            
        Returns:
            dict: Statut du message
        """
        try:
            conn = http.client.HTTPSConnection(self.api_host)
            
            headers = {
                'Authorization': f'App {self.api_key}',
                'Accept': 'application/json'
            }
            
            # Endpoint pour vérifier le statut
            endpoint = f"/sms/1/reports?messageId={message_id}"
            conn.request("GET", endpoint, headers=headers)
            
            res = conn.getresponse()
            data = res.read()
            response_text = data.decode("utf-8")
            
            if res.status == 200:
                response_data = json.loads(response_text)
                return {
                    'success': True,
                    'status': response_data
                }
            else:
                return {
                    'success': False,
                    'error': f'Erreur {res.status}: {response_text}'
                }
                
        except Exception as e:
            logger.error(f"Erreur vérification statut: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
        finally:
            try:
                conn.close()
            except:
                pass



# ================================================================
# FONCTION UTILITAIRE POUR LA LIMITATION DE TAUX
# ================================================================

def check_sms_rate_limit(user, phone_number):
    """
    Vérifier les limitations de taux SMS pour éviter le spam
    """
    hour_key = f"sms_rate_hour_{user.id}_{phone_number}"
    day_key = f"sms_rate_day_{user.id}_{phone_number}"
    
    # Vérifier limite horaire
    hourly_count = cache.get(hour_key, 0)
    daily_count = cache.get(day_key, 0)
    
    max_hourly = getattr(settings, 'SMS_RATE_LIMIT_PER_USER_PER_HOUR', 5)
    max_daily = getattr(settings, 'SMS_RATE_LIMIT_PER_USER_PER_DAY', 20)
    
    if hourly_count >= max_hourly:
        return False, f"Limite horaire atteinte ({max_hourly} SMS/heure)"
    
    if daily_count >= max_daily:
        return False, f"Limite quotidienne atteinte ({max_daily} SMS/jour)"
    
    return True, "OK"

def increment_sms_rate_limit(user, phone_number):
    """
    Incrémenter les compteurs de limitation de taux
    """
    hour_key = f"sms_rate_hour_{user.id}_{phone_number}"
    day_key = f"sms_rate_day_{user.id}_{phone_number}"
    
    # Incrémenter ou créer les compteurs
    cache.set(hour_key, cache.get(hour_key, 0) + 1, 3600)  # 1 heure
    cache.set(day_key, cache.get(day_key, 0) + 1, 86400)   # 24 heures
# Instance globale du service
sms_service = InfobipSMSService()