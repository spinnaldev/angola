// lib/core/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance => _instance ??= WebSocketService._();
  
  WebSocketService._();

  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  StreamSubscription? _subscription;
  
  String? _wsUrl;
  int? _userId;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration reconnectDelay = Duration(seconds: 3);
  static const Duration heartbeatInterval = Duration(seconds: 30);

  WebSocketChannel? _generalChannel;
  Stream<Map<String, dynamic>>? _generalStream;
  
  // Getters
  bool get isConnected => _isConnected;
  Stream<Map<String, dynamic>>? get messageStream => _messageController?.stream;

  /// Initialiser la connexion WebSocket
  Future<void> connect(String baseUrl, int userId) async {
    if (_isConnected && _userId == userId) {
      print('✅ WebSocket déjà connecté pour l\'utilisateur $userId');
      return;
    }

    _userId = userId;
    // ✅ MODIFICATION: Utiliser le consumer général au lieu du consumer user spécifique
    _wsUrl = '${baseUrl.replaceFirst('http', 'ws')}/ws/user/$userId/';
    
    try {
      await _connect();
    } catch (e) {
      print('❌ Erreur lors de la connexion WebSocket: $e');
      _scheduleReconnect();
    }
  }

  /// Établir la connexion WebSocket
  Future<void> _connect() async {
    if (_wsUrl == null) {
      throw Exception('URL WebSocket non définie');
    }

    print('🔌 Connexion WebSocket à: $_wsUrl');
    
    // Fermer la connexion existante si elle existe
    await disconnect();

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl!));
      _messageController = StreamController<Map<String, dynamic>>.broadcast();

      // Écouter les messages entrants
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      
      print('✅ WebSocket connecté avec succès');
      
      // Démarrer le heartbeat
      _startHeartbeat();

      // Envoyer un message de connexion
      _sendConnectionMessage();

    } catch (e) {
      print('❌ Erreur de connexion WebSocket: $e');
      _isConnected = false;
      throw e;
    }
  }

  /// Gérer les messages entrants
  void _handleMessage(dynamic data) {
    try {
      final Map<String, dynamic> message = json.decode(data);
      print('📨 Message WebSocket reçu: ${message['type']}');
      
      // Ajouter le message au stream
      _messageController?.add(message);
      
    } catch (e) {
      print('❌ Erreur lors du parsing du message WebSocket: $e');
    }
  }

  /// Gérer les erreurs WebSocket
  void _handleError(error) {
    print('❌ Erreur WebSocket: $error');
    _isConnected = false;
    _scheduleReconnect();
  }

  /// Gérer la déconnexion WebSocket
  void _handleDisconnection() {
    print('🔌 WebSocket déconnecté');
    _isConnected = false;
    _stopHeartbeat();
    _scheduleReconnect();
  }

  /// Programmer une reconnexion
  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      print('❌ Nombre maximum de tentatives de reconnexion atteint');
      return;
    }

    _reconnectAttempts++;
    print('🔄 Tentative de reconnexion ${_reconnectAttempts}/$maxReconnectAttempts dans ${reconnectDelay.inSeconds}s');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () {
      if (!_isConnected) {
        _connect().catchError((e) {
          print('❌ Échec de la reconnexion: $e');
          _scheduleReconnect();
        });
      }
    });
  }

  /// Démarrer le heartbeat
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (timer) {
      if (_isConnected) {
        sendMessage({
          'type': 'heartbeat',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });
  }

  /// Arrêter le heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Envoyer le message de connexion initial
  void _sendConnectionMessage() {
    sendMessage({
      'type': 'connection',
      'user_id': _userId,
      'client_type': 'flutter',
    });
    
    // ✅ NOUVEAU: Demander les compteurs initiaux après connexion
    Future.delayed(Duration(milliseconds: 500), () {
      requestInitialCounts();
    });
  }

  void requestInitialCounts() {
    sendMessage({
      'type': 'get_counts',
    });
    print('📊 Demande des compteurs initiaux envoyée');
  }

  /// Demander le nombre de notifications non lues (méthode existante conservée)
  void requestUnreadCount() {
    sendMessage({
      'type': 'get_unread_count',
    });
  }

  /// Envoyer un message via WebSocket
  void sendMessage(Map<String, dynamic> message) {
    if (!_isConnected || _channel == null) {
      print('❌ WebSocket non connecté, impossible d\'envoyer le message');
      return;
    }

    try {
      final jsonMessage = json.encode(message);
      _channel!.sink.add(jsonMessage);
      print('📤 Message WebSocket envoyé: ${message['type']}');
    } catch (e) {
      print('❌ Erreur lors de l\'envoi du message WebSocket: $e');
    }
  }

  /// Marquer une notification comme lue
  void markNotificationAsRead(int notificationId) {
    sendMessage({
      'type': 'mark_as_read',
      'notification_id': notificationId,
    });
  }

  /// Marquer toutes les notifications comme lues
  void markAllNotificationsAsRead() {
    sendMessage({
      'type': 'mark_all_as_read',
    });
  }

  /// Se joindre à une conversation
  void joinConversation(int conversationId) {
    sendMessage({
      'type': 'join_conversation',
      'conversation_id': conversationId,
    });
  }

  /// Quitter une conversation
  void leaveConversation(int conversationId) {
    sendMessage({
      'type': 'leave_conversation',
      'conversation_id': conversationId,
    });
  }

  void requestUnreadMessageCount() {
    sendMessage({
      'type': 'get_message_count',
    });
    print('💬 Demande du compteur de messages envoyée');
  }

  /// ✅ NOUVEAU: Marquer des messages comme lus via WebSocket
  void markMessagesAsRead(int conversationId) {
    sendMessage({
      'type': 'mark_messages_as_read',
      'conversation_id': conversationId,
    });
    print('✅ Demande de marquage messages comme lus envoyée pour conversation $conversationId');
  }
  
  /// Déconnecter le WebSocket
  Future<void> disconnect() async {
    print('🔌 Déconnexion WebSocket...');
    
    _isConnected = false;
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    
    await _subscription?.cancel();
    _subscription = null;
    
    await _channel?.sink.close(status.goingAway);
    _channel = null;
    
    await _messageController?.close();
    _messageController = null;
    
    print('✅ WebSocket déconnecté');
  }

  /// Nettoyer les ressources
  void dispose() {
    disconnect();
    _instance = null;
  }
}