// // lib/ui/screens/base_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../providers/auth_provider.dart';
// import '../../core/services/profile_manager.dart';
// import '../widgets/side_menu.dart';
// import '../widgets/app_bottom_navigation.dart';
// import 'home_screen.dart';
// import 'explore_screen.dart';
// import 'messaging/messages_screen.dart';
// import 'profile_screen.dart';
// import 'projects_list_screen.dart';

// class BaseScreen extends StatefulWidget {
//   final Widget body;
//   final int currentIndex;
//   final PreferredSizeWidget? appBar;
//   final bool hasBottomNavigation;

//   const BaseScreen({
//     Key? key,
//     required this.body,
//     this.currentIndex = 0,
//     this.appBar,
//     this.hasBottomNavigation = true,
//   }) : super(key: key);

//   @override
//   _BaseScreenState createState() => _BaseScreenState();
// }

// class _BaseScreenState extends State<BaseScreen> {
//   bool _isMenuOpen = false;

//   void _openMenu() {
//     setState(() {
//       _isMenuOpen = true;
//     });
//   }

//   void _closeMenu() {
//     setState(() {
//       _isMenuOpen = false;
//     });
//   }

//   void _handleNavigation(int index) {
//     // Fermer le menu si ouvert
//     if (_isMenuOpen) {
//       _closeMenu();
//     }

//     // Éviter la navigation si on est déjà sur la page demandée
//     if (index == widget.currentIndex) return;

//     // Vérifier si l'utilisateur est connecté
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final isAuthenticated = authProvider.isAuthenticated;

//     // Navigation selon le profil de l'utilisateur
//     if (isAuthenticated && ProfileManager.isProviderMode()) {
//       // Navigation pour prestataires : Accueil, Projets, Messages, Profil
//       _handleProviderNavigation(index);
//     } else {
//       // Navigation pour clients ou utilisateurs non connectés : Accueil, Explorer, Messages, Profil
//       _handleClientNavigation(index);
//     }
//   }

//   void _handleProviderNavigation(int index) {
//     switch (index) {
//       case 0: // Accueil
//         Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
//         break;
//       case 1: // Projets
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (context) => const ProjectsListScreen()),
//           (route) => false,
//         );
//         break;
//       case 2: // Messages
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (context) => const MessagesScreen()),
//           (route) => false,
//         );
//         break;
//       case 3: // Profil
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (context) => const ProfileScreen()),
//           (route) => false,
//         );
//         break;
//     }
//   }

//   void _handleClientNavigation(int index) {
//     switch (index) {
//       case 0: // Accueil
//         Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
//         break;
//       case 1: // Explorer
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (context) => const ExploreScreen()),
//           (route) => false,
//         );
//         break;
//       case 2: // Messages
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (context) => const MessagesScreen()),
//           (route) => false,
//         );
//         break;
//       case 3: // Profil
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (context) => const ProfileScreen()),
//           (route) => false,
//         );
//         break;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: widget.appBar,
//       body: Stack(
//         children: [
//           widget.body,
//           // Overlay pour le menu latéral
//           if (_isMenuOpen)
//             GestureDetector(
//               onTap: _closeMenu,
//               child: Container(
//                 color: Colors.black.withOpacity(0.5),
//                 child: Stack(
//                   children: [
//                     // Zone vide pour fermer le menu
//                     Positioned.fill(
//                       child: GestureDetector(
//                         onTap: _closeMenu,
//                         child: Container(color: Colors.transparent),
//                       ),
//                     ),
//                     // Menu latéral
//                     Positioned(
//                       right: 0,
//                       top: 0,
//                       bottom: 0,
//                       width: MediaQuery.of(context).size.width * 0.85,
//                       child: SideMenu(
//                         onClose: _closeMenu,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//       bottomNavigationBar: widget.hasBottomNavigation
//           ? AppBottomNavigation(
//               currentIndex: widget.currentIndex,
//               onTap: _handleNavigation,
//             )
//           : null,
//     );
//   }
// }

