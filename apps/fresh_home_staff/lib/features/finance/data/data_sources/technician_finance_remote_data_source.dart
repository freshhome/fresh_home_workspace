import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/core/error/exceptions.dart';
import '../models/technician_financial_account_model.dart';
import '../models/ledger_entry_model.dart';
import '../models/settlement_request_model.dart';

abstract class TechnicianFinanceRemoteDataSource {
  Future<TechnicianFinancialAccountModel> getFinancialAccount(String technicianId);
  Future<List<LedgerEntryModel>> getLedgerEntries(String accountId);
  Future<String> uploadProofImage(String technicianId, File file);
  Future<SettlementRequestModel> getSettlementRequest(String settlementId);
  Future<SettlementRequestModel> createSettlementRequest({
    required String technicianId,
    required double amount,
    required String method,
    required String requestType,
    String? proofImageUrl,
  });
}

class TechnicianFinanceRemoteDataSourceImpl
    implements TechnicianFinanceRemoteDataSource {
  final SupabaseClient _supabase;
  static const String _accountsTable = 'technician_financial_accounts';
  static const String _ledgerTable = 'ledger_entries';
  static const String _settlementsTable = 'settlement_requests';
  static const String _bucketName = 'settlement_proofs';

  TechnicianFinanceRemoteDataSourceImpl(this._supabase);

  @override
  Future<TechnicianFinancialAccountModel> getFinancialAccount(
      String technicianId) async {
    try {
      final response = await _supabase
          .from(_accountsTable)
          .select()
          .eq('technician_id', technicianId)
          .maybeSingle();

      if (response == null) {
        // Proactively register the financial account if it doesn't exist yet
        final newAccount = await _supabase
            .from(_accountsTable)
            .insert({'technician_id': technicianId})
            .select()
            .single();
        return TechnicianFinancialAccountModel.fromJson(newAccount);
      }
      return TechnicianFinancialAccountModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<List<LedgerEntryModel>> getLedgerEntries(String accountId) async {
    try {
      final response = await _supabase
          .from(_ledgerTable)
          .select()
          .eq('account_id', accountId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => LedgerEntryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<String> uploadProofImage(String technicianId, File file) async {
    try {
      final ext = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$technicianId.$ext';

      await _supabase.storage.from(_bucketName).upload(fileName, file);

      final publicUrl =
          _supabase.storage.from(_bucketName).getPublicUrl(fileName);
      return publicUrl;
    } on StorageException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.statusCode);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<SettlementRequestModel> createSettlementRequest({
    required String technicianId,
    required double amount,
    required String method,
    required String requestType,
    String? proofImageUrl,
  }) async {
    try {
      final response = await _supabase
          .from(_settlementsTable)
          .insert({
            'technician_id': technicianId,
            'amount': amount,
            'method': method,
            'request_type': requestType,
            'proof_image_url': proofImageUrl,
            'status': 'pending',
          })
          .select()
          .single();

      return SettlementRequestModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<SettlementRequestModel> getSettlementRequest(String settlementId) async {
    try {
      final response = await _supabase
          .from(_settlementsTable)
          .select()
          .eq('id', settlementId)
          .single();

      return SettlementRequestModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }
}
