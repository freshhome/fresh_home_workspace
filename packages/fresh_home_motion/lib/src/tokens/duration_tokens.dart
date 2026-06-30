/// Holds standardized time durations for all animations in the Fresh Home platform.
///
/// Inline millisecond values are prohibited in UI screens.
class FHMotionDurations {
  /// 0ms transition - instant state toggle
  final Duration instant = const Duration(milliseconds: 0);

  /// 100ms timing - button scale press, toggles, checkboxes
  final Duration micro = const Duration(milliseconds: 100);

  /// 200ms timing - tooltips, card expansions, small content entries
  final Duration snappy = const Duration(milliseconds: 200);

  /// 250ms timing - bottom sheet slides, standard page route transitions
  final Duration standard = const Duration(milliseconds: 250);

  /// 300ms timing - complex layout shifts, multi-step booking wizard animations
  final Duration complex = const Duration(milliseconds: 300);

  const FHMotionDurations();
}
