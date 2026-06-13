import '../../domain/entities/technician_financial_account.dart';

class TechnicianFinancialAccountModel extends TechnicianFinancialAccount {
  const TechnicianFinancialAccountModel({
    required super.id,
    required super.technicianId,
    required super.amountOwedToCompany,
    required super.amountOwedToTechnician,
    required super.debtLimit,
    required super.accountStatus,
    required super.netBalance,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TechnicianFinancialAccountModel.fromJson(Map<String, dynamic> json) {
    return TechnicianFinancialAccountModel(
      id: json['id'] as String,
      technicianId: json['technician_id'] as String,
      amountOwedToCompany: (json['amount_owed_to_company'] as num).toDouble(),
      amountOwedToTechnician: (json['amount_owed_to_technician'] as num).toDouble(),
      debtLimit: (json['debt_limit'] as num).toDouble(),
      accountStatus: json['account_status'] as String,
      netBalance: (json['net_balance'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'technician_id': technicianId,
      'amount_owed_to_company': amountOwedToCompany,
      'amount_owed_to_technician': amountOwedToTechnician,
      'debt_limit': debtLimit,
      'account_status': accountStatus,
      'net_balance': netBalance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
