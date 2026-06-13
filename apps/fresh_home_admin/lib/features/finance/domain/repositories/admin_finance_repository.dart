import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import '../entities/admin_settlement_request.dart';
import '../entities/admin_financial_case.dart';
import '../entities/admin_technician_account.dart';
import '../entities/monthly_financial_summary.dart';
import '../entities/admin_ledger_entry.dart';

abstract class AdminFinanceRepository {
  Future<Either<Failure, List<AdminSettlementRequest>>> getSettlementRequests();
  Future<Either<Failure, List<AdminFinancialCase>>> getFinancialCases();
  Future<Either<Failure, List<AdminTechnicianAccount>>> getTechnicianAccounts();
  Future<Either<Failure, List<MonthlyFinancialSummary>>> getMonthlyFinancialSummaries();
  Future<Either<Failure, List<AdminLedgerEntry>>> getLedgerEntries();
  Future<Either<Failure, void>> refreshFinancialReports();
  
  Future<Either<Failure, void>> approveSettlementRequest(String settlementId, {File? proofImage});
  Future<Either<Failure, void>> rejectSettlementRequest(String settlementId, String adminNotes);
  Future<Either<Failure, void>> resolveFinancialCase(String caseId, String resolutionNotes);
  Future<Either<Failure, void>> updateDebtLimit(String accountId, double newLimit);
  
  Future<Either<Failure, void>> createFinancialAdjustment({
    required String technicianId,
    required double amount,
    required String adjustmentType,
    required String reason,
    required String notes,
  });
}
