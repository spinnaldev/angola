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

      // Pas besoin de parser, les objets sont déjà créés
      _conversations = await _apiService.getConversations();
      
    } catch (error) {
      print('Error fetching conversations: $error');
      _conversations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Conversation?> startConversation(int providerId, {String? initialMessage}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Obtenir l'ID de l'utilisateur actuel si pas encore défini
      if (_currentUserId == null) {
        _currentUserId = await _apiService.getCurrentUserId();
      }

      // Récupérer les données JSON brutes
      final conversationData = await _apiService.startConversation(providerId, initialMessage);
      
      // Créer l'objet Conversation à partir des données JSON
      final conversation = Conversation.fromJson(conversationData, _currentUserId!);
      
      // Vérifier si la conversation existe déjà dans la liste
      final existingIndex = _conversations.indexWhere((c) => c.id == conversation.id);
      
      if (existingIndex != -1) {
        // Mettre à jour la conversation existante
        _conversations[existingIndex] = conversation;
      } else {
        // Ajouter la nouvelle conversation au début de la liste
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
    _isLoading = true;
    notifyListeners();

    try {
      if (_currentUserId == null) {
        _currentUserId = await _apiService.getCurrentUserId();
      }

      // Utiliser la méthode mise à jour avec providerId
      final conversationData = await _apiService.startConversation(
        providerId, 
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
      print('Error starting conversation with provider: $error');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Conversation?> startConversationWithClient(int clientId, {String? initialMessage}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_currentUserId == null) {
        _currentUserId = await _apiService.getCurrentUserId();
      }

      // Utiliser la méthode mise à jour avec clientId
      final conversationData = await _apiService.startConversation(
        null, // pas de providerId
        initialMessage,
        clientId: clientId,
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
      print('Error starting conversation with client: $error');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

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

  int getTotalUnreadCount() {
    return _conversations.fold(0, (sum, conversation) => sum + conversation.unreadCount);
  }
}