// // lib/ui/screens/home/home_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../providers/auth_provider.dart';
// import '../../../core/services/profile_manager.dart';
// import '../base_screen.dart';
// import '../provider/provider_dashboard.dart';
// import '../client/client_home_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({Key? key}) : super(key: key);

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   @override
//   void initState() {
//     super.initState();
//     // Initialiser le ProfileManager si pas encore fait
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _initializeProfile();
//     });
//   }

//   Future<void> _initializeProfile() async {
//     try {
//       await ProfileManager.initialize();
//       if (mounted) {
//         setState(() {}); // Rafraîchir l'interface
//       }
//     } catch (e) {
//       // Gérer l'erreur d'initialisation
//       debugPrint('Erreur lors de l\'initialisation du ProfileManager: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<AuthProvider>(
//       builder: (context, authProvider, child) {
//         final user = authProvider.currentUser;
        
//         if (user == null) {
//           // Utilisateur non connecté - afficher l'interface invité
//           return BaseScreen(
//             currentIndex: 0,
//             showProfileToggle: false,
//             body: _buildGuestHomeScreen(),
//           );
//         }

//         // Utilisateur connecté - afficher l'interface selon le profil
//         if (ProfileManager.isProviderMode()) {
//           return ProviderDashboard();
//         } else {
//           return ClientHomeScreen();
//         }
//       },
//     );
//   }

//   /// Interface d'accueil pour les utilisateurs non connectés
//   Widget _buildGuestHomeScreen() {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           // Hero section
//           _buildHeroSection(),
          
//           // Section catégories
//           _buildCategoriesPreview(),
          
//           // Section fonctionnalités
//           _buildFeaturesSection(),
          
//           // Section Call-to-Action
//           _buildCTASection(),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeroSection() {
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             Theme.of(context).primaryColor,
//             Theme.of(context).primaryColor.withOpacity(0.8),
//           ],
//         ),
//       ),
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 40),
//               Text(
//                 'Trouvez le prestataire idéal',
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                   height: 1.2,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 'Connectez-vous avec des professionnels qualifiés pour tous vos projets',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.white.withOpacity(0.9),
//                   height: 1.4,
//                 ),
//               ),
//               const SizedBox(height: 32),
              
//               // Barre de recherche
//               Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 10,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: TextField(
//                   decoration: InputDecoration(
//                     hintText: 'Rechercher un service...',
//                     prefixIcon: const Icon(Icons.search, color: Colors.grey),
//                     suffixIcon: Container(
//                       margin: const EdgeInsets.all(4),
//                       decoration: BoxDecoration(
//                         color: Theme.of(context).primaryColor,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: IconButton(
//                         icon: const Icon(Icons.arrow_forward, color: Colors.white),
//                         onPressed: () {
//                           Navigator.pushNamed(context, '/explore');
//                         },
//                       ),
//                     ),
//                     border: InputBorder.none,
//                     contentPadding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 16,
//                     ),
//                   ),
//                   onSubmitted: (value) {
//                     if (value.isNotEmpty) {
//                       Navigator.pushNamed(context, '/explore', arguments: {'search': value});
//                     }
//                   },
//                 ),
//               ),
              
//               const SizedBox(height: 40),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCategoriesPreview() {
//     final categories = [
//       {'name': 'Réparation', 'icon': Icons.build, 'color': Colors.blue},
//       {'name': 'Nettoyage', 'icon': Icons.cleaning_services, 'color': Colors.green},
//       {'name': 'Éducation', 'icon': Icons.school, 'color': Colors.orange},
//       {'name': 'Beauté', 'icon': Icons.face, 'color': Colors.pink},
//       {'name': 'Tech', 'icon': Icons.computer, 'color': Colors.purple},
//       {'name': 'Transport', 'icon': Icons.directions_car, 'color': Colors.teal},
//     ];

//     return Padding(
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Catégories populaires',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[800],
//             ),
//           ),
//           const SizedBox(height: 16),
//           GridView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 3,
//               crossAxisSpacing: 16,
//               mainAxisSpacing: 16,
//               childAspectRatio: 1,
//             ),
//             itemCount: categories.length,
//             itemBuilder: (context, index) {
//               final category = categories[index];
//               return GestureDetector(
//                 onTap: () {
//                   Navigator.pushNamed(context, '/explore', 
//                     arguments: {'category': category['name']});
//                 },
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: (category['color'] as Color).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                       color: (category['color'] as Color).withOpacity(0.3),
//                     ),
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         category['icon'] as IconData,
//                         size: 32,
//                         color: category['color'] as Color,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         category['name'] as String,
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           color: Colors.grey[800],
//                           fontSize: 12,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFeaturesSection() {
//     final features = [
//       {
//         'icon': Icons.verified_user,
//         'title': 'Prestataires vérifiés',
//         'description': 'Tous nos prestataires sont vérifiés et notés par la communauté',
//       },
//       {
//         'icon': Icons.schedule,
//         'title': 'Réservation facile',
//         'description': 'Réservez en quelques clics et recevez une confirmation immédiate',
//       },
//       {
//         'icon': Icons.support_agent,
//         'title': 'Support 24/7',
//         'description': 'Notre équipe est disponible pour vous aider à tout moment',
//       },
//     ];

//     return Container(
//       color: Colors.grey[50],
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Pourquoi nous choisir ?',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[800],
//             ),
//           ),
//           const SizedBox(height: 20),
//           ...features.map((feature) => Padding(
//             padding: const EdgeInsets.only(bottom: 16),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).primaryColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(
//                     feature['icon'] as IconData,
//                     color: Theme.of(context).primaryColor,
//                     size: 24,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         feature['title'] as String,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         feature['description'] as String,
//                         style: TextStyle(
//                           color: Colors.grey[600],
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           )).toList(),
//         ],
//       ),
//     );
//   }

//   Widget _buildCTASection() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//         children: [
//           Text(
//             'Prêt à commencer ?',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[800],
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'Rejoignez des milliers d\'utilisateurs satisfaits',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey[600],
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 24),
          
//           // Boutons d'action
//           Column(
//             children: [
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     Navigator.pushNamed(context, '/signup');
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Theme.of(context).primaryColor,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: const Text(
//                     'Créer un compte',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: OutlinedButton(
//                   onPressed: () {
//                     Navigator.pushNamed(context, '/login');
//                   },
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: Theme.of(context).primaryColor,
//                     side: BorderSide(color: Theme.of(context).primaryColor),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: const Text(
//                     'Se connecter',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
          
//           const SizedBox(height: 24),
          
//           // Liens rapides
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pushNamed(context, '/explore');
//                 },
//                 child: Text(
//                   'Explorer',
//                   style: TextStyle(
//                     color: Theme.of(context).primaryColor,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//               Container(
//                 width: 1,
//                 height: 16,
//                 color: Colors.grey[300],
//               ),
//               TextButton(
//                 onPressed: () {
//                   // Navigation vers page À propos
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('À propos - À venir')),
//                   );
//                 },
//                 child: Text(
//                   'À propos',
//                   style: TextStyle(
//                     color: Theme.of(context).primaryColor,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//               Container(
//                 width: 1,
//                 height: 16,
//                 color: Colors.grey[300],
//               ),
//               TextButton(
//                 onPressed: () {
//                   // Navigation vers aide
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Aide - À venir')),
//                   );
//                 },
//                 child: Text(
//                   'Aide',
//                   style: TextStyle(
//                     color: Theme.of(context).primaryColor,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }


