import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared/domain/booking/entities/booking/booking.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/utils/booking_status_helper.dart';

class OrderTimelineWidget extends StatelessWidget {
  final Booking booking;

  const OrderTimelineWidget({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final steps = _buildSteps();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [themeColor.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: themeColor.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.timeline_rounded, color: themeColor.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'مسار الطلب',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: themeColor.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            final isLast = i == steps.length - 1;
            return _TimelineStep(
              step: step,
              isLast: isLast,
              themeColor: themeColor,
            );
          }),
        ],
      ),
    );
  }

  List<_StepData> _buildSteps() {
    final steps = <_StepData>[];
    final isCancelled = BookingStatusHelper.isCancelled(booking.status);

    if (isCancelled) {
      // Show start point and then cancellation
      steps.add(_StepData(
        status: OrderStatus.assigned,
        timestamp: booking.assignedAt ?? booking.createdAt,
        isDone: true,
      ));
      steps.add(_StepData(
        status: booking.status,
        timestamp: booking.cancelledAt ?? booking.updatedAt,
        isDone: true,
        isCancelled: true,
      ));
    } else {
      final lifecycle = [
        _StepData(
          status: OrderStatus.created,
          timestamp: booking.createdAt,
          isDone: true, // Always done if we are here
        ),
        _StepData(
          status: OrderStatus.assigned,
          timestamp: booking.assignedAt,
          isDone: _isAtLeast(OrderStatus.assigned),
        ),
        _StepData(
          status: OrderStatus.accepted,
          timestamp: booking.acceptedAt,
          isDone: _isAtLeast(OrderStatus.accepted),
        ),
        _StepData(
          status: OrderStatus.ready,
          timestamp: booking.updatedAt, // Using updatedAt as proxy for attendance confirmation time
          isDone: _isAtLeast(OrderStatus.ready),
        ),
        _StepData(
          status: OrderStatus.onTheWay,
          timestamp: booking.dispatchedAt,
          isDone: _isAtLeast(OrderStatus.onTheWay),
        ),
        _StepData(
          status: OrderStatus.arrived,
          timestamp: booking.arrivedAt,
          isDone: _isAtLeast(OrderStatus.arrived),
        ),
        _StepData(
          status: OrderStatus.inProgress,
          timestamp: booking.startedAt,
          isDone: _isAtLeast(OrderStatus.inProgress),
        ),
        _StepData(
          status: OrderStatus.completed,
          timestamp: booking.completedAt,
          isDone: booking.status == OrderStatus.completed,
        ),
      ];
      steps.addAll(lifecycle);
    }

    return steps;
  }

  bool _isAtLeast(OrderStatus target) {
    const order = [
      OrderStatus.created,
      OrderStatus.pending,
      OrderStatus.assigned,
      OrderStatus.accepted,
      OrderStatus.ready,
      OrderStatus.onTheWay,
      OrderStatus.arrived,
      OrderStatus.inProgress,
      OrderStatus.completed,
    ];
    final currentIndex = order.indexOf(booking.status);
    final targetIndex = order.indexOf(target);
    
    // If not found (e.g. rescheduled/cancelled), handle specially or ignore
    if (currentIndex == -1 || targetIndex == -1) return false;
    
    return currentIndex >= targetIndex;
  }
}

class _StepData {
  final OrderStatus status;
  final DateTime? timestamp;
  final bool isDone;
  final bool isCancelled;

  const _StepData({
    required this.status,
    required this.timestamp,
    required this.isDone,
    this.isCancelled = false,
  });
}

class _TimelineStep extends StatelessWidget {
  final _StepData step;
  final bool isLast;
  final ThemeColorExtension themeColor;

  const _TimelineStep({
    required this.step,
    required this.isLast,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = step.isCancelled
        ? themeColor.error
        : step.isDone
            ? BookingStatusHelper.getColor(step.status)
            : themeColor.unselectedItem.withValues(alpha: 0.4);
    final icon = BookingStatusHelper.getIcon(step.status);
    final label = BookingStatusHelper.getLabel(step.status);
    final timeStr = step.timestamp != null
        ? DateFormat('dd/MM - hh:mm a', 'ar').format(step.timestamp!)
        : null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + Line column
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: step.isDone ? 0.15 : 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: step.isDone ? 2 : 1),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: step.isDone ? 0.6 : 0.2),
                          themeColor.unselectedItem.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Text column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: step.isDone ? FontWeight.bold : FontWeight.w500,
                      color: step.isDone ? themeColor.textPrimary : themeColor.secondaryText,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  if (timeStr != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: themeColor.secondaryText,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
