import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_colors.dart';

TabBarThemeData tabBarThemeLight = TabBarThemeData(
  labelColor: ThemeColors.tabLabelLight,
  unselectedLabelColor: ThemeColors.tabUnselectedLabelLight,
  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
  indicatorColor: ThemeColors.tabIndicatorLight,
);

TabBarThemeData tabBarThemeDark = TabBarThemeData(
  labelColor: ThemeColors.tabLabelDark,
  unselectedLabelColor: ThemeColors.tabUnselectedLabelDark,
  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
  indicatorColor: ThemeColors.tabIndicatorDark,
);
