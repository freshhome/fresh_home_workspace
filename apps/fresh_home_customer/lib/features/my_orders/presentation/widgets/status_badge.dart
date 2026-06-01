import 'package:flutter/material.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';

class StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case OrderStatus.created:
      case OrderStatus.pending:
        backgroundColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        text = "جديد";
        break;
      case OrderStatus.assigned:
        backgroundColor = const Color(0xFFEFF6FF); // Blue 50
        textColor = const Color(0xFF3B82F6); // Blue 500
        text = "تم التعيين";
        break;
      case OrderStatus.accepted:
        backgroundColor = const Color(0xFFECFDF5); // Emerald 50
        textColor = const Color(0xFF10B981); // Emerald 500
        text = "مقبول";
        break;
      case OrderStatus.ready:
        backgroundColor = const Color(0xFFECFDF5);
        textColor = const Color(0xFF10B981);
        text = "مؤكد (جاهز للتنفيذ)";
        break;
      case OrderStatus.onTheWay:
        backgroundColor = const Color(0xFFFFF7ED); // Orange 50
        textColor = const Color(0xFFF97316); // Orange 500
        text = "في الطريق";
        break;
      case OrderStatus.arrived:
        backgroundColor = const Color(0xFFECFEFF);
        textColor = const Color(0xFF0891B2);
        text = "وصل للموقع";
        break;
      case OrderStatus.inProgress:
        backgroundColor = const Color(0xFFF0F9FF); // Sky 50
        textColor = const Color(0xFF0EA5E9); // Sky 500
        text = "قيد التنفيذ";
        break;
      case OrderStatus.completed:
        backgroundColor = const Color(0xFFECFDF5); // Emerald 50
        textColor = const Color(0xFF059669); // Emerald 600
        text = "تم الانتهاء";
        break;
      case OrderStatus.failed:
      case OrderStatus.failedNoShow:
      case OrderStatus.expired:
        backgroundColor = const Color(0xFFFEF2F2);
        textColor = const Color(0xFFDC2626);
        text = status == OrderStatus.expired ? "منتهي" : "غير مكتمل";
        break;
      case OrderStatus.cancelled:
        backgroundColor = const Color(0xFFFEF2F2); // Red 50
        textColor = const Color(0xFFEF4444); // Red 500
        text = "ملغي";
        break;
      case OrderStatus.pendingInspection:
        backgroundColor = const Color(0xFFF3E8FF);
        textColor = const Color(0xFF8B5CF6);
        text = "بانتظار المعاينة";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}
