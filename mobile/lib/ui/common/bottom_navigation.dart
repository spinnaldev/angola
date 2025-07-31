// lib/ui/common/bottom_navigation.dart - VERSION CORRIGÉE
import 'package:flutter/material.dart';

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
    // 🔧 SOLUTION PRINCIPALE : Conteneur avec SafeArea et padding adaptatif
    return Container(
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
      child: SafeArea(
        // ✅ CORRECTION : SafeArea pour éviter les conflits avec les boutons système
        child: Container(
          // 📱 Hauteur adaptative au lieu de height fixe
          height: _getAdaptiveHeight(context),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            selectedItemColor: const Color(0xFF4B39EF), // Bleu TeyaGO
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
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.search, size: 24),
                label: 'Explorer',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline, size: 24),
                label: 'Message',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline, size: 24),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📱 Calcule la hauteur adaptative selon l'appareil et les zones de sécurité
  double _getAdaptiveHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    
    // Hauteur de base + padding système (si nécessaire)
    const baseHeight = 60.0;
    
    // Ajouter un padding minimum si l'appareil n'a pas de zone de sécurité naturelle
    return baseHeight + (bottomPadding > 0 ? 0 : 8);
  }
}