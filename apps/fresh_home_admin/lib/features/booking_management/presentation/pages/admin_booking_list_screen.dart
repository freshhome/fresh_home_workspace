import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:shared_features/shared_features.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cubit/admin_bookings_cubit.dart';
import '../cubit/admin_booking_drafts_cubit.dart';
import '../widgets/admin_booking_drafts_sheet.dart';
import '../widgets/admin_booking_card.dart';

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

  bool _isSameDay(DateTime a, DateTime b) {
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBookingsCubit, AdminBookingsState>(
      builder: (context, state) {
        int criticalCount = 0;
        int todayCount = 0;
        int tomorrowCount = 0;

        if (state is AdminBookingsLoaded) {
          final now = DateTime.now();
          final tomorrow = now.add(const Duration(days: 1));

          criticalCount = state.allBookings
              .where((b) => b.isCritical == true)
              .length;

          todayCount = state.allBookings
              .where((b) => _isSameDay(b.scheduledAt, now))
              .length;

          tomorrowCount = state.allBookings
              .where((b) => _isSameDay(b.scheduledAt, tomorrow))
              .length;
        }

        return DefaultTabController(
          length: 6,
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
                BlocBuilder<AdminBookingDraftsCubit, AdminBookingDraftsState>(
                  builder: (context, draftState) {
                    int count = 0;
                    if (draftState is AdminBookingDraftsLoaded) {
                      count = draftState.drafts.length;
                    }
                    return IconButton(
                      tooltip: 'المسودات المعلقة ($count)',
                      icon: Badge(
                        isLabelVisible: count > 0,
                        backgroundColor: const Color(0xFFF59E0B),
                        label: Text(
                          '$count',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                        child: const Icon(
                          Icons.assignment_late_outlined,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      onPressed: () => AdminBookingDraftsSheet.show(context),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: const Color(0xFF1E3A8A),
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: const Color(0xFF1E3A8A),
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
                tabs: [
                  // 1. اليوم
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('اليوم'),
                        if (todayCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              todayCount.toString(),
                              style: const TextStyle(
                                color: Color(0xFF1E3A8A),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 2. غداً
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('غداً'),
                        if (tomorrowCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF64748B).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              tomorrowCount.toString(),
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 3. طارئ
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
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

                  // 4. الكل
                  const Tab(text: 'الكل'),

                  // 5. المكتملة
                  const Tab(text: 'المكتملة'),

                  // 6. الملغاة
                  const Tab(text: 'الملغاة'),
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
                  final now = DateTime.now();
                  final tomorrow = now.add(const Duration(days: 1));

                  final todayBookings = state.allBookings
                      .where((b) => _isSameDay(b.scheduledAt, now))
                      .toList();

                  final tomorrowBookings = state.allBookings
                      .where((b) => _isSameDay(b.scheduledAt, tomorrow))
                      .toList();

                  final criticalBookings = state.allBookings
                      .where((b) => b.isCritical == true)
                      .toList();

                  return TabBarView(
                    children: [
                      // 1. اليوم
                      _BookingListView(
                        bookings: _filterBookings(todayBookings),
                        emptyMessage: 'لا توجد حجوزات مجدولة لليوم',
                      ),

                      // 2. غداً
                      _BookingListView(
                        bookings: _filterBookings(tomorrowBookings),
                        emptyMessage: 'لا توجد حجوزات مجدولة لغداً',
                      ),

                      // 3. طارئ
                      _BookingListView(
                        bookings: _filterBookings(criticalBookings),
                        isCritical: true,
                        emptyMessage: 'لا يوجد حالات طارئة 🎉',
                      ),

                      // 4. الكل
                      _BookingListView(
                        bookings: _filterBookings(state.allBookings),
                        emptyMessage: 'لا توجد أي حجوزات حالياً',
                      ),

                      // 5. المكتملة
                      _BookingListView(
                        bookings: _filterBookings(state.completedBookings),
                        emptyMessage: 'لا توجد حجوزات مكتملة',
                      ),

                      // 6. الملغاة
                      _BookingListView(
                        bookings: _filterBookings(state.cancelledBookings),
                        emptyMessage: 'لا توجد حجوزات ملغاة',
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
                ).then((_) {
                  if (context.mounted) {
                    context.read<AdminBookingDraftsCubit>().loadDrafts();
                  }
                });
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
  final String? emptyMessage;

  const _BookingListView({
    required this.bookings,
    this.isCritical = false,
    this.emptyMessage,
  });

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
                  emptyMessage ??
                      (isCritical
                          ? 'لا يوجد حالات طارئة 🎉'
                          : 'لا يوجد حجوزات حالياً'),
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
          return AdminBookingCard(booking: booking);
        },
      ),
    );
  }
}
