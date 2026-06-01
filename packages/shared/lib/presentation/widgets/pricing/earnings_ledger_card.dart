import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

class EarningsLedgerCard extends StatelessWidget {
  final String orderId;
  final String serviceName;
  final DateTime date;
  final double earnings;
  final String status;

  const EarningsLedgerCard({
    super.key,
    required this.orderId,
    required this.serviceName,
    required this.date,
    required this.earnings,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeColor.pricingTechEarnings.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [themeColor.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'طلب #$orderId',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: themeColor.secondaryText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'تم الدفع',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            serviceName,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أرباح الفني الصافية',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: themeColor.secondaryText,
                    ),
                  ),
                  Text(
                    '${earnings.toStringAsFixed(0)} ج.م',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: themeColor.pricingTechEarnings,
                    ),
                  ),
                ],
              ),
              Text(
                '${date.day}/${date.month}/${date.year}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: themeColor.secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
