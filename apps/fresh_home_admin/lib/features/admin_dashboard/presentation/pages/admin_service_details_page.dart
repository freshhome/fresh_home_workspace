import 'package:flutter/material.dart';
import 'package:fresh_home_admin/features/services_management/presentation/cubit/admin_sub_services_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/domain/service/enums/service_status.dart';
import '../cubit/admin_dashboard_cubit.dart';
import '../cubit/admin_dashboard_state.dart';
import 'admin_sub_service_capacity_page.dart';

class AdminServiceDetailsPage extends StatefulWidget {
  final String? categoryId;
  final String categoryName;

  const AdminServiceDetailsPage({
    super.key,
    this.categoryId,
    this.categoryName = 'خدمات التنظيف',
  });

  @override
  State<AdminServiceDetailsPage> createState() => _AdminServiceDetailsPageState();
}

class _AdminServiceDetailsPageState extends State<AdminServiceDetailsPage> {
  @override
  void initState() {
    super.initState();
    if (widget.categoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AdminSubServicesCubit>().loadSubServices(widget.categoryId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminSubServicesCubit, AdminSubServicesState>(
      builder: (context, subServicesState) {
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

            int totalTechs = 0;
            int totalBooked = 0;

            if (state is AdminDashboardLoaded) {
              totalTechs = state.selectedDateTechnicians.length;
              for (var tech in state.selectedDateTechnicians) {
                totalBooked += tech.workload;
              }
            }

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                backgroundColor: const Color(0xFFF8FAFC),
                appBar: _buildAppBar(context),
                body: RefreshIndicator(
                  onRefresh: () async {
                    if (widget.categoryId != null) {
                      context.read<AdminSubServicesCubit>().loadSubServices(widget.categoryId!);
                      // Note: We don't have a specific date here, using now as fallback or keeping existing report
                    }
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
                        _buildBreadcrumb(),
                        const SizedBox(height: 16),
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildStatsRow(totalTechs, totalBooked),
                        const SizedBox(height: 32),
                        const Text(
                          'قائمة الخدمات الفرعية',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (subServicesState is AdminSubServicesLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (subServicesState is AdminSubServicesLoaded)
                          ...subServicesState.subServices.map(
                            (sub) => Column(
                              children: [
                                _buildSubServiceCard(
                                  context: context,
                                  title: sub.title['ar'] ?? sub.title['en'] ?? '',
                                  subtitle:
                                      sub.description['ar'] ??
                                      sub.description['en'] ??
                                      '',
                                  icon: _getIconForSubService(sub.title['en'] ?? ''),
                                  status: sub.status == ServiceStatus.active ? 'نشط' : 'غير نشط',
                                  statusBgColor: sub.status == ServiceStatus.active ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                  statusColor: sub.status == ServiceStatus.active ? const Color(0xFF166534) : const Color(0xFF64748B),
                                  progressColor: const Color(0xFF1E3A8A),
                                  booked: 0, 
                                  total: totalTechs,
                                  avatars: [],
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          )
                        else
                          const Center(
                            child: Text(
                              'لا توجد خدمات فرعية مسجلة',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () {},
                  backgroundColor: const Color(0xFF1E3A8A),
                  child: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
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
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'تفاصيل الخدمة',
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

  Widget _buildBreadcrumb() {
    return Row(
      children: [
        const Icon(Icons.home_outlined, size: 16, color: Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 10,
          color: Color(0xFF94A3B8),
        ),
        const SizedBox(width: 8),
        const Text(
          'الخدمات الرئيسية',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B8),
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 10,
          color: Color(0xFF94A3B8),
        ),
        const SizedBox(width: 8),
        Text(
          widget.categoryName,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.categoryName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'إدارة وتحسين القدرة التشغيلية لخدمات النظافة المتخصصة',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  IconData _getIconForSubService(String name) {
    name = name.toLowerCase();
    if (name.contains('deep')) return Icons.cleaning_services_rounded;
    if (name.contains('window')) return Icons.window_rounded;
    if (name.contains('carpet')) return Icons.dry_cleaning_rounded;
    if (name.contains('sanitiz')) return Icons.sanitizer_rounded;
    if (name.contains('garden')) return Icons.yard_rounded;
    return Icons.settings_suggest_rounded;
  }

  Widget _buildStatsRow(int totalTechs, int totalBooked) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'إجمالي الفرق',
            value: '$totalTechs',
            icon: Icons.groups_rounded,
            subtitle: 'المتاحين لليوم المختار',
            subtitleColor: const Color(0xFF059669),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'الطلبات النشطة',
            value: '$totalBooked',
            icon: Icons.receipt_long_rounded,
            subtitle: 'قيد المعالجة حالياً',
            subtitleColor: const Color(0xFF94A3B8),
            iconColor: const Color(0xFFD97706),
            iconBgColor: const Color(0xFFFEF3C7),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required String subtitle,
    required Color subtitleColor,
    Color iconColor = const Color(0xFF2563EB),
    Color iconBgColor = const Color(0xFFDBEAFE),
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: subtitleColor,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildSubServiceCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String status,
    required Color statusBgColor,
    required Color statusColor,
    required Color progressColor,
    required int booked,
    required int total,
    required List<String> avatars,
    int? extraAvatarsCount,
    String? noTeamsText,
  }) {
    return GestureDetector(
      onTap: () {
        final cubit = context.read<AdminDashboardCubit>();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: cubit,
              child: AdminSubServiceCapacityPage(subServiceName: title),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF0F172A), size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$booked / $total',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                  fontFamily: 'Cairo',
                ),
              ),
              const Text(
                'سعة الفرق الحالية',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : booked / total,
                backgroundColor: const Color(0xFFF1F5F9),
                color: progressColor,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF94A3B8), size: 14),
              if (noTeamsText != null)
                Text(
                  noTeamsText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontFamily: 'Cairo',
                  ),
                )
              else
                Row(
                  children: [
                    if (extraAvatarsCount != null)
                      Align(
                        widthFactor: 0.7,
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '+$extraAvatarsCount',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                          ),
                        ),
                      ),
                    for (int i = 0; i < avatars.length; i++)
                      Align(
                        widthFactor: (i == avatars.length - 1 && extraAvatarsCount == null) ? 1.0 : 0.7,
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            image: DecorationImage(
                              image: NetworkImage(avatars[i]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    ));
  }
}
