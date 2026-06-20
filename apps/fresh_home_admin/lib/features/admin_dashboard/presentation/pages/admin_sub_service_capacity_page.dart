import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:shared/shared.dart';
import '../cubit/admin_dashboard_cubit.dart';
import '../cubit/admin_dashboard_state.dart';
import '../../domain/entities/technician_capacity_entry.dart';

class AdminSubServiceCapacityPage extends StatelessWidget {
  final String subServiceName;

  const AdminSubServiceCapacityPage({
    super.key,
    this.subServiceName = 'تنظيف عميق',
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        if (state is AdminDashboardLoading || (state is AdminDashboardLoaded && state.isActionInProgress)) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
          );
        }

        List<TechnicianCapacityEntry> technicians = [];
        int totalCap = 0;
        int totalBooked = 0;
        int availableTeams = 0;

        if (state is AdminDashboardLoaded) {
          technicians = state.selectedDateTechnicians;
          for (var tech in technicians) {
            totalCap += tech.capacity;
            totalBooked += tech.workload;
            if (tech.status == 'متاح' || tech.status == 'active' || tech.status == 'في الميدان') {
              availableTeams++;
            }
          }
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: _buildAppBar(context),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBreadcrumb(subServiceName),
                  const SizedBox(height: 16),
                  _buildHeader(subServiceName),
                  const SizedBox(height: 24),
                  _buildSummaryCards(totalCap, totalBooked, availableTeams),
                  const SizedBox(height: 32),
                  const Text(
                    'الفرق والفنيين المتاحين',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (technicians.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Text(
                          'لا يوجد فنيين مسجلين لهذا اليوم',
                          style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF64748B)),
                        ),
                      ),
                    )
                  else
                    ...technicians.map((tech) => Column(
                          children: [
                            _buildTechnicianCard(
                              technicianId: tech.technicianId,
                              name: tech.technicianName,
                              role: 'فني متخصص', // Generic as not in entity
                              avatarUrl: 'https://i.pravatar.cc/150?u=${tech.technicianId}',
                              status: tech.status,
                              statusColor: _getStatusColor(tech.status),
                              statusBgColor: _getStatusBgColor(tech.status),
                              bookedSlots: tech.workload,
                              totalSlots: tech.capacity,
                              timeSlots: _generateMockTimeSlots(tech.workload, tech.capacity),
                            ),
                            const SizedBox(height: 16),
                          ],
                        )),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'مكتمل' || status == 'full') return const Color(0xFF1E3A8A);
    if (status == 'متاح' || status == 'active') return const Color(0xFF059669);
    return const Color(0xFFD97706); // Busy / In Field
  }

  Color _getStatusBgColor(String status) {
    if (status == 'مكتمل' || status == 'full') return const Color(0xFFDBEAFE);
    if (status == 'متاح' || status == 'active') return const Color(0xFFD1FAE5);
    return const Color(0xFFFEF3C7);
  }

  List<Map<String, dynamic>> _generateMockTimeSlots(int booked, int total) {
    List<Map<String, dynamic>> slots = [];
    final times = ['09:00 ص', '12:00 م', '03:00 م', '06:00 م'];
    for (int i = 0; i < total && i < times.length; i++) {
      String status = 'available';
      if (i < booked) {
        status = booked == total ? 'completed' : 'booked';
      }
      slots.add({'time': times[i], 'status': status});
    }
    return slots;
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'إدارة السعة التشغيلية',
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

  Widget _buildBreadcrumb(String subServiceName) {
    return Row(
      children: [
        const Icon(Icons.home_outlined, size: 16, color: Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        const Icon(Icons.arrow_back_ios_new_rounded, size: 10, color: Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        const Text('خدمات التنظيف', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontFamily: 'Cairo')),
        const SizedBox(width: 8),
        const Icon(Icons.arrow_back_ios_new_rounded, size: 10, color: Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Text(subServiceName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontFamily: 'Cairo')),
      ],
    );
  }

  Widget _buildHeader(String subServiceName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.cleaning_services_rounded, color: Color(0xFF1E3A8A), size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subServiceName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'متابعة حالة الفرق وسعة الحجوزات المتاحة لهذا اليوم',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(int totalCap, int booked, int available) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            title: 'السعة الإجمالية',
            value: '$totalCap',
            subtitle: 'فترات متاحة',
            icon: Icons.speed_rounded,
            color: const Color(0xFF2563EB),
            bgColor: const Color(0xFFDBEAFE),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            title: 'المحجوز',
            value: '$booked',
            subtitle: 'طلبات مؤكدة',
            icon: Icons.bookmark_added_rounded,
            color: const Color(0xFF059669),
            bgColor: const Color(0xFFD1FAE5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            title: 'الفرق المتاحة',
            value: '$available',
            subtitle: 'فنيين جاهزين',
            icon: Icons.engineering_rounded,
            color: const Color(0xFFD97706),
            bgColor: const Color(0xFFFEF3C7),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE2E8F0).withValues(alpha:0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF94A3B8),
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianCard({
    required String technicianId,
    required String name,
    required String role,
    required String avatarUrl,
    required String status,
    required Color statusColor,
    required Color statusBgColor,
    required int bookedSlots,
    required int totalSlots,
    required List<Map<String, dynamic>> timeSlots,
  }) {
    final getUserByIdUseCase = GetIt.instance<GetUserByIdUseCase>();

    return FutureBuilder<Either<Failure, UserProfile>>(
      future: getUserByIdUseCase(uid: technicianId),
      builder: (context, snapshot) {
        double ratingVal = 5.0;
        if (snapshot.hasData) {
          snapshot.data!.fold(
            (failure) {},
            (profile) {
              if (profile is TechnicianProfile) {
                ratingVal = profile.rating;
              }
            },
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE2E8F0).withValues(alpha:0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(avatarUrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  fontFamily: 'Cairo',
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                role,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontFamily: 'Cairo',
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              ratingVal.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'استهلاك السعة',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Text(
                    '$bookedSlots / $totalSlots محجوز',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: timeSlots.asMap().entries.map((entry) {
                  final index = entry.key;
                  final slot = entry.value;
                  final isBooked = slot['status'] == 'booked';
                  final isCompleted = slot['status'] == 'completed';
                  final isAvailable = slot['status'] == 'available';

                  Color slotColor;
                  Color slotBorderColor;
                  IconData? slotIcon;

                  if (isBooked) {
                    slotColor = const Color(0xFFDBEAFE);
                    slotBorderColor = const Color(0xFF3B82F6);
                    slotIcon = Icons.schedule_rounded;
                  } else if (isCompleted) {
                    slotColor = const Color(0xFFD1FAE5);
                    slotBorderColor = const Color(0xFF10B981);
                    slotIcon = Icons.check_circle_outline_rounded;
                  } else {
                    slotColor = const Color(0xFFF8FAFC);
                    slotBorderColor = const Color(0xFFE2E8F0);
                    slotIcon = null;
                  }

                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(left: index == timeSlots.length - 1 ? 0 : 8),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: slotColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: slotBorderColor),
                      ),
                      child: Column(
                        children: [
                          if (slotIcon != null)
                            Icon(slotIcon, size: 14, color: slotBorderColor)
                          else
                            const SizedBox(height: 14),
                          const SizedBox(height: 4),
                          Text(
                            slot['time']!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isAvailable ? const Color(0xFF94A3B8) : slotBorderColor,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
