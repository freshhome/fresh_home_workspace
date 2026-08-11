import 'package:flutter/material.dart';

/// Supported status categories for [AppStatusBadge].
enum AppStatusType {
  primary,
  success,
  warning,
  info,
  error,
  neutral,
}

/// Standardized Status Badge Component for Fresh Home V2.
class AppStatusBadge extends StatelessWidget {
  final String label;
  final AppStatusType type;
  final IconData? icon;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.type = AppStatusType.neutral,
    this.icon,
    this.fontSize = 11.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  /// Factory constructor for Primary Address badge.
  factory AppStatusBadge.primaryAddress({Key? key}) {
    return AppStatusBadge(
      key: key,
      label: 'رئيسي',
      type: AppStatusType.success,
      icon: Icons.star_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getBadgeColors(type);

    return Semantics(
      label: 'حالة: $label',
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: colors.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: fontSize + 2, color: colors.textColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: colors.textColor,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _BadgeColors _getBadgeColors(AppStatusType type) {
    switch (type) {
      case AppStatusType.success:
        return const _BadgeColors(
          backgroundColor: Color(0xFFECFDF5),
          borderColor: Color(0xFFA7F3D0),
          textColor: Color(0xFF047857),
        );
      case AppStatusType.primary:
        return const _BadgeColors(
          backgroundColor: Color(0xFFEFF6FF),
          borderColor: Color(0xFFBFDBFE),
          textColor: Color(0xFF1D4ED8),
        );
      case AppStatusType.warning:
        return const _BadgeColors(
          backgroundColor: Color(0xFFFFFBEB),
          borderColor: Color(0xFFFDE68A),
          textColor: Color(0xFFB45309),
        );
      case AppStatusType.info:
        return const _BadgeColors(
          backgroundColor: Color(0xFFECFEFF),
          borderColor: Color(0xFFA5F3FC),
          textColor: Color(0xFF0E7490),
        );
      case AppStatusType.error:
        return const _BadgeColors(
          backgroundColor: Color(0xFFFEF2F2),
          borderColor: Color(0xFFFCA5A5),
          textColor: Color(0xFFB91C1C),
        );
      case AppStatusType.neutral:
        return const _BadgeColors(
          backgroundColor: Color(0xFFF8FAFC),
          borderColor: Color(0xFFE2E8F0),
          textColor: Color(0xFF475569),
        );
    }
  }
}

class _BadgeColors {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _BadgeColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}
