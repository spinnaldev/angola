// mobile/lib/ui/widgets/notification_badge.dart - Widget badge réutilisable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final bool showZero;
  final Color? badgeColor;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsets? padding;
  final double? top;
  final double? right;
  final VoidCallback? onTap;

  const NotificationBadge({
    Key? key,
    required this.child,
    this.showZero = false,
    this.badgeColor,
    this.textColor,
    this.fontSize,
    this.padding,
    this.top,
    this.right,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        final count = notificationProvider.unreadCount;
        
        return GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              child,
              if (count > 0 || (showZero && count == 0))
                Positioned(
                  top: top ?? -8,
                  right: right ?? -8,
                  child: Container(
                    padding: padding ?? const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: badgeColor ?? Colors.red,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: TextStyle(
                        color: textColor ?? Colors.white,
                        fontSize: fontSize ?? 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Widget spécialisé pour l'icône de notifications
class NotificationIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final double iconSize;
  final Color? iconColor;

  const NotificationIconButton({
    Key? key,
    this.onPressed,
    this.icon = Icons.notifications_none,
    this.iconSize = 24,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NotificationBadge(
      onTap: onPressed,
      child: IconButton(
        icon: Icon(icon, size: iconSize, color: iconColor),
        onPressed: onPressed,
      ),
    );
  }
}

// Widget pour le drawer/sidebar
class NotificationListTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final TextStyle? titleStyle;

  const NotificationListTile({
    Key? key,
    required this.title,
    this.icon = Icons.notifications_none,
    this.onTap,
    this.titleStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final unreadCount = notificationProvider.unreadCount;
        
        return ListTile(
          leading: NotificationBadge(
            top: -6,
            right: -6,
            child: Icon(
              icon,
              color: Colors.grey[700],
              size: 24,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: titleStyle ?? TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                    fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        );
      },
    );
  }
}

// Widget pour afficher un indicateur de notification dans une AppBar
class NotificationAppBarAction extends StatelessWidget {
  final VoidCallback? onPressed;

  const NotificationAppBarAction({
    Key? key,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NotificationBadge(
      top: 8,
      right: 8,
      onTap: onPressed,
      child: IconButton(
        icon: const Icon(Icons.notifications_none),
        onPressed: onPressed,
      ),
    );
  }
}

// Widget pour un bouton flottant avec badge
class NotificationFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const NotificationFloatingActionButton({
    Key? key,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NotificationBadge(
      top: 0,
      right: 0,
      onTap: onPressed,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        child: const Icon(Icons.notifications),
      ),
    );
  }
}