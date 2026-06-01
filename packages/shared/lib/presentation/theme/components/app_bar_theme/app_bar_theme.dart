import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_colors.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_styles.dart';


AppBarTheme appBarThemeLight = const AppBarTheme(
  centerTitle: true,
  elevation: 10,
  backgroundColor: ThemeColors.primaryLight,
  titleTextStyle: AppTextStyles.titleAppBarLight,
  iconTheme: IconThemeData(color: ThemeColors.appBarIconLight),
);

AppBarTheme appBarThemeDark = const AppBarTheme(
  centerTitle: true,
  elevation: 10,
  backgroundColor: ThemeColors.primaryDark,
  titleTextStyle: AppTextStyles.titleAppBarDark,
  iconTheme: IconThemeData(color: ThemeColors.appBarIconDark),
);
