#!/usr/bin/env python3
# Script pour vérifier les notifications et leurs extra_data

import os
import sys
import django

# Configuration Django
sys.path.append('/var/www/html/teyago/angola_api')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'angola_api.settings')
django.setup()

from operation.models import Notification

def check_latest_notifications():
    """Afficher les 5 dernières notifications avec détails"""
    print("🔍 === VÉRIFICATION DES NOTIFICATIONS ===\n")
    
    try:
        # Récupérer les 5 dernières notifications
        notifications = Notification.objects.all().order_by('-created_at')[:5]
        
        if not notifications:
            print("❌ Aucune notification trouvée")
            return
        
        print(f"📊 {notifications.count()} notifications trouvées\n")
        
        for i, notif in enumerate(notifications, 1):
            print(f"📨 === NOTIFICATION {i} ===")
            print(f"   ID: {notif.id}")
            print(f"   Utilisateur: {notif.user.email}")
            print(f"   Titre: {notif.title}")
            print(f"   Message: {notif.message[:50]}{'...' if len(notif.message) > 50 else ''}")
            print(f"   Type: {notif.notification_type}")
            print(f"   Related Object ID: {notif.related_object_id}")
            print(f"   Lu: {notif.is_read}")
            print(f"   Créé: {notif.created_at}")
            print(f"   Extra Data: {notif.extra_data}")
            print(f"   Type Extra Data: {type(notif.extra_data)}")
            
            # Analyse détaillée des extra_data
            if notif.extra_data:
                print("   🔍 Contenu Extra Data:")
                if isinstance(notif.extra_data, dict):
                    for key, value in notif.extra_data.items():
                        print(f"      - {key}: {value}")
                else:
                    print(f"      - Valeur brute: {notif.extra_data}")
            else:
                print("   ⚠️  Extra Data: VIDE/NULL")
            
            print("")
    
    except Exception as e:
        print(f"❌ Erreur lors de la vérification: {e}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")

def check_specific_notification_types():
    """Vérifier spécifiquement les notifications de messages"""
    print("🔍 === VÉRIFICATION NOTIFICATIONS DE MESSAGES ===\n")
    
    try:
        message_notifications = Notification.objects.filter(
            notification_type__in=['new_message', 'message']
        ).order_by('-created_at')[:3]
        
        if not message_notifications:
            print("❌ Aucune notification de message trouvée")
            return
        
        for notif in message_notifications:
            print(f"📨 Message Notification ID: {notif.id}")
            print(f"   User: {notif.user.email}")
            print(f"   Type: {notif.notification_type}")
            print(f"   Related ID: {notif.related_object_id}")
            print(f"   Extra Data: {notif.extra_data}")
            
            # Vérifier les clés attendues pour les messages
            if notif.extra_data and isinstance(notif.extra_data, dict):
                expected_keys = ['conversation_id', 'sender_id', 'sender_first_name']
                missing_keys = [key for key in expected_keys if key not in notif.extra_data]
                if missing_keys:
                    print(f"   ⚠️  Clés manquantes: {missing_keys}")
                else:
                    print("   ✅ Toutes les clés attendues présentes")
            else:
                print("   ❌ Extra Data manquant ou invalide")
            print("")
    
    except Exception as e:
        print(f"❌ Erreur: {e}")

def simulate_create_notification():
    """Simuler la création d'une notification avec extra_data"""
    print("🧪 === TEST CRÉATION NOTIFICATION AVEC EXTRA_DATA ===\n")
    
    try:
        from django.contrib.auth import get_user_model
        User = get_user_model()
        
        # Récupérer un utilisateur pour test
        user = User.objects.first()
        if not user:
            print("❌ Aucun utilisateur trouvé pour le test")
            return
        
        # Créer une notification de test avec extra_data
        test_extra_data = {
            'conversation_id': 999,
            'sender_id': 888,
            'sender_first_name': 'TEST USER',
            'sender_username': 'testuser'
        }
        
        test_notification = Notification.objects.create(
            user=user,
            title="🧪 Test Notification",
            message="Ceci est un test pour vérifier extra_data",
            notification_type="new_message",
            related_object_id=999,
            extra_data=test_extra_data
        )
        
        print(f"✅ Notification de test créée - ID: {test_notification.id}")
        print(f"   Extra Data stocké: {test_notification.extra_data}")
        print(f"   Type: {type(test_notification.extra_data)}")
        
        # Vérifier en relisant depuis la DB
        reloaded = Notification.objects.get(id=test_notification.id)
        print(f"   Extra Data relu: {reloaded.extra_data}")
        
        # Nettoyer
        test_notification.delete()
        print("   🗑️ Notification de test supprimée")
        
    except Exception as e:
        print(f"❌ Erreur test: {e}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")

if __name__ == "__main__":
    print("🚀 DIAGNOSTIC COMPLET DES NOTIFICATIONS\n")
    
    # 1. Vérifier les dernières notifications
    check_latest_notifications()
    
    print("="*60)
    
    # 2. Vérifier spécifiquement les messages
    check_specific_notification_types()
    
    print("="*60)
    
    # 3. Test de création
    simulate_create_notification()
    
    print("\n🎯 RÉSUMÉ:")
    print("1. Si extra_data est NULL/vide → Problème dans create_and_send_notification")
    print("2. Si extra_data est présent → Problème dans la sérialisation API/WebSocket")
    print("3. Le test de création indique si le modèle fonctionne correctement")