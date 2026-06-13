import 'package:equatable/equatable.dart';

class AdminLedgerEntry extends Equatable {
  final String id;
  final String accountId;
  final String technicianName;
  final String? bookingId;
  final String? adjustmentId;
  final String entryType;
  final double debit;
  final double credit;
  final double runningBalance;
  final String description;
  final String referenceId;
  final String referenceType;
  final String? createdBy;
  final DateTime createdAt;

  const AdminLedgerEntry({
    required this.id,
    required this.accountId,
    required this.technicianName,
    this.bookingId,
    this.adjustmentId,
    required this.entryType,
    required this.debit,
    required this.credit,
    required this.runningBalance,
    required this.description,
    required this.referenceId,
    required this.referenceType,
    this.createdBy,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        accountId,
        technicianName,
        bookingId,
        adjustmentId,
        entryType,
        debit,
        credit,
        runningBalance,
        description,
        referenceId,
        referenceType,
        createdBy,
        createdAt,
      ];
}
