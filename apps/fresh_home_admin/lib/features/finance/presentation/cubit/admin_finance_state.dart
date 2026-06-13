import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_settlement_request.dart';
import '../../domain/entities/admin_financial_case.dart';
import '../../domain/entities/admin_technician_account.dart';

abstract class AdminFinanceState extends Equatable {
  const AdminFinanceState();

  @override
  List<Object?> get props => [];
}

class AdminFinanceInitial extends AdminFinanceState {}

class AdminFinanceLoading extends AdminFinanceState {}

class AdminFinanceLoaded extends AdminFinanceState {
  final List<AdminSettlementRequest> settlementRequests;
  final List<AdminFinancialCase> financialCases;
  final List<AdminTechnicianAccount> technicianAccounts;
  final bool isActionInProgress;

  const AdminFinanceLoaded({
    required this.settlementRequests,
    required this.financialCases,
    required this.technicianAccounts,
    this.isActionInProgress = false,
  });

  AdminFinanceLoaded copyWith({
    List<AdminSettlementRequest>? settlementRequests,
    List<AdminFinancialCase>? financialCases,
    List<AdminTechnicianAccount>? technicianAccounts,
    bool? isActionInProgress,
  }) {
    return AdminFinanceLoaded(
      settlementRequests: settlementRequests ?? this.settlementRequests,
      financialCases: financialCases ?? this.financialCases,
      technicianAccounts: technicianAccounts ?? this.technicianAccounts,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
    );
  }

  @override
  List<Object?> get props => [
        settlementRequests,
        financialCases,
        technicianAccounts,
        isActionInProgress,
      ];
}

class AdminFinanceError extends AdminFinanceState {
  final String message;

  const AdminFinanceError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AdminFinanceActionSuccess extends AdminFinanceState {
  final String message;

  const AdminFinanceActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}
