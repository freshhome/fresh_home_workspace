/// Standardized scale ratios for spatial transitions.
///
/// Scale ranges are strictly capped to ensure a clean, professional feel.
class FHMotionScale {
  /// Starting scale for entering elements (e.g. 0.95)
  final double minEntry = 0.95;

  /// Max emphasis scale for press interactions (e.g. 1.05)
  final double maxEmphasis = 1.05;

  /// Base scale ratio (1.0)
  final double identity = 1.0;

  const FHMotionScale();
}
