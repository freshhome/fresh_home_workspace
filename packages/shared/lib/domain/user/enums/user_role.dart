import 'package:flutter/material.dart';
import '../../../../presentation/localization/translations/app_localizations.dart';

enum UserRole { client, technician, admin }

extension UserRoleExtension on UserRole {
  String translatedName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case UserRole.client:
        return l10n.role_client;
      case UserRole.technician:
        return l10n.role_technician;
      case UserRole.admin:
        return l10n.role_admin;   
    }
  }

  Color get color {
    switch (this) {
      case UserRole.client:
        return Colors.blue;
      case UserRole.technician:
        return Colors.deepPurple;
      case UserRole.admin:
        return const Color(0xFFFFD700); // Gold
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.client:
        return Icons.person_outline_rounded;
      case UserRole.technician:
        return Icons.build_circle_outlined;
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
    }
  }
}