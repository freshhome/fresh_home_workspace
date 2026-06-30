import 'package:flutter/foundation.dart';
import 'platform_capability.dart';

/// Centralized configuration class for the Fresh Home Motion Design System.
///
/// This config controls platform-wide policies, animation overrides, and capability testing parameters.
/// It contains no business logic or mutable global state.
@immutable
class FHMotionConfig {
  /// Force-disables skeleton shimmers globally (useful for testing or debugging).
  final bool disableShimmers;

  /// Force-disables all animations, falling back instantly to linear transitions (accessibility simulation).
  final bool forceReducedMotion;

  /// Custom provider to query device/hardware performance profile.
  final PlatformCapability platformCapability;

  const FHMotionConfig({
    this.disableShimmers = false,
    this.forceReducedMotion = false,
    this.platformCapability = const DefaultPlatformCapability(),
  });

  /// Standard production runtime configuration.
  static const FHMotionConfig defaultConfiguration = FHMotionConfig();

  /// Create a copied instance of the configuration with modified values.
  FHMotionConfig copyWith({
    bool? disableShimmers,
    bool? forceReducedMotion,
    PlatformCapability? platformCapability,
  }) {
    return FHMotionConfig(
      disableShimmers: disableShimmers ?? this.disableShimmers,
      forceReducedMotion: forceReducedMotion ?? this.forceReducedMotion,
      platformCapability: platformCapability ?? this.platformCapability,
    );
  }
}
