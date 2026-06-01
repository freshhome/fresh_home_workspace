import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_colors.dart';

final inputDecorationThemeLight = InputDecorationTheme(
  filled: true,
  fillColor: Colors.transparent, // علشان تبقى شفافة
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: ThemeColors.grey),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: ThemeColors.grey),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: ThemeColors.primaryLight, width: 2),
  ),
  labelStyle: TextStyle(color: ThemeColors.textPrimaryLight),
  hintStyle: TextStyle(color: ThemeColors.grey),
);

final inputDecorationThemeDark = InputDecorationTheme(
  
  filled: true,
  fillColor: Colors.transparent, 
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: ThemeColors.grey),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: ThemeColors.grey),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: ThemeColors.buttonBackgroundDark, width: 2), // التركيز بلون السيان
  ),
  labelStyle: TextStyle(color: ThemeColors.textPrimaryDark),
  hintStyle: TextStyle(color: ThemeColors.grey),
);
