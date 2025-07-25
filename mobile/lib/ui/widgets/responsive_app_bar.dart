// 📱 lib/ui/widgets/responsive_app_bar.dart
// Solution adaptée à VOTRE architecture BaseScreen + AppBottomNavigation

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/profile_manager.dart';
import 'side_menu.dart';

class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final double? elevation;

  const ResponsiveAppBar({
    Key? key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.elevation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // 📱 Breakpoints adaptés à votre app
        final isTablet = constraints.maxWidth >= 768;
        final isDesktop = constraints.maxWidth >= 1024;
        final isMobile = constraints.maxWidth < 768;

        return AppBar(
          title: _buildTitle(context, isDesktop, isTablet),
          leading: _buildLeading(context, isMobile),
          automaticallyImplyLeading: automaticallyImplyLeading && isMobile,
          actions: _buildActions(context, isDesktop, isTablet, isMobile, l10n),
          backgroundColor: backgroundColor ?? Colors.white,
          elevation: elevation ?? 0,
          foregroundColor: Colors.black87,
          toolbarHeight: isDesktop ? 70 : (isTablet ? 64 : 56),
          iconTheme: const IconThemeData(color: Colors.black87),
        );
      },
    );
  }

  Widget _buildTitle(BuildContext context, bool isDesktop, bool isTablet) {
    if (titleWidget != null) return titleWidget!;
    
    return Row(
      children: [
        // Logo pour desktop/tablette
        if (isDesktop || isTablet) ...[
          Icon(
            Icons.apps,
            color: Theme.of(context).primaryColor,
            size: isDesktop ? 32 : 28,
          ),
          const SizedBox(width: 12),
        ],
        // Titre adaptatif
        Flexible(
          child: Text(
            title ?? 'TeyaGO',
            style: TextStyle(
              fontSize: isDesktop ? 24 : (isTablet ? 20 : 18),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget? _buildLeading(BuildContext context, bool isMobile) {
    if (!isMobile) return null;
    return leading;
  }

  List<Widget> _buildActions(BuildContext context, bool isDesktop, bool isTablet, bool isMobile, AppLocalizations l10n) {
    List<Widget> actionWidgets = [];

    // 📱 Récupérer l'état d'authentification (comme dans votre code)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = authProvider.isAuthenticated;
    final isProvider = isAuthenticated && ProfileManager.isProviderMode();

    if (isDesktop) {
      // 💻 Menu complet pour desktop
      actionWidgets.addAll([
        _buildNavButton(context, l10n.home, Icons.home, () {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }),
        if (isProvider) 
          _buildNavButton(context, l10n.projects, Icons.work, () {
            // Navigation vers vos projets (adaptez selon votre route)
            Navigator.pushNamed(context, '/projects');
          })
        else
          _buildNavButton(context, l10n.explore, Icons.search, () {
            // Navigation vers explore
            Navigator.pushNamed(context, '/explore');
          }),
        _buildNavButton(context, l10n.messaging, Icons.message, () {
          Navigator.pushNamed(context, '/messages');
        }),
        const SizedBox(width: 16),
        _buildProfileButton(context, isDesktop: true, l10n: l10n),
        const SizedBox(width: 16),
      ]);
    } else if (isTablet) {
      // 📱 Menu réduit pour tablette
      actionWidgets.addAll([
        IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          },
          tooltip: l10n.home,
        ),
        IconButton(
          icon: Icon(isProvider ? Icons.work : Icons.search),
          onPressed: () {
            Navigator.pushNamed(context, isProvider ? '/projects' : '/explore');
          },
          tooltip: isProvider ? l10n.projects : l10n.explore,
        ),
        IconButton(
          icon: const Icon(Icons.message),
          onPressed: () {
            Navigator.pushNamed(context, '/messages');
          },
          tooltip: l10n.messaging,
        ),
        _buildProfileButton(context, isDesktop: false, l10n: l10n),
        const SizedBox(width: 8),
      ]);
    } else {
      // 📱 Menu minimal pour mobile (garde votre logique existante)
      actionWidgets.addAll([
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // Votre logique de notifications
          },
        ),
        _buildMenuButton(context),
        const SizedBox(width: 8),
      ]);
    }

    // Ajouter les actions personnalisées
    if (actions != null) {
      actionWidgets.addAll(actions!);
    }

    return actionWidgets;
  }

  Widget _buildNavButton(BuildContext context, String label, IconData icon, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
      label: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildProfileButton(BuildContext context, {required bool isDesktop, required AppLocalizations l10n}) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'profile':
            Navigator.pushNamed(context, '/profile');
            break;
          case 'settings':
            // Navigation vers paramètres
            break;
          case 'logout':
            authProvider.logout();
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text(l10n.myProfile),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('Paramètres'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Déconnexion', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 8 : 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              backgroundImage: user?.profilePicture != null 
                  ? NetworkImage(user!.profilePicture!) 
                  : null,
              child: user?.profilePicture == null 
                  ? const Icon(Icons.person, color: Colors.white, size: 20)
                  : null,
            ),
            if (isDesktop) ...[
              const SizedBox(width: 8),
              Text(
                user?.firstName ?? 'Utilisateur',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, color: Theme.of(context).primaryColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () {
        // 📱 IMPORTANT: S'intégrer avec votre SideMenu existant
        // Si votre BaseScreen gère déjà le menu, utilisez cette logique :
        
        showModalBottomSheet(
          context: context,
          builder: (context) => SideMenu(
            onClose: () => Navigator.pop(context),
          ),
          isScrollControlled: true,
          useSafeArea: true,
        );
        
        // OU si vous préférez votre logique existante dans BaseScreen:
        // Remplacez par un callback vers votre _openMenu()
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}