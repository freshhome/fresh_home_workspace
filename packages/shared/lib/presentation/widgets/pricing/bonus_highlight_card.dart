import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

class BonusHighlightCard extends StatelessWidget {
  final double bonusAmount;
  final String title;
  final String description;

  const BonusHighlightCard({
    super.key,
    required this.bonusAmount,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeColor.pricingDiscount.withValues(alpha: 0.15),
            themeColor.pricingDiscount.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeColor.pricingDiscount.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [themeColor.cardShadow],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeColor.pricingDiscount.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.star_rounded,
              color: themeColor.pricingDiscount,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: themeColor.pricingDiscount,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey.shade700
                        : Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'علاوة حوافز',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Text(
                '+${bonusAmount.toStringAsFixed(0)} ج.م',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: themeColor.pricingDiscount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
