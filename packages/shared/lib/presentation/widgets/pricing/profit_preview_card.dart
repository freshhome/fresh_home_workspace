import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

class ProfitPreviewCard extends StatelessWidget {
  final double customerPrice;
  final double technicianPayout;
  final double discountImpact;
  final double netProfit;

  const ProfitPreviewCard({
    super.key,
    required this.customerPrice,
    required this.technicianPayout,
    required this.discountImpact,
    required this.netProfit,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final profitMargin = customerPrice > 0 ? (netProfit / customerPrice) * 100 : 0.0;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: themeColor.cardBorder,
      ),
      elevation: 0,
      color: themeColor.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_rounded,
                  color: themeColor.pricingDiscount,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'تحليل هوامش الأرباح (Profit Margins)',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, thickness: 0.5),
            ),
            _buildDetailRow(
              context,
              'إيرادات العميل الإجمالية',
              '${customerPrice.toStringAsFixed(0)} ج.م',
              Colors.blueGrey,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              context,
              'تكلفة تشغيل الفني (المدفوع للفني)',
              '- ${technicianPayout.toStringAsFixed(0)} ج.م',
              themeColor.pricingTechEarnings,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              context,
              'تخفيضات العروض التسويقية (تتحملها الشركة)',
              '- ${discountImpact.toStringAsFixed(0)} ج.م',
              themeColor.pricingLocked,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, thickness: 1.0),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'صافي ربح العملية',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: netProfit >= 0 ? themeColor.pricingDiscount : themeColor.error,
                      ),
                    ),
                    Text(
                      'هامش الربح: ${profitMargin.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: themeColor.secondaryText,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${netProfit.toStringAsFixed(0)} ج.م',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: netProfit >= 0 ? themeColor.pricingDiscount : themeColor.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: context.themeColor.secondaryText,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
