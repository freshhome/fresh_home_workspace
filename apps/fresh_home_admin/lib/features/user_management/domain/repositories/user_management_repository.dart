import 'package:shared/domain/user/enums/user_role.dart';
import 'package:shared/domain/user/enums/user_status.dart';
import 'package:shared/data/user/models/remote/user_remote_model.dart';
import 'package:shared/data/user/models/remote/audit_log_remote_model.dart';
import 'package:shared/data/technician/models/remote/technician_skill_remote_model.dart';
import 'package:shared/data/technician/models/remote/capacity_pool_remote_model.dart';
import 'package:shared/data/user/models/remote/technician_profile_remote_model.dart';

abstract class UserManagementRepository {
  Future<List<UserRemoteModel>> getUsers({
    String? searchQuery,
    UserRole? roleFilter,
    UserStatus? statusFilter,
  });
  Future<List<UserRemoteModel>> getTechniciansBySubService(String subServiceId);
  Future<void> updateUserStatus(String userId, UserStatus status);
  Future<void> assignRole(String userId, UserRole role, {String? mainServiceId});
  Future<void> removeRole(String userId, UserRole role);
  Future<UserRemoteModel> getUserFullDetail(String userId);
  Future<List<AuditLogRemoteModel>> getUserAuditLogs(String userId);

  // ── Assignment System ──────────────────────────────────────────────────────
  Future<TechnicianProfileRemoteModel?> getTechnicianProfile(String technicianId);
  Future<void> setTechnicianMainService(String technicianId, String mainServiceId);
  Future<List<TechnicianSkillRemoteModel>> getTechnicianSkills(String technicianId);
  Future<List<CapacityPoolRemoteModel>> getTechnicianPools(String technicianId);
  Future<CapacityPoolRemoteModel> upsertCapacityPool({
    required String technicianId, String? poolId,
    required String title, required int maxDailyCapacity,
  });
  Future<void> deleteCapacityPool(String poolId);
  Future<void> assignSkill({
    required String technicianId, required String subServiceId, required String capacityPoolId,
  });
  Future<void> assignSkills({
    required String technicianId, required List<String> subServiceIds, required String capacityPoolId,
  });
  Future<void> toggleSkillActive(String skillId, bool isActive);
  Future<void> removeSkill(String skillId);
  Future<List<Map<String, dynamic>>> getAllSubServices({String? mainServiceId});
  Future<List<Map<String, dynamic>>> getAllMainServices();
}
