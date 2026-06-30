import 'package:flutter/widgets.dart';
import '../tokens/motion_tokens.dart';
import 'fade_in.dart';
import 'scale_transition.dart';

/// A motion wrapper for cards and panels combining snappy fade and scale entries.
///
/// Uses a single animation controller to optimize GPU paints and synchronize values.
/// This component contains no project-specific visual properties (like shapes, borders, or colors).
class FHAnimatedCard extends StatefulWidget {
  /// The widget content inside the card layout.
  final Widget child;

  /// Optional duration token. Defaults to [FHMotionTokens.duration.snappy].
  final Duration? duration;

  /// Optional curve token. Defaults to [FHMotionTokens.curve.decelerate].
  final Curve? curve;

  /// Padding wrapper for inner layout structure. Defaults to [EdgeInsets.zero].
  final EdgeInsetsGeometry padding;

  /// Flag to enable or disable the visual entrance transition.
  final bool enabled;

  /// Optional external animation source to share controllers and synchronize layers.
  final Animation<double>? animation;

  const FHAnimatedCard({
    super.key,
    required this.child,
    this.duration,
    this.curve,
    this.padding = EdgeInsets.zero,
    this.enabled = true,
    this.animation,
  });

  @override
  State<FHAnimatedCard> createState() => _FHAnimatedCardState();
}

class _FHAnimatedCardState extends State<FHAnimatedCard> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  void _initAnimation() {
    if (widget.animation != null) {
      _animation = widget.animation!;
      return;
    }

    if (!widget.enabled) {
      _animation = const AlwaysStoppedAnimation<double>(1.0);
      return;
    }

    final effectiveDuration = widget.duration ?? FHMotionTokens.duration.snappy;
    _controller = AnimationController(
      vsync: this,
      duration: effectiveDuration,
    );

    final effectiveCurve = widget.curve ?? FHMotionTokens.curve.decelerate;
    _animation = CurvedAnimation(
      parent: _controller!,
      curve: effectiveCurve,
    );

    _controller!.forward();
  }

  @override
  void didUpdateWidget(FHAnimatedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation ||
        widget.enabled != oldWidget.enabled ||
        widget.duration != oldWidget.duration ||
        widget.curve != oldWidget.curve) {
      _disposeInternal();
      _initAnimation();
    }
  }

  void _disposeInternal() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeInternal();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget paddedChild = widget.padding != EdgeInsets.zero
        ? Padding(padding: widget.padding, child: widget.child)
        : widget.child;

    if (!widget.enabled) {
      return paddedChild;
    }

    // Synchronize both entry transitions using the same animation source.
    return FHFadeIn(
      animation: _animation,
      enabled: widget.enabled,
      child: FHScaleTransition(
        animation: _animation,
        enabled: widget.enabled,
        beginScale: FHMotionTokens.scale.minEntry,
        endScale: FHMotionTokens.scale.identity,
        child: paddedChild,
      ),
    );
  }
}
