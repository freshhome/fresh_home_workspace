import '../../domain/entities/admin_ledger_entry.dart';

class AdminLedgerEntryModel extends AdminLedgerEntry {
  const AdminLedgerEntryModel({
    required super.id,
    required super.accountId,
    required super.technicianName,
    super.bookingId,
    super.adjustmentId,
    required super.entryType,
    required super.debit,
    required super.credit,
    required super.runningBalance,
    required super.description,
    required super.referenceId,
    required super.referenceType,
    super.createdBy,
    required super.createdAt,
  });

  factory AdminLedgerEntryModel.fromJson(Map<String, dynamic> json) {
    final accountMap = json['technician_financial_accounts'] as Map<String, dynamic>?;
    final profileMap = accountMap?['profiles'] as Map<String, dynamic>?;
    final firstName = profileMap?['first_name'] as String? ?? '';
    final lastName = profileMap?['last_name'] as String? ?? '';
    final techName = '$firstName $lastName'.trim();

    return AdminLedgerEntryModel(
      id: json['id'] as String,
      accountId: json['account_id'] as String,
      technicianName: techName.isNotEmpty ? techName : 'فني مجهول',
      bookingId: json['booking_id'] as String?,
      adjustmentId: json['adjustment_id'] as String?,
      entryType: json['entry_type'] as String,
      debit: (json['debit'] as num).toDouble(),
      credit: (json['credit'] as num).toDouble(),
      runningBalance: (json['running_balance'] as num).toDouble(),
      description: json['description'] as String? ?? '',
      referenceId: json['reference_id'] as String,
      referenceType: json['reference_type'] as String,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_id': accountId,
      'booking_id': bookingId,
      'adjustment_id': adjustmentId,
      'entry_type': entryType,
      'debit': debit,
      'credit': credit,
      'running_balance': runningBalance,
      'description': description,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
