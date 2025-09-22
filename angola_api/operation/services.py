# angola_api/operation/services.py - Créez ce fichier

from django.utils import timezone
from .models import AdminNotification

class AdminNotificationService:
    """Service pour gérer les notifications admin"""
    
    @staticmethod
    def create_notification(type_name, title, message, user=None, related_object=None, priority='normal', extra_data=None):
        """Créer une notification admin"""
        return AdminNotification.objects.create(
            type=type_name,
            title=title,
            message=message,
            related_user=user,
            related_object_id=related_object.id if related_object else None,
            related_object_type=related_object.__class__.__name__ if related_object else None,
            priority=priority,
            extra_data=extra_data or {}
        )
    
    @staticmethod
    def create_system_alert(title, message, priority='high'):
        """Créer une alerte système"""
        return AdminNotificationService.create_notification(
            type_name='system_alert',
            title=title,
            message=message,
            priority=priority
        )
    
    @staticmethod
    def get_unread_count():
        """Compter les notifications non lues"""
        return AdminNotification.objects.filter(is_read=False).count()
    
    @staticmethod
    def mark_all_as_read():
        """Marquer toutes comme lues"""
        return AdminNotification.objects.filter(is_read=False).update(
            is_read=True,
            read_at=timezone.now()
        )


# angola_api/operation/management/commands/test_notifications.py
# Créez ce fichier pour tester les notifications

from django.core.management.base import BaseCommand
from operation.models import User, AdminNotification
from operation.services import AdminNotificationService

class Command(BaseCommand):
    help = 'Teste le système de notifications admin'

    def handle(self, *args, **options):
        # Créer quelques notifications de test
        AdminNotificationService.create_system_alert(
            title="Test du système",
            message="Ceci est une notification de test pour vérifier le fonctionnement du système"
        )
        
        AdminNotificationService.create_notification(
            type_name='user_registration',
            title='Utilisateur de test',
            message='Un utilisateur test s\'est inscrit',
            priority='normal'
        )
        
        AdminNotificationService.create_notification(
            type_name='dispute_created',
            title='Litige de test',
            message='Un litige de test a été créé',
            priority='high'
        )
        
        self.stdout.write(
            self.style.SUCCESS('3 notifications de test créées avec succès')
        )


# angola_api/operation/admin.py - Ajoutez ceci pour l'interface Django Admin

from django.contrib import admin
from .models import AdminNotification

@admin.register(AdminNotification)
class AdminNotificationAdmin(admin.ModelAdmin):
    list_display = ['title', 'type', 'priority', 'related_user', 'is_read', 'created_at']
    list_filter = ['type', 'priority', 'is_read', 'created_at']
    search_fields = ['title', 'message']
    readonly_fields = ['created_at', 'read_at']
    
    def mark_as_read(self, request, queryset):
        count = queryset.update(is_read=True, read_at=timezone.now())
        self.message_user(request, f'{count} notifications marquées comme lues')
    
    mark_as_read.short_description = "Marquer comme lues"
    actions = [mark_as_read]


# angola_api/operation/tasks.py - Pour les tâches périodiques (optionnel)

from celery import shared_task
from django.utils import timezone
from datetime import timedelta
from .models import AdminNotification
from .services import AdminNotificationService

@shared_task
def clean_old_notifications():
    """Nettoyer les anciennes notifications lues (plus de 30 jours)"""
    cutoff_date = timezone.now() - timedelta(days=30)
    deleted_count = AdminNotification.objects.filter(
        is_read=True,
        read_at__lt=cutoff_date
    ).delete()
    
    return f"Supprimé {deleted_count[0]} anciennes notifications"

@shared_task
def daily_notification_summary():
    """Créer un résumé quotidien des notifications"""
    today = timezone.now().date()
    today_notifications = AdminNotification.objects.filter(
        created_at__date=today
    ).count()
    
    if today_notifications > 0:
        AdminNotificationService.create_system_alert(
            title="Résumé quotidien",
            message=f"{today_notifications} nouvelle(s) notification(s) aujourd'hui",
            priority='low'
        )

