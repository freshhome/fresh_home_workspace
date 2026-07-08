import 'package:shared/domain/user/enums/user_role.dart';
import 'package:shared/domain/user/enums/user_status.dart';
import 'package:shared/data/user/models/remote/user_remote_model.dart';
import 'package:shared/data/user/models/remote/audit_log_remote_model.dart';
import 'package:shared/data/technician/models/remote/technician_skill_remote_model.dart';
import 'package:shared/data/technician/models/remote/capacity_pool_remote_model.dart';
import 'package:shared/data/user/models/remote/technician_profile_remote_model.dart';
import '../data_sources/user_management_remote_data_source.dart';
import '../../domain/repositories/user_management_repository.dart';

class UserManagementRepositoryImpl implements UserManagementRepository {
  final UserManagementRemoteDataSource _remoteDataSource;

  UserManagementRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<UserRemoteModel>> getUsers({
    String? searchQuery,
    UserRole? roleFilter,
    UserStatus? statusFilter,
  }) {
    return _remoteDataSource.getUsers(
      searchQuery: searchQuery,
      roleFilter: roleFilter,
      statusFilter: statusFilter,
    );
  }

  @override
  Future<List<UserRemoteModel>> getTechniciansBySubService(String subServiceId) {
    return _remoteDataSource.getTechniciansBySubService(subServiceId);
  }

  @override
  Future<void> updateUserStatus(String userId, UserStatus status) {
    return _remoteDataSource.updateUserStatus(userId, status);
  }

  @override
  Future<void> assignRole(String userId, UserRole role, {String? mainServiceId}) {
    return _remoteDataSource.assignRole(userId, role, mainServiceId: mainServiceId);
  }

  @override
  Future<void> removeRole(String userId, UserRole role) {
    return _remoteDataSource.removeRole(userId, role);
  }

  @override
  Future<UserRemoteModel> getUserFullDetail(String userId) {
    return _remoteDataSource.getUserFullDetail(userId);
  }

  @override
  Future<List<AuditLogRemoteModel>> getUserAuditLogs(String userId) {
    return _remoteDataSource.getUserAuditLogs(userId);
  }

  // ── Assignment System ──────────────────────────────────────────────────────

  @override
  Future<TechnicianProfileRemoteModel?> getTechnicianProfile(String technicianId) {
    return _remoteDataSource.getTechnicianProfile(technicianId);
  }

  @override
  Future<void> setTechnicianMainService(String technicianId, String mainServiceId) {
    return _remoteDataSource.setTechnicianMainService(technicianId, mainServiceId);
  }

  @override
  Future<List<TechnicianSkillRemoteModel>> getTechnicianSkills(String technicianId) {
    return _remoteDataSource.getTechnicianSkills(technicianId);
  }

  @override
  Future<List<CapacityPoolRemoteModel>> getTechnicianPools(String technicianId) {
    return _remoteDataSource.getTechnicianPools(technicianId);
  }

  @override
  Future<CapacityPoolRemoteModel> upsertCapacityPool({
    required String technicianId,
    String? poolId,
    required String title,
    required String mainServiceId,
    required int maxDailyCapacity,
  }) {
    return _remoteDataSource.upsertCapacityPool(
      technicianId: technicianId,
      poolId: poolId,
      title: title,
      mainServiceId: mainServiceId,
      maxDailyCapacity: maxDailyCapacity,
    );
  }

  @override
  Future<void> deleteCapacityPool(String poolId) {
    return _remoteDataSource.deleteCapacityPool(poolId);
  }

  @override
  Future<void> assignSkill({
    required String technicianId,
    required String subServiceId,
    required String capacityPoolId,
  }) {
    return _remoteDataSource.assignSkill(
      technicianId: technicianId,
      subServiceId: subServiceId,
      capacityPoolId: capacityPoolId,
    );
  }

  @override
  Future<void> assignSkills({
    required String technicianId,
    required List<String> subServiceIds,
    required String capacityPoolId,
  }) {
    return _remoteDataSource.assignSkills(
      technicianId: technicianId,
      subServiceIds: subServiceIds,
      capacityPoolId: capacityPoolId,
    );
  }

  @override
  Future<void> toggleSkillActive(String skillId, bool isActive) {
    return _remoteDataSource.toggleSkillActive(skillId, isActive);
  }

  @override
  Future<void> removeSkill(String skillId) {
    return _remoteDataSource.removeSkill(skillId);
  }

  @override
  Future<List<Map<String, dynamic>>> getAllSubServices({String? mainServiceId}) {
    return _remoteDataSource.getAllSubServices(mainServiceId: mainServiceId);
  }

  @override
  Future<List<Map<String, dynamic>>> getAllMainServices() {
    return _remoteDataSource.getAllMainServices();
  }
}
