import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

class TechnicianPayoutPreviewCard extends StatelessWidget {
  final double customerPrice;
  final double technicianPayout;
  final double platformCommission;
  final double bonuses;
  final double promosAbsorbed;

  const TechnicianPayoutPreviewCard({
    super.key,
    required this.customerPrice,
    required this.technicianPayout,
    required this.platformCommission,
    required this.bonuses,
    required this.promosAbsorbed,
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
                  Icons.engineering_rounded,
                  color: themeColor.pricingTechEarnings,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'مستحقات الفني المقدرة (Technician Payout)',
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
              'المدفوع الكلي من العميل',
              '${customerPrice.toStringAsFixed(0)} ج.م',
              themeColor.textPrimary,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              context,
              'عمولة المنصة (Platform Commission)',
              '- ${platformCommission.toStringAsFixed(0)} ج.م',
              themeColor.pricingCommission,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              context,
              'علاوات وحوافز إضافية (Incentives/Bonuses)',
              '+ ${bonuses.toStringAsFixed(0)} ج.م',
              themeColor.pricingDiscount,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              context,
              'خصومات العميل (تتحملها المنصة بالكامل)',
              '+ ${promosAbsorbed.toStringAsFixed(0)} ج.م',
              Colors.teal,
              isAbsorbedBadge: true,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, thickness: 1.0),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'صافي مستحقات الفني',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: themeColor.pricingTechEarnings,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${technicianPayout.toStringAsFixed(0)} ج.م',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: themeColor.pricingTechEarnings,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    Color color, {
    bool isAbsorbedBadge = false,
  }) {
    final themeColor = context.themeColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: themeColor.secondaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isAbsorbedBadge)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
                  ),
                  child: const Text(
                    'لا يخصم من الفني',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
            ],
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
