import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import '../../domain/entities/fleet_dashboard_entry.dart';
import 'utilization_chart.dart';

class CapacityCard extends StatelessWidget {
  final FleetDashboardEntry entry;
  final VoidCallback onTap;

  const CapacityCard({super.key, required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final dateStr = DateFormat('EEE, MMM d').format(entry.targetDate);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeColor.cardBackground.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [themeColor.cardShadow],
          border: Border.all(
            color: themeColor.unselectedItem.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: themeColor.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(entry.utilizationPercentage).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${entry.utilizationPercentage.toInt()}%',
                    style: TextStyle(
                      color: _getStatusColor(entry.utilizationPercentage),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            UtilizationChart(utilizationPercentage: entry.utilizationPercentage),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn(context, l10n.total_capacity, entry.totalCapacity.toString()),
                _buildStatColumn(context, l10n.total_booked, entry.totalBooked.toString(), color: themeColor.primary),
                _buildStatColumn(context, l10n.available_slots, entry.availableCapacity.toString(), color: Colors.green),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String value, {Color? color}) {
    final themeColor = context.themeColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: themeColor.unselectedItem,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? themeColor.textPrimary,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(double utilization) {
    if (utilization < 50) return Colors.green;
    if (utilization < 80) return Colors.orange;
    return Colors.red;
  }
}
