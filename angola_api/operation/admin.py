from datetime import timezone
from django.contrib import admin

from operation.models import AdminNotification

# Register your models here.
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