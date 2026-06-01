import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

class LockedPriceBanner extends StatelessWidget {
  final bool isLocked;
  final String? customMessage;

  const LockedPriceBanner({
    super.key,
    required this.isLocked,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final bannerColor = isLocked ? themeColor.pricingLocked : themeColor.pricingEstimated;
    final icon = isLocked ? Icons.lock_outline_rounded : Icons.info_outline_rounded;
    final title = isLocked ? 'سعر مؤكد ومثبت (Locked Price)' : 'سعر تقديري (Estimated Price)';
    final subtitle = customMessage ??
        (isLocked
            ? 'هذا السعر نهائي ومحمي بموجب شروط الحجز ولن يتأثر بأي تغيرات لاحقة.'
            : 'هذا السعر تقريبي وقد يتغير بناءً على تفاصيل العمل الفعلية أو المعطيات الإضافية.');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: bannerColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: bannerColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey.shade700
                        : Colors.grey.shade300,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
