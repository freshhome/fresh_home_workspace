import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:shared/core/constants/app_assets.dart';

import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:shared/presentation/widget/my_custom_button.dart';

import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

class BuildButtonsSection extends StatelessWidget {
  final VoidCallback? onBlueButtonPressed;
  final VoidCallback? onGrayButtonPressed;

  final String blueButtonText;

  final String questionText;
  final String authAction;

  final VoidCallback? onGoogleSignInPressed;

  const BuildButtonsSection({
    super.key,
    required this.onBlueButtonPressed,
    required this.onGrayButtonPressed,
    this.onGoogleSignInPressed,
    required this.blueButtonText,
    required this.questionText,
    required this.authAction,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeColor = context.themeColor;
    final textStyle = Theme.of(context).extension<AppTextThemeExtension>()!;

    return Container(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Login Button
          MyCustomButton(onPressed: onBlueButtonPressed, text: blueButtonText),

          const SizedBox(height: 20),
          
          if (onGoogleSignInPressed != null) ...[
             // OR separator
            Row(
              children: [
                const Expanded(child: Divider(thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l10n.general_or,
                    style: textStyle.titleSectionSmall.copyWith(
                      color: themeColor.secondaryText,
                    ),
                  ),
                ),
                const Expanded(child: Divider(thickness: 1)),
              ],
            ),
            const SizedBox(height: 20),
            MyCustomButton(
              onPressed: onGoogleSignInPressed!,
              text: l10n.login_sign_in_google,
              backgroundColor: themeColor.cardBackground,
              textStyle: TextStyle(
                color: themeColor.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              isOutlined: true,
              borderColor: themeColor.cardBorder.color,
              leadingIcon: SvgPicture.asset(
                AppAssets.icGoogleLogo,
                width: 24,
                height: 24,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Navigation (Don't have an account?)
          GestureDetector(
            onTap: onGrayButtonPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(questionText, style: textStyle.titleSectionSmall),
                const SizedBox(width: 5),
                Text(
                  authAction,
                  style: textStyle.titleSectionSmall.copyWith(
                    color: themeColor.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
