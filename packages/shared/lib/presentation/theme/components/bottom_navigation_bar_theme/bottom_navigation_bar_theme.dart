import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_colors.dart';

BottomNavigationBarThemeData bottomNavigationBarThemeLight =
    const BottomNavigationBarThemeData(
      backgroundColor: ThemeColors.backgroundLight,
      selectedItemColor: ThemeColors.primaryLight,
      unselectedItemColor: ThemeColors.unselectedItemLight,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
      
    );

BottomNavigationBarThemeData bottomNavigationBarThemeDark =
    const BottomNavigationBarThemeData(
      backgroundColor: ThemeColors.primaryDark,
      selectedItemColor: ThemeColors.buttonBackgroundDark, // سيان ساطع للتباين
      unselectedItemColor: ThemeColors.unselectedItemDark,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),

    );
