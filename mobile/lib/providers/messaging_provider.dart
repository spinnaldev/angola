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

  MessagingProvider(this._apiService);

  List<Conversation> get conversations => _conversations;
  List<Message> getMessagesForConversation(int conversationId) => 
      _messages[conversationId] ?? [];
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  int? get currentConversationId => _currentConversationId;

  Future<void> fetchConversations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedConversations = await _apiService.getConversations();
      _conversations = fetchedConversations;
    } catch (error) {
      print('Error fetching conversations: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
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

  Future<Conversation?> startConversation(int providerId, {String? initialMessage}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final conversation = await _apiService.startConversation(providerId, initialMessage);
      
      // Ajouter la nouvelle conversation à la liste
      _conversations.insert(0, conversation);
      
      // Si un message initial a été envoyé
      if (initialMessage != null && initialMessage.isNotEmpty) {
        final message = await _apiService.getInitialMessage(conversation.id);
        if (message != null) {
          _messages[conversation.id] = [message];
        }
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

  int getTotalUnreadCount() {
    return _conversations.fold(0, (sum, conversation) => sum + conversation.unreadCount);
  }
}