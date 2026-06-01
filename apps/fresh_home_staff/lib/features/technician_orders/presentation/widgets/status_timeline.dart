import 'package:flutter/material.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';

class StatusTimeline extends StatelessWidget {
  final OrderStatus currentStatus;
  final bool isVertical;

  const StatusTimeline({
    super.key, 
    required this.currentStatus,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final l10n = AppLocalizations.of(context)!;

    final List<_StepData> steps = [
      _StepData(OrderStatus.assigned, l10n.tech_status_timeline_assigned, Icons.assignment_turned_in_rounded),
      _StepData(OrderStatus.accepted, l10n.tech_status_timeline_accepted, Icons.check_circle_rounded),
      _StepData(OrderStatus.onTheWay, l10n.tech_status_timeline_on_the_way, Icons.directions_car_rounded),
      _StepData(OrderStatus.arrived, l10n.tech_status_timeline_arrived, Icons.location_on_rounded),
      _StepData(OrderStatus.inProgress, l10n.tech_status_timeline_in_progress, Icons.engineering_rounded),
      _StepData(OrderStatus.completed, l10n.tech_status_timeline_completed, Icons.task_alt_rounded),
    ];

    int currentIndex = steps.indexWhere((s) => s.status == currentStatus);
    if (currentIndex == -1) {
        if (currentStatus == OrderStatus.completed) {
          currentIndex = steps.length - 1;
        } else {
          currentIndex = 0; 
        }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [themeColor.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.track_changes_rounded, color: themeColor.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                l10n.tech_details_timeline_title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: themeColor.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (isVertical)
            _buildVerticalTimeline(context, steps, currentIndex)
          else
            _buildHorizontalTimeline(context, steps, currentIndex),
        ],
      ),
    );
  }

  Widget _buildHorizontalTimeline(BuildContext context, List<_StepData> steps, int currentIndex) {
    final themeColor = context.themeColor;
    final completedColor = themeColor.secondary; // Green for completed

    return Row(
      children: List.generate(steps.length, (index) {
        final isLast = index == steps.length - 1;
        final isCompleted = index <= currentIndex;
        final isActive = index == currentIndex;
        final step = steps[index];

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isCompleted ? completedColor : themeColor.unselectedItem.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: isActive ? Border.all(color: completedColor, width: 2) : null,
                      ),
                      child: Icon(
                        step.icon,
                        size: 18,
                        color: isCompleted ? Colors.white : themeColor.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                        color: isCompleted ? themeColor.textPrimary : themeColor.secondaryText,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  width: 20,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4), 
                  color: (index < currentIndex) ? completedColor : themeColor.unselectedItem.withValues(alpha: 0.1),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildVerticalTimeline(BuildContext context, List<_StepData> steps, int currentIndex) {
    final themeColor = context.themeColor;
    final completedColor = themeColor.secondary; // Green for completed

    return Column(
      children: List.generate(steps.length, (index) {
        final isLast = index == steps.length - 1;
        final isCompleted = index <= currentIndex;
        final isActive = index == currentIndex;
        final step = steps[index];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted ? completedColor : themeColor.unselectedItem.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: isActive ? Border.all(color: completedColor, width: 2) : null,
                  ),
                  child: Icon(
                    step.icon,
                    size: 16,
                    color: isCompleted ? Colors.white : themeColor.secondaryText,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: (index < currentIndex) ? completedColor : themeColor.unselectedItem.withValues(alpha: 0.1),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isCompleted ? FontWeight.w900 : FontWeight.bold,
                        color: isCompleted ? themeColor.textPrimary : themeColor.secondaryText,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    if (isActive)
                      Text(
                        "الحالة الحالية",
                        style: TextStyle(
                          fontSize: 11,
                          color: completedColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _StepData {
  final OrderStatus status;
  final String label;
  final IconData icon;

  _StepData(this.status, this.label, this.icon);
}
