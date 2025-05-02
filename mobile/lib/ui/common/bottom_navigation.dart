// lib/ui/common/bottom_navigation.dart
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
        selectedItemColor: const Color(0xFF4B39EF), // Bleu précis
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.transparent, // Transparent pour éviter le fond gris
        elevation: 0, // Supprime l'ombre par défaut
        type: BottomNavigationBarType.fixed, // Fixed pour un comportement constant
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
    );
  }
}