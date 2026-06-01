import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/widget/glass_container.dart';

class ExitAppDialog extends StatelessWidget {
  const ExitAppDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Material(
          color: Colors.transparent,
          child: GlassContainer(
            borderRadius: 32,
            padding: const EdgeInsets.all(24),
            blur: 15,
            opacity: 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Icon Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha:0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),

                /// Title
                Text(
                  l10n.dialog_exit_title,
                  style: themeText.titleSectionLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                /// Message
                Text(
                  l10n.dialog_exit_message,
                  style: themeText.textBodySecondary.copyWith(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                /// Buttons
                Row(
                  children: [
                    /// Cancel Button
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          l10n.dialog_exit_cancel,
                          style: themeText.textBodySecondary.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    /// Exit Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          l10n.dialog_exit_confirm,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
