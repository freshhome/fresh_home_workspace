import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import '../../domain/entities/technician_capacity_entry.dart';
import '../cubit/admin_dashboard_cubit.dart';
import 'utilization_chart.dart';

class TechnicianTile extends StatelessWidget {
  final TechnicianCapacityEntry entry;
  final DateTime targetDate;

  const TechnicianTile({
    super.key,
    required this.entry,
    required this.targetDate,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [themeColor.cardShadow],
        border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: themeColor.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.engineering, color: themeColor.primary),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.technicianName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getLocalizedStatus(context, entry.status),
                        style: TextStyle(
                          color: _getStatusColor(entry.status),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: themeColor.unselectedItem),
                onSelected: (action) => _handleAction(context, action),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'reassign', child: Text(l10n.action_reassign)),
                  PopupMenuItem(value: 'force_status', child: Text(l10n.action_force_status)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${l10n.utilization}: ${entry.workload}/${entry.capacity}'),
              Text('${entry.utilizationPercentage.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          UtilizationChart(utilizationPercentage: entry.utilizationPercentage),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    final cubit = context.read<AdminDashboardCubit>();
    final l10n = AppLocalizations.of(context)!;
    
    if (action == 'force_status') {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.action_force_status),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['idle', 'healthy', 'full', 'blocked', 'overloaded'].map((status) {
              return ListTile(
                title: Text(_getLocalizedStatus(context, status)),
                onTap: () {
                  Navigator.pop(dialogContext);
                  cubit.forceStatusUpdate(entry.technicianId, targetDate, status);
                },
              );
            }).toList(),
          ),
        ),
      );
    } else if (action == 'reassign') {
      // In a full implementation, you'd show a modal scanning bookings for that tech 
      // and allowing selection of a booking to reassign.
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Reassign Booking Modal pending implementation')),
      );
    }
  }

  String _getLocalizedStatus(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'idle': return l10n.tech_status_idle;
      case 'healthy': return l10n.tech_status_healthy;
      case 'full': return l10n.tech_status_full;
      case 'blocked': return l10n.tech_status_blocked;
      case 'overloaded': return l10n.tech_status_overloaded;
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'idle': return Colors.grey;
      case 'healthy': return Colors.green;
      case 'full': return Colors.orange;
      case 'blocked': return Colors.black;
      case 'overloaded': return Colors.red;
      default: return Colors.blue;
    }
  }
}
