import 'package:equatable/equatable.dart';
import '../../domain/entities/monthly_financial_summary.dart';
import '../../domain/entities/admin_ledger_entry.dart';

abstract class AdminReportsState extends Equatable {
  const AdminReportsState();

  @override
  List<Object?> get props => [];
}

class AdminReportsInitial extends AdminReportsState {}

class AdminReportsLoading extends AdminReportsState {}

class AdminReportsLoaded extends AdminReportsState {
  final List<MonthlyFinancialSummary> summaries;
  final List<AdminLedgerEntry> ledgerEntries;
  final bool isActionInProgress;

  const AdminReportsLoaded({
    required this.summaries,
    required this.ledgerEntries,
    this.isActionInProgress = false,
  });

  AdminReportsLoaded copyWith({
    List<MonthlyFinancialSummary>? summaries,
    List<AdminLedgerEntry>? ledgerEntries,
    bool? isActionInProgress,
  }) {
    return AdminReportsLoaded(
      summaries: summaries ?? this.summaries,
      ledgerEntries: ledgerEntries ?? this.ledgerEntries,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
    );
  }

  @override
  List<Object?> get props => [
        summaries,
        ledgerEntries,
        isActionInProgress,
      ];
}

class AdminReportsError extends AdminReportsState {
  final String message;

  const AdminReportsError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AdminReportsActionSuccess extends AdminReportsState {
  final String message;

  const AdminReportsActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}
