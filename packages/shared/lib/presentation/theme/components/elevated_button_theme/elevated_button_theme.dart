import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_colors.dart';

// ElevatedButton Theme في الوضع النهاري (Light)
ElevatedButtonThemeData elevatedButtonThemeLight = ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    foregroundColor: ThemeColors.buttonTextLight, // لون النص
    backgroundColor: ThemeColors.primaryLight,    // لون الزر
    elevation: 5,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12), // تدوير الزوايا
    ),
  ),
);

// ElevatedButton Theme في الوضع الليلي (Dark)
// ElevatedButton Theme في الوضع الليلي (Dark)
ElevatedButtonThemeData elevatedButtonThemeDark = ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    foregroundColor: ThemeColors.buttonTextDark,  // لون النص - أبيض الآن
    backgroundColor: ThemeColors.buttonBackgroundDark,     // لون الزر - سيان الآن
    elevation: 5,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12), // تدوير الزوايا
    ),
  ),
);
