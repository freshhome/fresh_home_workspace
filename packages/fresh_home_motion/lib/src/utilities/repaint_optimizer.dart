import 'package:flutter/widgets.dart';

/// Helper widget to automatically wrap frequently repainted subtrees in RepaintBoundary.
class FHRepaintOptimizer extends StatelessWidget {
  /// The element subtree to optimize.
  final Widget child;

  /// Enable or disable optimization boundary.
  final bool enable;

  const FHRepaintOptimizer({
    Key? key,
    required this.child,
    this.enable = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (enable) {
      return RepaintBoundary(child: child);
    }
    return child;
  }
}
