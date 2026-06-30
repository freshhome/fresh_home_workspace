import 'package:flutter/widgets.dart';

/// Reusable linear content shimmers for loaded state placeholders.
class FHShimmer extends StatelessWidget {
  /// The skeleton layout boundary.
  final Widget child;

  /// Shimmer translation speed configurations.
  final Duration duration;

  const FHShimmer({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // SKELETON: Renders base static container placeholder
    return child;
  }
}
