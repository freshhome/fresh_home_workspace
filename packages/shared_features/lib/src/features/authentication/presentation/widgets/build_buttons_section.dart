import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:shared/core/constants/app_assets.dart';

import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:shared/presentation/widget/my_custom_button.dart';

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
    // final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;
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
                      color: Colors.grey,
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
              backgroundColor: Colors.white,
              textStyle: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              isOutlined: true,
              borderColor: Colors.grey.shade300,
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
                    color: const Color(0xFF0085FF),
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
