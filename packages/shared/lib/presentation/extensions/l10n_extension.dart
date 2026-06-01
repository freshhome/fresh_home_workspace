import 'package:flutter/widgets.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';

extension LocalizedBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
