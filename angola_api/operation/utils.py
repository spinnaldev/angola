from .models import Notification

def create_notification(user, title, message, notification_type, related_object_id=None):
    """Fonction utilitaire pour créer des notifications"""
    try:
        
        notification = Notification.objects.create(
            user=user,
            title=title,
            message=message,
            notification_type=notification_type,
            related_object_id=related_object_id
        )
        print(f"✅ Notification créée: {notification.id}")
        return notification
    except Exception as e:
        print(f"❌ Erreur création notification: {e}")
        return None