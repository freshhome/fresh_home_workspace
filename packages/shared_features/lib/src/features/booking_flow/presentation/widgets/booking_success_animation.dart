import 'package:flutter/material.dart';
import 'package:fresh_home_motion/fresh_home_motion.dart';

/// A production-quality success dialog widget that executes sequenced
/// animations after a successful booking flow.
///
/// Implements the Fresh Home Motion DNA: snappy velocity, deceleration,
/// zero spring-bounces, and automatic reduced motion fallbacks.
class BookingSuccessAnimation extends StatefulWidget {
  /// The title text of the success state (e.g. "Booking Confirmed!").
  final String title;

  /// The description text of the success state.
  final String subtitle;

  /// The label on the action button.
  final String buttonText;

  /// Callback executed when the primary button is pressed.
  final VoidCallback onClose;

  const BookingSuccessAnimation({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onClose,
  });

  @override
  State<BookingSuccessAnimation> createState() => _BookingSuccessAnimationState();
}

class _BookingSuccessAnimationState extends State<BookingSuccessAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Overlapping animation intervals
  late Animation<double> _backgroundFade;
  late Animation<double> _cardEntry;
  late Animation<double> _circleDraw;
  late Animation<double> _checkDraw;
  late Animation<double> _contentFade;
  late Animation<double> _buttonFade;

  @override
  void initState() {
    super.initState();

    // The entire sequenced dialog animation completes in a cohesive duration of 800ms
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Segment 1: Background overlay fades in (0ms -> 240ms)
    _backgroundFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Cubic(0.0, 0.0, 0.2, 1.0)),
    );

    // Segment 2: Card scales and fades simultaneously (160ms -> 480ms)
    _cardEntry = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.6, curve: Cubic(0.0, 0.0, 0.2, 1.0)),
    );

    // Segment 3: Success circle scale-up (400ms -> 560ms)
    _circleDraw = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.7, curve: Cubic(0.0, 0.0, 0.2, 1.0)),
    );

    // Segment 4: Checkmark drawing (480ms -> 640ms)
    _checkDraw = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 0.8, curve: Curves.linear),
    );

    // Segment 5: Title & Subtitle fade-in (560ms -> 760ms)
    _contentFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 0.95, curve: Cubic(0.0, 0.0, 0.2, 1.0)),
    );

    // Segment 6: Action Button fades in (640ms -> 800ms)
    _buttonFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.8, 1.0, curve: Cubic(0.0, 0.0, 0.2, 1.0)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Utilize standard design tokens for styling parameters
    final overlayColor = const Color(0xFF000000).withValues(alpha: FHMotionTokens.opacity.overlay);
    const successColor = Color(0xFF2E7D32); // Deep professional green

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Background Overlay Fade
          FHFadeIn(
            animation: _backgroundFade,
            beginOpacity: 0.0,
            endOpacity: FHMotionTokens.opacity.solid,
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(
                color: overlayColor,
              ),
            ),
          ),

          // 2. Dialog card entry (Scale + Fade via FHAnimatedCard wrapper)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FHAnimatedCard(
                animation: _cardEntry,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x1F000000),
                        blurRadius: 24.0,
                        offset: Offset(0, FHMotionTokens.elevation.modalSheet),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16.0),

                        // 3. Success Icon Circle Scale
                        FHScaleTransition(
                          animation: _circleDraw,
                          beginScale: FHMotionTokens.scale.minEntry,
                          endScale: FHMotionTokens.scale.identity,
                          child: Container(
                            width: 72.0,
                            height: 72.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: successColor.withValues(alpha: 0.09), // Subtle tint background
                            ),
                            child: Center(
                              // 4. Checkmark drawing inside the circle
                              child: AnimatedBuilder(
                                animation: _checkDraw,
                                builder: (context, child) {
                                  return CustomPaint(
                                    size: const Size(40.0, 40.0),
                                    painter: _FHCheckmarkPainter(
                                      _checkDraw.value,
                                      successColor,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24.0),

                        // 5. Title & Subtitle Fade Entry
                        FHFadeIn(
                          animation: _contentFade,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                widget.subtitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  height: 1.4,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32.0),

                        // 6. Action Button Fade
                        FHFadeIn(
                          animation: _buttonFade,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: widget.onClose,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D47A1), // Professional blue
                                foregroundColor: const Color(0xFFFFFFFF),
                                elevation: FHMotionTokens.elevation.flat,
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: Text(
                                widget.buttonText,
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter to cleanly draw checkmark path segment progression.
class _FHCheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _FHCheckmarkPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Path points normalized for 40x40 viewport
    final start = Offset(size.width * 0.28, size.height * 0.52);
    final pivot = Offset(size.width * 0.46, size.height * 0.70);
    final end = Offset(size.width * 0.74, size.height * 0.36);

    path.moveTo(start.dx, start.dy);

    if (progress < 0.4) {
      final t = progress / 0.4;
      final current = Offset.lerp(start, pivot, t)!;
      path.lineTo(current.dx, current.dy);
    } else {
      path.lineTo(pivot.dx, pivot.dy);
      final t = (progress - 0.4) / 0.6;
      final current = Offset.lerp(pivot, end, t)!;
      path.lineTo(current.dx, current.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_FHCheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
