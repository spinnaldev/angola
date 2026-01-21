// lib/ui/screens/messaging/conversation_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../../providers/messaging_provider.dart';
import '../../../providers/realtime_messaging_provider.dart';
import '../../../core/models/conversation.dart';
import '../../../core/models/message.dart';

class ConversationDetailScreen extends StatefulWidget {
  final int conversationId;
  final Person otherPerson;
  final int? highlightMessageId;
  const ConversationDetailScreen({
    Key? key,
    required this.conversationId,
    required this.otherPerson,
    this.highlightMessageId,
  }) : super(key: key);

  @override
  _ConversationDetailScreenState createState() => _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> 
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  bool _isComposing = false;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Charger les messages de la conversation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeConversation();
    });
    
    // Écouter les changements du champ de texte
    _messageController.addListener(() {
      final isComposing = _messageController.text.isNotEmpty;
      if (_isComposing != isComposing) {
        setState(() {
          _isComposing = isComposing;
        });
        
        // Envoyer l'indicateur de frappe
        context.read<RealtimeMessagingProvider>()
            .sendTypingIndicator(widget.conversationId, isComposing);
      }
    });

    // Écouter les changements de focus
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isComposing) {
        // Arrêter l'indicateur de frappe quand on perd le focus
        context.read<RealtimeMessagingProvider>()
            .sendTypingIndicator(widget.conversationId, false);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    
    // Quitter la conversation et arrêter l'indicateur de frappe
    context.read<RealtimeMessagingProvider>()
      ..sendTypingIndicator(widget.conversationId, false)
      ..leaveCurrentConversation();
    
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // Arrêter l'indicateur de frappe quand l'app passe en arrière-plan
      context.read<RealtimeMessagingProvider>()
          .sendTypingIndicator(widget.conversationId, false);
    }
  }

  /// Initialiser la conversation
  void _initializeConversation() {
    final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
    final realtimeProvider = Provider.of<RealtimeMessagingProvider>(context, listen: false);
    
    // Charger les messages
    messagingProvider.fetchMessages(widget.conversationId);
    
    // Rejoindre la conversation pour les messages en temps réel
    realtimeProvider.joinConversation(widget.conversationId);
    
    // Marquer les messages comme lus
    messagingProvider.markMessagesAsRead(widget.conversationId);
  }

  /// Faire défiler vers le bas
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Gérer l'envoi d'un message
  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    
    final trimmedText = text.trim();
    _messageController.clear();
    setState(() {
      _isComposing = false;
    });
    
    // Arrêter l'indicateur de frappe
    context.read<RealtimeMessagingProvider>()
        .sendTypingIndicator(widget.conversationId, false);
    
    final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
    final success = await messagingProvider.sendMessage(widget.conversationId, trimmedText);
    
    if (success) {
      // Faire défiler vers le bas après l'envoi
      Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
    } else {
      // Afficher un message d'erreur si l'envoi a échoué
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.messageSendError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: _buildAppBar(l10n),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildMessageInput(l10n),
        ],
      ),
    );
  }

  /// Construire l'app bar
  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      title: InkWell(
      onTap: () {
        if (widget.otherPerson.companyName != null ) {
          Navigator.pushNamed(
            context,
            '/provider-detail',
            arguments: widget.otherPerson.id,
          );
        } else {
          // Navigation vers profil client (si tu as un écran pour ça)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profil client non disponible')),
          );
        }
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF142FE2).withOpacity(0.1),
            backgroundImage: widget.otherPerson.profilePicture != null
                ? NetworkImage(widget.otherPerson.profilePicture!)
                : null,
            child: widget.otherPerson.profilePicture == null
                ? Text(
                    _getInitials(widget.otherPerson.firstName),
                    style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      widget.otherPerson.firstName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Icône pour indiquer que c'est cliquable
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
      actions: [
        // IconButton(
        //   icon: const Icon(Icons.phone),
        //   onPressed: () {
        //     // Implémenter l'appel téléphonique
        //   },
        // ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // Afficher les options de conversation
            _showConversationOptions(l10n);
          },
        ),
      ],
    );
  }

  /// Construire la liste des messages
  Widget _buildMessagesList() {
    return Consumer<MessagingProvider>(
      builder: (context, messagingProvider, child) {
        final messages = messagingProvider.getMessagesForConversation(widget.conversationId);
        
        if (messagingProvider.isLoading && _isFirstLoad) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noMessagesYet,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // Marquer les messages comme lus quand ils sont affichés
        if (_isFirstLoad) {
          _isFirstLoad = false;
          Future.delayed(const Duration(milliseconds: 500), () {
            messagingProvider.markMessagesAsRead(widget.conversationId);
            _scrollToBottom();
          });
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == messagingProvider.currentUserId;
            final showDate = _shouldShowDate(messages, index);
            
            return Column(
              children: [
                if (showDate) _buildDateSeparator(message.createdAt),
                _buildMessageBubble(message, isMe),
              ],
            );
          },
        );
      },
    );
  }

  /// Construire le champ de saisie de message
  Widget _buildMessageInput(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: l10n.typeMessage,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: _handleSubmitted,
                  maxLines: null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Consumer<MessagingProvider>(
              builder: (context, messagingProvider, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: _isComposing
                        ? const Color(0xFF6366F1)
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: messagingProvider.isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send),
                    color: _isComposing ? Colors.white : Colors.grey[600],
                    onPressed: _isComposing && !messagingProvider.isSending
                        ? () => _handleSubmitted(_messageController.text)
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Construire une bulle de message
  Widget _buildMessageBubble(Message message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF142FE2).withOpacity(0.1),
              backgroundImage: widget.otherPerson.profilePicture != null
                  ? NetworkImage(widget.otherPerson.profilePicture!)
                  : null,
              child: widget.otherPerson.profilePicture == null
                  ? Text(
                      _getInitials(widget.otherPerson.firstName),
                      style: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              margin: EdgeInsets.only(
                left: isMe ? 50 : 0,
                right: isMe ? 0 : 50,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF6366F1) : Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            Icon(
              message.isRead ? Icons.done_all : Icons.done,
              color: message.isRead ? Colors.blue : Colors.grey,
              size: 16,
            ),
          ],
        ],
      ),
    );
  }

  /// Construire un séparateur de date
  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDate(date),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  /// Afficher les options de conversation
  void _showConversationOptions(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.conversationInfo),
            onTap: () {
              Navigator.pop(context);
              // Afficher les informations de la conversation
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_off),
            title: Text(l10n.muteConversation),
            onTap: () {
              Navigator.pop(context);
              // Mettre en sourdine la conversation
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(l10n.deleteConversation),
            onTap: () {
              Navigator.pop(context);
              // Supprimer la conversation
            },
          ),
        ],
      ),
    );
  }

  /// Vérifier si on doit afficher la date
  bool _shouldShowDate(List<Message> messages, int index) {
    if (index == 0) return true;
    
    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];
    
    return !_isSameDay(currentMessage.createdAt, previousMessage.createdAt);
  }

  /// Vérifier si deux dates sont le même jour
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Formater une date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate == today) {
      return AppLocalizations.of(context)!.today;
    } else if (messageDate == yesterday) {
      return AppLocalizations.of(context)!.yesterday;
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  /// Obtenir les initiales d'un nom
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}