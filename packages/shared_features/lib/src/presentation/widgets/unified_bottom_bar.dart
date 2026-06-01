import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class UnifiedBottomBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final NavigationConfig navigationConfig;

  const UnifiedBottomBar({
    super.key,
    required this.navigationShell,
    required this.navigationConfig,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;
    final localizations = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: themeColor.cardBackground,
      selectedItemColor: themeColor.primary,
      unselectedItemColor: themeColor.unselectedItem,
      currentIndex: navigationShell.currentIndex,
      onTap: (index) => _onTap(context, index),
      items: navigationConfig.items.map((item) {
        String label = _getLocalizedLabel(item.labelKey, localizations);
        return BottomNavigationBarItem(
          icon: Icon(item.icon, size: screenWidth * 0.06),
          activeIcon: Icon(item.activeIcon, size: screenWidth * 0.06),
          label: label,
        );
      }).toList(),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  String _getLocalizedLabel(String key, AppLocalizations localizations) {
    switch (key) {
      case 'nav_home': return localizations.nav_home;
      case 'nav_my_orders': return localizations.nav_my_orders;
      case 'technician_orders_title': return localizations.technician_orders_title;
      case 'nav_profile': return localizations.nav_profile;
      case 'nav_user_management': return localizations.nav_user_management;
      case 'settings_title': return localizations.settings_title;
      case 'admin_dashboard_title': return localizations.settings_services_management;
      default: return key;
    }
  }
}
