// lib/providers/realtime_messaging_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/services/websocket_service.dart';
import '../core/models/message.dart';
import '../core/models/conversation.dart';
import 'messaging_provider.dart';

class RealtimeMessagingProvider with ChangeNotifier {
  final MessagingProvider _messagingProvider;
  final WebSocketService _webSocketService;
  
  StreamSubscription<Map<String, dynamic>>? _webSocketSubscription;
  bool _isListening = false;
  int? _currentConversationId;
  
  RealtimeMessagingProvider(this._messagingProvider, this._webSocketService);

  // Getters
  bool get isListening => _isListening;
  int? get currentConversationId => _currentConversationId;
  
  /// Démarrer l'écoute des messages en temps réel
  void startListening() {
    if (_isListening) {
      print('💬 Déjà en écoute des messages en temps réel');
      return;
    }

    print('💬 Démarrage de l\'écoute des messages en temps réel');
    
    _webSocketSubscription = _webSocketService.messageStream?.listen(
      _handleWebSocketMessage,
      onError: (error) {
        print('❌ Erreur WebSocket messages: $error');
      },
    );
    
    _isListening = true;
    print('✅ Écoute des messages en temps réel activée');
    
    // ✅ NOUVEAU: Demander les compteurs initiaux
    Future.delayed(Duration(milliseconds: 500), () {
      requestInitialCounts();
    });
  }


  /// Arrêter l'écoute des messages en temps réel
  void stopListening() {
    if (!_isListening) return;

    print('💬 Arrêt de l\'écoute des messages en temps réel');
    
    _webSocketSubscription?.cancel();
    _webSocketSubscription = null;
    _isListening = false;
    
    // Quitter la conversation actuelle
    if (_currentConversationId != null) {
      _leaveCurrentConversation();
    }
    
    print('✅ Écoute des messages en temps réel désactivée');
  }

  /// Rejoindre une conversation pour recevoir les messages en temps réel
  void joinConversation(int conversationId) {
    if (_currentConversationId == conversationId) {
      print('💬 Déjà dans la conversation $conversationId');
      return;
    }

    // Quitter la conversation précédente
    if (_currentConversationId != null) {
      _leaveCurrentConversation();
    }

    _currentConversationId = conversationId;
    
    if (_webSocketService.isConnected) {
      _webSocketService.joinConversation(conversationId);
      print('💬 Rejoint la conversation $conversationId');
    }
  }

  /// Quitter la conversation actuelle
  void leaveCurrentConversation() {
    if (_currentConversationId != null) {
      _leaveCurrentConversation();
    }
  }

  void _leaveCurrentConversation() {
    if (_currentConversationId == null) return;
    
    if (_webSocketService.isConnected) {
      _webSocketService.leaveConversation(_currentConversationId!);
      print('💬 Quitté la conversation $_currentConversationId');
    }
    
    _currentConversationId = null;
  }

  /// Gérer les messages WebSocket
  void _handleWebSocketMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    
    switch (type) {
      // Cases existantes conservées
      case 'message_update':
        _handleMessageUpdate(message);
        break;
      case 'chat_message':
        _handleChatMessage(message);
        break;
      case 'message_read':
        _handleMessageRead(message);
        break;
      case 'conversation_update':
        _handleConversationUpdate(message);
        break;
      case 'typing_indicator':
        _handleTypingIndicator(message);
        break;
      case 'connection_established':
        _handleConnectionEstablished(message);
        break;
        
      // ✅ NOUVEAUX CASES pour le compteur automatique
      case 'message_count_update':
        _handleMessageCountUpdate(message);
        break;
      case 'counts_update':
        _handleCountsUpdate(message);
        break;
      case 'initial_counts':
        _handleInitialCounts(message);
        break;
        
      default:
        // Ignorer les autres types de messages
        break;
    }
  }



  void _handleMessageCountUpdate(Map<String, dynamic> message) {
    try {
      final count = message['count'] as int? ?? 0;
      print('💬 Mise à jour compteur messages reçue: $count');
      
      // Mettre à jour le compteur dans MessagingProvider
      _messagingProvider.updateUnreadCountAutomatically(count);
      
      notifyListeners();
    } catch (e) {
      print('❌ Erreur mise à jour compteur messages: $e');
    }
  }

  /// Gérer la mise à jour des compteurs globaux
  void _handleCountsUpdate(Map<String, dynamic> message) {
    try {
      final eventType = message['event_type'] as String?;
      
      if (eventType == 'message_count_update') {
        final messageCount = message['message_count'] as int?;
        if (messageCount != null) {
          print('💬 Mise à jour compteur via counts_update: $messageCount');
          _messagingProvider.updateUnreadCountAutomatically(messageCount);
          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ Erreur counts_update messages: $e');
    }
  }

  /// Gérer les compteurs initiaux
  void _handleInitialCounts(Map<String, dynamic> message) {
    try {
      final messageCount = message['message_count'] as int? ?? 0;
      print('💬 Compteurs initiaux reçus - Messages: $messageCount');
      
      // Initialiser le compteur dans MessagingProvider
      _messagingProvider.initializeUnreadCount(messageCount);
      
      notifyListeners();
    } catch (e) {
      print('❌ Erreur compteurs initiaux messages: $e');
    }
  }

  /// Gérer les mises à jour de messages
  void _handleMessageUpdate(Map<String, dynamic> message) {
    try {
      final eventType = message['event_type'] as String?;
      
      switch (eventType) {
        case 'new_message':
          _handleNewMessage(message);
          break;
        case 'message_read':
          _handleMessageRead(message);
          break;
        case 'message_deleted':
          _handleMessageDeleted(message);
          break;
        default:
          print('💬 Type d\'événement de message non géré: $eventType');
      }
    } catch (e) {
      print('❌ Erreur lors du traitement de la mise à jour de message: $e');
    }
  }

  /// Gérer un nouveau message
  void _handleNewMessage(Map<String, dynamic> message) {
    try {
      final messageData = message['message'] as Map<String, dynamic>?;
      if (messageData == null) return;

      print('📨 Nouveau message reçu pour conversation: ${messageData['conversation_id']}');

      // Créer l'objet message
      final newMessage = Message.fromJson(messageData, _messagingProvider.currentUserId ?? 0);
      
      final conversationId = newMessage.conversationId;
      if (conversationId != null) {
        // ✅ SOLUTION SIMPLE: Utiliser la méthode publique existante
        // Le compteur sera automatiquement corrigé par le signal Django
        _messagingProvider.addMessageLocally(conversationId, newMessage);
      }
      
      // Mettre à jour la conversation dans la liste
      _updateConversationWithNewMessage(newMessage);
      
      notifyListeners();
      
    } catch (e) {
      print('❌ Erreur lors du traitement du nouveau message: $e');
    }
  }

  /// Gérer un message de chat direct
  void _handleChatMessage(Map<String, dynamic> message) {
    try {
      final messageData = message['message'] as Map<String, dynamic>?;
      if (messageData == null) return;

      print('💬 Message de chat reçu: ${messageData['content']}');

      // Créer l'objet message
      final newMessage = Message.fromJson(messageData, _messagingProvider.currentUserId ?? 0);
      
      final conversationId = newMessage.conversationId;
      if (conversationId != null) {
        // ✅ SOLUTION SIMPLE: Utiliser la méthode publique existante
        // Le compteur sera automatiquement corrigé par le signal Django
        _messagingProvider.addMessageLocally(conversationId, newMessage);
      }
      
      // Mettre à jour la conversation dans la liste
      _updateConversationWithNewMessage(newMessage);
      
      notifyListeners();
      
    } catch (e) {
      print('❌ Erreur lors du traitement du message de chat: $e');
    }
  }

  /// Gérer un message marqué comme lu
  void _handleMessageRead(Map<String, dynamic> message) {
    try {
      final conversationId = message['conversation_id'] as int?;
      final messageId = message['message_id'] as int?;
      
      if (conversationId == null) return;

      print('✅ Message marqué comme lu dans conversation: $conversationId');
      
      // Mettre à jour les messages dans le provider
      if (messageId != null) {
        _messagingProvider.markMessageAsReadLocally(conversationId, messageId);
      } else {
        _messagingProvider.markAllMessagesAsReadLocally(conversationId);
      }
      
      notifyListeners();
      
    } catch (e) {
      print('❌ Erreur lors du marquage du message comme lu: $e');
    }
  }

  /// Gérer un message supprimé
  void _handleMessageDeleted(Map<String, dynamic> message) {
    try {
      final conversationId = message['conversation_id'] as int?;
      final messageId = message['message_id'] as int?;
      
      if (conversationId == null || messageId == null) return;

      print('🗑️ Message supprimé: $messageId');
      
      // Supprimer le message du provider
      _messagingProvider.removeMessageLocally(conversationId, messageId);
      
      notifyListeners();
      
    } catch (e) {
      print('❌ Erreur lors de la suppression du message: $e');
    }
  }

  /// Gérer les mises à jour de conversation
  void _handleConversationUpdate(Map<String, dynamic> message) {
    try {
      final eventType = message['event_type'] as String?;
      
      switch (eventType) {
        case 'conversation_created':
          _handleConversationCreated(message);
          break;
        case 'participant_added':
          _handleParticipantAdded(message);
          break;
        case 'participant_removed':
          _handleParticipantRemoved(message);
          break;
        default:
          print('💬 Type d\'événement de conversation non géré: $eventType');
      }
    } catch (e) {
      print('❌ Erreur lors du traitement de la mise à jour de conversation: $e');
    }
  }

  /// Gérer une nouvelle conversation créée
  void _handleConversationCreated(Map<String, dynamic> message) {
    try {
      final conversationData = message['conversation'] as Map<String, dynamic>?;
      if (conversationData == null) return;

      print('💬 Nouvelle conversation créée: ${conversationData['id']}');
      
      // Recharger les conversations
      _messagingProvider.fetchConversations();
      
    } catch (e) {
      print('❌ Erreur lors du traitement de la nouvelle conversation: $e');
    }
  }

  /// Gérer l'ajout d'un participant
  void _handleParticipantAdded(Map<String, dynamic> message) {
    print('👤 Participant ajouté à la conversation');
    // Implémenter la logique selon les besoins
  }

  /// Gérer la suppression d'un participant
  void _handleParticipantRemoved(Map<String, dynamic> message) {
    print('👤 Participant supprimé de la conversation');
    // Implémenter la logique selon les besoins
  }

  /// Gérer l'indicateur de frappe
  void _handleTypingIndicator(Map<String, dynamic> message) {
    try {
      final conversationId = message['conversation_id'] as int?;
      final userId = message['user_id'] as int?;
      final isTyping = message['is_typing'] as bool?;
      
      if (conversationId == null || userId == null || isTyping == null) return;

      print('⌨️ Indicateur de frappe: user $userId ${isTyping ? 'tape' : 'arrête de taper'}');
      
      // Implémenter la logique de l'indicateur de frappe
      // _messagingProvider.updateTypingStatus(conversationId, userId, isTyping);
      
      notifyListeners();
      
    } catch (e) {
      print('❌ Erreur lors du traitement de l\'indicateur de frappe: $e');
    }
  }

  /// Gérer la confirmation de connexion
  void _handleConnectionEstablished(Map<String, dynamic> message) {
    print('✅ Connexion WebSocket établie pour les messages');
    
    // Rejoindre la conversation actuelle si elle existe
    if (_currentConversationId != null) {
      _webSocketService.joinConversation(_currentConversationId!);
    }
  }

  /// Mettre à jour une conversation avec un nouveau message
  void _updateConversationWithNewMessage(Message message) {
    try {
      final conversations = _messagingProvider.conversations;
      final conversationIndex = conversations.indexWhere((c) => c.id == message.conversationId);
      
      if (conversationIndex != -1) {
        final conversation = conversations[conversationIndex];
        
        // Créer le nouveau dernier message
        final lastMessage = LastMessage(
          content: message.content,
          senderId: message.senderId,
          createdAt: message.createdAt,
          isRead: message.isRead,
        );
        
        // ✅ MODIFICATION: Ne pas incrémenter unreadCount manuellement
        // Le compteur sera mis à jour automatiquement par le signal Django
        final updatedConversation = Conversation(
          id: conversation.id,
          otherPerson: conversation.otherPerson,
          currentUserId: conversation.currentUserId,
          lastMessage: lastMessage,
          unreadCount: conversation.unreadCount, // ✅ Garder la valeur actuelle
          createdAt: conversation.createdAt,
          isOnline: conversation.isOnline,
        );
        
        // Mettre à jour la conversation
        _messagingProvider.updateConversationLocally(conversationIndex, updatedConversation);
      }
    } catch (e) {
      print('❌ Erreur lors de la mise à jour de la conversation: $e');
    }
  }

  void requestInitialCounts() {
    if (_webSocketService.isConnected) {
      _webSocketService.sendMessage({
        'type': 'get_counts',
      });
      print('💬 Demande des compteurs initiaux envoyée');
    }
  }

  /// Envoyer un indicateur de frappe
  void sendTypingIndicator(int conversationId, bool isTyping) {
    if (!_webSocketService.isConnected) return;
    
    _webSocketService.sendMessage({
      'type': 'typing_indicator',
      'conversation_id': conversationId,
      'is_typing': isTyping,
    });
  }

  @override
  void dispose() {
    print('💬 RealtimeMessagingProvider disposing...');
    stopListening();
    super.dispose();
  }
}