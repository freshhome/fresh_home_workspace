import 'package:flutter/widgets.dart';

/// Reusable core loading widget.
///
/// Under the hood, this enforces the visual budget to prevent visual noise.
class FHLoadingIndicator extends StatelessWidget {
  /// Defines indicator sizing bounds.
  final double size;

  const FHLoadingIndicator({
    Key? key,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // SKELETON: Renders base static container placeholder
    return SizedBox(
      width: size,
      height: size,
      child: const DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle),
      ),
    );
  }
}
