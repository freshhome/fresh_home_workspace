import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import '../entities/technician_financial_account.dart';
import '../entities/ledger_entry.dart';
import '../entities/settlement_request.dart';

abstract class TechnicianFinanceRepository {
  Future<Either<Failure, TechnicianFinancialAccount>> getFinancialAccount();
  Future<Either<Failure, List<LedgerEntry>>> getLedgerEntries();
  Future<Either<Failure, SettlementRequest>> getSettlementRequest(String settlementId);
  Future<Either<Failure, SettlementRequest>> submitSettlementRequest({
    required double amount,
    required String method,
    required String requestType,
    File? proofImage,
  });
}
