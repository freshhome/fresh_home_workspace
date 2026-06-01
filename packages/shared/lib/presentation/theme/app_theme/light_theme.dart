
 import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/app_bar_theme/app_bar_theme.dart';
import 'package:shared/presentation/theme/components/bottom_navigation_bar_theme/bottom_navigation_bar_theme.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/colors/theme_colors.dart';
import 'package:shared/presentation/theme/components/elevated_button_theme/elevated_button_theme.dart';
import 'package:shared/presentation/theme/components/input_decoration_theme/input_decoration_theme.dart';
import 'package:shared/presentation/theme/components/tab_bar_theme/tab_bar_theme.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';


ThemeData  lightTheme = ThemeData(
      useMaterial3: true,
      appBarTheme: appBarThemeLight,
      tabBarTheme: tabBarThemeLight,
      bottomNavigationBarTheme: bottomNavigationBarThemeLight,
      elevatedButtonTheme: elevatedButtonThemeLight,
      scaffoldBackgroundColor: ThemeColors.backgroundLight,
      inputDecorationTheme: inputDecorationThemeLight,

      extensions: const <ThemeExtension<dynamic>>[
        AppTextThemeExtension.light,
        ThemeColorExtension.light,
      ],
    );
  