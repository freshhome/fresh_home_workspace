import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared/core/constants/app_assets.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';

class BuildHeader extends StatelessWidget {
  final String subtitle;

  const BuildHeader({super.key, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).extension<AppTextThemeExtension>()!;
    final themeColor = context.themeColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo Animation
          Lottie.asset(
            AppAssets.splashAnimationLogo,
            height: 120,
          ),

          const SizedBox(height: 10),

          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: textTheme.textBodySecondary.copyWith(
              fontSize: 16,
              color: themeColor.secondaryText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
