import 'package:flutter/material.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'animated_price_ticker.dart';
import 'coupon_chip.dart';
import 'dynamic_price_explanation_row.dart';

class PriceBreakdownCard extends StatelessWidget {
  final BookingPricing pricing;
  final bool showHeader;

  const PriceBreakdownCard({
    super.key,
    required this.pricing,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final metadata = pricing.metadata ?? {};

    // 1. Extract Options
    final List<dynamic> optionsRaw = metadata['options_breakdown'] as List<dynamic>? ?? [];
    final List<Map<String, dynamic>> options = optionsRaw.map((o) => Map<String, dynamic>.from(o as Map)).toList();

    // 2. Extract Applied Rules
    final List<dynamic> rulesRaw = metadata['applied_rules'] as List<dynamic>? ?? [];
    final List<Map<String, dynamic>> rules = rulesRaw.map((r) => Map<String, dynamic>.from(r as Map)).toList();

    // 3. Extract Applied Discounts
    final List<dynamic> discountsRaw = metadata['applied_discounts'] as List<dynamic>? ?? [];
    final List<Map<String, dynamic>> discounts = discountsRaw.map((d) => Map<String, dynamic>.from(d as Map)).toList();

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
            if (showHeader) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'تفاصيل الحساب المالي',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Icon(
                    Icons.receipt_long_rounded,
                    color: themeColor.primary.withValues(alpha: 0.7),
                    size: 20,
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, thickness: 0.5),
              ),
            ],

            // Base Price
            _buildRow(
              context,
              'السعر الأساسي للخدمة',
              pricing.basePrice,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
              ),
            ),

            // Options list
            if (options.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...options.map((opt) {
                final key = opt['key'] as String? ?? 'خيار إضافي';
                final priceVal = (opt['price'] as num? ?? opt['value'] as num? ?? 0).toDouble();
                final displayKey = _translateOptionKey(key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _buildRow(
                    context,
                    displayKey,
                    priceVal,
                    prefix: '+ ',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: themeColor.secondaryText,
                    ),
                  ),
                );
              }),
            ],

            // Rules list
            if (rules.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 12),
              ...rules.map((rule) {
                final name = rule['name'] as String? ?? rule['rule_name'] as String? ?? 'تعديل السعر التلقائي';
                final actionType = rule['action_type'] as String? ?? '';
                final actionValue = (rule['action_value'] as num? ?? 0).toDouble();
                return DynamicPriceExplanationRow(
                  title: name,
                  description: actionType == 'multiply' ? 'مضاعف تسعير سحابي' : 'رسوم إضافية ديناميكية',
                  changeAmount: actionValue,
                  isMultiplier: actionType == 'multiply',
                );
              }),
            ],

            // Discounts list
            if (discounts.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: discounts.map((disc) {
                  final name = disc['name'] as String? ?? 'خصم ترويجي';
                  final code = disc['code'] as String?;
                  final val = (disc['amount'] as num? ?? disc['value'] as num? ?? disc['discount_value'] as num? ?? 0).toDouble();
                  return CouponChip(
                    label: name,
                    code: code,
                    discountAmount: val,
                    isPercentage: false,
                  );
                }).toList(),
              ),
            ],

            // Divider before Total
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(height: 1, thickness: 1.5),
            ),

            // Final Total with AnimatedPriceTicker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الإجمالي النهائي (Total)',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: themeColor.primary,
                  ),
                ),
                AnimatedPriceTicker(
                  price: pricing.total,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: themeColor.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    String label,
    double amount, {
    String prefix = '',
    TextStyle? style,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          '$prefix${amount.toStringAsFixed(0)} ج.م',
          style: style?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _translateOptionKey(String key) {
    switch (key.toLowerCase()) {
      case 'furnished':
        return 'تنظيف أثاث متكامل';
      case 'deep_clean':
        return 'تنظيف عميق إضافي';
      case 'express_service':
        return 'خدمة سريعة (Express)';
      default:
        return key;
    }
  }
}
