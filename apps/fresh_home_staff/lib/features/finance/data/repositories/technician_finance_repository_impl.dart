import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:shared/core/error/exceptions.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/core/error/error_mapper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/technician_financial_account.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/entities/settlement_request.dart';
import '../../domain/repositories/technician_finance_repository.dart';
import '../data_sources/technician_finance_remote_data_source.dart';

class TechnicianFinanceRepositoryImpl implements TechnicianFinanceRepository {
  final TechnicianFinanceRemoteDataSource _remoteDataSource;
  final sb.SupabaseClient _supabase;

  TechnicianFinanceRepositoryImpl(this._remoteDataSource, this._supabase);

  String _getRequiredUid() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      throw const AppAuthException(
        'unauthenticated_request',
        code: 'unauthenticated',
      );
    }
    return uid;
  }

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
  Future<Either<Failure, TechnicianFinancialAccount>> getFinancialAccount() async {
    try {
      final uid = _getRequiredUid();
      final account = await _remoteDataSource.getFinancialAccount(uid);
      return Right(account);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExternalServiceError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LedgerEntry>>> getLedgerEntries() async {
    try {
      final uid = _getRequiredUid();
      // First get account to know its ID
      final account = await _remoteDataSource.getFinancialAccount(uid);
      final entries = await _remoteDataSource.getLedgerEntries(account.id);
      return Right(entries);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExternalServiceError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SettlementRequest>> submitSettlementRequest({
    required double amount,
    required String method,
    required String requestType,
    File? proofImage,
  }) async {
    try {
      final uid = _getRequiredUid();

      String? proofImageUrl;
      if (proofImage != null) {
        // 1. Compress proof image to WebP
        final compressed = await _compressImage(proofImage);
        // 2. Upload proof image to storage
        proofImageUrl =
            await _remoteDataSource.uploadProofImage(uid, compressed);
      }

      // 3. Insert settlement request
      final request = await _remoteDataSource.createSettlementRequest(
        technicianId: uid,
        amount: amount,
        method: method,
        requestType: requestType,
        proofImageUrl: proofImageUrl,
      );

      return Right(request);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExternalServiceError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SettlementRequest>> getSettlementRequest(String settlementId) async {
    try {
      final request = await _remoteDataSource.getSettlementRequest(settlementId);
      return Right(request);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExternalServiceError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
