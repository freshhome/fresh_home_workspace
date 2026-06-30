import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../utilities/reduced_motion_ext.dart';

/// A professional, high-fidelity loading indicator built for the Fresh Home Design System.
///
/// Implements a smooth, hardware-accelerated brand-inspired loader.
/// Automatically handles accessibility settings: drops rotation and wiggling
/// and switches to a calm, breathing opacity pulsing effect under reduced motion.
class FHLoadingIndicator extends StatefulWidget {
  /// Sizing bounds of the indicator. Defaults to 36.0.
  final double size;

  /// Stroke width of the loader outline. Defaults to 3.5.
  final double strokeWidth;

  /// The primary color of the spinner. Defaults to Fresh Home blue (0xFF0D47A1).
  final Color? color;

  const FHLoadingIndicator({
    super.key,
    this.size = 36.0,
    this.strokeWidth = 3.5,
    this.color,
  });

  @override
  State<FHLoadingIndicator> createState() => _FHLoadingIndicatorState();
}

class _FHLoadingIndicatorState extends State<FHLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Looping 1.8 second cycle for the sweep and wiggle animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? const Color(0xFF0D47A1);
    final prefersReduced = context.prefersReducedMotion;

    if (prefersReduced) {
      // Accessibility fallback: A calm fading breathing loop instead of animations
      return _FHBreathingLoadingIndicator(
        size: widget.size,
        strokeWidth: widget.strokeWidth,
        color: effectiveColor,
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _FHBrandLoaderPainter(
                color: effectiveColor,
                strokeWidth: widget.strokeWidth,
                progress: _controller.value,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter to draw the brand-inspired loading house with sweeping light
class _FHBrandLoaderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double progress;

  _FHBrandLoaderPainter({
    required this.color,
    required this.strokeWidth,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Compute scale factor to fit target 129x107.18 house coordinates into widget size
    final double scaleX = size.width / 129.0;
    final double scaleY = size.height / 107.18;
    final double fitScale = math.min(scaleX, scaleY);

    canvas.save();
    // Center alignment
    final double dx = (size.width - 129.0 * fitScale) / 2.0;
    final double dy = (size.height - 107.18 * fitScale) / 2.0;
    canvas.translate(dx, dy);
    canvas.scale(fitScale);

    // Make stroke width scale independent on screen
    final double localStrokeWidth = strokeWidth / fitScale;

    // 2. Animate values based on progress parameter (0.0 to 1.0)
    final double rotationAngle = progress * 2.0 * math.pi;

    // Window breathing opacity: ranges between 0.3 and 1.0
    final double windowOpacity = 0.3 + (math.sin(progress * 2.0 * math.pi).abs() * 0.7);

    // Smoke swing rotation: sways back and forth between -15 and +15 degrees
    final double smokeRotation = math.sin(progress * 2.0 * math.pi) * 15.0 * math.pi / 180.0;

    // 3. Draw background track (10% opacity)
    final Paint trackPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = localStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path housePath = Path()
      ..moveTo(0.0, 103.0)
      ..lineTo(129.0, 103.0)
      ..moveTo(0.0, 40.0)
      ..lineTo(64.5, 0.0)
      ..lineTo(129.0, 40.0);

    canvas.drawPath(housePath, trackPaint);

    // 4. Draw sweeping active light (using rotating SweepGradient)
    final Paint sweepPaint = Paint()
      ..strokeWidth = localStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Gradient gradient = SweepGradient(
      colors: [
        color.withOpacity(0.0),
        color.withOpacity(0.3),
        color,
        color.withOpacity(0.3),
        color.withOpacity(0.0),
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      transform: GradientRotation(rotationAngle),
    );

    sweepPaint.shader = gradient.createShader(
      const Rect.fromLTWH(0, 0, 129, 107.18),
    );

    canvas.drawPath(housePath, sweepPaint);

    // 5. Draw window grid (opacity pulses)
    final Paint windowPaint = Paint()
      ..color = color.withOpacity(windowOpacity)
      ..style = PaintingStyle.fill;

    // 2x2 grid of small window rects centered around (64.5, 68.0)
    canvas.drawRect(const Rect.fromLTRB(55.5, 59.0, 63.5, 67.0), windowPaint);
    canvas.drawRect(const Rect.fromLTRB(65.5, 59.0, 73.5, 67.0), windowPaint);
    canvas.drawRect(const Rect.fromLTRB(55.5, 69.0, 63.5, 77.0), windowPaint);
    canvas.drawRect(const Rect.fromLTRB(65.5, 69.0, 73.5, 77.0), windowPaint);

    // 6. Draw chimney smoke puff (swings w/ rotation)
    canvas.save();
    canvas.translate(99.978, 5.935);
    canvas.rotate(smokeRotation);
    canvas.translate(-10.87873, -13.01973);

    final Paint smokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Path 1
    final Path smokePath1 = Path()
      ..moveTo(17.7649, 3.17875)
      ..cubicTo(
        17.7649 - 0.1595, 3.17875 - 0.24572,
        17.0156 + 0.2683, 3.02475 - 0.15799,
        17.0156, 3.02475,
      )
      ..cubicTo(
        17.0156 - 1.6243, 3.02475 + 0.99972,
        11.4374, 5.29356,
        11.4374, 5.29356,
      )
      ..cubicTo(
        11.4374 - 14.04793, 5.29356 + 3.56834,
        2.99505 - 0.00688, 23.0148 - 0.0173,
        2.99505, 23.0148,
      )
      ..cubicTo(
        2.99505 + 6.81091, 23.0148 + 0.4882,
        18.9841 - 2.7471, 15.2039 + 6.8444,
        18.9841, 15.2039,
      )
      ..cubicTo(
        18.9841 + 2.1381, 15.2039 - 5.42324,
        17.7649 + 0.9303, 3.17875 + 1.57636,
        17.7649, 3.17875,
      )
      ..close();

    // Path 2
    final Path smokePath2 = Path()
      ..moveTo(13.8646, 11.7136)
      ..cubicTo(
        13.8646 - 0.0281, 11.7136 + 0.0336,
        3.11005 - 0.01683, 22.9357 - 0.5744,
        3.11005, 22.9357,
      )
      ..cubicTo(
        3.11005 - 0.01683, 22.9357 - 0.5744,
        13.8646, 11.7136,
        13.8646, 11.7136,
      )
      ..close();

    canvas.drawPath(smokePath1, smokePaint);
    canvas.drawPath(smokePath2, smokePaint);

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FHBrandLoaderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.progress != progress;
  }
}

/// Accessibility breathing indicator fallback for reduced motion preference
class _FHBreathingLoadingIndicator extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color color;

  const _FHBreathingLoadingIndicator({
    required this.size,
    required this.strokeWidth,
    required this.color,
  });

  @override
  State<_FHBreathingLoadingIndicator> createState() =>
      _FHBreathingLoadingIndicatorState();
}

class _FHBreathingLoadingIndicatorState extends State<_FHBreathingLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    // Calmer 2-second breathing pulse cycle
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _opacityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _FHStaticTrackPainter(
                color: widget.color,
                strokeWidth: widget.strokeWidth,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Painter to draw a clean static brand logo house layout for breathing animation
class _FHStaticTrackPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _FHStaticTrackPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / 129.0;
    final double scaleY = size.height / 107.18;
    final double fitScale = math.min(scaleX, scaleY);

    canvas.save();
    final double dx = (size.width - 129.0 * fitScale) / 2.0;
    final double dy = (size.height - 107.18 * fitScale) / 2.0;
    canvas.translate(dx, dy);
    canvas.scale(fitScale);

    final double localStrokeWidth = strokeWidth / fitScale;

    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = localStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path housePath = Path()
      ..moveTo(0.0, 103.0)
      ..lineTo(129.0, 103.0)
      ..moveTo(0.0, 40.0)
      ..lineTo(64.5, 0.0)
      ..lineTo(129.0, 40.0);

    canvas.drawPath(housePath, paint);

    final Paint fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Window grid
    canvas.drawRect(const Rect.fromLTRB(55.5, 59.0, 63.5, 67.0), fillPaint);
    canvas.drawRect(const Rect.fromLTRB(65.5, 59.0, 73.5, 67.0), fillPaint);
    canvas.drawRect(const Rect.fromLTRB(55.5, 69.0, 63.5, 77.0), fillPaint);
    canvas.drawRect(const Rect.fromLTRB(65.5, 69.0, 73.5, 77.0), fillPaint);

    // Smoke puff
    canvas.save();
    canvas.translate(99.978, 5.935);
    canvas.translate(-10.87873, -13.01973);

    final Path smokePath1 = Path()
      ..moveTo(17.7649, 3.17875)
      ..cubicTo(
        17.7649 - 0.1595, 3.17875 - 0.24572,
        17.0156 + 0.2683, 3.02475 - 0.15799,
        17.0156, 3.02475,
      )
      ..cubicTo(
        17.0156 - 1.6243, 3.02475 + 0.99972,
        11.4374, 5.29356,
        11.4374, 5.29356,
      )
      ..cubicTo(
        11.4374 - 14.04793, 5.29356 + 3.56834,
        2.99505 - 0.00688, 23.0148 - 0.0173,
        2.99505, 23.0148,
      )
      ..cubicTo(
        2.99505 + 6.81091, 23.0148 + 0.4882,
        18.9841 - 2.7471, 15.2039 + 6.8444,
        18.9841, 15.2039,
      )
      ..cubicTo(
        18.9841 + 2.1381, 15.2039 - 5.42324,
        17.7649 + 0.9303, 3.17875 + 1.57636,
        17.7649, 3.17875,
      )
      ..close();

    canvas.drawPath(smokePath1, fillPaint);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FHStaticTrackPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
