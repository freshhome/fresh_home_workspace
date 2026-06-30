import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../tokens/motion_tokens.dart';
import '../utilities/reduced_motion_ext.dart';

/// A high-fidelity native Flutter widget recreating the Fresh Home branding
/// animation (with house, swinging smoke puff, blinking window grid, and sliding letters F-R-H).
///
/// Fully optimized with `RepaintBoundary` and automatically scales to fit layout constraints.
/// Bypasses active animations and transitions instantly under Reduced Motion system preferences.
class FHBrandLogoAnimation extends StatefulWidget {
  /// The size of the animation container (draws as a square).
  final double size;

  /// Optional duration of a single full loop. Defaults to 6 seconds (180 frames at 30fps).
  final Duration duration;

  /// Flag to loop the animation continuously. Defaults to true.
  final bool repeat;

  /// Optional external animation controller to synchronize timing.
  final AnimationController? controller;

  /// Flag to enable animations. If false, behaves as prefersReducedMotion is true.
  final bool enabled;

  const FHBrandLogoAnimation({
    super.key,
    this.size = 200.0,
    this.duration = const Duration(seconds: 6),
    this.repeat = true,
    this.controller,
    this.enabled = true,
  });

  @override
  State<FHBrandLogoAnimation> createState() => _FHBrandLogoAnimationState();
}

class _FHBrandLogoAnimationState extends State<FHBrandLogoAnimation>
    with SingleTickerProviderStateMixin {
  AnimationController? _internalController;
  late AnimationController _activeController;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    if (widget.controller != null) {
      _activeController = widget.controller!;
    } else {
      _internalController = AnimationController(
        vsync: this,
        duration: widget.duration,
      );
      _activeController = _internalController!;
      if (widget.repeat) {
        _activeController.repeat();
      } else {
        _activeController.forward();
      }
    }
  }

  @override
  void didUpdateWidget(FHBrandLogoAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller ||
        widget.duration != oldWidget.duration ||
        widget.repeat != oldWidget.repeat) {
      _disposeInternal();
      _initController();
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
    final bool prefersReduced = context.prefersReducedMotion || !widget.enabled;

    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: prefersReduced
            ? CustomPaint(
                painter: _FHBrandLogoPainter(
                  progress: 1.0,
                  isReducedMotion: true,
                ),
              )
            : AnimatedBuilder(
                animation: _activeController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _FHBrandLogoPainter(
                      progress: _activeController.value,
                      isReducedMotion: false,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _FHBrandLogoPainter extends CustomPainter {
  final double progress;
  final bool isReducedMotion;

  _FHBrandLogoPainter({
    required this.progress,
    required this.isReducedMotion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Calculate fitting scale to map the 500x500 design viewport
    final double scaleX = size.width / 500.0;
    final double scaleY = size.height / 500.0;
    final double fitScale = math.min(scaleX, scaleY);

    canvas.save();
    // Center the content if dimensions are asymmetric
    final double dx = (size.width - 500.0 * fitScale) / 2.0;
    final double dy = (size.height - 500.0 * fitScale) / 2.0;
    canvas.translate(dx, dy);
    canvas.scale(fitScale);

    // 2. Resolve animations based on frame timeline (0 to 180 frames)
    final double currentFrame = isReducedMotion ? 180.0 : progress * 180.0;

    _drawHouse(canvas, currentFrame);
    _drawWindowGrid(canvas, currentFrame);
    _drawSmokePuff(canvas, currentFrame);
    _drawLetterF(canvas, currentFrame);
    _drawLetterR(canvas, currentFrame);
    _drawLetterH(canvas, currentFrame);

    canvas.restore();
  }

  // --- Drawing & Animation Helper Methods ---

  void _drawHouse(Canvas canvas, double frame) {
    // House fades in between frame 0 and 29
    double houseOpacity = 1.0;
    if (frame <= 29.0) {
      houseOpacity = frame / 29.0;
    }

    canvas.save();
    // Layer position, scale and anchor point transformations
    canvas.translate(249.2766, 240.2862);
    canvas.scale(3.733032);
    canvas.translate(-64.5, -53.61205);

    final Paint housePaint = Paint()
      ..color = const Color(0xFF22A5FC).withOpacity(houseOpacity)
      ..style = PaintingStyle.fill;

    // Group 1: Base bar
    final Path baseBar = Path()
      ..moveTo(0.0, 98.9566)
      ..lineTo(128.62, 98.9566)
      ..lineTo(128.62, 107.18)
      ..lineTo(0.0, 107.18)
      ..close();
    canvas.drawPath(baseBar, housePaint);

    // Group 2: Roof structure
    final Path roof = Path()
      ..moveTo(64.5761, 8.69872)
      ..lineTo(11.4853, 41.3383)
      ..lineTo(0.0, 41.3383)
      ..lineTo(0.0, 39.8749)
      ..lineTo(64.084, 0.0)
      ..lineTo(129.0, 40.2924)
      ..lineTo(129.0, 41.3383)
      ..lineTo(117.667, 41.3383)
      ..close();
    canvas.drawPath(roof, housePaint);

    canvas.restore();
  }

  void _drawWindowGrid(Canvas canvas, double frame) {
    if (frame < 82.0) return; // Grid only appears at frame 82

    double windowOpacity = 1.0;
    if (frame >= 82.0 && frame <= 96.0) {
      windowOpacity = 1.0;
    } else if (frame > 96.0 && frame <= 111.0) {
      // Lerp from 1.0 to 0.6
      final double t = (frame - 96.0) / 15.0;
      windowOpacity = 1.0 - t * 0.4;
    } else if (frame > 111.0 && frame <= 126.0) {
      // Lerp from 0.6 to 1.0
      final double t = (frame - 111.0) / 15.0;
      windowOpacity = 0.6 + t * 0.4;
    } else if (frame > 126.0 && frame <= 140.0) {
      // Lerp from 1.0 to 0.6
      final double t = (frame - 126.0) / 14.0;
      windowOpacity = 1.0 - t * 0.4;
    } else {
      windowOpacity = 0.6;
    }

    canvas.save();
    canvas.translate(249.2766, 142.5546);
    canvas.scale(3.733032);
    canvas.translate(-9.03685, -8.8142);

    final Paint windowPaint = Paint()
      ..color = const Color(0xFF22A5FC).withOpacity(windowOpacity)
      ..style = PaintingStyle.fill;

    // 2x2 grid of small window rects
    canvas.drawRect(const Rect.fromLTRB(9.75391, 9.97321, 18.0737, 17.5843), windowPaint);
    canvas.drawRect(const Rect.fromLTRB(0.0, 9.97321, 8.31978, 17.5843), windowPaint);
    canvas.drawRect(const Rect.fromLTRB(9.75391, 0.0, 18.0737, 7.61113), windowPaint);
    canvas.drawRect(const Rect.fromLTRB(0.0, 0.0, 8.31978, 7.61113), windowPaint);

    canvas.restore();
  }

  void _drawSmokePuff(Canvas canvas, double frame) {
    if (frame < 28.0) return; // Hidden before frame 28

    // Resolve opacity: fades in from frame 28 to 46
    double smokeOpacity = 1.0;
    if (frame <= 46.0) {
      smokeOpacity = (frame - 28.0) / 18.0;
    }

    // Resolve rotation angle in degrees
    double rotationDegrees = 0.0;
    if (frame >= 28.0 && frame <= 46.0) {
      rotationDegrees = ((frame - 28.0) / 18.0) * 20.0; // 0 to 20
    } else if (frame > 46.0 && frame <= 60.0) {
      final double t = (frame - 46.0) / 14.0;
      rotationDegrees = 20.0 - t * 40.0; // 20 to -20
    } else if (frame > 60.0 && frame <= 73.0) {
      final double t = (frame - 60.0) / 13.0;
      rotationDegrees = -20.0 + t * 20.0; // -20 to 0
    } else if (frame > 73.0 && frame <= 86.0) {
      final double t = (frame - 73.0) / 13.0;
      rotationDegrees = t * 20.0; // 0 to 20
    } else if (frame > 86.0 && frame <= 100.0) {
      final double t = (frame - 86.0) / 14.0;
      rotationDegrees = 20.0 - t * 40.0; // 20 to -20
    } else if (frame > 100.0 && frame <= 113.0) {
      final double t = (frame - 100.0) / 13.0;
      rotationDegrees = -20.0 + t * 20.0; // -20 to 0
    } else if (frame > 113.0 && frame <= 126.0) {
      final double t = (frame - 113.0) / 13.0;
      rotationDegrees = t * 20.0; // 0 to 20
    } else if (frame > 126.0 && frame <= 140.0) {
      final double t = (frame - 126.0) / 14.0;
      rotationDegrees = 20.0 - t * 40.0; // 20 to -20
    } else if (frame > 140.0 && frame <= 153.0) {
      final double t = (frame - 140.0) / 13.0;
      rotationDegrees = -20.0 + t * 20.0; // -20 to 0
    } else {
      rotationDegrees = 0.0;
    }

    final double rotationRadians = rotationDegrees * math.pi / 180.0;

    canvas.save();
    canvas.translate(381.7176, 62.3102);
    canvas.scale(3.733032);
    canvas.rotate(rotationRadians);
    canvas.translate(-10.87873, -13.01973);

    final Paint smokePaint = Paint()
      ..color = const Color(0xFF22A5FC).withOpacity(smokeOpacity)
      ..style = PaintingStyle.fill;

    // Path 1 (main body of puff)
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

    // Path 2 (interior stroke styling of puff)
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
  }

  void _drawLetterF(Canvas canvas, double frame) {
    if (frame < 44.0) return; // Slides up from frame 44

    double fOpacity = 1.0;
    double fX = 74.999;
    double fY = 303.0142;

    if (frame >= 44.0 && frame <= 70.0) {
      final double progress = (frame - 44.0) / 26.0;
      fOpacity = progress;
      fX = 78.0814 - progress * (78.0814 - 74.999);
      fY = 510.0933 - progress * (510.0933 - 303.0142);
    }

    canvas.save();
    canvas.translate(fX, fY);
    canvas.scale(3.733032);
    canvas.translate(-18.02655, -24.93515);

    final Paint fPaint = Paint()
      ..color = const Color(0xFF0D327D).withOpacity(fOpacity)
      ..style = PaintingStyle.fill;

    final Path fPath = Path()
      ..moveTo(11.105, 49.8262)
      ..lineTo(11.105, 29.506)
      ..lineTo(32.5542, 29.506)
      ..lineTo(32.5542, 20.4594)
      ..lineTo(11.105, 20.4594)
      ..lineTo(11.105, 9.18584)
      ..lineTo(36.0531, 9.18584)
      ..lineTo(36.0531, 0.0)
      ..lineTo(0.0, 0.0)
      ..lineTo(0.0, 49.8262)
      ..close();
    canvas.drawPath(fPath, fPaint);

    canvas.restore();
  }

  void _drawLetterR(Canvas canvas, double frame) {
    if (frame < 57.0) return; // Slides up from frame 57

    double rOpacity = 1.0;
    double rX = 249.2766;
    double rY = 303.0142;

    if (frame >= 57.0 && frame <= 83.0) {
      final double progress = (frame - 57.0) / 26.0;
      rOpacity = progress;
      rX = 249.7275 - progress * (249.7275 - 249.2766);
      rY = 510.0933 - progress * (510.0933 - 303.0142);
    }

    canvas.save();
    canvas.translate(rX, rY);
    canvas.scale(3.733032);
    canvas.translate(-21.03075, -24.93515);

    final Paint rPaint = Paint()
      ..color = const Color(0xFF22A5FC).withOpacity(rOpacity)
      ..style = PaintingStyle.fill;

    final Path rOuterPath = Path()
      ..moveTo(21.9814, 0.0)
      ..cubicTo(
        21.9814 + 21.2972, 0.0,
        29.5117 + 15.6814, 29.5752 - 6.2491,
        29.5117, 29.5752,
      )
      ..lineTo(42.0615, 49.8262)
      ..lineTo(30.1963, 49.8262)
      ..lineTo(18.2549, 31.1758)
      ..lineTo(11.1045, 31.1758)
      ..lineTo(11.1045, 49.8262)
      ..lineTo(0.0, 49.8262)
      ..lineTo(0.0, 0.0)
      ..close();

    final Path rInnerPath = Path()
      ..moveTo(10.9531, 22.1299)
      ..lineTo(19.4717, 22.1299)
      ..cubicTo(
        19.4717 + 6.1604, 22.1299,
        28.4463 - 0.228, 15.5186 + 5.3584,
        28.4463, 15.5186,
      )
      ..cubicTo(
        28.4463 + 0.2279, 15.5186 - 5.3587,
        19.4717 + 4.4337, 8.76855,
        19.4717, 8.76855,
      )
      ..lineTo(10.9531, 8.76855)
      ..close();

    final Path rCombined = Path.combine(PathOperation.difference, rOuterPath, rInnerPath);
    canvas.drawPath(rCombined, rPaint);

    canvas.restore();
  }

  void _drawLetterH(Canvas canvas, double frame) {
    if (frame < 71.0) return; // Slides up from frame 71

    double hOpacity = 1.0;
    double hX = 417.9026;
    double hY = 303.0142;

    if (frame >= 71.0 && frame <= 96.0) {
      final double progress = (frame - 71.0) / 25.0;
      hOpacity = progress;
      hY = 510.0933 - progress * (510.0933 - 303.0142);
    }

    canvas.save();
    canvas.translate(hX, hY);
    canvas.scale(3.733032);
    canvas.translate(-19.92805, -24.93515);

    final Paint hPaint = Paint()
      ..color = const Color(0xFF0D327D).withOpacity(hOpacity)
      ..style = PaintingStyle.fill;

    final Path hPath = Path()
      ..moveTo(10.6486, 49.8262)
      ..lineTo(0.0, 49.8262)
      ..lineTo(0.0, 0.0)
      ..lineTo(10.6486, 0.0)
      ..lineTo(10.6486, 18.7892)
      ..lineTo(28.7512, 18.7892)
      ..lineTo(28.7512, 0.0)
      ..lineTo(39.8561, 0.0)
      ..lineTo(39.8561, 49.8262)
      ..lineTo(28.7512, 49.8262)
      ..lineTo(28.7512, 28.5318)
      ..lineTo(10.6486, 28.5318)
      ..close();
    canvas.drawPath(hPath, hPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FHBrandLogoPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isReducedMotion != isReducedMotion;
  }
}
