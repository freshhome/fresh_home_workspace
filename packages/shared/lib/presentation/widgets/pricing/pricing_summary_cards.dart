import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

class PricingSummaryCards extends StatelessWidget {
  final double customerPrice;
  final double technicianPayout;
  final double netProfit;
  final double discountImpact;
  final bool globalCapHit;

  const PricingSummaryCards({
    super.key,
    required this.customerPrice,
    required this.technicianPayout,
    required this.netProfit,
    required this.discountImpact,
    this.globalCapHit = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                context,
                title: 'سعر العميل النهائي',
                value: '${customerPrice.toStringAsFixed(0)} ج.م',
                icon: Icons.person_outline_rounded,
                color: themeColor.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                context,
                title: 'مستحقات الفني',
                value: '${technicianPayout.toStringAsFixed(0)}.00 ج.م',
                icon: Icons.engineering_outlined,
                color: themeColor.pricingTechEarnings,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                context,
                title: 'صافي ربح الشركة',
                value: '${netProfit.toStringAsFixed(0)} ج.م',
                icon: Icons.account_balance_wallet_outlined,
                color: netProfit >= 0 ? themeColor.pricingDiscount : themeColor.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                context,
                title: 'تأثير الخصومات',
                value: '${discountImpact.toStringAsFixed(0)} ج.م',
                icon: Icons.percent_rounded,
                color: themeColor.pricingLocked,
                badgeText: globalCapHit ? 'تم بلوغ الحد الأقصى (30%)' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? badgeText,
  }) {
    final themeColor = context.themeColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [themeColor.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: themeColor.secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          if (badgeText != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: themeColor.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: themeColor.error.withValues(alpha: 0.2)),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: themeColor.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
