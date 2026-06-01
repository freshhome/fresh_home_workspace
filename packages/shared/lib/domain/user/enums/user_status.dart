import 'package:flutter/material.dart';
import '../../../../presentation/localization/translations/app_localizations.dart';

enum UserStatus { active, pending, suspended, banned }

extension UserStatusExtension on UserStatus {
  String translatedName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case UserStatus.active:
        return l10n.status_active;
      case UserStatus.pending:
        return l10n.status_pending;
      case UserStatus.suspended:
        return l10n.status_suspended;
      case UserStatus.banned:
        return l10n.status_banned;
    }
  }

  Color get color {
    switch (this) {
      case UserStatus.active:
        return Colors.green;
      case UserStatus.pending:
        return Colors.orange;
      case UserStatus.suspended:
        return Colors.red;
      case UserStatus.banned:
        return Colors.black;
    }
  }
}
