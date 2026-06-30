/// Standardized opacity thresholds for animations and overlays.
class FHMotionOpacity {
  /// Completely transparent (0.0)
  final double transparent = 0.0;

  /// Disabled state element transparency (0.38)
  final double disabled = 0.38;

  /// Secondary element visual weighting (0.60)
  final double secondary = 0.60;

  /// Completely visible (1.0)
  final double solid = 1.0;

  /// Modal overlay background transparency (0.40)
  final double overlay = 0.40;

  /// Hover/pressed card background tint transparency (0.05)
  final double background = 0.05;

  /// Shimmer placeholder layout transparency (0.08)
  final double loading = 0.08;

  const FHMotionOpacity();
}
