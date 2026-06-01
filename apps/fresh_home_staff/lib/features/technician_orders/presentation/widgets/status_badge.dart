import 'package:flutter/material.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';

class StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case OrderStatus.created:
      case OrderStatus.pending:
        backgroundColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        text = locale == 'ar' ? "جديد" : "New";
        break;
      case OrderStatus.assigned:
        backgroundColor = const Color(0xFFEFF6FF);
        textColor = const Color(0xFF3B82F6);
        text = l10n.tech_status_timeline_assigned;
        break;
      case OrderStatus.accepted:
        backgroundColor = const Color(0xFFECFDF5);
        textColor = const Color(0xFF10B981);
        text = l10n.tech_status_timeline_accepted;
        break;
      case OrderStatus.ready:
        backgroundColor = const Color(0xFFF0F9FF);
        textColor = const Color(0xFF0EA5E9);
        text = locale == 'ar' ? "جاهز للتنفيذ" : "Ready";
        break;
      case OrderStatus.onTheWay:
        backgroundColor = const Color(0xFFFFF7ED);
        textColor = const Color(0xFFF97316);
        text = l10n.tech_status_timeline_on_the_way;
        break;
      case OrderStatus.arrived:
        backgroundColor = const Color(0xFFECFEFF);
        textColor = const Color(0xFF0891B2);
        text = l10n.tech_status_timeline_arrived;
        break;
      case OrderStatus.inProgress:
        backgroundColor = const Color(0xFFF0F9FF);
        textColor = const Color(0xFF0EA5E9);
        text = l10n.tech_status_timeline_in_progress;
        break;
      case OrderStatus.completed:
        backgroundColor = const Color(0xFFECFDF5);
        textColor = const Color(0xFF059669);
        text = l10n.tech_status_timeline_completed;
        break;
      case OrderStatus.failed:
      case OrderStatus.failedNoShow:
        backgroundColor = const Color(0xFFFEF2F2);
        textColor = const Color(0xFFDC2626);
        text = locale == 'ar' ? "فشل الخدمة" : "Failed";
        break;
      case OrderStatus.expired:
        backgroundColor = const Color(0xFFFEF2F2);
        textColor = const Color(0xFFDC2626);
        text = locale == 'ar' ? "منتهي" : "Expired";
        break;
      case OrderStatus.cancelled:
        backgroundColor = const Color(0xFFFEF2F2);
        textColor = const Color(0xFFEF4444);
        text = l10n.order_status_cancelled;
        break;
      case OrderStatus.pendingInspection:
        backgroundColor = const Color(0xFFF3E8FF);
        textColor = const Color(0xFF8B5CF6);
        text = locale == 'ar' ? "بانتظار المعاينة" : "Pending Inspection";
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
