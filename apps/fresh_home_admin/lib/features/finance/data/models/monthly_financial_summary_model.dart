import '../../domain/entities/monthly_financial_summary.dart';

class MonthlyFinancialSummaryModel extends MonthlyFinancialSummary {
  const MonthlyFinancialSummaryModel({
    required super.monthYear,
    required super.startOfMonth,
    required super.totalCompanyNetProfit,
    required super.totalCommissions,
    required super.totalCashCollected,
    required super.totalOnlineEarnings,
    required super.totalSettlementsApproved,
  });

  factory MonthlyFinancialSummaryModel.fromJson(Map<String, dynamic> json) {
    return MonthlyFinancialSummaryModel(
      monthYear: json['month_year'] as String,
      startOfMonth: DateTime.parse(json['start_of_month'] as String),
      totalCompanyNetProfit: (json['total_company_net_profit'] as num).toDouble(),
      totalCommissions: (json['total_commissions'] as num).toDouble(),
      totalCashCollected: (json['total_cash_collected'] as num).toDouble(),
      totalOnlineEarnings: (json['total_online_earnings'] as num).toDouble(),
      totalSettlementsApproved: (json['total_settlements_approved'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month_year': monthYear,
      'start_of_month': startOfMonth.toIso8601String(),
      'total_company_net_profit': totalCompanyNetProfit,
      'total_commissions': totalCommissions,
      'total_cash_collected': totalCashCollected,
      'total_online_earnings': totalOnlineEarnings,
      'total_settlements_approved': totalSettlementsApproved,
    };
  }
}
