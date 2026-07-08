import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared/data/user/models/remote/user_remote_model.dart';
import 'package:shared/data/user/models/remote/audit_log_remote_model.dart';
import 'package:shared/domain/user/enums/user_role.dart';
import 'package:shared/domain/user/enums/user_status.dart';
import 'package:shared/data/user/models/remote/technician_profile_remote_model.dart';
import 'package:shared/data/technician/models/remote/technician_skill_remote_model.dart';
import 'package:shared/data/technician/models/remote/capacity_pool_remote_model.dart';
import 'package:shared/core/error/error_mapper.dart';
import 'package:shared/core/error/exceptions.dart';
import '../../domain/repositories/user_management_repository.dart';

abstract class UserDetailState extends Equatable {
  const UserDetailState();
  @override
  List<Object?> get props => [];
}

class UserDetailInitial extends UserDetailState {}
class UserDetailLoading extends UserDetailState {}

class UserDetailLoaded extends UserDetailState {
  final UserRemoteModel user;
  final List<AuditLogRemoteModel> auditLogs;
  final TechnicianProfileRemoteModel? technicianProfile;
  final List<CapacityPoolRemoteModel> capacityPools;
  final List<TechnicianSkillRemoteModel> technicianSkills;
  final List<Map<String, dynamic>> availableSubServices;
  final List<Map<String, dynamic>> mainServices;

  const UserDetailLoaded({
    required this.user,
    this.auditLogs = const [],
    this.technicianProfile,
    this.capacityPools = const [],
    this.technicianSkills = const [],
    this.availableSubServices = const [],
    this.mainServices = const [],
  });

  @override
  List<Object?> get props => [
        user,
        auditLogs,
        technicianProfile,
        capacityPools,
        technicianSkills,
        availableSubServices,
        mainServices,
      ];
}

class UserDetailUpdating extends UserDetailState {}
class UserDetailSuccess extends UserDetailState {
  final String message;
  const UserDetailSuccess(this.message);
  @override
  List<Object?> get props => [message];
}
class UserDetailError extends UserDetailState {
  final String message;
  const UserDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

class UserDetailCubit extends Cubit<UserDetailState> {
  final UserManagementRepository _repository;

  UserDetailCubit(this._repository) : super(UserDetailInitial());

  Future<void> fetchUserDetail(String userId) async {
    emit(UserDetailLoading());
    try {
      final user = await _repository.getUserFullDetail(userId);
      final auditLogs = await _repository.getUserAuditLogs(userId);

      TechnicianProfileRemoteModel? technicianProfile;
      List<CapacityPoolRemoteModel> capacityPools = [];
      List<TechnicianSkillRemoteModel> technicianSkills = [];
      List<Map<String, dynamic>> availableSubServices = [];
      List<Map<String, dynamic>> mainServices = [];

      if (user.roles.contains(UserRole.technician)) {
        technicianProfile = await _repository.getTechnicianProfile(userId);
        capacityPools = await _repository.getTechnicianPools(userId);
        technicianSkills = await _repository.getTechnicianSkills(userId);
        
        mainServices = await _repository.getAllMainServices();
        availableSubServices = await _repository.getAllSubServices();
      }

      emit(UserDetailLoaded(
        user: user,
        auditLogs: auditLogs,
        technicianProfile: technicianProfile,
        capacityPools: capacityPools,
        technicianSkills: technicianSkills,
        availableSubServices: availableSubServices,
        mainServices: mainServices,
      ));
    } on AppException catch (e) {
      emit(UserDetailError(ErrorMapper.mapExternalServiceError(e).message));
    } catch (e) {
      emit(UserDetailError(e.toString()));
    }
  }

  Future<void> updateUserStatus(String userId, UserStatus status) async {
    final currentState = state;
    emit(UserDetailUpdating());
    try {
      await _repository.updateUserStatus(userId, status);
      emit(const UserDetailSuccess('User status updated successfully'));
      if (currentState is UserDetailLoaded) fetchUserDetail(userId);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> assignRole(String userId, UserRole role, {String? mainServiceId}) async {
    final currentState = state;
    emit(UserDetailUpdating());
    try {
      await _repository.assignRole(userId, role, mainServiceId: mainServiceId);
      emit(UserDetailSuccess('Role ${role.name} assigned successfully'));
      if (currentState is UserDetailLoaded) fetchUserDetail(userId);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> removeRole(String userId, UserRole role) async {
    final currentState = state;
    emit(UserDetailUpdating());
    try {
      await _repository.removeRole(userId, role);
      emit(UserDetailSuccess('Role ${role.name} removed successfully'));
      if (currentState is UserDetailLoaded) fetchUserDetail(userId);
    } catch (e) {
      _handleError(e);
    }
  }

  // ── Assignment System Methods ──────────────────────────────────────────────

  Future<void> setMainService(String technicianId, String mainServiceId) async {
    final currentState = state;
    emit(UserDetailUpdating());
    try {
      await _repository.setTechnicianMainService(technicianId, mainServiceId);
      emit(const UserDetailSuccess('Main service assigned successfully'));
      if (currentState is UserDetailLoaded) fetchUserDetail(technicianId);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> upsertPool({
    required String technicianId,
    String? poolId,
    required String title,
    required String mainServiceId,
    required int maxDailyCapacity,
  }) async {
    final currentState = state;
    emit(UserDetailUpdating());
    try {
      await _repository.upsertCapacityPool(
        technicianId: technicianId,
        poolId: poolId,
        title: title,
        mainServiceId: mainServiceId,
        maxDailyCapacity: maxDailyCapacity,
      );
      emit(const UserDetailSuccess('Capacity pool saved successfully'));
      if (currentState is UserDetailLoaded) fetchUserDetail(technicianId);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> deletePool(String technicianId, String poolId) async {
    final currentState = state;
    emit(UserDetailUpdating());
    try {
      await _repository.deleteCapacityPool(poolId);
      emit(const UserDetailSuccess('Capacity pool deleted successfully'));
      if (currentState is UserDetailLoaded) fetchUserDetail(technicianId);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> assignSkills({
    required String technicianId,
    required List<String> subServiceIds,
    required String capacityPoolId,
  }) async {
    final currentState = state;
    emit(UserDetailUpdating());
    try {
      await _repository.assignSkills(
        technicianId: technicianId,
        subServiceIds: subServiceIds,
        capacityPoolId: capacityPoolId,
      );
      emit(const UserDetailSuccess('Skills assigned successfully'));
      if (currentState is UserDetailLoaded) fetchUserDetail(technicianId);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> toggleSkillActive({
    required String technicianId,
    required String skillId,
    required bool isActive,
  }) async {
    final currentState = state;
    emit(UserDetailUpdating());
    try {
      await _repository.toggleSkillActive(skillId, isActive);
      emit(const UserDetailSuccess('Skill status updated'));
      if (currentState is UserDetailLoaded) fetchUserDetail(technicianId);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> removeSkill({
    required String technicianId,
    required String skillId,
  }) async {
    final currentState = state;
    emit(UserDetailUpdating());
    try {
      await _repository.removeSkill(skillId);
      emit(const UserDetailSuccess('Skill removed successfully'));
      if (currentState is UserDetailLoaded) fetchUserDetail(technicianId);
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleError(Object e) {
    if (e is AppException) {
      emit(UserDetailError(ErrorMapper.mapExternalServiceError(e).message));
    } else {
      emit(UserDetailError(e.toString()));
    }
  }
}
