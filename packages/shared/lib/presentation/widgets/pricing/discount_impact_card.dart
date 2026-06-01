import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

class DiscountImpactCard extends StatelessWidget {
  final double discountAmount;
  final double subtotal;
  final List<dynamic> appliedCampaigns;
  final bool globalCapHit;

  const DiscountImpactCard({
    super.key,
    required this.discountAmount,
    required this.subtotal,
    required this.appliedCampaigns,
    this.globalCapHit = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final discountRatio = subtotal > 0 ? (discountAmount / subtotal) * 100 : 0.0;

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.percent_rounded,
                      color: themeColor.pricingLocked,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'تأثير الخصومات والحملات الترويجية',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                if (globalCapHit)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: themeColor.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: themeColor.error.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'تم بلوغ سقف الخصم (30%)',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: themeColor.error,
                      ),
                    ),
                  ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, thickness: 0.5),
            ),
            _buildDetailRow(context, 'قيمة الخصومات الإجمالية', '- ${discountAmount.toStringAsFixed(0)} ج.م', themeColor.pricingLocked),
            const SizedBox(height: 10),
            _buildDetailRow(context, 'المعدل الفعلي للتخفيض', '${discountRatio.toStringAsFixed(1)}% من المجموع الفرعي', themeColor.secondaryText),
            
            if (appliedCampaigns.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'الحملات النشطة المطبقة:',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: themeColor.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...appliedCampaigns.map((camp) {
                final name = camp['name'] as String? ?? 'خصم ترويجي';
                final code = camp['code'] as String?;
                final val = (camp['value'] as num? ?? 0).toDouble();
                final valType = camp['value_type'] as String? ?? 'flat';
                final displayVal = valType == 'percent' || valType == 'percentage'
                    ? '${val.toStringAsFixed(0)}%'
                    : '${val.toStringAsFixed(0)} ج.م';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: themeColor.pricingDiscount, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          code != null ? '$name ($code)' : name,
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: themeColor.secondaryText),
                        ),
                      ),
                      Text(
                        '- $displayVal',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: themeColor.pricingDiscount,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'لم يتم تطبيق أي حملات خصم أو كوبونات ترويجية على هذه العملية.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: themeColor.secondaryText,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            color: context.themeColor.secondaryText,
          ),
        ),
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
