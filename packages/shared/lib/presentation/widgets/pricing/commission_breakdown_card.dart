import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

class CommissionBreakdownCard extends StatelessWidget {
  final double customerPaid;
  final double technicianEarnings;
  final double platformCommission;

  const CommissionBreakdownCard({
    super.key,
    required this.customerPaid,
    required this.technicianEarnings,
    required this.platformCommission,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final commissionPercent = customerPaid > 0 ? (platformCommission / customerPaid) * 100 : 0.0;

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
                  Icons.pie_chart_rounded,
                  color: themeColor.pricingTechEarnings,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Text(
                  'تفاصيل توزيع المدفوعات (Commission Split)',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, thickness: 0.5),
            ),
            _buildRow(context, 'إجمالي مدفوعات العميل للخدمة', '${customerPaid.toStringAsFixed(0)} ج.م', themeColor.textPrimary, isBold: true),
            const SizedBox(height: 12),
            _buildRow(context, 'عمولة المنصة (${commissionPercent.toStringAsFixed(0)}%)', '- ${platformCommission.toStringAsFixed(0)} ج.م', themeColor.pricingCommission),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, thickness: 1.0),
            ),
            _buildRow(
              context,
              'صافي أرباح الفني المستلمة',
              '${technicianEarnings.toStringAsFixed(0)} ج.م',
              themeColor.pricingTechEarnings,
              isBold: true,
              fontSize: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    String label,
    String value,
    Color color, {
    bool isBold = false,
    double fontSize = 13,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: fontSize,
            color: isBold ? context.themeColor.textPrimary : context.themeColor.secondaryText,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}
