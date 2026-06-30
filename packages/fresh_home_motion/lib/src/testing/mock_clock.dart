/// Utility helper for mocking system tickers and animations in unit test runners.
class FHMockClock {
  const FHMockClock._();

  /// Mock time elapsed multiplier (e.g. timeDilation parameters).
  static double get timeDilation => 1.0;

  /// Artificially dilates animation time scale.
  static void dilate(double ratio) {
    // SKELETON: Mock action
  }
}
