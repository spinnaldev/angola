import json
import logging
from asgiref.sync import async_to_sync, sync_to_async
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model
from .models import Notification, Message, Conversation, Provider

User = get_user_model()
logger = logging.getLogger(__name__)

class NotificationConsumer(AsyncWebsocketConsumer):
    """Consumer pour les notifications en temps réel"""
    
    async def connect(self):
        self.user_id = self.scope['url_route']['kwargs']['user_id']
        self.notification_group_name = f'notifications_{self.user_id}'
        
        # Vérifier que l'utilisateur est authentifié
        if self.scope["user"].is_anonymous:
            await self.close()
            return
        
        # Vérifier que l'utilisateur accède à ses propres notifications
        if str(self.scope["user"].id) != self.user_id:
            await self.close()
            return
        
        # Rejoindre le groupe de notifications
        await self.channel_layer.group_add(
            self.notification_group_name,
            self.channel_name
        )
        
        await self.accept()
        
        logger.info(f"✅ NotificationConsumer connecté pour user {self.user_id}")
        
        # Envoyer le statut de connexion
        await self.send(text_data=json.dumps({
            'type': 'connection_established',
            'message': 'Notifications WebSocket connecté'
        }))

    async def disconnect(self, close_code):
        # Quitter le groupe de notifications
        await self.channel_layer.group_discard(
            self.notification_group_name,
            self.channel_name
        )
        
        logger.info(f"❌ NotificationConsumer déconnecté pour user {self.user_id}")

    async def receive(self, text_data):
        """Recevoir des messages du client"""
        try:
            text_data_json = json.loads(text_data)
            message_type = text_data_json.get('type')
            
            if message_type == 'mark_as_read':
                notification_id = text_data_json.get('notification_id')
                await self.mark_notification_as_read(notification_id)
            elif message_type == 'mark_all_as_read':
                await self.mark_all_notifications_as_read()
            elif message_type == 'get_unread_count':
                await self.send_unread_count()
                
        except json.JSONDecodeError:
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': 'Format JSON invalide'
            }))

    async def notification_message(self, event):
        """Envoyer une notification au client"""
        await self.send(text_data=json.dumps({
            'type': 'notification',
            'notification': event['notification']
        }))

    async def unread_count_update(self, event):
        """Envoyer la mise à jour du compteur"""
        await self.send(text_data=json.dumps({
            'type': 'unread_count',
            'count': event['count']
        }))

    @database_sync_to_async
    def mark_notification_as_read(self, notification_id):
        """Marquer une notification comme lue"""
        try:
            notification = Notification.objects.get(
                id=notification_id, 
                user_id=self.user_id
            )
            notification.is_read = True
            notification.save()
            
            # Compter les notifications non lues restantes
            unread_count = Notification.objects.filter(
                user_id=self.user_id, 
                is_read=False
            ).count()
            
            # Envoyer la mise à jour du compteur
            async_to_sync(self.channel_layer.group_send)(
                self.notification_group_name,
                {
                    'type': 'unread_count_update',
                    'count': unread_count
                }
            )
            
            return True
        except Notification.DoesNotExist:
            return False

    @database_sync_to_async
    def mark_all_notifications_as_read(self):
        """Marquer toutes les notifications comme lues"""
        Notification.objects.filter(
            user_id=self.user_id, 
            is_read=False
        ).update(is_read=True)
        
        # Envoyer la mise à jour du compteur (0)
        async_to_sync(self.channel_layer.group_send)(
            self.notification_group_name,
            {
                'type': 'unread_count_update',
                'count': 0
            }
        )

    @database_sync_to_async
    def get_unread_count(self):
        """Obtenir le nombre de notifications non lues"""
        return Notification.objects.filter(
            user_id=self.user_id, 
            is_read=False
        ).count()

    async def send_unread_count(self):
        """Envoyer le compteur de notifications non lues"""
        count = await self.get_unread_count()
        await self.send(text_data=json.dumps({
            'type': 'unread_count',
            'count': count
        }))

class ChatConsumer(AsyncWebsocketConsumer):
    """Consumer pour les messages de chat en temps réel"""
    
    async def connect(self):
        self.conversation_id = self.scope['url_route']['kwargs']['conversation_id']
        self.room_group_name = f'chat_{self.conversation_id}'
        
        # Vérifier l'authentification
        if self.scope["user"].is_anonymous:
            await self.close()
            return
        
        # Vérifier les permissions sur la conversation
        has_permission = await self.check_conversation_permission()
        if not has_permission:
            await self.close()
            return
        
        # Rejoindre le groupe de conversation
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        
        await self.accept()
        
        logger.info(f"✅ ChatConsumer connecté pour conversation {self.conversation_id}")

    async def disconnect(self, close_code):
        # Quitter le groupe de conversation
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )
        
        logger.info(f"❌ ChatConsumer déconnecté pour conversation {self.conversation_id}")

    async def receive(self, text_data):
        """Recevoir un message du client"""
        try:
            text_data_json = json.loads(text_data)
            message_type = text_data_json.get('type')
            
            if message_type == 'chat_message':
                content = text_data_json.get('content', '').strip()
                if content:
                    # Sauvegarder le message en base
                    message = await self.save_message(content)
                    if message:
                        # Envoyer le message à tous les participants
                        await self.channel_layer.group_send(
                            self.room_group_name,
                            {
                                'type': 'chat_message',
                                'message': message
                            }
                        )
            elif message_type == 'mark_messages_read':
                await self.mark_messages_as_read()
                
        except json.JSONDecodeError:
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': 'Format JSON invalide'
            }))

    async def chat_message(self, event):
        """Envoyer un message de chat au client"""
        await self.send(text_data=json.dumps({
            'type': 'message',
            'message': event['message']
        }))

    @database_sync_to_async
    def check_conversation_permission(self):
        """Vérifier que l'utilisateur peut accéder à cette conversation"""
        try:
            conversation = Conversation.objects.get(id=self.conversation_id)
            user = self.scope["user"]
            
            # L'utilisateur est soit le client, soit le prestataire
            is_client = conversation.client == user
            is_provider = (hasattr(user, 'provider_profile') and 
                          conversation.provider == user.provider_profile)
            
            return is_client or is_provider
        except Conversation.DoesNotExist:
            return False

    @database_sync_to_async
    def save_message(self, content):
        """Sauvegarder le message en base de données"""
        try:
            conversation = Conversation.objects.get(id=self.conversation_id)
            user = self.scope["user"]
            
            message = Message.objects.create(
                conversation=conversation,
                sender=user,
                content=content
            )
            
            # Mettre à jour la conversation
            conversation.updated_at = message.created_at
            conversation.save()
            
            # Retourner les données du message pour WebSocket
            return {
                'id': message.id,
                'content': message.content,
                'sender_id': message.sender.id,
                'sender_name': message.sender.get_full_name() or message.sender.username,
                'created_at': message.created_at.isoformat(),
                'is_read': message.is_read
            }
        except Exception as e:
            logger.error(f"Erreur sauvegarde message: {e}")
            return None

    @database_sync_to_async
    def mark_messages_as_read(self):
        """Marquer les messages comme lus pour cet utilisateur"""
        try:
            conversation = Conversation.objects.get(id=self.conversation_id)
            user = self.scope["user"]
            
            # Marquer comme lus les messages de l'autre personne
            if conversation.client == user:
                # L'utilisateur est le client, marquer les messages du prestataire
                Message.objects.filter(
                    conversation=conversation,
                    sender=conversation.provider.user,
                    is_read=False
                ).update(is_read=True)
            elif hasattr(user, 'provider_profile') and conversation.provider == user.provider_profile:
                # L'utilisateur est le prestataire, marquer les messages du client
                Message.objects.filter(
                    conversation=conversation,
                    sender=conversation.client,
                    is_read=False
                ).update(is_read=True)
                
        except Exception as e:
            logger.error(f"Erreur marquer messages lus: {e}")

class UserConsumer(AsyncWebsocketConsumer):
    """Consumer général pour l'utilisateur (notifications + messages)"""
    
    async def connect(self):
        self.user_id = self.scope['url_route']['kwargs']['user_id']
        self.user_group_name = f'user_{self.user_id}'
        
        # Vérifier l'authentification
        if self.scope["user"].is_anonymous:
            await self.close()
            return
        
        # Vérifier l'autorisation
        if str(self.scope["user"].id) != self.user_id:
            await self.close()
            return
        
        # Rejoindre le groupe utilisateur
        await self.channel_layer.group_add(
            self.user_group_name,
            self.channel_name
        )
        
        await self.accept()
        
        logger.info(f"✅ UserConsumer connecté pour user {self.user_id}")
        
        # Envoyer les compteurs initiaux
        await self.send_initial_counts()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(
            self.user_group_name,
            self.channel_name
        )
        
        logger.info(f"❌ UserConsumer déconnecté pour user {self.user_id}")

    async def receive(self, text_data):
        """Gérer les messages du client"""
        try:
            data = json.loads(text_data)
            message_type = data.get('type')
            
            if message_type == 'get_counts':
                await self.send_initial_counts()
                
        except json.JSONDecodeError:
            pass

    async def notification_update(self, event):
        """Envoyer une mise à jour de notification"""
        await self.send(text_data=json.dumps(event))

    async def message_update(self, event):
        """Envoyer une mise à jour de message"""
        await self.send(text_data=json.dumps(event))

    async def counts_update(self, event):
        """Envoyer une mise à jour des compteurs"""
        await self.send(text_data=json.dumps(event))

    @database_sync_to_async
    def get_counts(self):
        """Obtenir les compteurs de notifications et messages"""
        try:
            user = self.scope["user"]
            
            # Compteur notifications
            notification_count = Notification.objects.filter(
                user=user, 
                is_read=False
            ).count()
            
            # Compteur messages
            if hasattr(user, 'provider_profile'):
                # Prestataire : messages des clients
                message_count = Message.objects.filter(
                    conversation__provider=user.provider_profile,
                    sender__in=Conversation.objects.filter(
                        provider=user.provider_profile
                    ).values_list('client', flat=True),
                    is_read=False
                ).count()
            else:
                # Client : messages des prestataires
                message_count = Message.objects.filter(
                    conversation__client=user,
                    is_read=False
                ).exclude(sender=user).count()
            
            return {
                'notification_count': notification_count,
                'message_count': message_count,
                'total_count': notification_count + message_count
            }
        except Exception as e:
            logger.error(f"Erreur get_counts: {e}")
            return {'notification_count': 0, 'message_count': 0, 'total_count': 0}

    async def send_initial_counts(self):
        """Envoyer les compteurs initiaux"""
        counts = await self.get_counts()
        await self.send(text_data=json.dumps({
            'type': 'counts',
            **counts
        }))