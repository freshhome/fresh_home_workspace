import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

class CustomerPaidSummary extends StatelessWidget {
  final double basePrice;
  final double extraFees;
  final double customerDiscount;
  final double customerPaid;

  const CustomerPaidSummary({
    super.key,
    required this.basePrice,
    required this.extraFees,
    required this.customerDiscount,
    required this.customerPaid,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

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
                  Icons.receipt_rounded,
                  color: themeColor.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Text(
                  'تفاصيل ما سدده العميل (Customer Paid Summary)',
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
            _buildRow(context, 'سعر الخدمة الأساسي', '${basePrice.toStringAsFixed(0)} ج.م', themeColor.secondaryText),
            const SizedBox(height: 10),
            _buildRow(context, 'إضافات ومصاريف تشغيل', '+ ${extraFees.toStringAsFixed(0)} ج.م', themeColor.secondaryText),
            
            if (customerDiscount > 0) ...[
              const SizedBox(height: 10),
              _buildRow(
                context,
                'تخفيضات العروض المستحقة للعميل',
                '- ${customerDiscount.toStringAsFixed(0)} ج.م',
                themeColor.pricingLocked,
                badgeText: 'تتحملها الشركة بالكامل',
              ),
            ],
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, thickness: 1.0),
            ),
            _buildRow(context, 'الإجمالي المدفوع فعلياً من العميل', '${customerPaid.toStringAsFixed(0)} ج.م', themeColor.primary, isBold: true, fontSize: 14),
            
            if (customerDiscount > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security_rounded, color: Colors.teal, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ملاحظة الأمان: خصومات العميل والعروض الترويجية تتحملها الشركة بالكامل ولا تؤثر على حساب أرباح الفني أو نسبته.',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    String? badgeText,
  }) {
    final themeColor = context.themeColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: fontSize,
                color: isBold ? themeColor.textPrimary : themeColor.secondaryText,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (badgeText != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: themeColor.pricingLocked.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: themeColor.pricingLocked,
                  ),
                ),
              ),
            ],
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
