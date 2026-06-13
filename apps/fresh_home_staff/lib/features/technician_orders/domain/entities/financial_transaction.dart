import 'package:equatable/equatable.dart';

enum FinancialTransactionType {
  order,       // Completed order
  collection,  // Technician paid company (credit to technician balance / reduces debt)
  payout       // Company paid technician (debit to technician balance / reduces credit)
}

class FinancialTransaction extends Equatable {
  final String id;
  final String title;
  final DateTime date;
  final double amount; // Net amount for technician (positive or negative)
  final FinancialTransactionType type;
  
  // Optional details for order type transactions
  final String? orderId;
  final String? serviceName;
  final double? totalOrderAmount;
  final double? commission;
  final double? techPayout;
  final bool? isCollectedByTechnician;

  const FinancialTransaction({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.type,
    this.orderId,
    this.serviceName,
    this.totalOrderAmount,
    this.commission,
    this.techPayout,
    this.isCollectedByTechnician,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        date,
        amount,
        type,
        orderId,
        serviceName,
        totalOrderAmount,
        commission,
        techPayout,
        isCollectedByTechnician,
      ];
}
