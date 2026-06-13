import 'package:equatable/equatable.dart';

class MonthlyFinancialSummary extends Equatable {
  final String monthYear;
  final DateTime startOfMonth;
  final double totalCompanyNetProfit;
  final double totalCommissions;
  final double totalCashCollected;
  final double totalOnlineEarnings;
  final double totalSettlementsApproved;

  const MonthlyFinancialSummary({
    required this.monthYear,
    required this.startOfMonth,
    required this.totalCompanyNetProfit,
    required this.totalCommissions,
    required this.totalCashCollected,
    required this.totalOnlineEarnings,
    required this.totalSettlementsApproved,
  });

  @override
  List<Object?> get props => [
        monthYear,
        startOfMonth,
        totalCompanyNetProfit,
        totalCommissions,
        totalCashCollected,
        totalOnlineEarnings,
        totalSettlementsApproved,
      ];
}
