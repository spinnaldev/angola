from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    # WebSocket pour les notifications utilisateur
    re_path(r'ws/notifications/(?P<user_id>\w+)/$', consumers.NotificationConsumer.as_asgi()),
    
    # WebSocket pour les conversations/messages
    re_path(r'ws/chat/(?P<conversation_id>\w+)/$', consumers.ChatConsumer.as_asgi()),
    
    # WebSocket général pour l'utilisateur (notifications + messages)
    # re_path(r'ws/user/(?P<user_id>\w+)/$', consumers.UserConsumer.as_asgi()),

    re_path(r'ws/user/(?P<user_id>\w+)/$', consumers.GeneralConsumer.as_asgi()),
]