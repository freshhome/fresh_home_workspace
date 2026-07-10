import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/core/error/exceptions.dart';
import 'package:shared/data/user/models/remote/user_remote_model.dart';
import 'package:shared/data/user/models/remote/audit_log_remote_model.dart';
import 'package:shared/domain/user/enums/user_role.dart';
import 'package:shared/domain/user/enums/user_status.dart';
import 'package:shared/data/technician/models/remote/technician_skill_remote_model.dart';
import 'package:shared/data/technician/models/remote/capacity_pool_remote_model.dart';
import 'package:shared/data/user/models/remote/technician_profile_remote_model.dart';

abstract class UserManagementRemoteDataSource {
  Future<List<UserRemoteModel>> getUsers({
    String? searchQuery,
    UserRole? roleFilter,
    UserStatus? statusFilter,
  });
  Future<List<UserRemoteModel>> getTechniciansBySubService(String subServiceId, {DateTime? date});
  Future<void> updateUserStatus(String userId, UserStatus status);
  Future<void> assignRole(String userId, UserRole role, {String? mainServiceId});
  Future<void> removeRole(String userId, UserRole role);
  Future<UserRemoteModel> getUserFullDetail(String userId);
  Future<List<AuditLogRemoteModel>> getUserAuditLogs(String userId);

  // ── New Assignment System ──────────────────────────────────────────────────
  /// Get all skills (linked sub-services) for a technician
  Future<List<TechnicianSkillRemoteModel>> getTechnicianSkills(String technicianId);

  /// Get all capacity pools for a technician
  Future<List<CapacityPoolRemoteModel>> getTechnicianPools(String technicianId);

  /// Get the technician profile (includes mainServiceId)
  Future<TechnicianProfileRemoteModel?> getTechnicianProfile(String technicianId);

  /// Set the main service of a technician (one-time binding)
  Future<void> setTechnicianMainService(String technicianId, String mainServiceId);

  /// Create or update a capacity pool
  Future<CapacityPoolRemoteModel> upsertCapacityPool({
    required String technicianId,
    String? poolId,
    required String title,
    required String mainServiceId,
    required int maxDailyCapacity,
  });

  /// Delete a capacity pool
  Future<void> deleteCapacityPool(String poolId);

  /// Assign a skill (sub-service → pool mapping)
  Future<void> assignSkill({
    required String technicianId,
    required String subServiceId,
    required String capacityPoolId,
  });

  /// Assign multiple skills (batch operation)
  Future<void> assignSkills({
    required String technicianId,
    required List<String> subServiceIds,
    required String capacityPoolId,
  });

  /// Toggle skill active status
  Future<void> toggleSkillActive(String skillId, bool isActive);

  /// Remove a skill
  Future<void> removeSkill(String skillId);

  /// Get all sub-services (optionally filtered by main service)
  Future<List<Map<String, dynamic>>> getAllSubServices({String? mainServiceId});

  /// Get all main services
  Future<List<Map<String, dynamic>>> getAllMainServices();
}

class UserManagementRemoteDataSourceImpl implements UserManagementRemoteDataSource {
  final SupabaseClient _supabase;

  UserManagementRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<UserRemoteModel>> getUsers({
    String? searchQuery,
    UserRole? roleFilter,
    UserStatus? statusFilter,
  }) async {
    try {
      var query = _supabase
          .from('profiles')
          .select('*, user_roles(roles(name))');

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('first_name.ilike.%$searchQuery%,last_name.ilike.%$searchQuery%,email.ilike.%$searchQuery%');
      }
      if (statusFilter != null) {
        query = query.eq('account_status', statusFilter.name);
      }

      final response = await query.order('created_at', ascending: false);
      List<UserRemoteModel> users = (response as List)
          .map((json) => UserRemoteModel.fromJson(json))
          .toList();

      if (roleFilter != null) {
        users = users.where((u) => u.roles.contains(roleFilter)).toList();
      }
      return users;
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<List<UserRemoteModel>> getTechniciansBySubService(String subServiceId, {DateTime? date}) async {
    try {
      // 1. Fetch all technicians who have this sub-service skill (the base qualified list)
      final skillResponse = await _supabase
          .from('technician_skills')
          .select('technician_id')
          .eq('sub_service_id', subServiceId)
          .eq('is_active', true);
      
      final List<String> allTechIds = (skillResponse as List)
          .map((e) => e['technician_id'] as String)
          .toList();

      if (allTechIds.isEmpty) return [];

      List<String> activeTechIds = [];
      if (date != null) {
        // 2. Fetch actually available technicians for the specific date
        final rpcResponse = await _supabase.rpc(
          'get_available_technicians',
          params: {
            'p_sub_service_id': subServiceId,
            'p_date': date.toIso8601String().split('T').first,
          },
        );
        activeTechIds = (rpcResponse as List)
            .map((e) => e['technician_id'] as String)
            .toList();
      }

      // Fallback: If no technicians are available on that date, return all qualified technicians.
      final targetIds = (date != null && activeTechIds.isNotEmpty) ? activeTechIds : allTechIds;

      final response = await _supabase
          .from('profiles')
          .select('*, user_roles(roles(name))')
          .inFilter('id', targetIds);

      final result = (response as List)
          .map((json) => UserRemoteModel.fromJson(json))
          .toList();

      // If we did a fallback to all qualified technicians, sort available ones first (if any)
      if (date != null && activeTechIds.isNotEmpty && targetIds == allTechIds) {
        result.sort((a, b) {
          final aAvail = activeTechIds.contains(a.id) ? 1 : 0;
          final bAvail = activeTechIds.contains(b.id) ? 1 : 0;
          return bAvail.compareTo(aAvail);
        });
      }

      return result;
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<void> updateUserStatus(String userId, UserStatus status) async {
    try {
      await _supabase
          .from('profiles')
          .update({'account_status': status.name}).eq('id', userId);
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<void> assignRole(String userId, UserRole role, {String? mainServiceId}) async {
    try {
      await _supabase.rpc('assign_role_to_user', params: {
        'p_user_id': userId,
        'p_role_name': role.name,
      });

      // If assigning technician role and main service was provided, bind it
      if (role == UserRole.technician && mainServiceId != null) {
        await setTechnicianMainService(userId, mainServiceId);
      }
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<void> removeRole(String userId, UserRole role) async {
    try {
      await _supabase.rpc('remove_role_from_user', params: {
        'p_user_id': userId,
        'p_role_name': role.name,
      });
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<UserRemoteModel> getUserFullDetail(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*, user_roles(roles(name)), user_phones(*), user_addresses(*)')
          .eq('id', userId)
          .single();
      return UserRemoteModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<List<AuditLogRemoteModel>> getUserAuditLogs(String userId) async {
    try {
      final response = await _supabase
          .from('booking_logs')
          .select('*')
          .or('changed_by.eq.$userId,technician_id.eq.$userId')
          .order('created_at', ascending: false);
      return (response as List).map((e) => AuditLogRemoteModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  // ── New Assignment System Implementation ───────────────────────────────────

  @override
  Future<TechnicianProfileRemoteModel?> getTechnicianProfile(String technicianId) async {
    try {
      final response = await _supabase
          .from('technician_profiles')
          .select('*')
          .eq('user_id', technicianId)
          .maybeSingle();
      if (response == null) return null;
      return TechnicianProfileRemoteModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<void> setTechnicianMainService(String technicianId, String mainServiceId) async {
    // Note: main_service_id column was dropped from technician_profiles table in unified tree migration.
    // Technician main category is now resolved dynamically or via skills.
    debugPrint('ℹ️ setTechnicianMainService is a no-op since main_service_id column was dropped.');
    return;
  }

  @override
  Future<List<TechnicianSkillRemoteModel>> getTechnicianSkills(String technicianId) async {
    try {
      final response = await _supabase
          .from('technician_skills')
          .select('*, sub_services:services(id, title)')
          .eq('technician_id', technicianId);
      return (response as List).map((e) => TechnicianSkillRemoteModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<List<CapacityPoolRemoteModel>> getTechnicianPools(String technicianId) async {
    try {
      final response = await _supabase
          .from('capacity_pools')
          .select('*')
          .eq('technician_id', technicianId)
          .order('created_at');
      return (response as List).map((e) => CapacityPoolRemoteModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<CapacityPoolRemoteModel> upsertCapacityPool({
    required String technicianId,
    String? poolId,
    required String title,
    required String mainServiceId,
    required int maxDailyCapacity,
  }) async {
    try {
      final data = {
        'technician_id': technicianId,
        'title': title,
        'main_service_id': mainServiceId,
        'max_daily_capacity': maxDailyCapacity,
      };
      if (poolId != null) data['id'] = poolId;

      final response = await _supabase
          .from('capacity_pools')
          .upsert(data, onConflict: 'technician_id,title')
          .select()
          .single();
      return CapacityPoolRemoteModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<void> deleteCapacityPool(String poolId) async {
    try {
      await _supabase.from('capacity_pools').delete().eq('id', poolId);
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<void> assignSkill({
    required String technicianId,
    required String subServiceId,
    required String capacityPoolId,
  }) async {
    try {
      await _supabase.from('technician_skills').upsert({
        'technician_id': technicianId,
        'sub_service_id': subServiceId,
        'capacity_pool_id': capacityPoolId,
        'is_active': true,
      }, onConflict: 'technician_id,sub_service_id');
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<void> assignSkills({
    required String technicianId,
    required List<String> subServiceIds,
    required String capacityPoolId,
  }) async {
    try {
      final data = subServiceIds.map((id) => {
        'technician_id': technicianId,
        'sub_service_id': id,
        'capacity_pool_id': capacityPoolId,
        'is_active': true,
      }).toList();
      
      await _supabase.from('technician_skills').upsert(data, onConflict: 'technician_id,sub_service_id');
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<void> toggleSkillActive(String skillId, bool isActive) async {
    try {
      await _supabase
          .from('technician_skills')
          .update({'is_active': isActive}).eq('id', skillId);
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<void> removeSkill(String skillId) async {
    try {
      await _supabase.from('technician_skills').delete().eq('id', skillId);
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllSubServices({String? mainServiceId}) async {
    try {
      var query = _supabase
          .from('services')
          .select('id, title, main_service_id:parent_id')
          .eq('is_bookable', true);
      if (mainServiceId != null) {
        query = query.eq('parent_id', mainServiceId);
      }
      final response = await query;
      return (response as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllMainServices() async {
    try {
      final response = await _supabase
          .from('services')
          .select('id, title')
          .eq('is_bookable', false);
      return (response as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    }
  }
}
