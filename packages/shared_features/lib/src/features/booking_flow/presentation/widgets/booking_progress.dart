import 'package:flutter/material.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';

enum StepStatus { completed, current, upcoming }

class BookingProgress extends StatelessWidget {
  final int currentStep;

  /// Total number of steps. Defaults to 4 (customer flow).
  final int totalSteps;

  const BookingProgress({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;
    final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;

    // Customer steps (4) — same icons/labels as before
    final List<Map<String, dynamic>> customerSteps = [
      {'title': l10n.booking_step_1_title, 'icon': Icons.aspect_ratio},
      {'title': l10n.booking_step_2_title, 'icon': Icons.calendar_today},
      {'title': l10n.booking_step_3_title, 'icon': Icons.location_on},
      {'title': l10n.booking_step_4_title, 'icon': Icons.check_circle},
    ];

    // Admin steps (5)
    final List<Map<String, dynamic>> adminSteps = [
      {'title': 'الخدمة', 'icon': Icons.cleaning_services_rounded},
      {'title': 'السعر', 'icon': Icons.aspect_ratio},
      {'title': 'الموعد', 'icon': Icons.calendar_today},
      {'title': 'العميل', 'icon': Icons.person_outline},
      {'title': 'تأكيد', 'icon': Icons.check_circle},
    ];

    final steps = totalSteps == 5 ? adminSteps : customerSteps;

    final List<String> customerStepDescs = [
      l10n.booking_step_1_desc,
      l10n.booking_step_2_desc,
      l10n.booking_step_3_desc,
      l10n.booking_step_4_desc,
    ];

    final List<String> adminStepDescs = [
      'اختيار الخدمة',
      'تحديد السعر',
      'تحديد الموعد',
      'بيانات العميل',
      'تأكيد الحجز',
    ];

    final stepDescs = totalSteps == 5 ? adminStepDescs : customerStepDescs;

    const double circleSize = 34.0;

    return Container(
      color: themeColor.background,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topCenter,
            children: [
              // Background line
              Positioned(
                top: circleSize / 2,
                left: 20,
                right: 20,
                child: Container(
                  height: 2,
                  color: themeColor.unselectedItem.withValues(alpha: 0.3),
                ),
              ),
              // Progress line
              Positioned(
                top: circleSize / 2,
                left: 20,
                right: 20,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double progress =
                        (currentStep / (steps.length - 1)).clamp(0.0, 1.0);
                    return Align(
                      alignment:
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                      child: Container(
                        height: 2,
                        width: constraints.maxWidth * progress,
                        color: themeColor.buttonBackground,
                      ),
                    );
                  },
                ),
              ),
              // Step dots
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(steps.length, (index) {
                  final bool isCompleted = index < currentStep;
                  final bool isCurrent = index == currentStep;

                  Color color = isCompleted
                      ? themeColor.buttonBackground
                      : (isCurrent
                          ? themeColor.secondary
                          : themeColor.unselectedItem);

                  return Column(
                    children: [
                      Container(
                        width: circleSize,
                        height: circleSize,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: themeColor.cardBackground, width: 2),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [],
                        ),
                        child: Icon(
                          steps[index]['icon'],
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        steps[index]['title'],
                        style: themeText.textCaption.copyWith(
                          fontSize: 11,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCurrent
                              ? themeColor.textPrimary
                              : themeColor.unselectedItem,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${l10n.booking_step_progress} ${currentStep + 1}: ${stepDescs[currentStep]}',
            style: themeText.titleSectionSmall.copyWith(
              color: themeColor.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
