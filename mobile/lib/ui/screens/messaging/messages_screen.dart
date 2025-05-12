import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/messaging_provider.dart';
import '../base_screen.dart';
import 'conversation_detail_screen.dart';
import '../../../core/models/conversation.dart';
import '../../widgets/app_bottom_navigation.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Charger les conversations au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MessagingProvider>(context, listen: false).fetchConversations();
    });
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      currentIndex: 2, // messaging est sélectionné
      body: _buildMessagingContent(),
    );
  }
  Widget _buildMessagingContent() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Messagerie',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              // Action pour les notifications
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un message...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          
          // En-tête "Tous les messages"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tous les messages',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          ),
          
          // Liste des conversations
          Expanded(
            child: Consumer<MessagingProvider>(
              builder: (context, messagingProvider, child) {
                if (messagingProvider.isLoading && messagingProvider.conversations.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                var conversations = messagingProvider.conversations;
                
                // Filtrer les conversations si une recherche est en cours
                if (_searchQuery.isNotEmpty) {
                  conversations = conversations.where((conv) => 
                    conv.otherPerson.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    (conv.lastMessage?.content ?? '').toLowerCase().contains(_searchQuery.toLowerCase())
                  ).toList();
                }

                if (conversations.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty 
                        ? 'Aucune conversation' 
                        : 'Aucun résultat pour "$_searchQuery"',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: conversations.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    return _buildConversationItem(conversations[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildConversationItem(Conversation conversation) {
    final lastMessage = conversation.lastMessage;
    final hasUnread = conversation.unreadCount > 0;
    
    // Formater l'heure du dernier message
    String timeString = '';
    if (lastMessage != null) {
      timeString = _formatTime(lastMessage.createdAt);
    } else {
      timeString = _formatTime(conversation.createdAt);
    }
    
    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.grey[300],
        child: Text(
          conversation.otherPerson.initials,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        conversation.otherPerson.fullName,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Row(
        children: [
          // Icône de statut pour les messages
          if (lastMessage != null && lastMessage.senderId == conversation.currentUserId)
            Icon(
              lastMessage.isRead ? Icons.done_all : Icons.done,
              size: 14,
              color: lastMessage.isRead ? Colors.blue : Colors.grey,
            ),
          if (lastMessage != null && lastMessage.senderId == conversation.currentUserId)
            const SizedBox(width: 4),
          // Message
          Expanded(
            child: Text(
              lastMessage?.content ?? 'Démarrer une conversation...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasUnread ? Colors.black : Colors.grey[600],
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timeString,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          // Indicateur de statut en ligne
          if (!hasUnread)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: conversation.isOnline ? Colors.green : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationDetailScreen(
              conversationId: conversation.id,
              otherPerson: conversation.otherPerson,
            ),
          ),
        ).then((_) {
          // Rafraîchir les conversations au retour
          Provider.of<MessagingProvider>(context, listen: false).fetchConversations();
        });
      },
    );
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(today.day - 1);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (date == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (date == yesterday) {
      return 'Hier';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}