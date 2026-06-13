import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import '../../domain/repositories/technician_finance_repository.dart';
import 'technician_finance_state.dart';
import '../../domain/entities/settlement_request.dart';

class TechnicianFinanceCubit extends Cubit<TechnicianFinanceState> {
  final TechnicianFinanceRepository _repository;

  TechnicianFinanceCubit(this._repository) : super(TechnicianFinanceInitial());

  Future<void> loadFinancialData() async {
    emit(TechnicianFinanceLoading());
    final accountResult = await _repository.getFinancialAccount();

    await accountResult.fold(
      (failure) async => emit(TechnicianFinanceError(failure.message)),
      (account) async {
        final entriesResult = await _repository.getLedgerEntries();
        entriesResult.fold(
          (failure) => emit(TechnicianFinanceError(failure.message)),
          (entries) => emit(TechnicianFinanceLoaded(
            account: account,
            ledgerEntries: entries,
          )),
        );
      },
    );
  }

  Future<Either<Failure, SettlementRequest>> getSettlementRequest(String id) {
    return _repository.getSettlementRequest(id);
  }

  Future<void> submitSettlement({
    required double amount,
    required String method,
    required String requestType,
    File? proofImage,
  }) async {
    final currentState = state;
    final cachedAccount = currentState is TechnicianFinanceLoaded ? currentState.account : null;
    final cachedEntries = currentState is TechnicianFinanceLoaded ? currentState.ledgerEntries : null;

    emit(TechnicianFinanceActionLoading());
    final result = await _repository.submitSettlementRequest(
      amount: amount,
      method: method,
      requestType: requestType,
      proofImage: proofImage,
    );

    await result.fold(
      (failure) async {
        emit(TechnicianFinanceError(failure.message));
        if (cachedAccount != null && cachedEntries != null) {
          // Restore previous state so user doesn't see empty page on error
          emit(TechnicianFinanceLoaded(
            account: cachedAccount,
            ledgerEntries: cachedEntries,
          ));
        }
      },
      (_) async {
        emit(TechnicianFinanceActionSuccess());
        // Automatically reload financial data to reflect the changes
        await loadFinancialData();
      },
    );
  }
}
