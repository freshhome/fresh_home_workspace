import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // For timeDilation
import 'package:flutter/scheduler.dart' as schedulerBinding;
import 'package:fresh_home_motion/fresh_home_motion.dart';
import 'package:shared_features/shared_features.dart'; // For BookingSuccessAnimation

/// Interactive Playground page for reviewing, editing, and previewing
/// motion design system animations in the Admin Dashboard.
class MotionReviewPage extends StatefulWidget {
  const MotionReviewPage({Key? key}) : super(key: key);

  @override
  State<MotionReviewPage> createState() => _MotionReviewPageState();
}

class _MotionReviewPageState extends State<MotionReviewPage> {
  // Playground state parameters
  double _speedMultiplier = 1.0;
  bool _simulatedReducedMotion = false;

  // Visual triggers for preview cards
  bool _fadeInTrigger = true;
  bool _scaleTrigger = true;
  bool _cardTrigger = true;

  @override
  void dispose() {
    // Reset global timeDilation on exit to avoid affecting other screens
    schedulerBinding.timeDilation = 1.0;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Update global Flutter time dilation
    schedulerBinding.timeDilation = _speedMultiplier;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'لوحة مراجعة حركات النظام',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📋 Control Panel Section
              _buildControlPanel(),
              const SizedBox(height: 24.0),

              // 🏷️ Grid of Animation Primitives
              const Text(
                'اللبنات الحركية الأساسية (Motion Primitives)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16.0),
              _buildPrimitivesGrid(),
              const SizedBox(height: 24.0),

              // 🎯 Staggered Complete Dialog Animations
              const Text(
                'رسوم التدفق المتكاملة (Sequenced Flow Animations)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16.0),
              _buildFlowAnimationsSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the top dashboard control panel for time dilation and accessibility simulation
  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'لوحة التحكم والتعديل التفاعلية',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Time dilation slider (Slow motion)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سرعة الحركة (Slow Motion): ${_speedMultiplier.toStringAsFixed(1)}x',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    Slider(
                      value: _speedMultiplier,
                      min: 1.0,
                      max: 5.0,
                      divisions: 4,
                      activeColor: const Color(0xFF0D47A1),
                      onChanged: (val) {
                        setState(() {
                          _speedMultiplier = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // 2. Simulated Reduced motion checkbox/switch
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'تقليل الحركة (A11y)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  Switch(
                    value: _simulatedReducedMotion,
                    activeColor: Colors.pink.shade700,
                    onChanged: (val) {
                      setState(() {
                        _simulatedReducedMotion = val;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          if (_simulatedReducedMotion)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.accessibility_new_rounded,
                    color: Colors.pink.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تم تفعيل محاكاة إمكانية الوصول: سيتم تجاوز التكبير/التصغير وحركات النقل واستبدالها بتلاشٍ أو ظهور فوري.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.pink.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Builds a responsive grid of visual cards exhibiting primitive animation widgets
  Widget _buildPrimitivesGrid() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int columnCount = screenWidth < 800 ? 1 : 3;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: columnCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        // 1. FHFadeIn Card
        _buildDemoCard(
          title: 'تلاشي الظهور (FHFadeIn)',
          description: 'يتحكم في الشفافية بنسب ثابتة وتوقيع decelerate.',
          trigger: _fadeInTrigger,
          onToggle: () {
            setState(() {
              _fadeInTrigger = !_fadeInTrigger;
            });
          },
          animatedWidget: FHFadeIn(
            enabled: !_simulatedReducedMotion,
            animation: _fadeInTrigger
                ? null
                : const AlwaysStoppedAnimation<double>(0.0),
            child: Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.indigo.shade500,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Fading Content',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),

        // 2. FHScaleTransition Card
        _buildDemoCard(
          title: 'التكبير والتصغير (FHScaleTransition)',
          description: 'تباطؤ مباشر (Direct Deceleration) دون ارتداد.',
          trigger: _scaleTrigger,
          onToggle: () {
            setState(() {
              _scaleTrigger = !_scaleTrigger;
            });
          },
          animatedWidget: FHScaleTransition(
            enabled: !_simulatedReducedMotion,
            beginScale: 0.2,
            endScale: 1.0,
            animation: _scaleTrigger
                ? null
                : const AlwaysStoppedAnimation<double>(0.2),
            child: Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Decelerated Scale',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),

        // 3. FHAnimatedCard Card
        _buildDemoCard(
          title: 'البطاقة المشتركة (FHAnimatedCard)',
          description: 'دمج الشفافية والحجم بمتحكم واحد لتخفيف أثر المعالج.',
          trigger: _cardTrigger,
          onToggle: () {
            setState(() {
              _cardTrigger = !_cardTrigger;
            });
          },
          animatedWidget: FHAnimatedCard(
            enabled: _cardTrigger && !_simulatedReducedMotion,
            child: Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.purple.shade600,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Combined Entrance',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Helper to build a demonstration card for a primitive widget animation
  Widget _buildDemoCard({
    required String title,
    required String description,
    required bool trigger,
    required VoidCallback onToggle,
    required Widget animatedWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xE0E2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              height: 1.3,
            ),
          ),
          const Spacer(),
          Center(child: SizedBox(height: 90, child: animatedWidget)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onToggle,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0D47A1),
                side: const BorderSide(color: Color(0xFF0D47A1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                trigger ? 'إخفاء المعاينة / تصغير' : 'تشغيل الحركة / تكبير',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the section for staggered animation flow preview (Booking Success Dialog)
  Widget _buildFlowAnimationsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xE0E2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.task_alt_rounded, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text(
                'حركة نجاح الحجز (Booking Success Animation)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'حركة تسلسلية كاملة خالية من الارتداد (Direct Deceleration)، تشتمل على تلاشي الخلفية وتضخم الكارت وتدرج ظهور الدائرة ورسم علامة الصح بـ CustomPainter مع تلاشي الأزرار بالتتابع.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _launchBookingSuccessDialog(context),
              icon: const Icon(
                Icons.play_circle_outline_rounded,
                color: Colors.white,
              ),
              label: const Text(
                'عرض حوار نجاح الحجز وتجربته',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Launches the fullscreen/dialog overlay success animation spike in a test dialog
  void _launchBookingSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors
          .transparent, // Implemented internally by the widget stack background
      builder: (BuildContext dialogContext) {
        // Set the static simulated reduced motion preference in the context using configuration wrapper
        return BookingSuccessAnimation(
          title: 'تم تأكيد الحجز بنجاح!',
          subtitle:
              'تمت جدولة موعد الخدمة المنزلية. سيتم إسناد الفني المسؤول وإشعارك قريباً.',
          buttonText: 'العودة للوحة المعاينة',
          onClose: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }
}
