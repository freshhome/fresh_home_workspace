import 'package:flutter/material.dart';

/// ملف يحتوي على كل الألوان اللي هيتم استخدامها في التطبيق
/// متقسم حسب الثيم (فاتح - داكن) علشان تسهّل التعديل وإعادة الاستخدام

abstract class ThemeColors {
  /// اللون الأساسي - يستخدم في AppBar، الأزرار الرئيسية
  ///
  static const Color primaryLight = Color(0xFF0D327D); // أزرق داكن (اللون الأساسي الجديد)
  static const Color primaryDark = Color(0xFF64B5F6); // أزرق فاتح للوضع الداكن (Light Blue)

  /// ألوان التدرج للأزرار
  static const Color buttonGradientStart = Color(0xFF0D327D);
  static const Color buttonGradientEnd = Color(0xFF22A5FC);

  /// اللون الثانوي - يستخدم في الأيقونات، الأزرار الثانوية
  ///
  static const Color secondaryLight = Color(0xFF2ECC71); // أخضر فاتح
  static const Color secondaryDark = Color(0xFF69F0AE); // أخضر نيون للوضع الداكن

  /// لون الخلفية العام للتطبيق - يستخدم في Scaffold
  static const Color backgroundLight = Color(0xFFF8FAFC); // Subtle off-white (Slate 50)
  static const Color backgroundDark = Color(0xFF04103A);

  /// لون النص الرئيسي - يستخدم في النصوص السوداء
  static const Color textPrimaryLight = Colors.black;
  static const Color textPrimaryDark = Colors.white;

  /// لون النص الثانوي - يستخدم في النصوص الرمادية والوصف
  static const Color secondaryTextLight = Color(0xFF757575);
  static const Color secondaryTextDark = Color(0xFFB0BEC5);

  /// لون الأيقونات والنص داخل AppBar
  static const Color appBarIconLight = Colors.white;
  static const Color appBarIconDark = Colors.white; // أيقونات بيضاء دائماً للوضوح

  /// لون الأزرار - خلفية
  static const Color buttonBackgroundLight = Color(0xFF00A8E8);
  static const Color buttonBackgroundDark = Color(0xFF22A5FC); // سيان ساطع

  /// لون الأزرار - النص داخل الزر
  static const Color buttonTextLight = Colors.white;
  static const Color buttonTextDark = Colors.white; // نص أبيض للتباين مع السيان

  /// ألوان التحذير
  static const Color warningLight = Color(0xFFFF9800);
  static const Color warningDark = Color(0xFFFFA726);

  /// ألوان الخطأ أو العمليات الخطيرة
  static const Color errorLight = Color(0xFFE53935); // أحمر
  static const Color errorDark = Color(0xFFEF5350); // أحمر فاتح للوضع الداكن

  /// لون الكروت والحوارات
  static const Color cardBackgroundLight = Colors.white; // Pure white for better contrast
  static const Color cardBackgroundDark = Color(0xFF2B385A); // رمادي داكن أنيق

  /// لون الكروت والحوارات المتداخلة
  static const Color nestedCardBackgroundLight = Color(0xFFFFFFFF); // أبيض
  static const Color nestedCardBackgroundDark = Color(0xFF35476D);

  /// لون العنصر غير النشط (unselected)
  static const Color unselectedItemLight = Color(0xFF90A4AE); // رمادي فاتح
  static const Color unselectedItemDark = Color(0xFFB0BEC5); // رمادي متوسط
  /// لون الـ TabBar عند التحديد
  static const Color tabLabelLight = Colors.white;
  static const Color tabLabelDark = Color(0xFFFFFFFF);

  /// لون الـ TabBar عند عدم التحديد
  static const Color tabUnselectedLabelLight = Color(0xFFE0F7FA);
  static const Color tabUnselectedLabelDark = Color(0xFF90A4AE);

  /// لون الـ TabBar عند التحديد
  static const Color tabIndicatorLight = Colors.white;
  static const Color tabIndicatorDark = Color(0xFF00A8E8);

  /// ظل للكروت في الوضع الفاتح
  static const BoxShadow lightShadow = BoxShadow(
    color: Color(0x0D000000), // Very soft black (5% opacity)
    blurRadius: 40,
    offset: Offset(0, 8),
  );

  /// ظل للكروت في الوضع الداكن
  static const BoxShadow darkShadow = BoxShadow(
    color: Color(0xCC000000), // Deep black with 80% opacity for contrast
    blurRadius: 25,
    offset: Offset(0, 12),
    spreadRadius: -4, // Tighter, cleaner look
  );

  /// لون الحواف في الوضع الفاتح
  static const BorderSide lightCardBorder = BorderSide(
    color: Color(0xFFD0D0D0), // رمادي أغمق من الخلفية
    width: 1,
  );

  /// لون الحواف في الوضع الداكن
  static const BorderSide darkCardBorder = BorderSide(
    color: Color(0x33FFFFFF), // أبيض شفاف بنسبة 20%
    width: 1,
  );

  /// لون الحواف في الوضع الفاتح للكروت المميزة
  static const BorderSide highlightedLightCardBorder = BorderSide(
    color: Color(0xFF4A90E2), // أزرق هادي بيدي إحساس بالأهمية
    width: 1.5,
  );

  /// لون الحواف في الوضع الداكن للكروت المميزة
  static const BorderSide highlightedDarkCardBorder = BorderSide(
    color: Color(0xFF4A90E2), // نفس الأزرق المستخدم في الفاتح
    width: 1.5,
  );

  /// لون رمادي عام يستخدم في الفواصل أو النصوص الثانوية
  static const Color grey = Color(0xFF9E9E9E);

  /// لون خلفية أيقونة الخدمة
  static const Color serviceIconBackgroundLight = Color(0xFFF0F8FF); // Alice Blue
  static const Color serviceIconBackgroundDark = Color(0xFF07294A); // Dark Blue

  // ── Pricing Semantic Colors (Light Theme) ──
  static const Color pricingAccentLight = Color(0xFFE6A23C); // Gold/Amber Accent
  static const Color pricingDiscountLight = Color(0xFF2ECC71); // Emerald Green
  static const Color pricingLockedLight = Color(0xFFD35400); // Deep Orange for Locked
  static const Color pricingEstimatedLight = Color(0xFF2980B9); // Blue for Estimated
  static const Color pricingTechEarningsLight = Color(0xFF8E44AD); // Purple for Tech Earnings
  static const Color pricingCommissionLight = Color(0xFFC0392B); // Red for Platform Commission

  // ── Pricing Semantic Colors (Dark Theme) ──
  static const Color pricingAccentDark = Color(0xFFF1C40F); // Gold/Yellow
  static const Color pricingDiscountDark = Color(0xFF69F0AE); // Green Neon
  static const Color pricingLockedDark = Color(0xFFE67E22); // Orange
  static const Color pricingEstimatedDark = Color(0xFF3498DB); // Light Blue
  static const Color pricingTechEarningsDark = Color(0xFF9B59B6); // Light Purple
  static const Color pricingCommissionDark = Color(0xFFEF5350); // Coral Red
}
