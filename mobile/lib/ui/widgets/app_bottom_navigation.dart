// lib/ui/widgets/app_bottom_navigation.dart - CORRIGÉ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/auth_provider.dart';
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
    // Vérifier si l'utilisateur est connecté
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = authProvider.isAuthenticated;
    
    // DEBUG : Afficher le profil actuel
    print("🔍 AppBottomNavigation - Profil détecté:");
    print("   - Authentifié: $isAuthenticated");
    print("   - Mode prestataire: ${ProfileManager.isProviderMode()}");
    
    if (isAuthenticated && ProfileManager.isProviderMode()) {
      // ✅ Navigation pour PRESTATAIRES : Accueil, Projets, Messages, Profil
      print("   → Menu PRESTATAIRE: Accueil(0), Projets(1), Messages(2), Profil(3)");
      return [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Accueil',  // Index 0
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.work_outline),
          activeIcon: Icon(Icons.work),
          label: 'Projets',  // Index 1
        ),
        BottomNavigationBarItem(
          icon: _buildMessagesIcon(context),
          activeIcon: _buildMessagesActiveIcon(context),
          label: 'Messages',  // Index 2
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',   // Index 3
        ),
      ];
    } else {
      // ✅ Navigation pour CLIENTS ou utilisateurs non connectés : Accueil, Explorer, Messages, Profil
      print("   → Menu CLIENT: Accueil(0), Explorer(1), Messages(2), Profil(3)");
      return [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Accueil',   // Index 0
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          activeIcon: Icon(Icons.search),
          label: 'Explorer',  // Index 1
        ),
        BottomNavigationBarItem(
          icon: _buildMessagesIcon(context),
          activeIcon: _buildMessagesActiveIcon(context),
          label: 'Messages',  // Index 2
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',    // Index 3
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
      height: 80, // Hauteur augmentée comme demandé
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF142FE2),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
            fontSize: 13, // Légèrement plus grand
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          iconSize: 26, // Icônes légèrement plus grandes
          items: _getNavigationItems(context),
        ),
      ),
    );
  }
}