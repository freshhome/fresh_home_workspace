import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_colors.dart';

@immutable
class ThemeColorExtension extends ThemeExtension<ThemeColorExtension> {
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color background;
  final Color textPrimary;
  final Color appBarIcon;
  final Color buttonBackground;
  final Color buttonText;
  final Color cardBackground;
  final Color nestedCardBackground;
  final Color warning;
  final Color error;
  final Color secondaryText;
  final Color unselectedItem;
  final Color tabLabel;
  final Color tabUnselectedLabel;
  final Color tabIndicator;
  final BoxShadow cardShadow;
  final BorderSide cardBorder;
  final BorderSide highlightedcardBorder;
  final Gradient buttonGradient;
  final Color serviceIconBackground;
  final Color pricingAccent;
  final Color pricingDiscount;
  final Color pricingLocked;
  final Color pricingEstimated;
  final Color pricingTechEarnings;
  final Color pricingCommission;

  const ThemeColorExtension({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.background,
    required this.textPrimary,
    required this.appBarIcon,
    required this.buttonBackground,
    required this.buttonText,
    required this.warning,
    required this.error,
    required this.secondaryText,
    required this.cardBackground,
    required this.nestedCardBackground,
    required this.unselectedItem,
    required this.tabLabel,
    required this.tabUnselectedLabel,
    required this.tabIndicator,
    required this.cardShadow,
    required this.cardBorder,
    required this.highlightedcardBorder,
    required this.buttonGradient,
    required this.serviceIconBackground,
    required this.pricingAccent,
    required this.pricingDiscount,
    required this.pricingLocked,
    required this.pricingEstimated,
    required this.pricingTechEarnings,
    required this.pricingCommission,
  });

  @override
  ThemeColorExtension copyWith({
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? background,
    Color? textPrimary,
    Color? appBarIcon,
    Color? buttonBackground,
    Color? buttonText,
    Color? warning,
    Color? error,
    Color? secondaryText,
    Color? cardBackground,
    Color? nestedCardBackground,
    Color? unselectedItem,
    Color? tabLabel,
    Color? tabUnselectedLabel,
    Color? tabIndicator,
    BoxShadow? cardShadow,
    BorderSide? cardBorder,
    BorderSide? highlightedcardBorder,
    Gradient? buttonGradient,
    Color? serviceIconBackground,
    Color? pricingAccent,
    Color? pricingDiscount,
    Color? pricingLocked,
    Color? pricingEstimated,
    Color? pricingTechEarnings,
    Color? pricingCommission,
  }) {
    return ThemeColorExtension(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      background: background ?? this.background,
      textPrimary: textPrimary ?? this.textPrimary,
      appBarIcon: appBarIcon ?? this.appBarIcon,
      buttonBackground: buttonBackground ?? this.buttonBackground,
      buttonText: buttonText ?? this.buttonText,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      secondaryText: secondaryText ?? this.secondaryText,
      cardBackground: cardBackground ?? this.cardBackground,
      nestedCardBackground: nestedCardBackground ?? this.nestedCardBackground,
      unselectedItem: unselectedItem ?? this.unselectedItem,
      tabLabel: tabLabel ?? this.tabLabel,
      tabUnselectedLabel: tabUnselectedLabel ?? this.tabUnselectedLabel,
      tabIndicator: tabIndicator ?? this.tabIndicator,
      cardShadow: cardShadow ?? this.cardShadow,
      cardBorder: cardBorder ?? this.cardBorder,
      highlightedcardBorder: highlightedcardBorder ?? this.highlightedcardBorder,
      buttonGradient: buttonGradient ?? this.buttonGradient,
      serviceIconBackground: serviceIconBackground ?? this.serviceIconBackground,
      pricingAccent: pricingAccent ?? this.pricingAccent,
      pricingDiscount: pricingDiscount ?? this.pricingDiscount,
      pricingLocked: pricingLocked ?? this.pricingLocked,
      pricingEstimated: pricingEstimated ?? this.pricingEstimated,
      pricingTechEarnings: pricingTechEarnings ?? this.pricingTechEarnings,
      pricingCommission: pricingCommission ?? this.pricingCommission,
    );
  }

  @override
  ThemeColorExtension lerp(covariant ThemeExtension<ThemeColorExtension>? other, double t) {
    if (other is! ThemeColorExtension) return this;
    return ThemeColorExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      background: Color.lerp(background, other.background, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      appBarIcon: Color.lerp(appBarIcon, other.appBarIcon, t)!,
      buttonBackground: Color.lerp(buttonBackground, other.buttonBackground, t)!,
      buttonText: Color.lerp(buttonText, other.buttonText, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      nestedCardBackground: Color.lerp(nestedCardBackground, other.nestedCardBackground, t)!,
      unselectedItem: Color.lerp(unselectedItem, other.unselectedItem, t)!,
      tabLabel: Color.lerp(tabLabel, other.tabLabel, t)!,
      tabUnselectedLabel: Color.lerp(tabUnselectedLabel, other.tabUnselectedLabel, t)!,
      tabIndicator: Color.lerp(tabIndicator, other.tabIndicator, t)!,
      cardShadow: BoxShadow.lerp(cardShadow, other.cardShadow, t)!,
      cardBorder: other.cardBorder,
      highlightedcardBorder: other.highlightedcardBorder,
      buttonGradient: Gradient.lerp(buttonGradient, other.buttonGradient, t)!,
      serviceIconBackground: Color.lerp(serviceIconBackground, other.serviceIconBackground, t)!,
      pricingAccent: Color.lerp(pricingAccent, other.pricingAccent, t)!,
      pricingDiscount: Color.lerp(pricingDiscount, other.pricingDiscount, t)!,
      pricingLocked: Color.lerp(pricingLocked, other.pricingLocked, t)!,
      pricingEstimated: Color.lerp(pricingEstimated, other.pricingEstimated, t)!,
      pricingTechEarnings: Color.lerp(pricingTechEarnings, other.pricingTechEarnings, t)!,
      pricingCommission: Color.lerp(pricingCommission, other.pricingCommission, t)!,
    );
  }

  static const ThemeColorExtension light = ThemeColorExtension(
    primary: ThemeColors.primaryLight,
    onPrimary: Colors.white,
    secondary: ThemeColors.secondaryLight,
    onSecondary: Colors.white,
    background: ThemeColors.backgroundLight,
    textPrimary: ThemeColors.textPrimaryLight,
    appBarIcon: ThemeColors.appBarIconLight,
    buttonBackground: ThemeColors.buttonBackgroundLight,
    buttonText: ThemeColors.buttonTextLight,
    warning: ThemeColors.warningLight,
    error: ThemeColors.errorLight,
    secondaryText: ThemeColors.secondaryTextLight,
    cardBackground: ThemeColors.cardBackgroundLight,
    nestedCardBackground: ThemeColors.nestedCardBackgroundLight,
    unselectedItem: ThemeColors.unselectedItemLight,
    tabLabel: ThemeColors.tabLabelLight,
    tabUnselectedLabel: ThemeColors.tabUnselectedLabelLight,
    tabIndicator: ThemeColors.tabIndicatorLight,
    cardShadow: ThemeColors.lightShadow,
    cardBorder: ThemeColors.lightCardBorder,
    highlightedcardBorder: ThemeColors.highlightedLightCardBorder,
    buttonGradient: LinearGradient(
      colors: [ThemeColors.buttonGradientStart, ThemeColors.buttonGradientEnd],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    serviceIconBackground: ThemeColors.serviceIconBackgroundLight,
    pricingAccent: ThemeColors.pricingAccentLight,
    pricingDiscount: ThemeColors.pricingDiscountLight,
    pricingLocked: ThemeColors.pricingLockedLight,
    pricingEstimated: ThemeColors.pricingEstimatedLight,
    pricingTechEarnings: ThemeColors.pricingTechEarningsLight,
    pricingCommission: ThemeColors.pricingCommissionLight,
  );

  static const ThemeColorExtension dark = ThemeColorExtension(
    primary: ThemeColors.primaryDark,
    onPrimary: Colors.white,
    secondary: ThemeColors.secondaryDark,
    onSecondary: Colors.white,
    background: ThemeColors.backgroundDark,
    textPrimary: ThemeColors.textPrimaryDark,
    appBarIcon: ThemeColors.appBarIconDark,
    buttonBackground: ThemeColors.buttonBackgroundDark,
    buttonText: ThemeColors.buttonTextDark,
    warning: ThemeColors.warningDark,
    error: ThemeColors.errorDark,
    secondaryText: ThemeColors.secondaryTextDark,
    cardBackground: ThemeColors.cardBackgroundDark,
    nestedCardBackground: ThemeColors.nestedCardBackgroundDark,
    unselectedItem: ThemeColors.unselectedItemDark,
    tabLabel: ThemeColors.tabLabelDark,
    tabUnselectedLabel: ThemeColors.tabUnselectedLabelDark,
    tabIndicator: ThemeColors.tabIndicatorDark,
    cardShadow: ThemeColors.darkShadow,
    cardBorder: ThemeColors.darkCardBorder,
    highlightedcardBorder: ThemeColors.highlightedDarkCardBorder,
    buttonGradient: LinearGradient(
      colors: [ThemeColors.buttonGradientStart, ThemeColors.buttonGradientEnd],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    serviceIconBackground: ThemeColors.serviceIconBackgroundDark,
    pricingAccent: ThemeColors.pricingAccentDark,
    pricingDiscount: ThemeColors.pricingDiscountDark,
    pricingLocked: ThemeColors.pricingLockedDark,
    pricingEstimated: ThemeColors.pricingEstimatedDark,
    pricingTechEarnings: ThemeColors.pricingTechEarningsDark,
    pricingCommission: ThemeColors.pricingCommissionDark,
  );
}

extension ThemeColorContext on BuildContext {
  ThemeColorExtension get themeColor => Theme.of(this).extension<ThemeColorExtension>()!;
}
