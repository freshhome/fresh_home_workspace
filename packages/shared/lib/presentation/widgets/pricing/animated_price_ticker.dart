import 'package:flutter/material.dart';

class AnimatedPriceTicker extends StatelessWidget {
  final double price;
  final TextStyle? style;
  final String currency;
  final Duration duration;

  const AnimatedPriceTicker({
    super.key,
    required this.price,
    this.style,
    this.currency = 'ج.م',
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: price, end: price),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          '${value.toStringAsFixed(0)} $currency',
          style: style,
        );
      },
    );
  }
}
