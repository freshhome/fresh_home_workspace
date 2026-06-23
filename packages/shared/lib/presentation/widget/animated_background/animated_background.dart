

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared/core/constants/app_assets.dart';
// import 'package:lottie/lottie.dart';

const iconSize = 56.0;
const rowCount = 5;

/// ✅ اللستة الهارد كود - غير فيها زي ما تحب بعدين
final List<Widget> widgetOptions = [
  // Icon(Icons.cleaning_services, size: 40, color: Colors.teal),
  // Lottie.asset('assets/animations/Main Scene (1).json', height: 100, width: 100),
  SvgPicture.asset(
    AppAssets.iconCleaningGlassSpray,
    width: iconSize,
    height: iconSize,
    colorFilter: ColorFilter.mode(Color(0xFFB3E5FC), BlendMode.srcIn),
  ),
  SvgPicture.asset(
    AppAssets.iconCleaningVacuumMachine,
    width: iconSize,
    height: iconSize,
    colorFilter: ColorFilter.mode(Color(0xFFB3E5FC), BlendMode.srcIn),
  ),
  SvgPicture.asset(
    AppAssets.iconFreshHomeCompanyLogo,
    width: iconSize,
    height: iconSize,
    colorFilter: ColorFilter.mode(Color(0xFFB3E5FC), BlendMode.srcIn),
  ),
  SvgPicture.asset(
    AppAssets.iconHandKeyHolding,
    width: iconSize,
    height: iconSize,
    colorFilter: ColorFilter.mode(Color(0xFFB3E5FC), BlendMode.srcIn),
  ),
  SvgPicture.asset(
    AppAssets.iconMaintenanceToolsSet,
    width: iconSize,
    height: iconSize,
    colorFilter: ColorFilter.mode(Color(0xFFB3E5FC), BlendMode.srcIn),
  ),
];

/// ✅ سرعة عشوائية
double generateSpeed() => 30 + Random().nextInt(30).toDouble();

/// ✅ موديل العنصر مع الخصائص الجديدة للعمق ثلاثي الأبعاد
class MovingItemModel {
  final double startY;
  final double speed;
  final double scale;
  final double opacity;

  MovingItemModel({
    required this.startY,
    required this.speed,
    required this.scale,
    required this.opacity,
  });
}

/// ✅ توليد بيانات العنصر مع مستويات عمق مختلفة (Parallax)
class ItemGenerator {
  static List<MovingItemModel> generateItems(Size screenSize) {
    final spacing = screenSize.height / (rowCount + 1);

    return List.generate(rowCount, (i) {
      final int depthLayer = i % 3; // 0 = بعيد، 1 = متوسط، 2 = قريب
      final double scale;
      final double opacity;
      final double speed;

      if (depthLayer == 0) {
        // طبقة بعيدة جداً (صغيرة، خافتة، بطيئة)
        scale = 0.45;
        opacity = 0.12;
        speed = 12.0 + Random().nextInt(8);
      } else if (depthLayer == 1) {
        // طبقة متوسطة البعد
        scale = 0.75;
        opacity = 0.22;
        speed = 22.0 + Random().nextInt(12);
      } else {
        // طبقة قريبة (كبيرة، سريعة، أكثر وضوحاً)
        scale = 1.05;
        opacity = 0.32;
        speed = 36.0 + Random().nextInt(18);
      }

      return MovingItemModel(
        startY: spacing * (i + 1),
        speed: speed,
        scale: scale,
        opacity: opacity,
      );
    });
  }
}

/// ✅ العنصر المتحرك
class MovingItem extends StatefulWidget {
  final MovingItemModel itemData;
  const MovingItem({super.key, required this.itemData});

  @override
  State<MovingItem> createState() => _MovingItemState();
}

class _MovingItemState extends State<MovingItem>
    with SingleTickerProviderStateMixin {
  late double xPos;
  late Ticker _ticker;
  late double screenWidth;
  late Widget currentWidget;
  late double rotationAngle;
  late double rotationDirection; // 1.0 للاتجاه الموجب، -1.0 للاتجاه السالب

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenWidth = MediaQuery.of(context).size.width;
    xPos = Random().nextDouble() * screenWidth;
    rotationAngle = Random().nextDouble() * 2 * pi;
    rotationDirection = Random().nextBool() ? 1.0 : -1.0;
    currentWidget = _getRandomWidget();

    _ticker = createTicker(_updatePosition)..start();
  }

  Widget _getRandomWidget() {
    return widgetOptions[Random().nextInt(widgetOptions.length)];
  }

  void _updatePosition(Duration elapsed) {
    const dt = 1 / 60;
    setState(() {
      xPos -= widget.itemData.speed * dt;
      // دوران مستمر ناعم (0.3 راديان في الثانية)
      rotationAngle += rotationDirection * 0.3 * dt;

      if (xPos < -(iconSize * widget.itemData.scale)) {
        xPos = screenWidth;
        currentWidget = _getRandomWidget(); // تبديل الودجت
        rotationDirection = Random().nextBool() ? 1.0 : -1.0;
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // حساب تلاشي الحواف لمنع الظهور المفاجئ
    double edgeOpacity = 1.0;
    final itemScaledSize = iconSize * widget.itemData.scale;
    
    if (xPos < 50) {
      edgeOpacity = (xPos + itemScaledSize) / (50 + itemScaledSize);
      if (edgeOpacity < 0.0) edgeOpacity = 0.0;
    } else if (xPos > screenWidth - 70) {
      edgeOpacity = (screenWidth - xPos) / 70;
      if (edgeOpacity < 0.0) edgeOpacity = 0.0;
    }

    final double finalOpacity = widget.itemData.opacity * edgeOpacity;

    return Positioned(
      top: widget.itemData.startY,
      left: xPos,
      child: Transform.scale(
        scale: widget.itemData.scale,
        child: Transform.rotate(
          angle: rotationAngle,
          child: Opacity(
            opacity: finalOpacity.clamp(0.0, 1.0),
            child: currentWidget,
          ),
        ),
      ),
    );
  }
}

/// ✅ الخلفية المتحركة
class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final items = ItemGenerator.generateItems(constraints.biggest);

        return Stack(
          children: items
              .map((itemData) => MovingItem(itemData: itemData))
              .toList(),
        );
      },
    );
  }
}

/// ✅ شاشة العرض
class FreshHomeAnimatedBackground extends StatelessWidget {
  const FreshHomeAnimatedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          Center(
            child: Text(
              'Welcome to Fresh Home',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
