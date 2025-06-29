// lib/ui/widgets/app_bottom_navigation.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/messaging_provider.dart';
import '../../core/services/profile_manager.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  /// Récupère les éléments de navigation selon le profil actuel
  List<BottomNavigationBarItem> _getNavigationItems(BuildContext context) {
    if (ProfileManager.isProviderMode()) {
      // Navigation pour prestataires : Demandes de devis, Litige, Messages, Profil
      return [
        const BottomNavigationBarItem(
          icon: Icon(Icons.request_quote_outlined),
          activeIcon: Icon(Icons.request_quote),
          label: 'Demandes',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.gavel_outlined),
          activeIcon: Icon(Icons.gavel),
          label: 'Litigess',
        ),
        BottomNavigationBarItem(
          icon: _buildMessagesIcon(context),
          activeIcon: _buildMessagesActiveIcon(context),
          label: 'Messages',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ];
    } else {
      // Navigation pour clients : Accueil, Explorer, Messages, Profil
      return [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Accueil',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          activeIcon: Icon(Icons.search),
          label: 'Explorer',
        ),
        BottomNavigationBarItem(
          icon: _buildMessagesIcon(context),
          activeIcon: _buildMessagesActiveIcon(context),
          label: 'Messages',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ];
    }
  }

  /// Construit l'icône des messages avec badge de notification
  Widget _buildMessagesIcon(BuildContext context) {
    return Consumer<MessagingProvider>(
      builder: (context, messagingProvider, child) {
        final unreadCount = messagingProvider.getTotalUnreadCount();
        return Stack(
          children: [
            const Icon(Icons.chat_bubble_outline),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Construit l'icône active des messages avec badge de notification
  Widget _buildMessagesActiveIcon(BuildContext context) {
    return Consumer<MessagingProvider>(
      builder: (context, messagingProvider, child) {
        final unreadCount = messagingProvider.getTotalUnreadCount();
        return Stack(
          children: [
            const Icon(Icons.chat_bubble),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        items: _getNavigationItems(context),
      ),
    );
  }
}