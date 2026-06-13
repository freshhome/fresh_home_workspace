import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import '../../domain/repositories/admin_finance_repository.dart';
import '../../domain/entities/admin_settlement_request.dart';
import '../../domain/entities/admin_financial_case.dart';
import '../../domain/entities/admin_technician_account.dart';
import 'admin_finance_state.dart';

class AdminFinanceCubit extends Cubit<AdminFinanceState> {
  final AdminFinanceRepository _repository;

  AdminFinanceCubit(this._repository) : super(AdminFinanceInitial());

  Future<void> loadFinancialData() async {
    emit(AdminFinanceLoading());

    final results = await Future.wait([
      _repository.getSettlementRequests(),
      _repository.getFinancialCases(),
      _repository.getTechnicianAccounts(),
    ]);

    final settlementsRes = results[0] as Either<Failure, List<AdminSettlementRequest>>;
    final casesRes = results[1] as Either<Failure, List<AdminFinancialCase>>;
    final accountsRes = results[2] as Either<Failure, List<AdminTechnicianAccount>>;

    settlementsRes.fold(
      (failure) => emit(AdminFinanceError(message: failure.message)),
      (settlements) {
        casesRes.fold(
          (failure) => emit(AdminFinanceError(message: failure.message)),
          (cases) {
            accountsRes.fold(
              (failure) => emit(AdminFinanceError(message: failure.message)),
              (accounts) => emit(AdminFinanceLoaded(
                settlementRequests: settlements,
                financialCases: cases,
                technicianAccounts: accounts,
              )),
            );
          },
        );
      },
    );
  }

  Future<void> approveSettlement(String settlementId, {File? proofImage}) async {
    if (state is! AdminFinanceLoaded) return;
    final currentState = state as AdminFinanceLoaded;

    emit(currentState.copyWith(isActionInProgress: true));

    final result = await _repository.approveSettlementRequest(settlementId, proofImage: proofImage);

    result.fold(
      (failure) {
        emit(AdminFinanceError(message: failure.message));
        emit(currentState.copyWith(isActionInProgress: false));
      },
      (_) async {
        emit(const AdminFinanceActionSuccess(message: 'settlement_approved_success'));
        await loadFinancialData();
      },
    );
  }

  Future<void> updateTechnicianDebtLimit(String accountId, double newLimit) async {
    if (state is! AdminFinanceLoaded) return;
    final currentState = state as AdminFinanceLoaded;

    emit(currentState.copyWith(isActionInProgress: true));

    final result = await _repository.updateDebtLimit(accountId, newLimit);

    result.fold(
      (failure) {
        emit(AdminFinanceError(message: failure.message));
        emit(currentState.copyWith(isActionInProgress: false));
      },
      (_) async {
        emit(const AdminFinanceActionSuccess(message: 'admin_finance_success_debt'));
        await loadFinancialData();
      },
    );
  }

  Future<void> rejectSettlement(String settlementId, String adminNotes) async {
    if (state is! AdminFinanceLoaded) return;
    final currentState = state as AdminFinanceLoaded;

    emit(currentState.copyWith(isActionInProgress: true));

    final result = await _repository.rejectSettlementRequest(settlementId, adminNotes);

    result.fold(
      (failure) {
        emit(AdminFinanceError(message: failure.message));
        emit(currentState.copyWith(isActionInProgress: false));
      },
      (_) async {
        emit(const AdminFinanceActionSuccess(message: 'settlement_rejected_success'));
        await loadFinancialData();
      },
    );
  }

  Future<void> resolveCase(String caseId, String resolutionNotes) async {
    if (state is! AdminFinanceLoaded) return;
    final currentState = state as AdminFinanceLoaded;

    emit(currentState.copyWith(isActionInProgress: true));

    final result = await _repository.resolveFinancialCase(caseId, resolutionNotes);

    result.fold(
      (failure) {
        emit(AdminFinanceError(message: failure.message));
        emit(currentState.copyWith(isActionInProgress: false));
      },
      (_) async {
        emit(const AdminFinanceActionSuccess(message: 'financial_case_resolved_success'));
        await loadFinancialData();
      },
    );
  }

  Future<void> createAdjustment({
    required String technicianId,
    required double amount,
    required String adjustmentType,
    required String reason,
    required String notes,
  }) async {
    if (state is! AdminFinanceLoaded) return;
    final currentState = state as AdminFinanceLoaded;

    emit(currentState.copyWith(isActionInProgress: true));

    final result = await _repository.createFinancialAdjustment(
      technicianId: technicianId,
      amount: amount,
      adjustmentType: adjustmentType,
      reason: reason,
      notes: notes,
    );

    result.fold(
      (failure) {
        emit(AdminFinanceError(message: failure.message));
        emit(currentState.copyWith(isActionInProgress: false));
      },
      (_) async {
        emit(const AdminFinanceActionSuccess(message: 'adjustment_created_success'));
        await loadFinancialData();
      },
    );
  }
}
