// lib/providers/messaging_provider.dart
import 'package:flutter/foundation.dart';
import '../core/models/conversation.dart';
import '../core/models/message.dart';
import '../core/services/api_service.dart';

class MessagingProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Conversation> _conversations = [];
  Map<int, List<Message>> _messages = {};
  bool _isLoading = false;
  bool _isSending = false;
  int? _currentConversationId;
  int? _currentUserId;

  MessagingProvider(this._apiService);

  // Getters
  List<Conversation> get conversations => _conversations;
  List<Message> getMessagesForConversation(int conversationId) => 
      _messages[conversationId] ?? [];
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  int? get currentUserId => _currentUserId;

  // Méthode pour définir l'utilisateur actuel
  void setCurrentUserId(int userId) {
    _currentUserId = userId;
  }

  Future<void> fetchConversations() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_currentUserId == null) {
        _currentUserId = await _apiService.getCurrentUserId();
      }

      _conversations = await _apiService.getConversations();
      
    } catch (error) {
      print('Error fetching conversations: $error');
      _conversations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Conversation?> startConversation(int? providerId, String? initialMessage, {int? clientId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_currentUserId == null) {
        _currentUserId = await _apiService.getCurrentUserId();
      }

      Map<String, dynamic> conversationData;
      
      if (providerId != null) {
        conversationData = await _apiService.startConversation(providerId, initialMessage);
      } else if (clientId != null) {
        // Logique pour démarrer une conversation avec un client
        conversationData = await _apiService.startConversationWithClient(clientId, initialMessage);
      } else {
        throw Exception('Ni providerId ni clientId fourni');
      }
      
      final conversation = Conversation.fromJson(conversationData, _currentUserId!);
      
      final existingIndex = _conversations.indexWhere((c) => c.id == conversation.id);
      if (existingIndex != -1) {
        _conversations[existingIndex] = conversation;
      } else {
        _conversations.insert(0, conversation);
      }
      
      _isLoading = false;
      notifyListeners();
      return conversation;
      
    } catch (error) {
      print('Error starting conversation: $error');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Conversation?> startConversationWithProvider(int providerId, {String? initialMessage}) async {
    return startConversation(providerId, initialMessage);
  }

  Future<Conversation?> startConversationWithClient(int clientId, {String? initialMessage}) async {
    return startConversation(null, initialMessage, clientId: clientId);
  }
  // Future<Conversation?> startConversationWithClient(int clientId, {String? initialMessage}) async {
  //   return startConversation(null, initialMessage, clientId: clientId);
  // }

  Future<Conversation?> startConversationFromProject(int projectId, {String? initialMessage}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_currentUserId == null) {
        _currentUserId = await _apiService.getCurrentUserId();
      }

      final conversationData = await _apiService.startConversationFromProject(
        projectId,
        initialMessage,
      );
      
      final conversation = Conversation.fromJson(conversationData, _currentUserId!);
      
      final existingIndex = _conversations.indexWhere((c) => c.id == conversation.id);
      if (existingIndex != -1) {
        _conversations[existingIndex] = conversation;
      } else {
        _conversations.insert(0, conversation);
      }
      
      _isLoading = false;
      notifyListeners();
      return conversation;
      
    } catch (error) {
      print('Error starting conversation from project: $error');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> fetchMessages(int conversationId) async {
    _isLoading = true;
    _currentConversationId = conversationId;
    notifyListeners();

    try {
      final fetchedMessages = await _apiService.getMessages(conversationId);
      _messages[conversationId] = fetchedMessages;
    } catch (error) {
      print('Error fetching messages: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(int conversationId, String content) async {
    _isSending = true;
    notifyListeners();

    try {
      final message = await _apiService.sendMessage(conversationId, content);
      
      // Ajouter le message à la liste
      if (_messages.containsKey(conversationId)) {
        _messages[conversationId]!.add(message);
      } else {
        _messages[conversationId] = [message];
      }
      
      // Mettre à jour le dernier message dans la conversation
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        final conversation = _conversations[index];
        final updatedLastMessage = LastMessage(
          content: content,
          senderId: message.senderId,
          createdAt: DateTime.now(),
          isRead: false,
        );
        
        // Créer une nouvelle conversation avec le dernier message mis à jour
        final updatedConversation = Conversation(
          id: conversation.id,
          otherPerson: conversation.otherPerson,
          currentUserId: conversation.currentUserId,
          lastMessage: updatedLastMessage,
          unreadCount: conversation.unreadCount,
          createdAt: conversation.createdAt,
          isOnline: conversation.isOnline,
        );
        
        // Mettre à jour la liste des conversations
        _conversations[index] = updatedConversation;
      }
      
      _isSending = false;
      notifyListeners();
      return true;
    } catch (error) {
      print('Error sending message: $error');
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  /// Marquer les messages d'une conversation comme lus
  Future<bool> markMessagesAsRead(int conversationId) async {
    try {
      final success = await _apiService.markMessagesAsRead(conversationId);
      
      if (success) {
        // Mettre à jour localement les messages comme lus
        markAllMessagesAsReadLocally(conversationId);
        
        // Mettre à jour le compteur non lu de la conversation
        final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
        if (conversationIndex != -1) {
          final conversation = _conversations[conversationIndex];
          final updatedConversation = Conversation(
            id: conversation.id,
            otherPerson: conversation.otherPerson,
            currentUserId: conversation.currentUserId,
            lastMessage: conversation.lastMessage,
            unreadCount: 0,
            createdAt: conversation.createdAt,
            isOnline: conversation.isOnline,
          );
          _conversations[conversationIndex] = updatedConversation;
          notifyListeners();
        }
      }
      
      return success;
    } catch (error) {
      print('Error marking messages as read: $error');
      return false;
    }
  }

  int getTotalUnreadCount() {
    return _conversations.fold(0, (sum, conversation) => sum + conversation.unreadCount);
  }

  // ========================================
  // MÉTHODES POUR LES TEMPS RÉEL
  // ========================================

  /// Ajouter un message localement (pour WebSocket)
  void addMessageLocally(int conversationId, Message message) {
    if (_messages.containsKey(conversationId)) {
      // Vérifier si le message n'existe pas déjà
      if (!_messages[conversationId]!.any((m) => m.id == message.id)) {
        _messages[conversationId]!.add(message);
        notifyListeners();
      }
    } else {
      _messages[conversationId] = [message];
      notifyListeners();
    }
  }

  /// Marquer un message comme lu localement
  void markMessageAsReadLocally(int conversationId, int messageId) {
    if (_messages.containsKey(conversationId)) {
      final messageIndex = _messages[conversationId]!.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        final message = _messages[conversationId]![messageIndex];
        if (!message.isRead) {
          _messages[conversationId]![messageIndex] = Message(
            id: message.id,
            conversationId: message.conversationId,
            senderId: message.senderId,
            senderName: message.senderName,
            content: message.content,
            createdAt: message.createdAt,
            isRead: true,
          );
          notifyListeners();
        }
      }
    }
  }

  /// Marquer tous les messages d'une conversation comme lus localement
  void markAllMessagesAsReadLocally(int conversationId) {
    if (_messages.containsKey(conversationId)) {
      bool hasChanges = false;
      for (int i = 0; i < _messages[conversationId]!.length; i++) {
        final message = _messages[conversationId]![i];
        if (!message.isRead) {
          _messages[conversationId]![i] = Message(
            id: message.id,
            conversationId: message.conversationId,
            senderId: message.senderId,
            senderName: message.senderName,
            content: message.content,
            createdAt: message.createdAt,
            isRead: true,
          );
          hasChanges = true;
        }
      }
      if (hasChanges) {
        notifyListeners();
      }
    }
  }

  /// Supprimer un message localement
  void removeMessageLocally(int conversationId, int messageId) {
    if (_messages.containsKey(conversationId)) {
      _messages[conversationId]!.removeWhere((m) => m.id == messageId);
      notifyListeners();
    }
  }

  /// Mettre à jour une conversation localement
  void updateConversationLocally(int index, Conversation updatedConversation) {
    if (index >= 0 && index < _conversations.length) {
      _conversations[index] = updatedConversation;
      notifyListeners();
    }
  }

  /// Ajouter ou mettre à jour une conversation localement
  void addOrUpdateConversationLocally(Conversation conversation) {
    final existingIndex = _conversations.indexWhere((c) => c.id == conversation.id);
    if (existingIndex != -1) {
      _conversations[existingIndex] = conversation;
    } else {
      _conversations.insert(0, conversation);
    }
    notifyListeners();
  }

  /// Supprimer une conversation localement
  void removeConversationLocally(int conversationId) {
    _conversations.removeWhere((c) => c.id == conversationId);
    _messages.remove(conversationId);
    notifyListeners();
  }

  /// Nettoyer les données
  void clearData() {
    _conversations.clear();
    _messages.clear();
    _currentConversationId = null;
    _currentUserId = null;
    notifyListeners();
  }
}