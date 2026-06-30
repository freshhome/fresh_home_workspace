/// Depth and shadow tokens that coordinate with physical scale transitions.
class FHMotionElevation {
  /// Base flat elevation (0.0)
  final double flat = 0.0;

  /// Standard active/hovered card elevation (2.0)
  final double card = 2.0;

  /// Floating overlay bottom sheet elevation (8.0)
  final double modalSheet = 8.0;

  /// Critical alert dialog box elevation (16.0)
  final double dialog = 16.0;

  const FHMotionElevation();
}
