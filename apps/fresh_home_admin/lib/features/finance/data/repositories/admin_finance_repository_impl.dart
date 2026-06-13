import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/core/error/exceptions.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/admin_settlement_request.dart';
import '../../domain/entities/admin_financial_case.dart';
import '../../domain/entities/admin_technician_account.dart';
import '../../domain/entities/monthly_financial_summary.dart';
import '../../domain/entities/admin_ledger_entry.dart';
import '../../domain/repositories/admin_finance_repository.dart';
import '../data_sources/admin_finance_remote_data_source.dart';

class AdminFinanceRepositoryImpl implements AdminFinanceRepository {
  final AdminFinanceRemoteDataSource _remoteDataSource;

  AdminFinanceRepositoryImpl(this._remoteDataSource);

  Future<File> _compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.webp';
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 40,
        format: CompressFormat.webp,
      );
      if (compressedFile != null) {
        return File(compressedFile.path);
      }
    } catch (_) {
      // Safe fallback
    }
    return file;
  }

  @override
  Future<Either<Failure, List<AdminSettlementRequest>>> getSettlementRequests() async {
    try {
      final requests = await _remoteDataSource.getSettlementRequests();
      return Right(requests);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AdminFinancialCase>>> getFinancialCases() async {
    try {
      final cases = await _remoteDataSource.getFinancialCases();
      return Right(cases);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AdminTechnicianAccount>>> getTechnicianAccounts() async {
    try {
      final accounts = await _remoteDataSource.getTechnicianAccounts();
      return Right(accounts);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MonthlyFinancialSummary>>> getMonthlyFinancialSummaries() async {
    try {
      final summaries = await _remoteDataSource.getMonthlyFinancialSummaries();
      return Right(summaries);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AdminLedgerEntry>>> getLedgerEntries() async {
    try {
      final entries = await _remoteDataSource.getLedgerEntries();
      return Right(entries);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> refreshFinancialReports() async {
    try {
      await _remoteDataSource.refreshFinancialReports();
      return const Right(null);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> approveSettlementRequest(String settlementId, {File? proofImage}) async {
    try {
      String? adminProofUrl;
      if (proofImage != null) {
        final compressed = await _compressImage(proofImage);
        adminProofUrl = await _remoteDataSource.uploadProofImage(settlementId, compressed);
      }
      await _remoteDataSource.approveSettlementRequest(settlementId, adminProofUrl: adminProofUrl);
      return const Right(null);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateDebtLimit(String accountId, double newLimit) async {
    try {
      await _remoteDataSource.updateDebtLimit(accountId, newLimit);
      return const Right(null);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectSettlementRequest(String settlementId, String adminNotes) async {
    try {
      await _remoteDataSource.rejectSettlementRequest(settlementId, adminNotes);
      return const Right(null);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resolveFinancialCase(String caseId, String resolutionNotes) async {
    try {
      await _remoteDataSource.resolveFinancialCase(caseId, resolutionNotes);
      return const Right(null);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createFinancialAdjustment({
    required String technicianId,
    required double amount,
    required String adjustmentType,
    required String reason,
    required String notes,
  }) async {
    try {
      await _remoteDataSource.createFinancialAdjustment(
        technicianId: technicianId,
        amount: amount,
        adjustmentType: adjustmentType,
        reason: reason,
        notes: notes,
      );
      return const Right(null);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
