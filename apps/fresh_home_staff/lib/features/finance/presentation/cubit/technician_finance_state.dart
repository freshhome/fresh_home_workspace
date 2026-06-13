import 'package:equatable/equatable.dart';
import '../../domain/entities/technician_financial_account.dart';
import '../../domain/entities/ledger_entry.dart';

abstract class TechnicianFinanceState extends Equatable {
  const TechnicianFinanceState();

  @override
  List<Object?> get props => [];
}

class TechnicianFinanceInitial extends TechnicianFinanceState {}

class TechnicianFinanceLoading extends TechnicianFinanceState {}

class TechnicianFinanceLoaded extends TechnicianFinanceState {
  final TechnicianFinancialAccount account;
  final List<LedgerEntry> ledgerEntries;

  const TechnicianFinanceLoaded({
    required this.account,
    required this.ledgerEntries,
  });

  @override
  List<Object?> get props => [account, ledgerEntries];
}

class TechnicianFinanceActionLoading extends TechnicianFinanceState {}

class TechnicianFinanceActionSuccess extends TechnicianFinanceState {}

class TechnicianFinanceError extends TechnicianFinanceState {
  final String message;

  const TechnicianFinanceError(this.message);

  @override
  List<Object?> get props => [message];
}
