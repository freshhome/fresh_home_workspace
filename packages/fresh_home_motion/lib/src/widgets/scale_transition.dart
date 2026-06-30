import 'package:flutter/widgets.dart';
import '../tokens/motion_tokens.dart';
import '../utilities/reduced_motion_ext.dart';

/// A widget that implements the official Fresh Home snappy scale transition.
///
/// Enforces the Direct Deceleration visual policy (zero cartoony bounce/spring).
/// Responds automatically to accessibility settings to prevent vestibular discomfort.
class FHScaleTransition extends StatefulWidget {
  /// The element to scale.
  final Widget child;

  /// Starting scale ratio. Defaults to [FHMotionTokens.scale.minEntry] (0.95).
  final double beginScale;

  /// Ending scale ratio. Defaults to [FHMotionTokens.scale.identity] (1.0).
  final double endScale;

  /// Optional duration token. Defaults to [FHMotionTokens.duration.snappy].
  final Duration? duration;

  /// Optional curve token. Defaults to [FHMotionTokens.curve.decelerate].
  final Curve? curve;

  /// The alignment of the scale pivot. Defaults to [Alignment.center].
  final Alignment alignment;

  /// Flag to enable or disable the transition.
  final bool enabled;

  /// Optional external animation source to share controllers and synchronize layers.
  final Animation<double>? animation;

  const FHScaleTransition({
    Key? key,
    required this.child,
    this.beginScale = 0.95,
    this.endScale = 1.0,
    this.duration,
    this.curve,
    this.alignment = Alignment.center,
    this.enabled = true,
    this.animation,
  }) : super(key: key);

  @override
  State<FHScaleTransition> createState() => _FHScaleTransitionState();
}

class _FHScaleTransitionState extends State<FHScaleTransition> with SingleTickerProviderStateMixin {
  AnimationController? _internalController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  void _initAnimation() {
    if (widget.animation != null) {
      _scaleAnimation = widget.animation!;
      return;
    }

    if (!widget.enabled) {
      _scaleAnimation = AlwaysStoppedAnimation<double>(widget.endScale);
      return;
    }

    final effectiveDuration = widget.duration ?? FHMotionTokens.duration.snappy;
    _internalController = AnimationController(
      vsync: this,
      duration: effectiveDuration,
    );

    final effectiveCurve = widget.curve ?? FHMotionTokens.curve.decelerate;

    _scaleAnimation = Tween<double>(
      begin: widget.beginScale,
      end: widget.endScale,
    ).animate(
      CurvedAnimation(
        parent: _internalController!,
        curve: effectiveCurve,
      ),
    );

    _internalController!.forward();
  }

  @override
  void didUpdateWidget(FHScaleTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation ||
        widget.enabled != oldWidget.enabled ||
        widget.beginScale != oldWidget.beginScale ||
        widget.endScale != oldWidget.endScale ||
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
      animation: _scaleAnimation,
      child: widget.child,
      builder: (context, child) {
        // If reduced motion is active, scaling is bypassed completely to avoid vestibular issues.
        final scaleValue = prefersReduced ? widget.endScale : _scaleAnimation.value;
        return Transform.scale(
          scale: scaleValue,
          alignment: widget.alignment,
          child: child,
        );
      },
    );
  }
}
