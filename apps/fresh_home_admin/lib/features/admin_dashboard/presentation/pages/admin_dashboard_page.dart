import 'package:flutter/material.dart';
import 'package:fresh_home_admin/features/services_management/presentation/cubit/admin_sub_services_cubit.dart';
import 'package:fresh_home_admin/features/services_management/presentation/cubit/services_management_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/admin_dashboard_cubit.dart';
import '../cubit/admin_dashboard_state.dart';

import '../../domain/entities/fleet_dashboard_entry.dart';
import 'admin_daily_schedule_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        if (state is AdminDashboardLoading || state is AdminDashboardInitial) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8F9FD),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
            ),
          );
        } else if (state is AdminDashboardError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FD),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<AdminDashboardCubit>().loadDashboard(),
                    child: const Text(
                      'إعادة المحاولة',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (state is AdminDashboardLoaded) {
          final fleetData = state.fleetDashboard;
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FD),
            appBar: _buildAppBar(context),
            body: RefreshIndicator(
              onRefresh: () async {
                context.read<AdminDashboardCubit>().loadDashboard();
                context.read<ServicesManagementCubit>().loadServices();
              },
              color: const Color(0xFF1E3A8A),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildActionButtons(),
                      const SizedBox(height: 32),
                      _buildWeeklySchedules(fleetData),
                      const SizedBox(height: 32),
                      _buildAnalysisCard(fleetData),
                      const SizedBox(height: 24),
                      _buildSummaryCard(fleetData),
                      const SizedBox(height: 80), // Space for FAB
                    ],
                  ),
                ),
              ),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.startFloat,
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              backgroundColor: const Color(0xFF2563EB),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF8F9FD),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Color(0xFF0F172A),
          size: 20,
        ),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'نظرة عامة على الجدول',
        style: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w800,
          fontFamily: 'Cairo',
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.calendar_month_rounded, size: 20),
            label: const Text(
              'تعديل عدة أيام',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E3A8A),
              side: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.copy_all_rounded, size: 20),
            label: const Text(
              'نسخ إعدادات يوم',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySchedules(List<FleetDashboardEntry> fleetData) {
    if (fleetData.isEmpty) return const SizedBox();

    final List<Widget> rows = [];
    for (int i = 0; i < fleetData.length; i += 7) {
      final weekData = fleetData.skip(i).take(7).toList();
      String title = 'الأسبوع الحالي';
      if (i == 7) title = 'الأسبوع القادم';
      if (i >= 14) title = 'الأسبوع اللاحق';

      final firstDay = weekData.first.targetDate;
      final DateFormat formatter = DateFormat('MMMM yyyy', 'ar');
      String subtitle = formatter.format(firstDay);

      rows.add(_buildWeekRow(title, subtitle, weekData: weekData));
      if (i + 7 < fleetData.length) {
        rows.add(const SizedBox(height: 32));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _buildWeekRow(
    String title,
    String subtitle, {
    required List<FleetDashboardEntry> weekData,
  }) {
    final DateFormat dayNameFormatter = DateFormat('EEEE', 'ar');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                fontFamily: 'Cairo',
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            itemCount: weekData.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final entry = weekData[index];
              final dayName = dayNameFormatter.format(entry.targetDate);
              final dayNum = entry.targetDate.day.toString().padLeft(2, '0');
              final monthNum = entry.targetDate.month.toString().padLeft(
                2,
                '0',
              );

              String status;
              Color statusColor;
              Color statusBgColor;
              Color topBorderColor;

              if (entry.totalCapacity == 0) {
                status = 'فارغ';
                statusColor = const Color(0xFF64748B);
                statusBgColor = const Color(0xFFF1F5F9);
                topBorderColor = const Color(0xFFCBD5E1);
              } else if (entry.availableCapacity <= 0) {
                status = 'مكتمل';
                statusColor = const Color(0xFFEF4444);
                statusBgColor = const Color(0xFFFEE2E2);
                topBorderColor = const Color(0xFFEF4444);
              } else {
                status = 'متاح';
                statusColor = const Color(0xFF2563EB);
                statusBgColor = const Color(0xFFDBEAFE);
                topBorderColor = const Color(0xFF2563EB);
              }

              return _buildDayCard(
                context: context,
                dayName: dayName,
                dayNum: dayNum,
                month: monthNum,
                status: status,
                statusColor: statusColor,
                statusBgColor: statusBgColor,
                totalCapacity: entry.totalCapacity.toString(),
                bookedCapacity: entry.totalBooked.toString(),
                availableCapacity: entry.availableCapacity.toString(),
                topBorderColor: topBorderColor,
                date: entry.targetDate,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard({
    required BuildContext context,
    required String dayName,
    required String dayNum,
    required String month,
    required String status,
    required Color statusColor,
    required Color statusBgColor,
    required String totalCapacity,
    required String bookedCapacity,
    required String availableCapacity,
    required Color topBorderColor,
    required DateTime date,
  }) {
    return GestureDetector(
      onTap: () {
        final dashboardCubit = context.read<AdminDashboardCubit>();
        final servicesCubit = context.read<ServicesManagementCubit>();
        final subServicesCubit = context.read<AdminSubServicesCubit>();

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MultiBlocProvider(
              providers: [
                BlocProvider.value(
                  value: dashboardCubit..loadTechnicianDetailsForDate(date),
                ),
                BlocProvider.value(value: servicesCubit),
                BlocProvider.value(value: subServicesCubit),
              ],
              child: AdminDailySchedulePage(date: date),
            ),
          ),
        );
      },
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE2E8F0).withValues(alpha:0.6),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 16,
              right: 16,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: topBorderColor,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dayName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        '$dayNum/$month',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildCountRow(
                    'الإجمالي:',
                    totalCapacity,
                    const Color(0xFF0F172A),
                  ),
                  const SizedBox(height: 4),
                  _buildCountRow(
                    'محجوز:',
                    bookedCapacity,
                    const Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 4),
                  _buildCountRow(
                    'متاح:',
                    availableCapacity,
                    const Color(0xFF059669),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountRow(String title, String count, Color countColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          count,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: countColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisCard(List<FleetDashboardEntry> fleetData) {
    if (fleetData.isEmpty) return const SizedBox();

    // Calculate average utilization
    double avgUtilization = 0;
    int days = fleetData.length > 7 ? 7 : fleetData.length;
    for (int i = 0; i < days; i++) {
      avgUtilization += fleetData[i].utilizationPercentage;
    }
    avgUtilization = days > 0 ? avgUtilization / days : 0;

    String analysisMessage = avgUtilization > 70
        ? 'الأسبوع الحالي يظهر طلباً مرتفعاً على الخدمات بنسبة ${(avgUtilization).toStringAsFixed(0)}%.'
        : 'الأسبوع الحالي يظهر إشغالاً متوسطاً بنسبة ${(avgUtilization).toStringAsFixed(0)}%.';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE2E8F0).withValues(alpha:0.6),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تحليل كثافة العمل',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            analysisMessage,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              height: 1.5,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: fleetData.take(7).map((entry) {
                final dayName = DateFormat(
                  'EEEE',
                  'ar',
                ).format(entry.targetDate).split(' ').last;
                final pct = entry.utilizationPercentage;
                final height = (pct / 100.0) * 80.0 + 15; // Min 15

                Color color;
                if (pct > 80) {
                  color = const Color(0xFFFECACA); // Red
                } else if (pct > 50) {
                  color = const Color(0xFFFFEDD5); // Orange
                } else {
                  color = const Color(0xFFBBF7D0); // Green
                }

                return _buildBar(height: height, color: color, label: dayName);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar({
    required double height,
    required Color color,
    required String label,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(List<FleetDashboardEntry> fleetData) {
    int totalCapacity = 0;
    int totalBooked = 0;
    int availableCapacity = 0;

    for (var entry in fleetData) {
      totalCapacity += entry.totalCapacity;
      totalBooked += entry.totalBooked;
      availableCapacity += entry.availableCapacity;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF1E3A8A),
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'الملخص العام',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'إجمالي الحجوزات',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$totalBooked / $totalCapacity',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'القدرة الاستيعابية المتبقية',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$availableCapacity',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
