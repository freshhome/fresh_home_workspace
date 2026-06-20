import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_features/shared_features.dart';
import 'package:shared/shared.dart';
import 'package:get_it/get_it.dart';
import '../../../technician_orders/presentation/routes/technician_orders_routes.dart';
import '../../../technician_orders/presentation/cubit/technician_orders_cubit.dart';
import '../../../technician_orders/presentation/cubit/technician_orders_state.dart';
import '../../../../features/finance/presentation/cubit/technician_finance_cubit.dart';
import '../../../../features/finance/presentation/cubit/technician_finance_state.dart';
import '../../../reviews/presentation/routes/technician_reviews_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final textTheme = Theme.of(context).extension<AppTextThemeExtension>()!;
    final l10n = AppLocalizations.of(context)!;

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
              // Header Section
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
              const SizedBox(height: 30),
              // Wallet Overview Card & Today's Stats
              BlocBuilder<TechnicianFinanceCubit, TechnicianFinanceState>(
                builder: (context, financialState) {
                  return BlocBuilder<TechnicianOrdersCubit, TechnicianOrdersState>(
                    builder: (context, ordersState) {
                      String jobsToday = '...';
                      String earningsToday = '...';
                      String completedJobsToday = '...';

                      if (ordersState is TechnicianOrdersLoaded) {
                        final now = DateTime.now();
                        final todayStart = DateTime(now.year, now.month, now.day);
                        final todayEnd = todayStart.add(const Duration(days: 1));

                        // Compile all bookings scheduled for today to get a complete daily view
                        final List<Booking> allTodayBookings = [];
                        
                        // 1. Active today bookings (scheduled for today, not completed/cancelled)
                        allTodayBookings.addAll(ordersState.todayOrders);

                        // 2. Completed/history bookings scheduled for today
                        for (var group in ordersState.historyGroups) {
                          for (var order in group.orders) {
                            if (!order.scheduledAt.isBefore(todayStart) &&
                                order.scheduledAt.isBefore(todayEnd)) {
                              allTodayBookings.add(order);
                            }
                          }
                        }

                        // 3. Cancelled bookings scheduled for today
                        for (var group in ordersState.cancelledGroups) {
                          for (var order in group.orders) {
                            if (!order.scheduledAt.isBefore(todayStart) &&
                                order.scheduledAt.isBefore(todayEnd)) {
                              allTodayBookings.add(order);
                            }
                          }
                        }

                        // Total today's orders (excluding cancelled)
                        final int activeOrCompletedCount = allTodayBookings
                            .where((o) => o.status != OrderStatus.cancelled)
                            .length;
                        jobsToday = activeOrCompletedCount.toString();

                        // Completed tasks today
                        final int completedCount = allTodayBookings
                            .where((o) => o.status == OrderStatus.completed)
                            .length;
                        completedJobsToday = completedCount.toString();

                        // Total earnings from completed today bookings
                        final double totalEarnings = allTodayBookings
                            .where((o) => o.status == OrderStatus.completed)
                            .fold(0.0, (sum, o) => sum + o.price.total);
                        earningsToday = totalEarnings.toStringAsFixed(0);
                      }

                      final profileState = context.watch<ProfileCubit>().state;
                      String rating = '5.0';

                      if (profileState is ProfileLoaded) {
                        final prof = profileState.profile;
                        rating = prof is TechnicianProfile ? prof.rating.toString() : '5.0';
                      }

                      final isAr = Localizations.localeOf(context).languageCode == 'ar';
                      final completedLabel = isAr ? 'المهام المنجزة اليوم' : 'Completed Today';
                      final todayEarningsLabel = isAr ? 'دخل اليوم' : 'Today Earnings';

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
                          // A. Wallet overview card
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
                          const SizedBox(height: 20),
                          // B. Today's stats 2x2 grid
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio: 1.4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            children: [
                              _buildStatCard(
                                context: context,
                                title: l10n.tech_stats_jobs_today,
                                value: jobsToday,
                                icon: Icons.assignment_rounded,
                                color: Colors.blue.shade700,
                              ),
                              _buildStatCard(
                                context: context,
                                title: todayEarningsLabel,
                                value: isAr ? '$earningsToday ج.م' : '$earningsToday EGP',
                                icon: Icons.payments_rounded,
                                color: Colors.green.shade700,
                                onTap: () => context.pushNamed(
                                  TechnicianOrdersRoutes.technicianFinancialPortal,
                                ),
                              ),
                              _buildStatCard(
                                context: context,
                                title: l10n.tech_stats_rating,
                                value: rating,
                                icon: Icons.star_rounded,
                                color: Colors.amber.shade700,
                              ),
                              _buildStatCard(
                                context: context,
                                title: completedLabel,
                                value: completedJobsToday,
                                icon: Icons.check_circle_rounded,
                                color: Colors.teal.shade700,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 30),
              // Quick Tools
              Text(
                l10n.tech_quick_tools_title,
                style: textTheme.textOverline.copyWith(
                  color: themeColor.secondaryText,
                  letterSpacing: 1.2,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildToolItem(
                    context,
                    Icons.account_balance_wallet_outlined,
                    l10n.tech_tool_wallet,
                    onTap: () => context.pushNamed(
                      TechnicianOrdersRoutes.technicianFinancialPortal,
                    ),
                  ),
                  _buildToolItem(
                    context,
                    Icons.calendar_today_outlined,
                    l10n.tech_tool_schedule,
                    onTap: () => context.pushNamed('smart_schedule'),
                  ),
                  _buildToolItem(
                    context,
                    Icons.star_outline_rounded,
                    l10n.tech_tool_reviews,
                    onTap: () => context.pushNamed(TechnicianReviewsRoutes.technicianReviews),
                  ),
                  _buildToolItem(
                    context,
                    Icons.headset_mic_outlined,
                    l10n.tech_tool_support,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Active Job Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.tech_active_job_title,
                    style: textTheme.textOverline.copyWith(
                      color: themeColor.secondaryText,
                      letterSpacing: 1.2,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: themeColor.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.tech_job_status_upcoming,
                      style: textTheme.textOverline.copyWith(
                        color: themeColor.primary,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Active Job Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: themeColor.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [themeColor.cardShadow],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'John Doe',
                                style: textTheme.titleSectionLarge.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Cairo',
                                  color: themeColor.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'AC Repair & Maintenance',
                                style: textTheme.textBodySecondary.copyWith(
                                  color: themeColor.secondaryText,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '14:00',
                          style: TextStyle(
                            color: themeColor.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Progress Indicator
                    Row(
                      children: [
                        _buildProgressStep(
                          context,
                          l10n.tech_job_status_accepted,
                          true,
                        ),
                        _buildProgressStep(
                          context,
                          l10n.tech_job_status_in_progress,
                          false,
                        ),
                        _buildProgressStep(
                          context,
                          l10n.tech_job_status_completed,
                          false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: MyCustomButton(
                            text: l10n.tech_action_view_details,
                            isOutlined: true,
                            borderColor: themeColor.primary,
                            height: 56,
                            borderRadius: 16,
                            leadingIcon: Icon(
                              Icons.info_outline_rounded,
                              color: themeColor.primary,
                              size: 18,
                            ),
                            textStyle: textTheme.textButton.copyWith(
                              color: themeColor.primary,
                              fontFamily: 'Cairo',
                            ),
                            onPressed: () {
                              // TODO: Navigate to Order Details
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MyCustomButton(
                            text: l10n.tech_action_start_job,
                            backgroundColor: themeColor.primary,
                            height: 56,
                            borderRadius: 16,
                            leadingIcon: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            textStyle: textTheme.textButton.copyWith(
                              color: Colors.white,
                              fontFamily: 'Cairo',
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildToolItem(
    BuildContext context,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    final themeColor = context.themeColor;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: themeColor.cardBackground,
              shape: BoxShape.circle,
              boxShadow: [themeColor.cardShadow],
            ),
            child: Icon(icon, color: themeColor.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: themeColor.textPrimary.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(BuildContext context, String label, bool isActive) {
    final themeColor = context.themeColor;
    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: isActive
                    ? Container()
                    : Divider(
                        color: themeColor.unselectedItem.withValues(alpha: 0.3),
                        thickness: 1.5,
                      ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isActive
                      ? themeColor.primary
                      : themeColor.unselectedItem.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Divider(
                  color: themeColor.unselectedItem.withValues(alpha: 0.3),
                  thickness: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              color: isActive ? themeColor.primary : themeColor.secondaryText,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final themeColor = context.themeColor;
    final cardWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.1),
          width: 1,
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
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: themeColor.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
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
