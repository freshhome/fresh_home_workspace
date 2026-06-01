import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_colors.dart';

abstract class AppTextStyles {
  // ---------------- استايلات العناوين الرئيسية ----------------
  /// عنوان رئيسي كبير (مثلاً في شاشة البداية أو الترويسة)
  static const TextStyle titleDisplayLargeLight = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: ThemeColors.textPrimaryLight,
  );
  static const TextStyle titleDisplayLargeDark = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: ThemeColors.textPrimaryDark,
  );

  /// عنوان رئيسي ثانوي
  static const TextStyle titleDisplayMediumLight = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: ThemeColors.textPrimaryLight,
  );
  static const TextStyle titleDisplayMediumDark = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: ThemeColors.textPrimaryDark,
  );

  /// عنوان ثالث أو رئيس قسم
  static const TextStyle titleDisplaySmallLight = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: ThemeColors.textPrimaryLight,
  );
  static const TextStyle titleDisplaySmallDark = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: ThemeColors.textPrimaryDark,
  );

  /// عنوان قسم كبير
  static const TextStyle titleSectionLargeLight = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: ThemeColors.textPrimaryLight,
  );
  static const TextStyle titleSectionLargeDark = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: ThemeColors.textPrimaryDark,
  );


  /// عنوان ألاب بار الرئيسي 
  static const TextStyle titleAppBarLight =TextStyle(
    color: ThemeColors.appBarIconLight,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle titleAppBarDark = TextStyle(
    color: ThemeColors.appBarIconDark,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );





  /// عنوان قسم متوسط
  static const TextStyle titleSectionMediumLight = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: ThemeColors.textPrimaryLight,
  );
  static const TextStyle titleSectionMediumDark = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: ThemeColors.textPrimaryDark,
  );

  /// عنوان قسم صغير (مثلاً عنوان كارت داخلي)
  static const TextStyle titleSectionSmallLight = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: ThemeColors.textPrimaryLight,
  );
  static const TextStyle titleSectionSmallDark = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: ThemeColors.textPrimaryDark,
  );

  // ---------------- استايلات النصوص الثانوية ----------------
  /// وصف توضيحي قوي للنصوص أو الشروحات المهمة
  static const TextStyle textSubtitlePrimaryLight = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: ThemeColors.textPrimaryLight,
  );
  static const TextStyle textSubtitlePrimaryDark = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: ThemeColors.textPrimaryDark,
  );

  /// وصف توضيحي ثانوي أو اختياري
  static const TextStyle textSubtitleSecondaryLight = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: ThemeColors.textPrimaryLight,
  );
  static const TextStyle textSubtitleSecondaryDark = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: ThemeColors.textPrimaryDark,
  );

  // ---------------- استايلات النصوص العادية ----------------
  /// نص رئيسي (فقرات أو نصوص طويلة)
  static const TextStyle textBodyPrimaryLight = TextStyle(
    fontSize: 16,
    color: ThemeColors.textPrimaryLight,
  );
  static const TextStyle textBodyPrimaryDark = TextStyle(
    fontSize: 16,
    color: ThemeColors.textPrimaryDark,
  );

  /// نص صغير أو أقل أهمية
  static const TextStyle textBodySecondaryLight = TextStyle(
    fontSize: 14,
    color: ThemeColors.textPrimaryLight,
  );
  static const TextStyle textBodySecondaryDark = TextStyle(
    fontSize: 14,
    color: ThemeColors.textPrimaryDark,
  );

  // ---------------- استايلات الأزرار ----------------
  /// نص الأزرار
  static const TextStyle textButtonLight = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: ThemeColors.buttonTextLight,
  );
  static const TextStyle textButtonDark = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: ThemeColors.buttonTextDark,
  );
  // ---------------- استايلات نصوص textform ----------------






  
  // ---------------- استايلات النصوص الثانوية الأصغر ----------------
  /// نص توضيحي صغير (مثلاً تحت صورة أو عنصر بسيط)
  static const TextStyle textCaptionLight = TextStyle(
    fontSize: 12,
    color: ThemeColors.grey,
  );
  static const TextStyle textCaptionDark = TextStyle(
    fontSize: 12,
    color: ThemeColors.grey,
  );

  /// خطوط صغيرة جدًا (مثلاً توقيع أو تصنيف صغير)
  static const TextStyle textOverlineLight = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: ThemeColors.grey,
  );
  static const TextStyle textOverlineDark = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: ThemeColors.grey,
  );

  ///                           
  // ---------------- استايلات الأخطاء ----------------
  /// رسائل الخطأ
  static const TextStyle textErrorLight = TextStyle(
    fontSize: 14,
    color: Colors.red,
  );
  static const TextStyle textErrorDark = TextStyle(
    fontSize: 14,
    color: Colors.red,
  );

  // ---------------- استايلات النجاح ----------------
  /// رسائل النجاح
  static const TextStyle textSuccessLight = TextStyle(
    fontSize: 14,
    color: Colors.green,
  );
  static const TextStyle textSuccessDark = TextStyle(
    fontSize: 14,
    color: Colors.green,
  );
}
