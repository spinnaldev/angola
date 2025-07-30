# angola_api/operation/admin_conversation_serializers.py

from rest_framework import serializers
from .models import Conversation, Message, User, Provider
from django.utils import timezone

class AdminUserSerializer(serializers.ModelSerializer):
    """Serializer utilisateur pour l'admin"""
    full_name = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'full_name', 
                 'profile_picture', 'is_active', 'last_login', 'date_joined']
    
    def get_full_name(self, obj):
        return f"{obj.first_name} {obj.last_name}".strip() or obj.username

class AdminProviderSerializer(serializers.ModelSerializer):
    """Serializer provider pour l'admin"""
    user = AdminUserSerializer()
    
    class Meta:
        model = Provider
        fields = ['id', 'user', 'company_name', 'phone_number', 'bio', 'location', 
                 'average_rating', 'total_reviews', 'is_verified']

class AdminMessageSerializer(serializers.ModelSerializer):
    """Serializer message pour l'admin avec plus de détails"""
    sender = AdminUserSerializer()
    sender_type = serializers.SerializerMethodField()
    time_ago = serializers.SerializerMethodField()
    is_admin_message = serializers.SerializerMethodField()
    
    class Meta:
        model = Message
        fields = ['id', 'sender', 'sender_type', 'content', 'is_read', 'created_at', 
                 'time_ago', 'is_admin_message']
    
    def get_sender_type(self, obj):
        """Détermine si l'expéditeur est client, provider ou admin"""
        if obj.sender.is_staff:
            return 'admin'
        elif hasattr(obj.sender, 'provider_profile'):
            return 'provider'
        else:
            return 'client'
    
    def get_time_ago(self, obj):
        """Retourne le temps écoulé depuis l'envoi"""
        now = timezone.now()
        diff = now - obj.created_at
        
        if diff.days > 0:
            return f"il y a {diff.days} jour{'s' if diff.days > 1 else ''}"
        elif diff.seconds > 3600:
            hours = diff.seconds // 3600
            return f"il y a {hours} heure{'s' if hours > 1 else ''}"
        elif diff.seconds > 60:
            minutes = diff.seconds // 60
            return f"il y a {minutes} minute{'s' if minutes > 1 else ''}"
        else:
            return "à l'instant"
    
    def get_is_admin_message(self, obj):
        """Vérifie si c'est un message admin"""
        return obj.sender.is_staff or obj.content.startswith('[MESSAGE ADMIN]') or obj.content.startswith('[ADMIN]')

class AdminConversationListSerializer(serializers.ModelSerializer):
    """Serializer pour la liste des conversations (vue d'ensemble)"""
    client = AdminUserSerializer()
    provider = AdminProviderSerializer()
    last_message = serializers.SerializerMethodField()
    total_messages = serializers.IntegerField(read_only=True)
    unread_messages = serializers.IntegerField(read_only=True)
    duration = serializers.SerializerMethodField()
    status = serializers.SerializerMethodField()
    
    class Meta:
        model = Conversation
        fields = ['id', 'client', 'provider', 'last_message', 'total_messages', 
                 'unread_messages', 'created_at', 'updated_at', 'duration', 'status']
    
    def get_last_message(self, obj):
        """Récupère le dernier message avec détails"""
        if hasattr(obj, 'recent_messages') and obj.recent_messages:
            last_msg = obj.recent_messages[0]
        else:
            last_msg = obj.messages.order_by('-created_at').first()
        
        if last_msg:
            return {
                'id': last_msg.id,
                'content': last_msg.content[:100] + ('...' if len(last_msg.content) > 100 else ''),
                'sender_name': f"{last_msg.sender.first_name} {last_msg.sender.last_name}".strip() or last_msg.sender.username,
                'sender_type': 'admin' if last_msg.sender.is_staff else ('provider' if hasattr(last_msg.sender, 'provider_profile') else 'client'),
                'created_at': last_msg.created_at,
                'is_read': last_msg.is_read
            }
        return None
    
    def get_duration(self, obj):
        """Durée de la conversation"""
        diff = timezone.now() - obj.created_at
        if diff.days > 0:
            return f"{diff.days} jour{'s' if diff.days > 1 else ''}"
        elif diff.seconds > 3600:
            hours = diff.seconds // 3600
            return f"{hours}h"
        else:
            minutes = diff.seconds // 60
            return f"{minutes}min"
    
    def get_status(self, obj):
        """Statut de la conversation"""
        unread_count = getattr(obj, 'unread_messages', 0)
        if unread_count > 0:
            return 'unread'
        
        # Vérifier si conversation récente (moins de 24h)
        if (timezone.now() - obj.updated_at).days == 0:
            return 'active'
        
        return 'read'

class AdminConversationDetailSerializer(serializers.ModelSerializer):
    """Serializer détaillé pour une conversation spécifique"""
    client = AdminUserSerializer()
    provider = AdminProviderSerializer()
    messages = AdminMessageSerializer(many=True, read_only=True)
    total_messages = serializers.IntegerField(read_only=True)
    unread_messages = serializers.IntegerField(read_only=True)
    conversation_stats = serializers.SerializerMethodField()
    
    class Meta:
        model = Conversation
        fields = ['id', 'client', 'provider', 'messages', 'total_messages', 
                 'unread_messages', 'created_at', 'updated_at', 'conversation_stats']
    
    def get_conversation_stats(self, obj):
        """Statistiques de la conversation"""
        messages = obj.messages.all()
        
        if not messages:
            return {
                'total_messages': 0,
                'client_messages': 0,
                'provider_messages': 0,
                'admin_messages': 0,
                'average_response_time': None
            }
        
        client_messages = messages.filter(sender=obj.client).count()
        provider_messages = messages.filter(sender=obj.provider.user).count()
        admin_messages = messages.filter(sender__is_staff=True).count()
        
        return {
            'total_messages': messages.count(),
            'client_messages': client_messages,
            'provider_messages': provider_messages,
            'admin_messages': admin_messages,
            'first_message_date': messages.order_by('created_at').first().created_at,
            'last_message_date': messages.order_by('-created_at').first().created_at,
        }

class AdminConversationStatsSerializer(serializers.Serializer):
    """Serializer pour les statistiques globales"""
    total_conversations = serializers.IntegerField()
    conversations_with_unread = serializers.IntegerField()
    recent_conversations = serializers.IntegerField()
    total_messages = serializers.IntegerField()
    unread_messages = serializers.IntegerField()
    active_users = serializers.ListField()