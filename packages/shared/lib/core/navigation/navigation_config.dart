import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Configuration for bottom navigation items
/// Each app can provide its own navigation configuration
class NavigationConfig {
  final List<NavigationItem> items;

  const NavigationConfig({required this.items});

  /// Returns the path of the first navigation item (default landing page)
  String get initialPath => items.isNotEmpty ? items.first.path : '/';
}

/// Represents a single navigation item in the bottom navigation bar
class NavigationItem {
  /// Localization key for the label (e.g., 'nav_home', 'nav_my_orders')
  final String labelKey;
  
  /// Icon to display when item is not selected
  final IconData icon;
  
  /// Icon to display when item is selected
  final IconData activeIcon;

  /// The route path for this navigation item
  final String path;
  
  /// Builder function to create the page widget
  final Widget Function(BuildContext context) pageBuilder;

  /// Optional sub-routes for this navigation item (e.g., detail pages)
  final List<RouteBase>? subRoutes;

  const NavigationItem({
    required this.labelKey,
    required this.icon,
    required this.activeIcon,
    required this.path,
    required this.pageBuilder,
    this.subRoutes,
  });
}
