import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/core/error/exceptions.dart';
import '../models/admin_settlement_request_model.dart';
import '../models/admin_financial_case_model.dart';
import '../models/admin_technician_account_model.dart';
import '../models/monthly_financial_summary_model.dart';
import '../models/admin_ledger_entry_model.dart';

abstract class AdminFinanceRemoteDataSource {
  Future<List<AdminSettlementRequestModel>> getSettlementRequests();
  Future<List<AdminFinancialCaseModel>> getFinancialCases();
  Future<List<AdminTechnicianAccountModel>> getTechnicianAccounts();
  Future<List<MonthlyFinancialSummaryModel>> getMonthlyFinancialSummaries();
  Future<List<AdminLedgerEntryModel>> getLedgerEntries();
  Future<void> refreshFinancialReports();
  
  Future<void> approveSettlementRequest(String settlementId, {String? adminProofUrl});
  Future<String> uploadProofImage(String name, File file);
  Future<void> updateDebtLimit(String accountId, double newLimit);
  Future<void> rejectSettlementRequest(String settlementId, String adminNotes);
  Future<void> resolveFinancialCase(String caseId, String resolutionNotes);
  
  Future<void> createFinancialAdjustment({
    required String technicianId,
    required double amount,
    required String adjustmentType,
    required String reason,
    required String notes,
  });
}

class AdminFinanceRemoteDataSourceImpl implements AdminFinanceRemoteDataSource {
  final SupabaseClient _supabase;

  AdminFinanceRemoteDataSourceImpl(this._supabase);

  String _getCurrentUserId() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const SupabaseExceptionApp('User is not authenticated', code: 'auth_error');
    }
    return userId;
  }

  @override
  Future<List<AdminSettlementRequestModel>> getSettlementRequests() async {
    try {
      final response = await _supabase
          .from('settlement_requests')
          .select('*, profiles:technician_id(first_name, last_name)')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AdminSettlementRequestModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<List<AdminFinancialCaseModel>> getFinancialCases() async {
    try {
      final response = await _supabase
          .from('financial_cases')
          .select('*, reported_by_profile:reported_by(first_name, last_name)')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AdminFinancialCaseModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<List<AdminTechnicianAccountModel>> getTechnicianAccounts() async {
    try {
      final response = await _supabase
          .from('technician_financial_accounts')
          .select('*, profiles:technician_id(first_name, last_name)')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AdminTechnicianAccountModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<List<MonthlyFinancialSummaryModel>> getMonthlyFinancialSummaries() async {
    try {
      final response = await _supabase
          .from('mv_monthly_financial_summary')
          .select('*')
          .order('month_year', ascending: false);

      return (response as List)
          .map((json) => MonthlyFinancialSummaryModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<List<AdminLedgerEntryModel>> getLedgerEntries() async {
    try {
      final response = await _supabase
          .from('ledger_entries')
          .select('*, technician_financial_accounts(profiles(first_name, last_name))')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AdminLedgerEntryModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<void> refreshFinancialReports() async {
    try {
      await _supabase.rpc('refresh_financial_reports');
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<void> approveSettlementRequest(String settlementId, {String? adminProofUrl}) async {
    try {
      final adminId = _getCurrentUserId();
      await _supabase.from('settlement_requests').update({
        'status': 'approved',
        'reviewed_by': adminId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'admin_proof_url': adminProofUrl,
      }).eq('id', settlementId);
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<String> uploadProofImage(String name, File file) async {
    try {
      final ext = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$name.$ext';

      await _supabase.storage.from('settlement_proofs').upload(fileName, file);

      final publicUrl =
          _supabase.storage.from('settlement_proofs').getPublicUrl(fileName);
      return publicUrl;
    } on StorageException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.statusCode);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString());
    }
  }

  @override
  Future<void> updateDebtLimit(String accountId, double newLimit) async {
    try {
      await _supabase
          .from('technician_financial_accounts')
          .update({'debt_limit': newLimit})
          .eq('id', accountId);
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<void> rejectSettlementRequest(String settlementId, String adminNotes) async {
    try {
      final adminId = _getCurrentUserId();
      await _supabase.from('settlement_requests').update({
        'status': 'rejected',
        'admin_notes': adminNotes,
        'reviewed_by': adminId,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', settlementId);
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<void> resolveFinancialCase(String caseId, String resolutionNotes) async {
    try {
      final adminId = _getCurrentUserId();
      await _supabase.from('financial_cases').update({
        'status': 'resolved',
        'resolution_notes': resolutionNotes,
        'resolved_by': adminId,
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', caseId);
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<void> createFinancialAdjustment({
    required String technicianId,
    required double amount,
    required String adjustmentType,
    required String reason,
    required String notes,
  }) async {
    try {
      final adminId = _getCurrentUserId();
      // 1. Insert as 'pending' to satisfy DB schema triggers which require status update.
      final response = await _supabase.from('financial_adjustments').insert({
        'technician_id': technicianId,
        'amount': amount,
        'adjustment_type': adjustmentType,
        'reason': reason,
        'notes': notes,
        'status': 'pending',
        'created_by': adminId,
      }).select('id').single();

      final adjustmentId = response['id'] as String;

      // 2. Immediately update to 'approved' to fire trg_automate_adjustment_ledger.
      await _supabase.from('financial_adjustments').update({
        'status': 'approved',
        'approved_by': adminId,
        'approved_at': DateTime.now().toIso8601String(),
      }).eq('id', adjustmentId);
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }
}
