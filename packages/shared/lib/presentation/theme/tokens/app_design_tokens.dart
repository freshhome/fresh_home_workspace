import 'package:flutter/material.dart';

/// Enterprise Design Tokens for Fresh Home V2.
///
/// Extracted from empirical codebase usage to standardise Spacing, Radius,
/// Elevation, Durations, Breakpoints, Icon Sizes, and Opacity.
abstract class AppDesignTokens {
  /// Spacing Scale Tokens (4pt/8pt Grid System)
  static const spacing = _AppSpacing();

  /// Border Radius Tokens
  static const radius = _AppRadius();

  /// Elevation Tokens
  static const elevation = _AppElevation();

  /// Animation & Transition Duration Tokens
  static const durations = _AppDurations();

  /// Screen Breakpoints Tokens
  static const breakpoints = _AppBreakpoints();

  /// Standardized Icon Size Tokens
  static const iconSizes = _AppIconSizes();

  /// Opacity Tokens
  static const opacity = _AppOpacity();
}

class _AppSpacing {
  const _AppSpacing();

  /// Extra small spacing (4.0)
  final double xs = 4.0;

  /// Small spacing (8.0)
  final double sm = 8.0;

  /// Medium spacing (16.0)
  final double md = 16.0;

  /// Large spacing (24.0)
  final double lg = 24.0;

  /// Extra large spacing (32.0)
  final double xl = 32.0;

  /// Double extra large spacing (48.0)
  final double xxl = 48.0;

  /// EdgeInsets helper for symmetrical horizontal medium padding (16.0)
  EdgeInsets get horizontalMd => const EdgeInsets.symmetric(horizontal: 16.0);

  /// EdgeInsets helper for symmetrical horizontal large padding (24.0)
  EdgeInsets get horizontalLg => const EdgeInsets.symmetric(horizontal: 24.0);

  /// EdgeInsets helper for default screen padding (20.0, 16.0, 20.0, 24.0)
  EdgeInsets get screenPadding => const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0);
}

class _AppRadius {
  const _AppRadius();

  /// Extra small radius (4.0)
  final double xs = 4.0;

  /// Small radius (8.0)
  final double sm = 8.0;

  /// Medium radius (12.0)
  final double md = 12.0;

  /// Large radius (16.0)
  final double lg = 16.0;

  /// Extra large radius (24.0)
  final double xl = 24.0;

  /// Circular radius (999.0)
  final double circular = 999.0;

  /// BorderRadius helper for medium radius (12.0)
  BorderRadius get borderRadiusMd => BorderRadius.circular(12.0);

  /// BorderRadius helper for large radius (16.0)
  BorderRadius get borderRadiusLg => BorderRadius.circular(16.0);

  /// BorderRadius helper for extra large radius (24.0)
  BorderRadius get borderRadiusXl => BorderRadius.circular(24.0);
}

class _AppElevation {
  const _AppElevation();

  /// Flat elevation (0.0)
  final double flat = 0.0;

  /// Low elevation (2.0)
  final double low = 2.0;

  /// Medium elevation (4.0)
  final double medium = 4.0;

  /// High elevation (8.0)
  final double high = 8.0;

  /// Standard soft shadow list for cards
  List<BoxShadow> softShadow(Color baseColor) => [
        BoxShadow(
          color: baseColor.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
}

class _AppDurations {
  const _AppDurations();

  /// Fast animation duration (150ms)
  final Duration fast = const Duration(milliseconds: 150);

  /// Normal animation duration (300ms)
  final Duration normal = const Duration(milliseconds: 300);

  /// Slow animation duration (500ms)
  final Duration slow = const Duration(milliseconds: 500);
}

class _AppBreakpoints {
  const _AppBreakpoints();

  /// Mobile breakpoint upper bound (<600dp)
  final double mobile = 600.0;

  /// Tablet breakpoint upper bound (600dp - 1024dp)
  final double tablet = 1024.0;

  /// Desktop breakpoint (>1024dp)
  final double desktop = 1440.0;
}

class _AppIconSizes {
  const _AppIconSizes();

  /// Small icon size (16.0)
  final double sm = 16.0;

  /// Medium icon size (20.0)
  final double md = 20.0;

  /// Large icon size (24.0)
  final double lg = 24.0;

  /// Extra large icon size (32.0)
  final double xl = 32.0;
}

class _AppOpacity {
  const _AppOpacity();

  /// Disabled element opacity (0.6)
  final double disabled = 0.6;

  /// Subtle background tint opacity (0.12)
  final double subtle = 0.12;

  /// Faint background tint opacity (0.04)
  final double faint = 0.04;
}
