import 'package:flutter/material.dart';

/// Standardized Skeleton Loading Container to prevent layout shifts during async data fetches.
class AppSkeletonLoading extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const AppSkeletonLoading({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 12.0,
    this.margin,
  });

  /// Factory constructor for line skeletons (text placeholders).
  factory AppSkeletonLoading.line({
    Key? key,
    double? width,
    double height = 14.0,
    EdgeInsetsGeometry? margin,
  }) {
    return AppSkeletonLoading(
      key: key,
      width: width,
      height: height,
      borderRadius: 4.0,
      margin: margin,
    );
  }

  /// Factory constructor for circular skeletons (avatar placeholders).
  factory AppSkeletonLoading.circle({
    Key? key,
    required double size,
    EdgeInsetsGeometry? margin,
  }) {
    return AppSkeletonLoading(
      key: key,
      width: size,
      height: size,
      borderRadius: 999.0,
      margin: margin,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
