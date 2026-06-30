import 'duration_tokens.dart';
import 'curve_tokens.dart';
import 'scale_tokens.dart';
import 'opacity_tokens.dart';
import 'elevation_tokens.dart';

/// Single unified Namespace for all Motion Design Tokens.
///
/// Consumption example:
/// ```dart
/// FHMotionTokens.duration.snappy
/// FHMotionTokens.curve.decelerate
/// ```
class FHMotionTokens {
  const FHMotionTokens._();

  /// Timing duration tokens
  static const FHMotionDurations duration = FHMotionDurations();

  /// Standard curves tokens
  static const FHMotionCurves curve = FHMotionCurves();

  /// Visual scale tokens
  static const FHMotionScale scale = FHMotionScale();

  /// Layer opacity tokens
  static const FHMotionOpacity opacity = FHMotionOpacity();

  /// Depth elevation tokens
  static const FHMotionElevation elevation = FHMotionElevation();
}
