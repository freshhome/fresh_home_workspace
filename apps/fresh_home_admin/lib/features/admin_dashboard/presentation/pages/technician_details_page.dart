import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import '../cubit/admin_dashboard_cubit.dart';
import '../cubit/admin_dashboard_state.dart';
import '../widgets/technician_tile.dart';

class TechnicianDetailsPage extends StatelessWidget {
  final DateTime date;

  const TechnicianDetailsPage({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat('EEEE, MMM d, yyyy').format(date);

    return Scaffold(
      backgroundColor: themeColor.background,
      appBar: AppBar(
        title: Text('${l10n.technician_details_title} - $dateStr', style: const TextStyle(fontSize: 16)),
        backgroundColor: themeColor.background,
        elevation: 0,
      ),
      body: BlocConsumer<AdminDashboardCubit, AdminDashboardState>(
        listener: (context, state) {
          if (state is AdminDashboardError) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is AdminActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.general_operation_success), backgroundColor: Colors.green),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminDashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AdminDashboardLoaded) {
            if (state.isActionInProgress) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.selectedDateTechnicians.isEmpty) {
              return const Center(child: Text('No technician data for this date.'));
            }

            return RefreshIndicator(
              onRefresh: () => context.read<AdminDashboardCubit>().loadTechnicianDetailsForDate(date),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.selectedDateTechnicians.length,
                itemBuilder: (context, index) {
                  return TechnicianTile(
                    entry: state.selectedDateTechnicians[index],
                    targetDate: date,
                  );
                },
              ),
            );
          }

          return Center(
            child: ElevatedButton(
              onPressed: () => context.read<AdminDashboardCubit>().loadTechnicianDetailsForDate(date),
              child: Text(l10n.retry),
            ),
          );
        },
      ),
    );
  }
}
