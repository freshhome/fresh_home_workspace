import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';
import '../../domain/entities/financial_transaction.dart';
import '../../domain/entities/daily_order_group.dart';
import 'technician_orders_cubit.dart';
import 'technician_orders_state.dart';

abstract class FinancialState {}

class FinancialInitial extends FinancialState {}

class FinancialLoading extends FinancialState {}

class FinancialLoaded extends FinancialState {
  final double netBalance;
  final bool hasMoney; // true if netBalance >= 0, false if netBalance < 0
  final double weeklyEarnings;
  final double monthlyEarnings;
  final List<FinancialTransaction> transactions;
  final List<Map<String, dynamic>> dailyStats;

  FinancialLoaded({
    required this.netBalance,
    required this.hasMoney,
    required this.weeklyEarnings,
    required this.monthlyEarnings,
    required this.transactions,
    required this.dailyStats,
  });
}

class FinancialError extends FinancialState {
  final String message;
  FinancialError(this.message);
}

class FinancialCubit extends Cubit<FinancialState> {
  final TechnicianOrdersCubit ordersCubit;
  StreamSubscription? _ordersSubscription;

  FinancialCubit({required this.ordersCubit}) : super(FinancialInitial()) {
    _ordersSubscription = ordersCubit.stream.listen((state) {
      if (state is TechnicianOrdersLoaded) {
        _calculateFinancials(
          state.todayOrders,
          state.historyGroups,
          state.upcomingGroups,
        );
      }
    });

    // Initial calculation if already loaded
    if (ordersCubit.state is TechnicianOrdersLoaded) {
      final loaded = ordersCubit.state as TechnicianOrdersLoaded;
      _calculateFinancials(
        loaded.todayOrders,
        loaded.historyGroups,
        loaded.upcomingGroups,
      );
    }
  }

  void _calculateFinancials(
    List<Booking> todayOrders,
    List<DailyOrderGroup> historyGroups,
    List<DailyOrderGroup> upcomingGroups,
  ) {
    emit(FinancialLoading());

    try {
      // 1. Gather all completed bookings
      final List<Booking> allCompletedBookings = [];

      // Check today orders
      for (var o in todayOrders) {
        if (o.status == OrderStatus.completed) {
          allCompletedBookings.add(o);
        }
      }

      // Check history groups
      for (var group in historyGroups) {
        for (var o in group.orders) {
          if (o.status == OrderStatus.completed) {
            allCompletedBookings.add(o);
          }
        }
      }

      // Check upcoming groups
      for (var group in upcomingGroups) {
        for (var o in group.orders) {
          if (o.status == OrderStatus.completed) {
            allCompletedBookings.add(o);
          }
        }
      }

      // Sort completed bookings by completion date or scheduledAt descending
      allCompletedBookings.sort((a, b) {
        final aDate = a.completedAt ?? a.scheduledAt;
        final bDate = b.completedAt ?? b.scheduledAt;
        return bDate.compareTo(aDate);
      });

      // 2. Map completed bookings to FinancialTransaction
      final List<FinancialTransaction> transactions = [];

      for (var o in allCompletedBookings) {
        final double totalAmount = o.price.total;

        // Determine commission rate and platform commission/technician payout
        final double commissionRate =
            (o.price.metadata?['commission_rate'] as num?)?.toDouble() ?? 0.30;
        final double commission =
            (o.price.metadata?['platform_commission'] as num?)?.toDouble() ??
                (totalAmount * commissionRate);
        final double techPayout =
            (o.price.metadata?['technician_payout'] as num?)?.toDouble() ??
                (totalAmount * (1.0 - commissionRate));

        // Determine collection method:
        // If payment_method is 'cash' in pricingInputs, it was collected by technician.
        // Falls back to mock simulation for legacy bookings without explicit payment method.
        final bool isCollectedByTechnician = o.pricingInputs?['payment_method'] == 'cash' ||
            (o.pricingInputs?['payment_method'] == null && o.id.hashCode % 2 == 0);

        // If collected by tech (Cash): net amount is negative commission (owed to company)
        // If collected by company (Card/Online): net amount is positive techPayout (owed to tech)
        final double netAmount =
            isCollectedByTechnician ? -commission : techPayout;

        final title = o.service.name['ar'] ?? o.service.name['en'] ?? 'خدمة منزلية';

        transactions.add(
          FinancialTransaction(
            id: o.id,
            title: title,
            date: o.completedAt ?? o.scheduledAt,
            amount: netAmount,
            type: FinancialTransactionType.order,
            orderId: o.displayId,
            serviceName: title,
            totalOrderAmount: totalAmount,
            commission: commission,
            techPayout: techPayout,
            isCollectedByTechnician: isCollectedByTechnician,
          ),
        );
      }

      // 3. Add mock collections/payouts to show complete functionality
      final now = DateTime.now();

      // Mock 1: Technician paid commission to company (reduces his debt -> positive contribution)
      transactions.add(
        FinancialTransaction(
          id: 'tx-mock-1',
          title: 'تحصيل (تحويل للشركة)',
          date: now.subtract(const Duration(days: 2)),
          amount: 500.00,
          type: FinancialTransactionType.collection,
        ),
      );

      // Mock 2: Company transferred payout to technician (reduces company's debt to tech -> negative contribution)
      transactions.add(
        FinancialTransaction(
          id: 'tx-mock-2',
          title: 'تحصيل (تحويل من الشركة)',
          date: now.subtract(const Duration(days: 4)),
          amount: -400.00,
          type: FinancialTransactionType.payout,
        ),
      );

      // Sort all transactions by date descending
      transactions.sort((a, b) => b.date.compareTo(a.date));

      // 4. Calculate Net Balance
      final double netBalance = transactions.fold(
        0.0,
        (sum, tx) => sum + tx.amount,
      );
      final bool hasMoney = netBalance >= 0;

      // 5. Calculate Weekly and Monthly Earnings for completed orders
      final startOfToday = DateTime(now.year, now.month, now.day);
      final startOfWeek = startOfToday.subtract(
        Duration(days: now.weekday % 7),
      ); // Sunday/Saturday start
      final startOfMonth = DateTime(now.year, now.month, 1);

      double weeklyEarnings = 0.0;
      double monthlyEarnings = 0.0;

      for (var tx in transactions) {
        if (tx.type == FinancialTransactionType.order) {
          final double earningValue =
              tx.amount > 0
                  ? tx.amount
                  : (tx.totalOrderAmount ?? 0.0) - (tx.commission ?? 0.0);
          if (!tx.date.isBefore(startOfWeek)) {
            weeklyEarnings += earningValue;
          }
          if (!tx.date.isBefore(startOfMonth)) {
            monthlyEarnings += earningValue;
          }
        }
      }

      // 6. Calculate Daily Stats for the last 7 days ending today
      final List<Map<String, dynamic>> dailyStats = List.generate(7, (i) {
        final date = startOfToday.subtract(Duration(days: 6 - i));

        String dayAr = '';
        switch (date.weekday) {
          case DateTime.monday:
            dayAr = 'الاثنين';
            break;
          case DateTime.tuesday:
            dayAr = 'الثلاثاء';
            break;
          case DateTime.wednesday:
            dayAr = 'الأربعاء';
            break;
          case DateTime.thursday:
            dayAr = 'الخميس';
            break;
          case DateTime.friday:
            dayAr = 'الجمعة';
            break;
          case DateTime.saturday:
            dayAr = 'السبت';
            break;
          case DateTime.sunday:
            dayAr = 'الأحد';
            break;
        }

        // Sum technician earnings for this specific day from orders only
        double dayAmount = 0.0;
        int completedCount = 0;
        for (var tx in transactions) {
          if (tx.type == FinancialTransactionType.order &&
              tx.date.year == date.year &&
              tx.date.month == date.month &&
              tx.date.day == date.day) {
            final double earningValue =
                tx.amount > 0
                    ? tx.amount
                    : (tx.totalOrderAmount ?? 0.0) - (tx.commission ?? 0.0);
            dayAmount += earningValue;
            completedCount++;
          }
        }

        return {'day': dayAr, 'amount': dayAmount, 'completed': completedCount};
      });

      emit(
        FinancialLoaded(
          netBalance: netBalance,
          hasMoney: hasMoney,
          weeklyEarnings: weeklyEarnings,
          monthlyEarnings: monthlyEarnings,
          transactions: transactions,
          dailyStats: dailyStats,
        ),
      );
    } catch (e, stack) {
      debugPrint('❌ [FinancialCubit] Calculate Financials Error: $e\n$stack');
      emit(FinancialError('حدث خطأ أثناء احتساب البيانات المالية: $e'));
    }
  }

  @override
  Future<void> close() {
    _ordersSubscription?.cancel();
    return super.close();
  }
}
