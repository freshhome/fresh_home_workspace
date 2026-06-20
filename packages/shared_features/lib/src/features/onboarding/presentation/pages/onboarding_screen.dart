import 'package:flutter/material.dart';
import 'package:shared/core/constants/app_assets.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';

import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

class OnboardingScreen extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  const OnboardingScreen({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textTheme = Theme.of(context).extension<AppTextThemeExtension>()!;
    final themeColor = context.themeColor;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Center(
              child: Image.asset(
                AppAssets.onboardingLogo,
                width: screenWidth * 0.25,
                height: screenWidth * 0.25,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleDisplayLarge.copyWith(
                color: themeColor.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Image.asset(
              imagePath,
              width: screenWidth * 0.9,
              height: screenWidth * 0.6,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                description,

                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: themeColor.secondaryText,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
