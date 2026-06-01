import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';

class OrderStatusModel {
  static OrderStatus fromJson(String statusName) {
    switch (statusName) {
      case 'created': return OrderStatus.created;
      case 'pending': return OrderStatus.pending;
      case 'assigned': return OrderStatus.assigned;
      case 'accepted': return OrderStatus.accepted;
      case 'ready': return OrderStatus.ready;
      case 'on_the_way': return OrderStatus.onTheWay;
      case 'arrived': return OrderStatus.arrived;
      case 'in_progress': return OrderStatus.inProgress;
      case 'pending_inspection': return OrderStatus.pendingInspection;
      case 'completed': return OrderStatus.completed;
      case 'cancelled': return OrderStatus.cancelled;
      case 'failed': return OrderStatus.failed;
      case 'failed_no_show': return OrderStatus.failedNoShow;
      case 'expired': return OrderStatus.expired;
      
      // Legacy & Special Mappings
      case 'cancelled_by_customer': return OrderStatus.cancelled;
      case 'cancelled_by_admin': return OrderStatus.cancelled;
      case 'cancelled_by_technician': return OrderStatus.cancelled;
      case 'rescheduled': return OrderStatus.accepted;
      
      default: return OrderStatus.created;
    }
  }

  static String toJson(OrderStatus status) {
    switch (status) {
      case OrderStatus.created: return 'created';
      case OrderStatus.pending: return 'pending';
      case OrderStatus.assigned: return 'assigned';
      case OrderStatus.accepted: return 'accepted';
      case OrderStatus.ready: return 'ready';
      case OrderStatus.onTheWay: return 'on_the_way';
      case OrderStatus.arrived: return 'arrived';
      case OrderStatus.inProgress: return 'in_progress';
      case OrderStatus.pendingInspection: return 'pending_inspection';
      case OrderStatus.completed: return 'completed';
      case OrderStatus.cancelled: return 'cancelled';
      case OrderStatus.failed: return 'failed';
      case OrderStatus.failedNoShow: return 'failed_no_show';
      case OrderStatus.expired: return 'expired';
    }
  }
}
