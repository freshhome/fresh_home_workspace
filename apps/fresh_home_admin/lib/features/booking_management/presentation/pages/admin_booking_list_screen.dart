import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:shared_features/shared_features.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cubit/admin_bookings_cubit.dart';
import 'package:intl/intl.dart';

class AdminBookingListScreen extends StatefulWidget {
  const AdminBookingListScreen({super.key});

  @override
  State<AdminBookingListScreen> createState() => _AdminBookingListScreenState();
}

class _AdminBookingListScreenState extends State<AdminBookingListScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Booking> _filterBookings(List<Booking> bookings) {
    if (_searchQuery.isEmpty) return bookings;
    return bookings.where((b) {
      final idMatch = b.displayId.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final nameMatch = b.contact.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      return idMatch || nameMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBookingsCubit, AdminBookingsState>(
      builder: (context, state) {
        int criticalCount = 0;
        if (state is AdminBookingsLoaded) {
          criticalCount = state.allBookings
              .where((b) => b.isCritical == true)
              .length;
        }

        return DefaultTabController(
          length: 5,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'ابحث برقم الطلب أو اسم العميل...',
                        hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 14),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    )
                  : const Text(
                      'إدارة الحجوزات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                      ),
                    ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close_rounded : Icons.search_rounded,
                    color: const Color(0xFF1E3A8A),
                  ),
                  onPressed: () {
                    setState(() {
                      if (_isSearching) {
                        _isSearching = false;
                        _searchQuery = '';
                        _searchController.clear();
                      } else {
                        _isSearching = true;
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
              ],
              bottom: TabBar(
                isScrollable: true,
                labelColor: Color(0xFF1E3A8A),
                unselectedLabelColor: Color(0xFF64748B),
                indicatorColor: Color(0xFF1E3A8A),
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(text: 'الكل'),
                  Tab(text: 'النشطة'),
                  Tab(text: 'المكتملة'),
                  Tab(text: 'الملغاة'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 6),
                        const Text('طارئ'),
                        if (criticalCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              criticalCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            body: Builder(
              builder: (context) {
                if (state is AdminBookingsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                  );
                }

                if (state is AdminBookingsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is AdminBookingsLoaded) {
                  final criticalBookings = _filterBookings(
                    state.allBookings
                        .where((b) => b.isCritical == true)
                        .toList(),
                  );

                  return TabBarView(
                    children: [
                      _BookingListView(
                        bookings: _filterBookings(state.allBookings),
                      ),
                      _BookingListView(
                        bookings: _filterBookings(state.activeBookings),
                      ),
                      _BookingListView(
                        bookings: _filterBookings(state.completedBookings),
                      ),
                      _BookingListView(
                        bookings: _filterBookings(state.cancelledBookings),
                      ),
                      _BookingListView(
                        bookings: criticalBookings,
                        isCritical: true,
                      ),
                    ],
                  );
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                final adminId =
                    Supabase.instance.client.auth.currentUser?.id ?? '';
                GoRouter.of(context).pushNamed(
                  AppRoutes.bookingFlow,
                  extra: BookingFlowConfig(
                    mode: BookingFlowMode.admin,
                    actorId: adminId,
                  ),
                );
              },
              backgroundColor: const Color(0xFF1E3A8A),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'حجز جديد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BookingListView extends StatelessWidget {
  final List<Booking> bookings;
  final bool isCritical;

  const _BookingListView({required this.bookings, this.isCritical = false});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<AdminBookingsCubit>().refreshBookings(),
        color: const Color(0xFF1E3A8A),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isCritical
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCritical
                        ? Icons.check_circle_outline_rounded
                        : Icons.assignment_outlined,
                    size: 48,
                    color: isCritical
                        ? const Color(0xFF10B981)
                        : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isCritical
                      ? 'لا يوجد حالات طارئة 🎉'
                      : 'لا يوجد حجوزات حالياً',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: isCritical
                        ? const Color(0xFF10B981)
                        : const Color(0xFF64748B),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AdminBookingsCubit>().refreshBookings(),
      color: const Color(0xFF1E3A8A),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _OrderCard(booking: booking);
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Booking booking;

  const _OrderCard({required this.booking});

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.created:
      case OrderStatus.pending:
        return const Color(0xFF64748B);
      case OrderStatus.assigned:
      case OrderStatus.accepted:
      case OrderStatus.ready:
        return const Color(0xFF1E3A8A);
      case OrderStatus.pendingInspection:
        return const Color(0xFF8B5CF6);
      case OrderStatus.onTheWay:
        return const Color(0xFFF59E0B);
      case OrderStatus.arrived:
        return const Color(0xFF06B6D4);
      case OrderStatus.inProgress:
        return const Color(0xFF3B82F6);
      case OrderStatus.completed:
        return const Color(0xFF10B981);
      case OrderStatus.cancelled:
      case OrderStatus.failed:
      case OrderStatus.failedNoShow:
      case OrderStatus.expired:
        return const Color(0xFFEF4444);
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.created:
        return 'جديد';
      case OrderStatus.pending:
        return 'بانتظار تعيين';
      case OrderStatus.assigned:
        return 'مسند لفني';
      case OrderStatus.accepted:
        return 'مقبول';
      case OrderStatus.ready:
        return 'جاهز للتنفيذ';
      case OrderStatus.onTheWay:
        return 'في الطريق';
      case OrderStatus.arrived:
        return 'وصل للموقع';
      case OrderStatus.inProgress:
        return 'قيد العمل';
      case OrderStatus.completed:
        return 'مكتمل';
      case OrderStatus.cancelled:
        return 'ملغي';
      case OrderStatus.failed:
        return 'فاشل';
      case OrderStatus.failedNoShow:
        return 'فشل (عدم حضور)';
      case OrderStatus.expired:
        return 'منتهي';
      case OrderStatus.pendingInspection:
        return 'بانتظار المعاينة';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => GoRouter.of(
            context,
          ).push('/admin/bookings/detail/${booking.id}', extra: booking),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              booking.status,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(booking.status),
                            style: TextStyle(
                              color: _getStatusColor(booking.status),
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (!booking.isWhatsappConfirmed) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB), // Amber 50
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFDE68A)), // Amber 200
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFD97706), // Amber 600
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'غير مؤكد',
                                  style: TextStyle(
                                    color: Color(0xFFD97706),
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '#${booking.displayId}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (booking.isCritical) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.criticalReason ?? 'حالة طوارئ غير محددة',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: Color(0xFFB91C1C),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      height: 54,
                      width: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: const Icon(
                        Icons.cleaning_services_rounded,
                        color: Color(0xFF1E3A8A),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.service.name['ar'] ?? 'خدمة غير معروفة',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            booking.contact.name,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Color(0xFFF1F5F9), height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('yyyy/MM/dd').format(booking.scheduledAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('hh:mm a').format(booking.scheduledAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${booking.price.total} ج.م',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E3A8A),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
