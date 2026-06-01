import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

class UtilizationChart extends StatelessWidget {
  final double utilizationPercentage;
  final double height;

  const UtilizationChart({
    super.key,
    required this.utilizationPercentage,
    this.height = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    
    // Determine color based on threshold
    Color trackColor;
    if (utilizationPercentage < 50) {
      trackColor = Colors.green;
    } else if (utilizationPercentage < 80) {
      trackColor = Colors.orange;
    } else {
      trackColor = Colors.red;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: height,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            color: themeColor.unselectedItem.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                height: height,
                width: constraints.maxWidth * (utilizationPercentage / 100).clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      trackColor.withValues(alpha: 0.7),
                      trackColor,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
