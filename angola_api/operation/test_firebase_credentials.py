import os
import sys
import django

# Ajouter le chemin du projet Django
sys.path.append('/var/www/html/teyago/angola_api')

# Configuration Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'angola_api.settings')
django.setup()

def test_firebase_direct():
    """Test direct Firebase sans référence à _DEFAULT_FIREBASE_APP"""
    
    print("🔥 === TEST FIREBASE DIRECT ===\n")
    
    try:
        import firebase_admin
        from firebase_admin import credentials, messaging
        from operation.models import User, FCMToken
        
        print("✅ Imports Firebase réussis")
        
        # Nettoyer toutes les apps (méthode compatible)
        try:
            apps = firebase_admin.get_app()
            firebase_admin.delete_app(apps)
            print("🧹 App Firebase existante supprimée")
        except ValueError:
            print("ℹ️  Aucune app Firebase à nettoyer")
        
        # Initialiser avec credentials
        creds_path = "/var/www/html/teyago/angola_api/angola_api/firebase-credentials.json"
        cred = credentials.Certificate(creds_path)
        
        print(f"🔑 Credentials chargés depuis: {creds_path}")
        
        app = firebase_admin.initialize_app(cred)
        print(f"✅ Firebase initialisé: {app.project_id}")
        
        # Test avec un token réel
        token = FCMToken.objects.filter(is_active=True).first()
        if not token:
            print("⚠️  Aucun token FCM actif trouvé pour le test")
            return True
        
        print(f"🔑 Token de test: {token.token[:20]}...")
        print(f"👤 Utilisateur: {token.user.email}")
        
        # Créer un message de test simple
        message = messaging.Message(
            notification=messaging.Notification(
                title="🧪 Test Firebase Direct",
                body="Test d'envoi direct depuis le script de diagnostic"
            ),
            data={
                'test': 'true',
                'timestamp': str(django.utils.timezone.now().timestamp())
            },
            token=token.token
        )
        
        print(f"📝 Message créé")
        
        # Envoyer le message
        print(f"🚀 Envoi du message...")
        message_id = messaging.send(message)
        
        print(f"🎉 SUCCÈS! Message ID: {message_id}")
        return True
        
    except Exception as e:
        print(f"❌ ÉCHEC: {e}")
        print(f"   Type: {type(e)}")
        
        # Diagnostics spécifiques
        if "Invalid JWT Signature" in str(e):
            print(f"\n💡 SOLUTION: Problème d'horloge serveur")
            print(f"   Commandes à exécuter:")
            print(f"   sudo timedatectl set-ntp true")
            print(f"   sudo ntpdate -s time.nist.gov")
            
        elif "service account" in str(e).lower():
            print(f"\n💡 SOLUTION: Problème de service account")
            print(f"   Régénérer les credentials depuis Firebase Console")
            
        elif "project" in str(e).lower():
            print(f"\n💡 SOLUTION: Problème de project ID")
            print(f"   Vérifier que le projet 'teyago-services' existe")
        
        return False

def check_server_time():
    """Vérifier l'heure du serveur"""
    
    print("🕐 === VÉRIFICATION HEURE SERVEUR ===\n")
    
    import datetime
    import time
    
    # Heure locale
    local_time = datetime.datetime.now()
    print(f"🕐 Heure locale: {local_time}")
    
    # Heure UTC
    utc_time = datetime.datetime.utcnow()
    print(f"🌍 Heure UTC: {utc_time}")
    
    # Timestamp
    timestamp = time.time()
    print(f"⏱️  Timestamp: {timestamp}")
    
    # Test avec une API de temps
    try:
        import requests
        response = requests.get('http://worldtimeapi.org/api/timezone/UTC', timeout=10)
        if response.status_code == 200:
            world_time = response.json()['datetime'][:19]
            print(f"🌐 Heure mondiale: {world_time}")
            
            # Comparer
            world_dt = datetime.datetime.fromisoformat(world_time)
            diff = abs((utc_time - world_dt).total_seconds())
            
            if diff > 60:  # Plus de 1 minute de différence
                print(f"⚠️  ATTENTION: Différence de {diff:.0f} secondes avec l'heure mondiale")
                print(f"   Cela peut causer 'Invalid JWT Signature'")
                return False
            else:
                print(f"✅ Horloge synchronisée (différence: {diff:.0f}s)")
                return True
        
    except Exception as e:
        print(f"⚠️  Impossible de vérifier l'heure mondiale: {e}")
    
    return True

if __name__ == "__main__":
    print("🚀 DIAGNOSTIC FIREBASE COMPLET\n")
    
    # 1. Vérifier l'heure
    time_ok = check_server_time()
    
    print("\n" + "="*50 + "\n")
    
    # 2. Tester Firebase
    firebase_ok = test_firebase_direct()
    
    print("\n" + "="*50)
    print("📊 RÉSULTAT FINAL:")
    print(f"   - Heure serveur: {'✅ OK' if time_ok else '❌ Problème'}")
    print(f"   - Firebase: {'✅ OK' if firebase_ok else '❌ Problème'}")
    
    if not time_ok:
        print(f"\n🔧 ACTION REQUISE: Synchroniser l'horloge serveur")
        print(f"   sudo timedatectl set-ntp true")
    
    if not firebase_ok:
        print(f"\n🔧 ACTION REQUISE: Résoudre le problème Firebase identifié ci-dessus")