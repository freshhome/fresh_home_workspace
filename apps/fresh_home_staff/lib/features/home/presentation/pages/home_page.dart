import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_features/shared_features.dart';
import 'package:shared/shared.dart';
import 'package:get_it/get_it.dart';
import '../../../technician_orders/presentation/routes/technician_orders_routes.dart';
import '../../../technician_orders/presentation/cubit/technician_orders_cubit.dart';
import '../../../technician_orders/presentation/cubit/technician_orders_state.dart';
import '../../../technician_orders/presentation/widgets/technician_order_card.dart';
import '../../../../features/finance/presentation/cubit/technician_finance_cubit.dart';
import '../../../../features/finance/presentation/cubit/technician_finance_state.dart';
import '../../../reviews/presentation/routes/technician_reviews_routes.dart';
import '../../../technician_schedule/presentation/routes/technician_schedule_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final textTheme = Theme.of(context).extension<AppTextThemeExtension>()!;
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return MultiBlocProvider(
      providers: [
        BlocProvider<TechnicianOrdersCubit>.value(
          value: GetIt.instance<TechnicianOrdersCubit>()..loadOrders(),
        ),
        BlocProvider<TechnicianFinanceCubit>.value(
          value: GetIt.instance<TechnicianFinanceCubit>()..loadFinancialData(),
        ),
      ],
      child: Scaffold(
        backgroundColor: themeColor.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Header Section (User Avatar, Greeting & Notifications)
                BlocBuilder<ProfileCubit, ProfileState>(
                  builder: (context, state) {
                    String userName = '';
                    String? avatarUrl;
                    if (state is ProfileLoaded) {
                      userName = state.profile.firstName;
                      avatarUrl = state.profile.avatarUrl;
                    } else if (state is ProfileLoading) {
                      userName = '...';
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFE2E8F0),
                          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null || avatarUrl.isEmpty
                              ? const Icon(
                                  Icons.person_rounded,
                                  size: 32,
                                  color: Color(0xFF94A3B8),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.tech_greeting_morning,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.textBodySecondary.copyWith(
                                  color: themeColor.secondaryText,
                                  fontSize: 12,
                                  height: 1.2,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              Text(
                                userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleDisplaySmall.copyWith(
                                  height: 1.0,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Cairo',
                                  color: themeColor.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => context.pushNamed(AppRoutes.notifications),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: themeColor.cardBackground,
                              shape: BoxShape.circle,
                              boxShadow: [themeColor.cardShadow],
                            ),
                            child: Stack(
                              children: [
                                Icon(
                                  Icons.notifications_none_outlined,
                                  color: themeColor.textPrimary,
                                  size: 22,
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Wallet Overview Card & 4 Summary Cards
                BlocBuilder<TechnicianFinanceCubit, TechnicianFinanceState>(
                  builder: (context, financialState) {
                    return BlocBuilder<TechnicianOrdersCubit, TechnicianOrdersState>(
                      builder: (context, ordersState) {
                        int jobsTodayCount = 0;
                        int completedJobsCount = 0;
                        int remainingJobsCount = 0;
                        double totalEarnings = 0.0;

                        if (ordersState is TechnicianOrdersLoaded) {
                          final now = DateTime.now();
                          final todayStart = DateTime(now.year, now.month, now.day);
                          final todayEnd = todayStart.add(const Duration(days: 1));

                          final List<Booking> allTodayBookings = [];
                          allTodayBookings.addAll(ordersState.todayOrders);

                          for (var group in ordersState.historyGroups) {
                            for (var order in group.orders) {
                              if (!order.scheduledAt.isBefore(todayStart) &&
                                  order.scheduledAt.isBefore(todayEnd)) {
                                allTodayBookings.add(order);
                              }
                            }
                          }

                          for (var group in ordersState.cancelledGroups) {
                            for (var order in group.orders) {
                              if (!order.scheduledAt.isBefore(todayStart) &&
                                  order.scheduledAt.isBefore(todayEnd)) {
                                allTodayBookings.add(order);
                              }
                            }
                          }

                          jobsTodayCount = allTodayBookings
                              .where((o) => o.status != OrderStatus.cancelled)
                              .length;

                          completedJobsCount = allTodayBookings
                              .where((o) => o.status == OrderStatus.completed)
                              .length;

                          remainingJobsCount = (jobsTodayCount - completedJobsCount).clamp(0, 999);

                          totalEarnings = allTodayBookings
                              .where((o) => o.status == OrderStatus.completed)
                              .fold(0.0, (sum, o) => sum + o.price.total);
                        }

                        final profileState = context.watch<ProfileCubit>().state;
                        String rating = '5.0';
                        if (profileState is ProfileLoaded) {
                          final prof = profileState.profile;
                          rating = prof is TechnicianProfile ? prof.rating.toString() : '5.0';
                        }

                        // Wallet balance calculation
                        double netBalance = 0.0;
                        bool hasMoney = true;
                        bool isWalletLoaded = false;

                        if (financialState is TechnicianFinanceLoaded) {
                          netBalance = financialState.account.netBalance;
                          hasMoney = financialState.account.netBalance >= 0;
                          isWalletLoaded = true;
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // A. Wallet Overview Card
                            GestureDetector(
                              onTap: () => context.pushNamed(
                                TechnicianOrdersRoutes.technicianFinancialPortal,
                              ),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: !isWalletLoaded
                                        ? [
                                            themeColor.primary.withValues(alpha: 0.8),
                                            themeColor.primary.withValues(alpha: 0.6),
                                          ]
                                        : hasMoney
                                            ? [
                                                themeColor.primary,
                                                themeColor.primary.withValues(alpha: 0.8),
                                              ]
                                            : [
                                                const Color(0xFFDC2626),
                                                const Color(0xFF991B1B),
                                              ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (!isWalletLoaded
                                              ? themeColor.primary
                                              : hasMoney
                                                  ? themeColor.primary
                                                  : const Color(0xFFDC2626))
                                          .withValues(alpha: 0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    )
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isAr ? 'رصيدي الحالي' : 'My Balance',
                                            style: const TextStyle(
                                              fontFamily: 'Cairo',
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            !isWalletLoaded
                                                ? '... ج.م'
                                                : '${netBalance.abs().toStringAsFixed(0)} ج.م',
                                            style: const TextStyle(
                                              fontFamily: 'Cairo',
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              !isWalletLoaded
                                                  ? (isAr ? 'جاري التحميل...' : 'Loading...')
                                                  : hasMoney
                                                      ? (isAr ? 'متاح للسحب' : 'Available for withdrawal')
                                                      : (isAr ? 'مستحق للشركة' : 'Due to company'),
                                              style: const TextStyle(
                                                fontFamily: 'Cairo',
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // B. 4 Summary Cards Grid
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              childAspectRatio: 1.15,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              children: [
                                // Card 1: Today's Orders & Completion (Merged) -> Navigates to Technician Orders
                                _buildEnhancedStatCard(
                                  context: context,
                                  title: isAr ? 'طلبات اليوم' : 'Today Orders',
                                  value: '$jobsTodayCount',
                                  subtitle: isAr
                                      ? 'المنجز: $completedJobsCount • الباقي: $remainingJobsCount'
                                      : 'Done: $completedJobsCount • Left: $remainingJobsCount',
                                  icon: Icons.assignment_turned_in_rounded,
                                  color: Colors.blue.shade700,
                                  onTap: () => context.go(AppRoutes.technicianOrders),
                                ),

                                // Card 2: Today's Income -> Navigates to Financial Portal (رصيدي)
                                _buildEnhancedStatCard(
                                  context: context,
                                  title: isAr ? 'دخل اليوم' : 'Today Income',
                                  value: '${totalEarnings.toStringAsFixed(0)} ج.م',
                                  subtitle: isAr ? 'عرض محفظتي ورصيدي' : 'View My Wallet',
                                  icon: Icons.payments_rounded,
                                  color: Colors.green.shade700,
                                  onTap: () => context.pushNamed(
                                    TechnicianOrdersRoutes.technicianFinancialPortal,
                                  ),
                                ),

                                // Card 3: Rating & Reviews -> Navigates to Reviews
                                _buildEnhancedStatCard(
                                  context: context,
                                  title: isAr ? 'تقييم العملاء' : 'Customer Rating',
                                  value: '$rating ★',
                                  subtitle: isAr ? 'آراء العملاء وملاحظاتهم' : 'View Reviews',
                                  icon: Icons.star_rounded,
                                  color: Colors.amber.shade700,
                                  onTap: () => context.pushNamed(
                                    TechnicianReviewsRoutes.technicianReviews,
                                  ),
                                ),

                                // Card 4: My Schedule (جدولي) -> Navigates to Smart Schedule
                                _buildEnhancedStatCard(
                                  context: context,
                                  title: isAr ? 'جدولي ومواعيدي' : 'My Schedule',
                                  value: isAr ? 'عرض الجدول' : 'Open Schedule',
                                  subtitle: isAr ? 'إدارة الشيفتات والسعة' : 'Manage Shifts',
                                  icon: Icons.calendar_month_rounded,
                                  color: Colors.indigo.shade700,
                                  onTap: () => context.pushNamed(
                                    TechnicianScheduleRoutes.smartSchedule,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Active Tasks Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? 'المهمات النشطة اليوم' : 'Active Tasks Today',
                      style: textTheme.textOverline.copyWith(
                        color: themeColor.secondaryText,
                        letterSpacing: 1.1,
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.technicianOrders),
                      child: Text(
                        isAr ? 'عرض الكل' : 'View All',
                        style: TextStyle(
                          color: themeColor.primary,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Dynamic Active Tasks (From TechnicianOrdersCubit)
                BlocBuilder<TechnicianOrdersCubit, TechnicianOrdersState>(
                  builder: (context, ordersState) {
                    if (ordersState is TechnicianOrdersLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (ordersState is TechnicianOrdersLoaded) {
                      final activeOrders = ordersState.todayOrders;

                      if (activeOrders.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                          decoration: BoxDecoration(
                            color: themeColor.cardBackground,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [themeColor.cardShadow],
                            border: Border.all(
                              color: themeColor.unselectedItem.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: themeColor.primary.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.task_alt_rounded,
                                  size: 36,
                                  color: themeColor.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isAr ? 'لا توجد مهمات نشطة حالياً اليوم' : 'No active tasks today',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: themeColor.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAr
                                    ? 'يمكنك متابعة جدولك أو تصفح كافة الطلبات من قائمة الطلبات'
                                    : 'You can check your schedule or view all orders in orders tab',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: themeColor.secondaryText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activeOrders.length,
                        itemBuilder: (context, index) {
                          final order = activeOrders[index];
                          return TechnicianOrderCard(
                            order: order,
                            onTap: () {
                              context.pushNamed(
                                AppRoutes.orderDetails,
                                pathParameters: {'id': order.id},
                                extra: {
                                  'cubit': context.read<TechnicianOrdersCubit>(),
                                  'order': order,
                                },
                              );
                            },
                          );
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final themeColor = context.themeColor;
    final cardWidget = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: themeColor.secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: themeColor.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: themeColor.secondaryText.withValues(alpha: 0.8),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: cardWidget,
      );
    }
    return cardWidget;
  }
}
