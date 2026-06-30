import 'package:flutter/foundation.dart';

/// Abstraction class responsible for detecting device graphics capability and target framerates.
abstract class PlatformCapability {
  const PlatformCapability();

  /// Returns true if the device hardware is low-end (e.g. legacy web canvas, poor processor).
  bool isLowEndDevice();

  /// Returns target frames per second (FPS) for calculations.
  double getTargetFrameRate();
}

/// Production implementation of platform capability checks.
class DefaultPlatformCapability extends PlatformCapability {
  const DefaultPlatformCapability();

  @override
  bool isLowEndDevice() {
    // Web runs on CanvasKit or HTML rendering, defaults to conserving resources by default.
    if (kIsWeb) {
      return true;
    }
    // Baseline fallback for mobile device profiles.
    return false;
  }

  @override
  double getTargetFrameRate() {
    // Web is target-bound to standard 60 FPS.
    if (kIsWeb) {
      return 60.0;
    }
    return 60.0; // Standard baseline
  }
}
