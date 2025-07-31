// lib/ui/widgets/app_bottom_navigation.dart - HAUTEUR FIXE + RESPONSIVITÉ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

  @override
  Widget build(BuildContext context) {
    // 📱 SOLUTION 1: Hauteur fixe avec gestion des zones de sécurité
    return _buildFixedHeightWithSafeArea(context);
    
    // 🔄 Alternatives disponibles :
    // return _buildCalculatedHeight(context);
    // return _buildContainerApproach(context);
  }

  /// 🎯 SOLUTION 1: Hauteur fixe + SafeArea interne
  Widget _buildFixedHeightWithSafeArea(BuildContext context) {
    const double fixedHeight = 80; // Votre hauteur souhaitée
    
    return Container(
      height: fixedHeight + MediaQuery.of(context).padding.bottom,
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
      child: Column(
        children: [
          // Zone de navigation avec votre hauteur fixe
          SizedBox(
            height: fixedHeight,
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: onTap,
              items: _getNavigationItems(context),
              selectedItemColor: const Color(0xFF4B39EF),
              unselectedItemColor: Colors.grey.shade600,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          // Padding pour les zones de sécurité (boutons système)
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  /// 🎯 SOLUTION 2: Hauteur calculée intelligemment
  Widget _buildCalculatedHeight(BuildContext context) {
    const double baseHeight = 85.0;
    final double systemPadding = MediaQuery.of(context).padding.bottom;
    final double totalHeight = baseHeight + systemPadding;
    
    return Container(
      height: totalHeight,
      decoration: _getContainerDecoration(),
      child: SafeArea(
        child: SizedBox(
          height: baseHeight, // Hauteur exacte pour votre contenu
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            items: _getNavigationItems(context),
            selectedItemColor: const Color(0xFF4B39EF),
            unselectedItemColor: Colors.grey.shade600,
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
          ),
        ),
      ),
    );
  }

  /// 🎯 SOLUTION 3: Container avec hauteur fixe + Positioned
  Widget _buildContainerApproach(BuildContext context) {
    const double navigationHeight = 85.0;
    
    return Container(
      height: navigationHeight,
      decoration: _getContainerDecoration(),
      child: Stack(
        children: [
          // Navigation principale
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: navigationHeight,
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: onTap,
              items: _getNavigationItems(context),
              selectedItemColor: const Color(0xFF4B39EF),
              unselectedItemColor: Colors.grey.shade600,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: true,
              showUnselectedLabels: true,
            ),
          ),
        ],
      ),
    );
  }

  /// Décoration commune du container
  BoxDecoration _getContainerDecoration() {
    return BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          spreadRadius: 1,
          blurRadius: 5,
          offset: const Offset(0, -2),
        ),
      ],
    );
  }

  /// Récupère les éléments de navigation selon le profil actuel
  List<BottomNavigationBarItem> _getNavigationItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = authProvider.isAuthenticated;
    
    if (isAuthenticated && ProfileManager.isProviderMode()) {
      return [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          label: l10n.home,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.work_outline),
          activeIcon: const Icon(Icons.work),
          label: l10n.projects,
        ),
        BottomNavigationBarItem(
          icon: _buildMessagesIcon(context),
          activeIcon: _buildMessagesIcon(context, isActive: true),
          label: l10n.messaging,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          activeIcon: const Icon(Icons.person),
          label: l10n.profile,
        ),
      ];
    } else {
      return [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          label: l10n.home,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.search_outlined),
          activeIcon: const Icon(Icons.search),
          label: l10n.explore,
        ),
        BottomNavigationBarItem(
          icon: _buildMessagesIcon(context),
          activeIcon: _buildMessagesIcon(context, isActive: true),
          label: l10n.messaging,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          activeIcon: const Icon(Icons.person),
          label: l10n.profile,
        ),
      ];
    }
  }

  /// Construit l'icône des messages avec badge
  Widget _buildMessagesIcon(BuildContext context, {bool isActive = false}) {
    return Consumer<MessagingProvider>(
      builder: (context, messagingProvider, child) {
        final unreadCount = messagingProvider.getTotalUnreadCount();
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(isActive ? Icons.message : Icons.message_outlined),
            if (unreadCount > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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
}