
import os
import sys
import json
import datetime
import requests
from pathlib import Path

# Configuration Django
sys.path.append('/var/www/html/teyago/angola_api')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'angola_api.settings')

import django
django.setup()

def check_server_time():
    """Vérifier la synchronisation de l'horloge serveur"""
    print("🕐 === VÉRIFICATION HEURE SERVEUR ===\n")
    
    import time
    
    # Heure locale et UTC
    local_time = datetime.datetime.now()
    utc_time = datetime.datetime.utcnow()
    
    print(f"🕐 Heure locale: {local_time}")
    print(f"🌍 Heure UTC: {utc_time}")
    print(f"⏱️  Timestamp: {time.time()}")
    
    # Comparer avec l'heure mondiale
    try:
        response = requests.get('http://worldtimeapi.org/api/timezone/UTC', timeout=10)
        if response.status_code == 200:
            world_time = response.json()['datetime'][:19]
            print(f"🌐 Heure mondiale: {world_time}")
            
            world_dt = datetime.datetime.fromisoformat(world_time)
            diff = abs((utc_time - world_dt).total_seconds())
            
            if diff > 60:  # Plus de 1 minute
                print(f"❌ PROBLÈME: Différence de {diff:.0f} secondes!")
                print("💡 SOLUTION: Exécuter 'sudo ntpdate -s time.nist.gov'")
                return False
            else:
                print(f"✅ Horloge synchronisée (différence: {diff:.0f}s)")
                return True
    
    except Exception as e:
        print(f"⚠️  Impossible de vérifier l'heure: {e}")
        return None

def check_firebase_credentials():
    """Vérifier les credentials Firebase"""
    print("\n🔑 === VÉRIFICATION CREDENTIALS FIREBASE ===\n")
    
    creds_path = "/var/www/html/teyago/angola_api/angola_api/firebase-credentials.json"
    
    # Vérifier existence du fichier
    if not os.path.exists(creds_path):
        print(f"❌ Fichier credentials introuvable: {creds_path}")
        return False
    
    print(f"✅ Fichier credentials trouvé")
    
    # Vérifier permissions
    stat = os.stat(creds_path)
    permissions = oct(stat.st_mode)[-3:]
    print(f"📁 Permissions: {permissions}")
    
    if permissions not in ['600', '644']:
        print(f"⚠️  Permissions recommandées: 600 ou 644")
        print(f"💡 Corriger avec: sudo chmod 600 {creds_path}")
    
    # Vérifier contenu JSON
    try:
        with open(creds_path, 'r') as f:
            creds_data = json.load(f)
        
        required_fields = ['type', 'project_id', 'private_key_id', 'private_key', 'client_email']
        missing = [field for field in required_fields if field not in creds_data]
        
        if missing:
            print(f"❌ Champs manquants: {missing}")
            return False
        
        print(f"✅ JSON valide avec tous les champs requis")
        print(f"📝 Project ID: {creds_data.get('project_id')}")
        print(f"📧 Client Email: {creds_data.get('client_email')}")
        
        # Vérifier format de la clé privée
        private_key = creds_data.get('private_key', '')
        if not private_key.startswith('-----BEGIN PRIVATE KEY-----'):
            print(f"❌ Format de clé privée invalide")
            return False
        
        print(f"✅ Clé privée au bon format")
        return True
        
    except json.JSONDecodeError as e:
        print(f"❌ JSON invalide: {e}")
        return False
    except Exception as e:
        print(f"❌ Erreur lecture fichier: {e}")
        return False

def test_firebase_direct():
    """Test direct Firebase avec diagnostic détaillé"""
    print("\n🔥 === TEST FIREBASE DIRECT ===\n")
    
    try:
        import firebase_admin
        from firebase_admin import credentials, messaging
        
        print("✅ Imports Firebase réussis")
        
        # Nettoyer app existante
        try:
            app = firebase_admin.get_app()
            firebase_admin.delete_app(app)
            print("🧹 App Firebase existante supprimée")
        except ValueError:
            print("ℹ️  Aucune app Firebase à nettoyer")
        
        # Initialiser
        creds_path = "/var/www/html/teyago/angola_api/angola_api/firebase-credentials.json"
        cred = credentials.Certificate(creds_path)
        
        app = firebase_admin.initialize_app(cred)
        print(f"✅ Firebase initialisé - Project: {app.project_id}")
        
        # Test avec token factice (pour tester l'auth sans spam)
        fake_token = "fake_token_for_auth_test"
        
        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title="Test Auth",
                    body="Test d'authentification"
                ),
                token=fake_token
            )
            
            # Cela devrait échouer avec "Unregistered" pas "Invalid JWT"
            messaging.send(message)
            print("🎉 AUTH OK - Token fake rejeté comme attendu")
            
        except Exception as send_error:
            error_str = str(send_error)
            
            if "Invalid JWT Signature" in error_str:
                print(f"❌ PROBLÈME AUTH: {send_error}")
                print("💡 L'authentification Firebase échoue encore")
                return False
            elif "Unregistered" in error_str or "not-registered" in error_str:
                print("✅ AUTH OK - Firebase rejette le token fake (normal)")
                return True
            else:
                print(f"✅ AUTH OK - Autre erreur attendue: {send_error}")
                return True
    
    except Exception as e:
        print(f"❌ ÉCHEC Firebase: {e}")
        
        if "Invalid JWT Signature" in str(e):
            print("\n💡 SOLUTIONS À ESSAYER:")
            print("1. sudo ntpdate -s time.nist.gov")
            print("2. Régénérer les credentials Firebase")
            print("3. Vérifier le project_id dans les credentials")
        
        return False

def fix_credentials_permissions():
    """Corriger les permissions du fichier credentials"""
    print("\n🔧 === CORRECTION PERMISSIONS ===\n")
    
    creds_path = "/var/www/html/teyago/angola_api/angola_api/firebase-credentials.json"
    
    try:
        # Définir propriétaire et permissions
        os.system(f"sudo chown www-data:www-data {creds_path}")
        os.system(f"sudo chmod 600 {creds_path}")
        print(f"✅ Permissions corrigées pour {creds_path}")
        return True
    except Exception as e:
        print(f"❌ Erreur correction permissions: {e}")
        return False

def main():
    """Fonction principale de diagnostic"""
    print("🚀 DIAGNOSTIC FIREBASE FCM COMPLET\n")
    print("="*50)
    
    results = {}
    
    # 1. Vérifier heure serveur
    results['time'] = check_server_time()
    
    # 2. Vérifier credentials
    results['credentials'] = check_firebase_credentials()
    
    # 3. Corriger permissions si nécessaire
    if results['credentials']:
        fix_credentials_permissions()
    
    # 4. Test Firebase direct
    results['firebase'] = test_firebase_direct()
    
    # Résumé
    print("\n" + "="*50)
    print("📋 === RÉSUMÉ DU DIAGNOSTIC ===\n")
    
    for test, result in results.items():
        status = "✅" if result else "❌" if result is False else "⚠️"
        print(f"{status} {test.upper()}: {'OK' if result else 'ÉCHEC' if result is False else 'INCONNU'}")
    
    if all(r for r in results.values() if r is not None):
        print("\n🎉 DIAGNOSTIC COMPLET: Tout semble OK!")
        print("🔄 Redémarrer Apache: sudo systemctl restart apache2")
    else:
        print("\n⚠️  PROBLÈMES DÉTECTÉS - Voir solutions ci-dessus")

if __name__ == "__main__":
    main()