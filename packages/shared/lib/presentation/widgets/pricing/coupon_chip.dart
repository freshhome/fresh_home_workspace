import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

class CouponChip extends StatelessWidget {
  final String label;
  final String? code;
  final double discountAmount;
  final bool isPercentage;

  const CouponChip({
    super.key,
    required this.label,
    this.code,
    required this.discountAmount,
    this.isPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final displayValue = isPercentage
        ? '${discountAmount.toStringAsFixed(0)}%'
        : '${discountAmount.toStringAsFixed(0)} ج.م';

    return CustomPaint(
      painter: _CouponBorderPainter(
        color: themeColor.pricingDiscount,
        borderRadius: 8.0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: themeColor.pricingDiscount.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_offer_rounded,
              color: themeColor.pricingDiscount,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              code != null ? '$label ($code)' : label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: themeColor.pricingDiscount,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: themeColor.pricingDiscount,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '-$displayValue',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  _CouponBorderPainter({required this.color, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Draw rounded rect with ticket notches on left/right centers
    final double notchRadius = 5.0;
    final double notchCenterY = size.height / 2;

    path.moveTo(borderRadius, 0);
    path.lineTo(size.width - borderRadius, 0);
    path.arcToPoint(
      Offset(size.width, borderRadius),
      radius: Radius.circular(borderRadius),
    );
    
    // Right side notch
    path.lineTo(size.width, notchCenterY - notchRadius);
    path.arcToPoint(
      Offset(size.width, notchCenterY + notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(size.width, size.height - borderRadius);
    
    path.arcToPoint(
      Offset(size.width - borderRadius, size.height),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(borderRadius, size.height);
    path.arcToPoint(
      Offset(0, size.height - borderRadius),
      radius: Radius.circular(borderRadius),
    );
    
    // Left side notch
    path.lineTo(0, notchCenterY + notchRadius);
    path.arcToPoint(
      Offset(0, notchCenterY - notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(0, borderRadius);
    path.arcToPoint(
      Offset(borderRadius, 0),
      radius: Radius.circular(borderRadius),
    );

    // Draw dashed path
    final dashWidth = 4.0;
    final dashSpace = 3.0;
    
    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final double length = dashWidth;
        final Path extract = pathMetric.extractPath(distance, distance + length);
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
