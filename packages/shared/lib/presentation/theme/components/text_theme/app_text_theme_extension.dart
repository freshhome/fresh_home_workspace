import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_styles.dart';

@immutable
class AppTextThemeExtension extends ThemeExtension<AppTextThemeExtension> {
  final TextStyle titleDisplayLarge;
  final TextStyle titleDisplayMedium;
  final TextStyle titleDisplaySmall;
  final TextStyle titleSectionLarge;
  final TextStyle titleSectionMedium;
  final TextStyle titleSectionSmall;

  final TextStyle textSubtitlePrimary;
  final TextStyle textSubtitleSecondary;

  final TextStyle textBodyPrimary;
  final TextStyle textBodySecondary;

  final TextStyle textButton;
  final TextStyle textCaption;
  final TextStyle textOverline;

  final TextStyle textError;
  final TextStyle textSuccess;

  const AppTextThemeExtension({
    required this.titleDisplayLarge,
    required this.titleDisplayMedium,
    required this.titleDisplaySmall,
    required this.titleSectionLarge,
    required this.titleSectionMedium,
    required this.titleSectionSmall,
    required this.textSubtitlePrimary,
    required this.textSubtitleSecondary,
    required this.textBodyPrimary,
    required this.textBodySecondary,
    required this.textButton,
    required this.textCaption,
    required this.textOverline,
    required this.textError,
    required this.textSuccess,
  });

  @override
  AppTextThemeExtension copyWith({
    TextStyle? titleDisplayLarge,
    TextStyle? titleDisplayMedium,
    TextStyle? titleDisplaySmall,
    TextStyle? titleSectionLarge,
    TextStyle? titleSectionMedium,
    TextStyle? titleSectionSmall,
    TextStyle? textSubtitlePrimary,
    TextStyle? textSubtitleSecondary,
    TextStyle? textBodyPrimary,
    TextStyle? textBodySecondary,
    TextStyle? textButton,
    TextStyle? textCaption,
    TextStyle? textOverline,
    TextStyle? textError,
    TextStyle? textSuccess,
  }) {
    return AppTextThemeExtension(
      titleDisplayLarge: titleDisplayLarge ?? this.titleDisplayLarge,
      titleDisplayMedium: titleDisplayMedium ?? this.titleDisplayMedium,
      titleDisplaySmall: titleDisplaySmall ?? this.titleDisplaySmall,
      titleSectionLarge: titleSectionLarge ?? this.titleSectionLarge,
      titleSectionMedium: titleSectionMedium ?? this.titleSectionMedium,
      titleSectionSmall: titleSectionSmall ?? this.titleSectionSmall,
      textSubtitlePrimary: textSubtitlePrimary ?? this.textSubtitlePrimary,
      textSubtitleSecondary: textSubtitleSecondary ?? this.textSubtitleSecondary,
      textBodyPrimary: textBodyPrimary ?? this.textBodyPrimary,
      textBodySecondary: textBodySecondary ?? this.textBodySecondary,
      textButton: textButton ?? this.textButton,
      textCaption: textCaption ?? this.textCaption,
      textOverline: textOverline ?? this.textOverline,
      textError: textError ?? this.textError,
      textSuccess: textSuccess ?? this.textSuccess,
    );
  }

  @override
  AppTextThemeExtension lerp(ThemeExtension<AppTextThemeExtension>? other, double t) {
    if (other is! AppTextThemeExtension) return this;
    return AppTextThemeExtension(
      titleDisplayLarge: TextStyle.lerp(titleDisplayLarge, other.titleDisplayLarge, t)!,
      titleDisplayMedium: TextStyle.lerp(titleDisplayMedium, other.titleDisplayMedium, t)!,
      titleDisplaySmall: TextStyle.lerp(titleDisplaySmall, other.titleDisplaySmall, t)!,
      titleSectionLarge: TextStyle.lerp(titleSectionLarge, other.titleSectionLarge, t)!,
      titleSectionMedium: TextStyle.lerp(titleSectionMedium, other.titleSectionMedium, t)!,
      titleSectionSmall: TextStyle.lerp(titleSectionSmall, other.titleSectionSmall, t)!,
      textSubtitlePrimary: TextStyle.lerp(textSubtitlePrimary, other.textSubtitlePrimary, t)!,
      textSubtitleSecondary: TextStyle.lerp(textSubtitleSecondary, other.textSubtitleSecondary, t)!,
      textBodyPrimary: TextStyle.lerp(textBodyPrimary, other.textBodyPrimary, t)!,
      textBodySecondary: TextStyle.lerp(textBodySecondary, other.textBodySecondary, t)!,
      textButton: TextStyle.lerp(textButton, other.textButton, t)!,
      textCaption: TextStyle.lerp(textCaption, other.textCaption, t)!,
      textOverline: TextStyle.lerp(textOverline, other.textOverline, t)!,
      textError: TextStyle.lerp(textError, other.textError, t)!,
      textSuccess: TextStyle.lerp(textSuccess, other.textSuccess, t)!,
    );
  }

  // ---------------- Static Instances ----------------

  static const light = AppTextThemeExtension(
    titleDisplayLarge: AppTextStyles.titleDisplayLargeLight,
    titleDisplayMedium: AppTextStyles.titleDisplayMediumLight,
    titleDisplaySmall: AppTextStyles.titleDisplaySmallLight,
    titleSectionLarge: AppTextStyles.titleSectionLargeLight,
    titleSectionMedium: AppTextStyles.titleSectionMediumLight,
    titleSectionSmall: AppTextStyles.titleSectionSmallLight,
    textSubtitlePrimary: AppTextStyles.textSubtitlePrimaryLight,
    textSubtitleSecondary:  AppTextStyles.textSubtitleSecondaryLight,
    textBodyPrimary: AppTextStyles.textBodyPrimaryLight,
    textBodySecondary: AppTextStyles.textBodySecondaryLight,
    textButton: AppTextStyles.textButtonLight,
    textCaption: AppTextStyles.textCaptionLight,
    textOverline: AppTextStyles.textOverlineLight,
    textError: AppTextStyles.textErrorLight,
    textSuccess :AppTextStyles.textSuccessLight,
  );

  static const dark = AppTextThemeExtension(
    titleDisplayLarge: AppTextStyles.titleDisplayLargeDark,
    titleDisplayMedium:AppTextStyles.titleDisplayMediumDark,
    titleDisplaySmall: AppTextStyles.titleDisplaySmallDark,
    titleSectionLarge: AppTextStyles.titleSectionLargeDark,
    titleSectionMedium: AppTextStyles.titleSectionMediumDark,
    titleSectionSmall: AppTextStyles.titleSectionSmallDark,
    textSubtitlePrimary: AppTextStyles.textSubtitlePrimaryDark,
    textSubtitleSecondary: AppTextStyles.textSubtitleSecondaryDark,
    textBodyPrimary: AppTextStyles.textBodyPrimaryDark,
    textBodySecondary: AppTextStyles.textBodySecondaryDark,
    textButton: AppTextStyles.textButtonDark,
    textCaption: AppTextStyles.textCaptionDark,
    textOverline: AppTextStyles.textOverlineDark,
    textError: AppTextStyles.textErrorDark,
    textSuccess: AppTextStyles.textSuccessDark,
  );
}
