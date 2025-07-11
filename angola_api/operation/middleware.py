import logging
import jwt
logger = logging.getLogger(__name__)

class JWTDebugMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Debug uniquement pour les endpoints API
        if '/api/' in request.path:
            logger.debug(f"🔍 === JWT DEBUG pour {request.method} {request.path} ===")
            
            # Vérifier les headers d'autorisation
            auth_header = request.META.get('HTTP_AUTHORIZATION', '')
            logger.debug(f"🔑 Authorization header: {auth_header[:50]}..." if auth_header else "❌ Pas d'Authorization header")
            
            if auth_header.startswith('Bearer '):
                token = auth_header.split(' ')[1]
                logger.debug(f"🎫 Token extrait: {token[:20]}...{token[-10:]}")
                
                try:
                    # Décoder le token sans vérification pour voir le contenu
                    decoded = jwt.decode(token, options={"verify_signature": False})
                    logger.debug(f"📋 Contenu du token: {decoded}")
                    logger.debug(f"👤 User ID dans token: {decoded.get('user_id', 'Non trouvé')}")
                    logger.debug(f"⏰ Expiration: {decoded.get('exp', 'Non trouvé')}")
                    
                    # Vérifier l'expiration
                    import time
                    current_time = time.time()
                    exp_time = decoded.get('exp', 0)
                    if exp_time < current_time:
                        logger.warning(f"⚠️ Token expiré! Exp: {exp_time}, Now: {current_time}")
                    else:
                        logger.debug(f"✅ Token valide jusqu'à: {exp_time}")
                        
                except Exception as e:
                    logger.error(f"❌ Erreur décodage token: {e}")
            
            # Vérifier l'utilisateur après le middleware d'authentification
            response = self.get_response(request)
            
            # Debug de l'utilisateur après authentification
            if hasattr(request, 'user'):
                logger.debug(f"👤 request.user: {request.user}")
                logger.debug(f"🔐 is_authenticated: {request.user.is_authenticated}")
                logger.debug(f"👻 is_anonymous: {request.user.is_anonymous}")
                if hasattr(request.user, 'id'):
                    logger.debug(f"🆔 User ID: {request.user.id}")
            else:
                logger.debug("❌ Pas de request.user")
            
            logger.debug(f"📊 Response status: {response.status_code}")
            logger.debug("🔍 === FIN JWT DEBUG ===")
            
            return response
        
        return self.get_response(request)
    
class AuthDebugMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Debug des headers d'authentification
        if '/api/' in request.path:
            auth_header = request.META.get('HTTP_AUTHORIZATION', 'None')
            logger.debug(f"📍 {request.method} {request.path}")
            logger.debug(f"🔑 Authorization header: {auth_header[:50] if auth_header != 'None' else 'None'}...")
            logger.debug(f"📱 User-Agent: {request.META.get('HTTP_USER_AGENT', 'None')}")
            
        response = self.get_response(request)
        
        if '/api/' in request.path and response.status_code in [401, 403]:
            logger.warning(f"❌ Auth failed for {request.path}: {response.status_code}")
            
        return response