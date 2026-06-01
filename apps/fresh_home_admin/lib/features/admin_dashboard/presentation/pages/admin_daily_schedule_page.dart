import 'package:flutter/material.dart';
import 'package:fresh_home_admin/features/services_management/presentation/cubit/admin_sub_services_cubit.dart';
import 'package:fresh_home_admin/features/services_management/presentation/cubit/services_management_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared/domain/service/enums/service_status.dart';
import '../cubit/admin_dashboard_cubit.dart';
import '../cubit/admin_dashboard_state.dart';

import 'admin_service_details_page.dart';

class AdminDailySchedulePage extends StatelessWidget {
  final DateTime date;

  const AdminDailySchedulePage({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServicesManagementCubit, ServicesManagementState>(
      builder: (context, servicesState) {
        return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
          builder: (context, state) {
            if (state is AdminDashboardLoading ||
                (state is AdminDashboardLoaded && state.isActionInProgress)) {
              return const Scaffold(
                backgroundColor: Color(0xFFF8FAFC),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                ),
              );
            }

            if (servicesState is ServicesManagementInitial) {
              context.read<ServicesManagementCubit>().loadServices();
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (servicesState is ServicesManagementError) {
              return Scaffold(
                body: Center(child: Text('خطأ في تحميل الخدمات: ${servicesState.message}')),
              );
            }

            List<Widget> serviceCards = [];

            if (servicesState is ServicesManagementLoaded &&
                state is AdminDashboardLoaded) {
              if (servicesState.services.isEmpty) {
                serviceCards = [
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'لا توجد خدمات متاحة حالياً',
                        style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                      ),
                    ),
                  ),
                ];
              } else {
                for (var service in servicesState.services) {
                  // Filter technicians for this specific main service
                  final serviceTechs = state.selectedDateTechnicians
                      .where((t) => t.mainServiceId == service.id)
                      .toList();

                  int serviceBooked = serviceTechs.fold(
                    0,
                    (sum, t) => sum + t.workload,
                  );
                  int serviceTotal = serviceTechs.fold(
                    0,
                    (sum, t) => sum + t.capacity,
                  );
                  int activeInService = serviceTechs
                      .where(
                        (t) =>
                            t.status == 'active' ||
                            t.status == 'في الميدان' ||
                            t.status == 'متاح',
                      )
                      .length;

                  final String title =
                      service.title['ar'] ?? service.title['en'] ?? '';
                  final String subtitle =
                      service.description['ar'] ?? service.description['en'] ?? '';

                  serviceCards.add(
                    _buildServiceCard(
                      context: context,
                      servicesState: servicesState,
                      title: title,
                      subtitle: subtitle,
                      icon: _getIconForMainService(title),
                      iconBgColor: _getBgColorForMainService(title),
                      iconColor: _getIconColorForMainService(title),
                      status:
                          service.status == ServiceStatus.active ? 'نشط' : 'مغلق',
                      statusBgColor: service.status == ServiceStatus.active
                          ? const Color(0xFFD1FAE5)
                          : const Color(0xFFF1F5F9),
                      statusColor: service.status == ServiceStatus.active
                          ? const Color(0xFF059669)
                          : const Color(0xFF64748B),
                      booked: serviceBooked,
                      total: serviceTotal > 0 ? serviceTotal : 1,
                      progressColor: _getIconColorForMainService(title),
                      footerText: service.status == ServiceStatus.active
                          ? '$activeInService فني متاح'
                          : 'لا يوجد طلبات',
                    ),
                  );
                  serviceCards.add(const SizedBox(height: 16));
                }
              }
            } else if (servicesState is ServicesManagementLoading) {
              serviceCards = [
                const Center(child: CircularProgressIndicator()),
              ];
            }

            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: _buildAppBar(context),
              body: RefreshIndicator(
                onRefresh: () async {
                  context.read<AdminDashboardCubit>().loadTechnicianDetailsForDate(date);
                  context.read<ServicesManagementCubit>().loadServices();
                },
                color: const Color(0xFF1E3A8A),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildCloseDayButton(),
                      const SizedBox(height: 24),
                      ...serviceCards,
                      const SizedBox(height: 8),
                      if (state is AdminDashboardLoaded)
                        _buildPerformanceSummary(state),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFF0F172A),
          size: 20,
        ),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'تفاصيل الجدول',
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

  Widget _buildHeader() {
    final DateFormat dayNameFormatter = DateFormat('EEEE', 'ar');
    final DateFormat dateFormatter = DateFormat('dd MMMM yyyy', 'ar');
    final String dayName = dayNameFormatter.format(date);
    final String fullDate = dateFormatter.format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dayName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          fullDate,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  IconData _getIconForMainService(String title) {
    title = title.toLowerCase();
    if (title.contains('تنظيف') || title.contains('clean')) {
      return Icons.cleaning_services_rounded;
    }
    if (title.contains('صيانة') || title.contains('mainten')) {
      return Icons.handyman_rounded;
    }
    if (title.contains('حشرات') || title.contains('pest')) {
      return Icons.pest_control_rounded;
    }
    return Icons.category_rounded;
  }

  Color _getIconColorForMainService(String title) {
    title = title.toLowerCase();
    if (title.contains('تنظيف') || title.contains('clean')) {
      return const Color(0xFF3730A3);
    }
    if (title.contains('صيانة') || title.contains('mainten')) {
      return const Color(0xFF9A3412);
    }
    if (title.contains('حشرات') || title.contains('pest')) {
      return const Color(0xFF166534);
    }
    return const Color(0xFF1E3A8A);
  }

  Color _getBgColorForMainService(String title) {
    title = title.toLowerCase();
    if (title.contains('تنظيف') || title.contains('clean')) {
      return const Color(0xFFE0E7FF);
    }
    if (title.contains('صيانة') || title.contains('mainten')) {
      return const Color(0xFFFFEDD5);
    }
    if (title.contains('حشرات') || title.contains('pest')) {
      return const Color(0xFFDCFCE7);
    }
    return const Color(0xFFF1F5F9);
  }

  Widget _buildCloseDayButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A8A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.block_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'إغلاق اليوم بالكامل',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required ServicesManagementState servicesState,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String status,
    required Color statusBgColor,
    required Color statusColor,
    required int booked,
    required int total,
    required Color progressColor,
    required String footerText,
  }) {
    return GestureDetector(
      onTap: () {
        String? categoryId;
        if (servicesState is ServicesManagementLoaded) {
          // Try to find the category by title (cleaning, etc.)
          try {
            categoryId = servicesState.services
                .firstWhere(
                  (s) =>
                      (s.title['ar']?.contains(title.replaceAll('خدمات ', '')) ??
                          false) ||
                      (s.title['en']?.toLowerCase().contains(
                            title
                                .toLowerCase()
                                .replaceAll('services', '')
                                .trim(),
                          ) ??
                          false),
                )
                .id;
          } catch (_) {
            // Fallback or handle if not found
          }
        }

        final dashboardCubit = context.read<AdminDashboardCubit>();
        final subServicesCubit = context.read<AdminSubServicesCubit>();

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: dashboardCubit),
                BlocProvider.value(value: subServicesCubit),
              ],
              child: AdminServiceDetailsPage(
                categoryId: categoryId,
                categoryName: title,
              ),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE2E8F0).withValues(alpha:0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'التقدم اليومي',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  '$booked محجوز / $total إجمالي',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : booked / total,
                backgroundColor: const Color(0xFFF1F5F9),
                color: progressColor,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF94A3B8),
                  size: 14,
                ),
                Text(
                  footerText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSummary(AdminDashboardLoaded state) {
    int totalBookings = 0;
    int totalCapacity = 0;
    for (var tech in state.selectedDateTechnicians) {
      totalBookings += tech.workload;
      totalCapacity += tech.capacity;
    }
    double completionRate = totalCapacity > 0
        ? (totalBookings / totalCapacity) * 100
        : 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ملخص الأداء اليومي',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'بناء على $totalBookings طلب مكتمل',
                    style: const TextStyle(
                      color: Color(0xFF93C5FD),
                      fontSize: 12,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${completionRate.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'نسبة الإنجاز',
                        style: TextStyle(
                          color: Color(0xFF93C5FD),
                          fontSize: 12,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: const [
                      Text(
                        '4.2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'متوسط الوقت (ساعة)',
                        style: TextStyle(
                          color: Color(0xFF93C5FD),
                          fontSize: 12,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
