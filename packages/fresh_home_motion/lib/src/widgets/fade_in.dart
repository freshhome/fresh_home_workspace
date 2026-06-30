import 'package:flutter/widgets.dart';
import '../tokens/motion_tokens.dart';
import '../utilities/reduced_motion_ext.dart';

/// A performance-optimized primitive widget for fade-in opacity transitions.
///
/// Complies with the Fresh Home Motion Design System by utilizing tokens for default
/// timing/curves and automatically responding to reduced motion system settings.
class FHFadeIn extends StatefulWidget {
  /// The element to animate.
  final Widget child;

  /// Optional duration token. Defaults to [FHMotionTokens.duration.standard].
  final Duration? duration;

  /// Optional curve token. Defaults to [FHMotionTokens.curve.decelerate].
  final Curve? curve;

  /// Optional delay before starting the animation.
  final Duration? delay;

  /// Starting opacity value. Defaults to transparent opacity token.
  final double beginOpacity;

  /// Ending opacity value. Defaults to solid opacity token.
  final double endOpacity;

  /// Flag to enable or disable the fade transition.
  final bool enabled;

  /// Optional external animation source to share controllers and synchronize layers.
  final Animation<double>? animation;

  const FHFadeIn({
    Key? key,
    required this.child,
    this.duration,
    this.curve,
    this.delay,
    this.beginOpacity = 0.0,
    this.endOpacity = 1.0,
    this.enabled = true,
    this.animation,
  }) : super(key: key);

  @override
  State<FHFadeIn> createState() => _FHFadeInState();
}

class _FHFadeInState extends State<FHFadeIn> with SingleTickerProviderStateMixin {
  AnimationController? _internalController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  void _initAnimation() {
    if (widget.animation != null) {
      _fadeAnimation = widget.animation!;
      return;
    }

    if (!widget.enabled) {
      _fadeAnimation = AlwaysStoppedAnimation<double>(widget.endOpacity);
      return;
    }

    final effectiveDuration = widget.duration ?? FHMotionTokens.duration.standard;
    _internalController = AnimationController(
      vsync: this,
      duration: effectiveDuration,
    );

    final effectiveCurve = widget.curve ?? FHMotionTokens.curve.decelerate;

    _fadeAnimation = Tween<double>(
      begin: widget.beginOpacity,
      end: widget.endOpacity,
    ).animate(
      CurvedAnimation(
        parent: _internalController!,
        curve: effectiveCurve,
      ),
    );

    if (widget.delay != null && widget.delay! > Duration.zero) {
      Future.delayed(widget.delay!, () {
        if (mounted && _internalController != null) {
          _internalController!.forward();
        }
      });
    } else {
      _internalController!.forward();
    }
  }

  @override
  void didUpdateWidget(FHFadeIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation ||
        widget.enabled != oldWidget.enabled ||
        widget.beginOpacity != oldWidget.beginOpacity ||
        widget.endOpacity != oldWidget.endOpacity ||
        widget.duration != oldWidget.duration ||
        widget.curve != oldWidget.curve) {
      _disposeInternal();
      _initAnimation();
    }
  }

  void _disposeInternal() {
    _internalController?.dispose();
    _internalController = null;
  }

  @override
  void dispose() {
    _disposeInternal();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    final prefersReduced = context.prefersReducedMotion;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      child: widget.child,
      builder: (context, child) {
        // If reduced motion is preferred, bypass animated transitions and snap to final state opacity.
        final opacityValue = prefersReduced ? widget.endOpacity : _fadeAnimation.value;
        return Opacity(
          opacity: opacityValue.clamp(0.0, 1.0),
          child: child,
        );
      },
    );
  }
}
