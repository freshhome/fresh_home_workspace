import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:shared/presentation/theme/components/colors/theme_colors.dart';


import '../cubit/my_orders_cubit.dart';
import '../cubit/my_orders_state.dart';
import '../widgets/order_card.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)!.my_orders_title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
            onPressed: () => context.go(AppRoutes.tabHome),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: ThemeColors.primaryLight,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: ThemeColors.primaryLight,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: AppLocalizations.of(context)!.my_orders_tab_upcoming),
              Tab(text: AppLocalizations.of(context)!.my_orders_tab_today),
              Tab(text: AppLocalizations.of(context)!.my_orders_tab_history),
            ],
          ),
        ),
        body: BlocBuilder<MyOrdersCubit, MyOrdersState>(
          builder: (context, state) {
            if (state is MyOrdersLoading) {
              return Center(child: CircularProgressIndicator(color: ThemeColors.primaryLight));
            }

            if (state is MyOrdersLoaded) {
              return Stack(
                children: [
                  TabBarView(
                    children: [
                      _buildOrdersList(context, state.upcomingOrders),
                      _buildOrdersList(context, state.todayOrders),
                      _buildOrdersList(context, state.historyOrders),
                    ],
                  ),
                  if (state.isUpdating)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: ThemeColors.primaryLight,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }

            if (state is MyOrdersError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    MyCustomButton(
                      onPressed: () => context.read<MyOrdersCubit>().loadOrders(),
                      text: AppLocalizations.of(context)!.general_retry,
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

  Widget _buildOrdersList(BuildContext context, List<Booking> orders) {
    return RefreshIndicator(
      color: ThemeColors.primaryLight,
      onRefresh: () async {
        await context.read<MyOrdersCubit>().loadOrders();
      },
      child: orders.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.my_orders_empty,
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return OrderCard(order: orders[index]);
              },
            ),
    );
  }
}

