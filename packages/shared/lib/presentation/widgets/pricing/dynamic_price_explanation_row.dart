import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

class DynamicPriceExplanationRow extends StatelessWidget {
  final String title;
  final String description;
  final double changeAmount;
  final bool isMultiplier;
  final IconData? icon;

  const DynamicPriceExplanationRow({
    super.key,
    required this.title,
    required this.description,
    required this.changeAmount,
    this.isMultiplier = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final isDiscount = changeAmount < 0;
    final textColor = isDiscount ? themeColor.pricingDiscount : themeColor.textPrimary;
    final leadingIcon = icon ?? (isDiscount ? Icons.trending_down_rounded : Icons.add_circle_outline_rounded);
    
    final String displayAmount;
    if (isMultiplier) {
      displayAmount = 'x${changeAmount.toStringAsFixed(2)}';
    } else {
      final prefix = changeAmount > 0 ? '+' : '';
      displayAmount = '$prefix${changeAmount.toStringAsFixed(0)} ج.م';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            leadingIcon,
            size: 16,
            color: isDiscount ? themeColor.pricingDiscount : themeColor.pricingAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey.shade900
                        : Colors.white,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: themeColor.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            displayAmount,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
