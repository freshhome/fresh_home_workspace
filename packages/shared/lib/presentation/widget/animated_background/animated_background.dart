

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

/// ✅ موديل العنصر (من غير widget دلوقتي)
class MovingItemModel {
  final double startY;
  final double speed;

  MovingItemModel({required this.startY, required this.speed});
}

/// ✅ توليد بيانات العنصر
class ItemGenerator {
  static List<MovingItemModel> generateItems(Size screenSize) {
    final spacing = screenSize.height / (rowCount + 1);

    return List.generate(rowCount, (i) {
      return MovingItemModel(startY: spacing * (i + 1), speed: generateSpeed());
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenWidth = MediaQuery.of(context).size.width;
    xPos = Random().nextDouble() * screenWidth;
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

      if (xPos < -iconSize) {
        xPos = screenWidth;
        currentWidget = _getRandomWidget(); // ✅ بدل الودجت بعنصر جديد
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
    return Positioned(
      top: widget.itemData.startY,
      left: xPos,
      child: currentWidget,
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
