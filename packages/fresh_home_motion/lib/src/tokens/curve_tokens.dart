import 'package:flutter/animation.dart';

/// Holds standardized cubic bezier animation curves for the Fresh Home platform.
///
/// Spring/bounce curves are prohibited. Implementations must wrap native Curve mappings.
class FHMotionCurves {
  /// Standard Ease In Out for internal transformations: CubicBezier(0.20, 0.00, 0.20, 1.00)
  final Curve standard = const Cubic(0.20, 0.00, 0.20, 1.00);

  /// Snap Decelerate for incoming view entries: CubicBezier(0.00, 0.00, 0.20, 1.00)
  final Curve decelerate = const Cubic(0.00, 0.00, 0.20, 1.00);

  /// Accelerate for outgoing dismissals: CubicBezier(0.40, 0.00, 1.00, 1.00)
  final Curve accelerate = const Cubic(0.40, 0.00, 1.00, 1.00);

  /// Linear curve for constant shimmers and loaders
  final Curve linear = Curves.linear;

  const FHMotionCurves();
}
