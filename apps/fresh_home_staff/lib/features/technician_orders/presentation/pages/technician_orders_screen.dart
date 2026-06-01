import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:shared/presentation/theme/components/colors/theme_colors.dart';
import '../cubit/technician_orders_cubit.dart';
import '../cubit/technician_orders_state.dart';
import '../widgets/technician_order_card.dart';
import '../widgets/day_summary_card.dart';

import '../../domain/entities/daily_order_group.dart';

class TechnicianOrdersScreen extends StatelessWidget {
  const TechnicianOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: themeColor.background,
        appBar: AppBar(
          title: Text(
            l10n.technician_orders_title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: themeColor.textPrimary,
              fontFamily: 'Cairo',
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: themeColor.textPrimary,
              size: 20,
            ),
            onPressed: () => context.go(AppRoutes.tabHome),
          ),
          backgroundColor: themeColor.background,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: themeColor.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: themeColor.primary,
            unselectedLabelColor: themeColor.secondaryText,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              fontFamily: 'Cairo',
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              fontFamily: 'Cairo',
            ),
            indicatorWeight: 3,
            tabs: [
              Tab(text: l10n.technician_orders_tab_upcoming),
              Tab(text: l10n.technician_orders_tab_today),
              Tab(text: l10n.technician_orders_tab_history),
            ],
          ),
        ),
        body: BlocBuilder<TechnicianOrdersCubit, TechnicianOrdersState>(
          builder: (context, state) {
            if (state is TechnicianOrdersLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: ThemeColors.primaryLight,
                ),
              );
            }

            if (state is TechnicianOrdersLoaded) {
              return TabBarView(
                children: [
                  _buildGroupedOrdersList(context, state.upcomingGroups),
                  _buildTodayOrdersList(context, state.todayOrders),
                  _buildGroupedOrdersList(context, state.historyGroups),
                ],
              );
            }

            if (state is TechnicianOrdersError) {
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
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<TechnicianOrdersCubit>().loadOrders(),
                      child: Text(AppLocalizations.of(context)!.general_retry),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildTodayOrdersList(BuildContext context, List<Booking> orders) {
    if (orders.isEmpty) return _buildEmptyState(context);

    return RefreshIndicator(
      onRefresh: () => context.read<TechnicianOrdersCubit>().loadOrders(),
      color: context.themeColor.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return TechnicianOrderCard(
            order: orders[index],
            showSensitiveData: true, // Today: Show ALL details
            onTap: () => _navigateToDetails(context, orders[index], true),
          );
        },
      ),
    );
  }

  Widget _buildGroupedOrdersList(
    BuildContext context,
    List<DailyOrderGroup> groups,
  ) {
    if (groups.isEmpty) return _buildEmptyState(context);
    return _GroupedOrdersListView(groups: groups);
  }

  Widget _buildEmptyState(BuildContext context) {
    final themeColor = context.themeColor;
    return RefreshIndicator(
      onRefresh: () => context.read<TechnicianOrdersCubit>().loadOrders(),
      color: themeColor.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.technician_orders_empty,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetails(
    BuildContext context,
    Booking order,
    bool showSensitive,
  ) {
    GoRouter.of(context).pushNamed(
      AppRoutes.orderDetails,
      pathParameters: {'id': order.id.toString()},
      extra: {
        'order': order,
        'showSensitiveDetails': showSensitive,
        'cubit': context.read<TechnicianOrdersCubit>(),
      },
    );
  }
}

class _GroupedOrdersListView extends StatefulWidget {
  final List<DailyOrderGroup> groups;
  const _GroupedOrdersListView({required this.groups});

  @override
  State<_GroupedOrdersListView> createState() => _GroupedOrdersListViewState();
}

class _GroupedOrdersListViewState extends State<_GroupedOrdersListView> {
  DateTime? _expandedDate;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<TechnicianOrdersCubit>().loadOrders(),
      color: context.themeColor.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.groups.length,
        itemBuilder: (context, index) {
          final group = widget.groups[index];
          final isExpanded =
              _expandedDate != null &&
              DateUtils.isSameDay(_expandedDate, group.date);

          return _DayGroupItem(
            group: group,
            isExpanded: isExpanded,
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedDate = null; // Collapse if already expanded
                } else {
                  _expandedDate =
                      group.date; // Expand this one (collapses others)
                }
              });
            },
          );
        },
      ),
    );
  }
}

class _DayGroupItem extends StatelessWidget {
  final DailyOrderGroup group;
  final bool isExpanded;
  final VoidCallback onTap;

  const _DayGroupItem({
    required this.group,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DaySummaryCard(
          date: group.date,
          orderCount: group.orderCount,
          totalAmount: group.totalAmount,
          isExpanded: isExpanded,
          onTap: onTap,
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: group.orders.map((order) {
              return TechnicianOrderCard(
                order: order,
                showSensitiveData: false, // Upcoming/History: HIDDEN details
                onTap: () => GoRouter.of(context).pushNamed(
                  AppRoutes.orderDetails,
                  pathParameters: {'id': order.id.toString()},
                  extra: {
                    'order': order,
                    'showSensitiveDetails': false,
                    'cubit': context.read<TechnicianOrdersCubit>(),
                  },
                ),
              );
            }).toList(),
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }
}
