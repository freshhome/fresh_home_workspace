import 'package:flutter/material.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';

/// Centralized status mapper used across Customer, Staff, and Admin apps.
class BookingStatusHelper {
  BookingStatusHelper._();

  static String getLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.created:
        return 'طلب جديد';
      case OrderStatus.pending:
        return 'بانتظار التعيين';
      case OrderStatus.assigned:
        return 'تم تعيين فني';
      case OrderStatus.accepted:
        return 'الفني قبل الطلب';
      case OrderStatus.ready:
        return 'الفني أكد الحضور';
      case OrderStatus.onTheWay:
        return 'الفني في الطريق';
      case OrderStatus.arrived:
        return 'وصل للموقع';
      case OrderStatus.inProgress:
        return 'تم بدء الخدمة';
      case OrderStatus.completed:
        return 'تم الانتهاء';
      case OrderStatus.cancelled:
        return 'تم الإلغاء';
      case OrderStatus.failed:
      case OrderStatus.failedNoShow:
        return 'فشل (عدم حضور)';
      case OrderStatus.expired:
        return 'منتهي';
      case OrderStatus.pendingInspection:
        return 'بانتظار المعاينة';
    }
  }

  static Color getColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.created:
      case OrderStatus.pending:
        return const Color(0xFF64748B); // Slate
      case OrderStatus.assigned:
        return const Color(0xFF3B82F6); // Blue
      case OrderStatus.accepted:
      case OrderStatus.ready:
        return const Color(0xFF10B981); // Emerald
      case OrderStatus.onTheWay:
        return const Color(0xFFF59E0B); // Amber
      case OrderStatus.arrived:
        return const Color(0xFF06B6D4); // Cyan
      case OrderStatus.inProgress:
        return const Color(0xFF3B82F6); // Blue
      case OrderStatus.completed:
        return const Color(0xFF22C55E); // Green
      case OrderStatus.pendingInspection:
        return const Color(0xFF8B5CF6); // Purple/Indigo
      case OrderStatus.cancelled:
      case OrderStatus.failed:
      case OrderStatus.failedNoShow:
      case OrderStatus.expired:
        return const Color(0xFFEF4444); // Red
    }
  }

  static IconData getIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.created:
      case OrderStatus.pending:
        return Icons.fiber_new_rounded;
      case OrderStatus.assigned:
        return Icons.person_pin_rounded;
      case OrderStatus.accepted:
      case OrderStatus.ready:
        return Icons.thumb_up_alt_rounded;
      case OrderStatus.onTheWay:
        return Icons.directions_car_rounded;
      case OrderStatus.arrived:
        return Icons.location_on_rounded;
      case OrderStatus.inProgress:
        return Icons.handyman_rounded;
      case OrderStatus.completed:
        return Icons.task_alt_rounded;
      case OrderStatus.pendingInspection:
        return Icons.visibility_rounded;
      case OrderStatus.cancelled:
      case OrderStatus.failed:
      case OrderStatus.failedNoShow:
      case OrderStatus.expired:
        return Icons.cancel_rounded;
    }
  }

  static bool isCancelled(OrderStatus status) {
    return status == OrderStatus.cancelled ||
        status == OrderStatus.failed ||
        status == OrderStatus.failedNoShow ||
        status == OrderStatus.expired;
  }

  static bool isActive(OrderStatus status) {
    return status == OrderStatus.created ||
        status == OrderStatus.pending ||
        status == OrderStatus.assigned ||
        status == OrderStatus.accepted ||
        status == OrderStatus.ready ||
        status == OrderStatus.onTheWay ||
        status == OrderStatus.arrived ||
        status == OrderStatus.inProgress ||
        status == OrderStatus.pendingInspection;
  }
}
