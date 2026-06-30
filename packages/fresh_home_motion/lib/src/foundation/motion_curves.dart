import 'package:flutter/animation.dart';
import '../tokens/motion_tokens.dart';

/// Central wrapper for resolving Fresh Home cubic curves.
///
/// Ensures widgets query curves through this layer to support dynamic fallback
/// behaviors when reduced motion settings are enabled in the environment.
class FHCurves {
  const FHCurves._();

  /// Resolves the standard curve for general layout transitions.
  ///
  /// Automatically returns [Curves.linear] if [prefersReducedMotion] is active.
  static Curve standard({required bool prefersReducedMotion}) {
    if (prefersReducedMotion) {
      return FHMotionTokens.curve.linear;
    }
    return FHMotionTokens.curve.standard;
  }

  /// Resolves the decelerate curve for elements entering the screen layout.
  ///
  /// Automatically returns [Curves.linear] if [prefersReducedMotion] is active.
  static Curve decelerate({required bool prefersReducedMotion}) {
    if (prefersReducedMotion) {
      return FHMotionTokens.curve.linear;
    }
    return FHMotionTokens.curve.decelerate;
  }

  /// Resolves the accelerate curve for elements exiting the screen layout.
  ///
  /// Automatically returns [Curves.linear] if [prefersReducedMotion] is active.
  static Curve accelerate({required bool prefersReducedMotion}) {
    if (prefersReducedMotion) {
      return FHMotionTokens.curve.linear;
    }
    return FHMotionTokens.curve.accelerate;
  }

  /// Returns standard linear curve for continuous loading loops.
  static Curve get linear => FHMotionTokens.curve.linear;
}
