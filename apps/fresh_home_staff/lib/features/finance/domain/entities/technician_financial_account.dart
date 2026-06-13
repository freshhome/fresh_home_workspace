import 'package:equatable/equatable.dart';

class TechnicianFinancialAccount extends Equatable {
  final String id;
  final String technicianId;
  final double amountOwedToCompany;
  final double amountOwedToTechnician;
  final double debtLimit;
  final String accountStatus; // 'active', 'restricted', 'blocked'
  final double netBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TechnicianFinancialAccount({
    required this.id,
    required this.technicianId,
    required this.amountOwedToCompany,
    required this.amountOwedToTechnician,
    required this.debtLimit,
    required this.accountStatus,
    required this.netBalance,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        technicianId,
        amountOwedToCompany,
        amountOwedToTechnician,
        debtLimit,
        accountStatus,
        netBalance,
        createdAt,
        updatedAt,
      ];
}
