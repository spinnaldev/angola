// lib/ui/screens/profile_screen.dart - VERSION AVEC RECHARGEMENT AMÉLIORÉ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:teyago/ui/widgets/verification/verification_status_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/project_provider.dart';
import '../../core/models/user.dart';
import '../../core/models/service.dart';
import '../../core/models/client_project.dart';
// IMPORTS AJOUTÉS POUR LA VÉRIFICATION
import '../widgets/verification_status_widget.dart';
import '../../core/services/verification_helper.dart';

import 'edit_profile_screen.dart';
import 'service_detail_screen.dart';
import 'user_projects_screen.dart';
import 'project_detail_screen.dart';
import 'package:intl/intl.dart';
import './base_screen.dart';
import '../screens/client/client_projects_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RouteAware {
  // ✅ NOUVEAU : Flag pour éviter les rechargements multiples
  bool _isLoading = false;
  // ✅ NOUVEAU : Flag pour s'assurer du rechargement au retour sur la page
  bool _shouldReload = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // ✅ AMÉLIORÉ : Logique de rechargement plus robuste
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ NOUVEAU : Toujours recharger quand on arrive sur cette page
    if (_shouldReload) {
      _shouldReload = false; // Éviter les rechargements multiples immédiatement
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadData();
        }
      });
    }
  }

  // ✅ NOUVEAU : Gérer le retour sur la page
  void didPopNext() {
    // Cette méthode est appelée quand on revient sur cette page
    if (mounted) {
      _shouldReload = true;
      _loadData();
    }
  }

  // ✅ NOUVEAU : Méthode publique pour forcer le rechargement
  void forceReload() {
    if (mounted) {
      _shouldReload = true;
      _loadData();
    }
  }

  // ✅ MÉTHODE AMÉLIORÉE : Rechargement plus robuste avec gestion d'erreurs améliorée
  Future<void> _loadData() async {
    // ✅ NOUVEAU : Ne pas bloquer si un rechargement est déjà en cours,
    // mais permettre un nouveau rechargement après un délai
    if (_isLoading) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // ✅ AMÉLIORÉ : Recharger d'abord le profil utilisateur avec retry
      await _reloadUserProfile(authProvider);
      
      final user = authProvider.currentUser;

      if (user != null) {
        if (user.role == 'provider') {
          // Charger les services du prestataire avec retry
          await _reloadProviderData();
        } else {
          // Charger les projets du client avec retry
          await _reloadClientData();
        }
      }
      
      // ✅ NOUVEAU : Marquer comme rechargé avec succès
      _shouldReload = false;
      
    } catch (e) {
      print('Erreur lors du rechargement des données du profil: $e');
      // ✅ NOUVEAU : En cas d'erreur, permettre un nouvel essai
      _shouldReload = true;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ✅ NOUVELLE MÉTHODE : Recharger le profil utilisateur avec retry
  Future<void> _reloadUserProfile(AuthProvider authProvider) async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        await authProvider.refreshUserProfile();
        return; // Succès, sortir de la boucle
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          throw e; // Relancer l'erreur après le nombre max de tentatives
        }
        // Attendre avant de retry
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }
  }

  // ✅ NOUVELLE MÉTHODE : Recharger les données du prestataire
  Future<void> _reloadProviderData() async {
    try {
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
      await serviceProvider.fetchMyServices();
    } catch (e) {
      print('Erreur lors du rechargement des services: $e');
      // Ne pas faire échouer tout le rechargement pour cette erreur
    }
  }

  // ✅ NOUVELLE MÉTHODE : Recharger les données du client
  Future<void> _reloadClientData() async {
    try {
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      await projectProvider.fetchUserProjects();
    } catch (e) {
      print('Erreur lors du rechargement des projets: $e');
      // Ne pas faire échouer tout le rechargement pour cette erreur
    }
  }

  void _handleNavigation(int index) {
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else if (index == 1) {
      Navigator.pushNamedAndRemoveUntil(context, '/explore', (route) => false);
    } else if (index == 2) {
      Navigator.pushNamedAndRemoveUntil(context, '/messages', (route) => false);
    }
    // index 3 = profil actuel, ne rien faire
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      currentIndex: 3, // profil est sélectionné
      body: _buildProfilContent(),
    );
  }

  Widget _buildProfilContent() {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;

          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // ✅ AMÉLIORÉ : RefreshIndicator avec callback amélioré
          return RefreshIndicator(
            onRefresh: () async {
              _shouldReload = true;
              await _loadData();
            },
            child: SafeArea(
              child: Column(
                children: [
                  // Header avec titre et crayon d'édition
                  _buildHeader(l10n),

                  Expanded(
                    child: SingleChildScrollView(
                      // ✅ NOUVEAU : Toujours permettre le scroll pour le pull-to-refresh
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          // ✅ NOUVEAU : Indicateur de chargement discret pendant le refresh
                          if (_isLoading)
                            Container(
                              width: double.infinity,
                              height: 2,
                              child: const LinearProgressIndicator(
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF142FE2)),
                              ),
                            ),

                          // Section profil utilisateur avec badges de vérification
                          _buildUserProfileSection(user, l10n),

                          _buildDivider(),

                          // NOUVELLE SECTION : Statut de vérification
                          _buildVerificationSection(user, l10n),

                          _buildDivider(),
                          
                          // Section adresse et membre depuis
                          _buildLocationAndMemberSection(user, l10n),

                          _buildDivider(),

                          // Section Mes projets/services avec vérification
                          _buildProjectsSection(user, l10n),

                          const SizedBox(height: 100), // Espace pour la bottom nav
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // NOUVELLE MÉTHODE : Section de vérification
  Widget _buildVerificationSection(User user, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: VerificationStatusCard(
        user: user,
        onVerifyPressed: () => _navigateToVerification(user.role),
        showExpanded: !user.verificationInfo.isVerified, // Étendu si pas vérifié
      ),
    );
  }

  // NOUVELLE MÉTHODE : Navigation vers vérification
  void _navigateToVerification(String role) {
    if (role == 'provider') {
      Navigator.pushNamed(context, '/provider-verification').then((_) {
        // ✅ NOUVEAU : Forcer le rechargement au retour
        forceReload();
      });
    } else if (role == 'client') {
      Navigator.pushNamed(context, '/phone-verification').then((_) {
        // ✅ NOUVEAU : Forcer le rechargement au retour
        forceReload();
      });
    }
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.myProfile,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ).then((_) {
                // ✅ AMÉLIORÉ : Forcer le rechargement au retour de l'édition
                forceReload();
              });
            },
            icon: const Icon(
              Icons.edit,
              color: Colors.black,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileSection(User user, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom avec badge de vérification
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    // AJOUT : Badge de vérification à côté du nom
                    if (user.verificationInfo.isVerified)
                      VerificationBadge(
                        user: user,
                        size: 18,
                        showLabel: true,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.onlineOneMinuteAgo,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: user.role == 'provider'
                            ? const Color(0xFF142FE2).withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.role == 'provider' ? l10n.provider : l10n.client,
                        style: TextStyle(
                          color: user.role == 'provider'
                              ? const Color(0xFF142FE2)
                              : Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // AJOUT : Indicateur compact du statut de vérification
                    _buildCompactVerificationStatus(user, l10n),
                  ],
                ),
              ],
            ),
          ),
          // Photo de profil avec badge de vérification
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF142FE2),
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 35,
                  backgroundImage:
                      user.profilePicture != null && user.profilePicture!.isNotEmpty
                          ? NetworkImage(user.profilePicture!)
                          : null,
                  child: user.profilePicture == null || user.profilePicture!.isEmpty
                      ? Text(
                          user.firstName.isNotEmpty ? user.firstName[0] : 'U',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                  backgroundColor: const Color(0xFF142FE2),
                ),
              ),
              // AJOUT : Badge de vérification sur la photo
              if (user.verificationInfo.isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: VerificationBadge(
                      user: user,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactVerificationStatus(User user, AppLocalizations l10n) {
    final verificationInfo = user.verificationInfo;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: verificationInfo.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: verificationInfo.statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verificationInfo.statusIcon,
            size: 12,
            color: verificationInfo.statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            verificationInfo.status == 'verified' 
                ? l10n.verified
                : verificationInfo.status == 'pending'
                    ? l10n.verificationPending
                    : l10n.notVerified,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: verificationInfo.statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationAndMemberSection(User user, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Adresse
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF142FE2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 20,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.locationLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.location ?? l10n.defaultLocation,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Membre depuis
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.memberSince,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getFormattedMemberDate(user.dateJoined, l10n),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFormattedMemberDate(DateTime date, AppLocalizations l10n) {
    // Formater la date selon la langue
    final locale = l10n.localeName;
    switch (locale) {
      case 'fr':
        return DateFormat('MMMM yyyy', 'fr_FR').format(date);
      case 'en':
        return DateFormat('MMMM yyyy', 'en_US').format(date);
      case 'pt':
        return DateFormat('MMMM yyyy', 'pt_PT').format(date);
      default:
        return DateFormat('MMMM yyyy').format(date);
    }
  }

  Widget _buildProjectsSection(User user, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                user.role == 'provider'
                    ? l10n.myServices
                    : l10n.myProjects,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  if (user.role == 'provider') {
                    // Navigation vers gestion des services
                    Navigator.pushNamed(context, '/service-management').then((_) {
                      // ✅ NOUVEAU : Recharger au retour
                      forceReload();
                    });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClientProjectsScreen(),
                      ),
                    ).then((_) {
                      // ✅ NOUVEAU : Recharger au retour
                      forceReload();
                    });
                  }
                },
                child: Text(
                  l10n.viewAll,
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // MODIFICATION : Vérifier si l'utilisateur peut voir ses projets/services
          if (!user.canPerformActions) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.verificationRequired,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.role == 'provider'
                        ? l10n.profileVerificationDescription
                        : l10n.phoneVerificationDescription,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _navigateToVerification(user.role),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                      child: Text(
                        user.role == 'provider' 
                            ? l10n.verifyMyProfile
                            : l10n.verifyMyPhone,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Affichage normal si vérifié
            if (user.role == 'provider')
              _buildProviderServicesCarousel(l10n)
            else
              _buildClientProjectsCarousel(l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderServicesCarousel(AppLocalizations l10n) {
    return Consumer<ServiceProvider>(
      builder: (context, serviceProvider, child) {
        if (serviceProvider.isLoading || _isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final services = serviceProvider.myServices;

        if (services.isEmpty) {
          return Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noServiceAdded,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.createFirstService,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: services.length.clamp(0, 5), // Limiter à 5 services
            itemBuilder: (context, index) {
              final service = services[index];
              return _buildServiceCard(service, l10n);
            },
          ),
        );
      },
    );
  }

  Widget _buildClientProjectsCarousel(AppLocalizations l10n) {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        if (projectProvider.isLoadingUserProjects || _isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final projects = projectProvider.userProjects;

        if (projects.isEmpty) {
          return Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    l10n.noProjectCreated,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.createFirstProject,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: projects.length.clamp(0, 5), // Limiter à 5 projets
            itemBuilder: (context, index) {
              final project = projects[index];
              return _buildProjectCard(project, l10n);
            },
          ),
        );
      },
    );
  }

  Widget _buildServiceCard(Service service, AppLocalizations l10n) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceDetailScreen(
                serviceId: service.id,
                providerId: service.provider_id,
              ),
            ),
          ).then((_) {
            // ✅ NOUVEAU : Recharger au retour
            forceReload();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: service.imageUrl.isNotEmpty
                  ? Image.network(
                      service.imageUrl,
                      width: 160,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 160,
                          height: 100,
                          color: const Color(0xFF142FE2).withOpacity(0.1),
                          child: const Icon(
                            Icons.work,
                            color: Color(0xFF6366F1),
                            size: 32,
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 160,
                      height: 100,
                      color: const Color(0xFF142FE2).withOpacity(0.1),
                      child: const Icon(
                        Icons.work,
                        color: Color(0xFF6366F1),
                        size: 32,
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.priceType == 'quote'
                          ? l10n.onQuote
                          : '${service.price.toInt()}AOA',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(ClientProject project, AppLocalizations l10n) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailScreen(projectId: project.id),
            ),
          ).then((_) {
            // ✅ NOUVEAU : Recharger au retour
            forceReload();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: project.isOpen
                          ? Colors.green.withOpacity(0.1)
                          : project.isCompleted
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getProjectStatusText(project, l10n),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: project.isOpen
                            ? Colors.green
                            : project.isCompleted
                                ? Colors.blue
                                : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                project.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),

              // Informations du projet
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 14,
                    color: Colors.green[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    project.budgetDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.mail,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.offersCount(project.offersCount),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getProjectStatusText(ClientProject project, AppLocalizations l10n) {
    if (project.isOpen) return l10n.open;
    if (project.isCompleted) return l10n.completed;
    return l10n.inProgress;
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.grey[200],
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  final String? profilePicture;
  final String firstName;
  final double radius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;

  const ProfileAvatar({
    Key? key,
    this.profilePicture,
    required this.firstName,
    this.radius = 35,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderColor != null 
            ? Border.all(
                color: borderColor!,
                width: borderWidth,
              )
            : null,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? const Color(0xFF142FE2),
        // ✅ Ne pas utiliser backgroundImage si on veut gérer les erreurs
        child: _buildAvatarContent(),
      ),
    );
  }

  Widget _buildAvatarContent() {
    // Si pas d'image ou image vide, afficher les initiales
    if (profilePicture == null || profilePicture!.isEmpty) {
      return _buildInitials();
    }

    // Utiliser Image.network avec errorBuilder au lieu de NetworkImage
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Image.network(
          profilePicture!,
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            
            // Indicateur de chargement
            return Container(
              color: (backgroundColor ?? const Color(0xFF142FE2)).withOpacity(0.1),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      backgroundColor ?? const Color(0xFF142FE2),
                    ),
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // En cas d'erreur (404, network, etc.), afficher les initiales
            print('❌ Erreur chargement image profil: $error');
            return _buildInitials();
          },
        ),
      ),
    );
  }

  Widget _buildInitials() {
    return Text(
      firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
      style: TextStyle(
        fontSize: radius * 0.8, // Adapter la taille à la taille de l'avatar
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}