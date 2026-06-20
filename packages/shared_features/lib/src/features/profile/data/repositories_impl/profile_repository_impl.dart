import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:shared/core/error/exceptions.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/core/error/error_mapper.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/user/entities/user/phone.dart';
import 'package:shared/domain/user/entities/user/user_profile.dart';
import 'package:shared/data/user/mappers/address_mapper.dart';
import 'package:shared/data/user/mappers/phone_mapper.dart';
import 'package:shared/data/user/mappers/user_profile_mapper.dart';
import 'package:shared/data/user/mappers/user_roles_mappers.dart';
import 'package:shared/data/user/models/local/client_profile_hive_model.dart';
import 'package:shared/data/user/models/local/technician_profile_hive_model.dart';
import 'package:shared/data/user/models/remote/customer_profile_remote_model.dart';
import 'package:shared/data/user/models/remote/user_remote_model.dart';
import 'package:shared/data/user/datasources/user_remote_datasource.dart';

import 'package:shared_features/src/features/authentication/data/authentication_data.dart';
import 'package:shared/domain/user/enums/user_role.dart';
import 'package:shared/domain/user/enums/user_status.dart';
import 'package:shared/data/user/models/remote/technician_profile_remote_model.dart';
import 'package:shared_features/src/features/profile/data/data_sources/technician_profile_remote_data_source.dart';
import 'package:shared_features/src/features/profile/data/data_sources/client_profile_remote_data_source.dart';
import 'package:shared_features/src/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:shared/data/technician/models/remote/capacity_pool_remote_model.dart';
import 'package:shared/data/technician/models/remote/technician_skill_remote_model.dart';
import 'package:shared/domain/user/entities/user/capacity_pool.dart';
import 'package:shared/domain/user/entities/user/technician_skill.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final AuthLocalDataSource localDataSource;
  final UserRemoteDataSource userRemoteDataSource;
  final ClientProfileRemoteDataSource clientProfileRemoteDataSource;
  final TechnicianProfileRemoteDataSource technicianProfileRemoteDataSource;
  final sb.SupabaseClient supabase;

  ProfileRepositoryImpl({
    required this.localDataSource,
    required this.userRemoteDataSource,
    required this.clientProfileRemoteDataSource,
    required this.technicianProfileRemoteDataSource,
    required this.supabase,
  });

  Future<UserRemoteModel> _requireCurrentUserModel() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) {
      throw const AppAuthException(
        'unauthenticated_request',
        code: 'unauthenticated',
      );
    }
    final model = await userRemoteDataSource.getUserById(uid);
    if (model == null) {
      throw const SupabaseExceptionApp(
        'User profile not found in database',
        code: 'profile_not_found',
      );
    }
    return model;
  }

  Future<CustomerProfileRemoteModel> _requireClientProfile(String uid) async {
    final profile = await clientProfileRemoteDataSource.getClientProfile(uid);
    if (profile == null) {
      final newProfile = CustomerProfileRemoteModel(
        userId: uid,
        preferredPaymentMethod: 'cash',
        addresses: const [],
        phoneNumbers: const [],
      );
      await clientProfileRemoteDataSource.saveClientProfile(newProfile);
      return newProfile;
    }
    return profile;
  }

  Future<TechnicianProfileRemoteModel?> _fetchTechnicianProfile(
    String uid,
    UserRemoteModel userModel,
  ) async {
    if (!userModel.roles.contains(UserRole.technician)) return null;

    final techProfile = await technicianProfileRemoteDataSource
        .getTechnicianProfile(uid);
    return techProfile;
  }

  UserProfile? _fromCache() {
    final cachedUser = localDataSource.getCachedUser();
    final cachedProfile = localDataSource.getCachedClientProfile();
    final cachedTechProfile = localDataSource.getCachedTechnicianProfile();

    if (cachedUser != null) {
      final roles = userRoleFromCode(codes: cachedUser.rolesCodes);
      final phoneNumbers = cachedUser.phones.map((p) => Phone(
        userId: cachedUser.uid,
        phoneNumber: p,
        isPrimary: false,
        isVerified: false,
        createdAt: DateTime.now(),
      )).toList();

      if (roles.contains(UserRole.admin)) {
        return AdminProfile(
          uid: cachedUser.uid,
          firstName: cachedUser.firstName,
          lastName: cachedUser.lastName,
          email: cachedUser.email,
          accountStatus: UserStatus.values.firstWhere(
            (e) => e.name == cachedUser.accountStatus,
            orElse: () => UserStatus.active,
          ),
          gender: cachedUser.gender,
          avatarUrl: cachedUser.avatarUrl,
          roles: roles,
          phoneNumbers: phoneNumbers,
          createdAt: cachedUser.createdAt,
          updatedAt: cachedUser.updatedAt,
          adminPermissions: const [],
        );
      } else if (roles.contains(UserRole.technician)) {
        final tech = cachedTechProfile;
        return TechnicianProfile(
          uid: cachedUser.uid,
          firstName: cachedUser.firstName,
          lastName: cachedUser.lastName,
          email: cachedUser.email,
          accountStatus: UserStatus.values.firstWhere(
            (e) => e.name == cachedUser.accountStatus,
            orElse: () => UserStatus.active,
          ),
          gender: cachedUser.gender,
          avatarUrl: cachedUser.avatarUrl,
          roles: roles,
          phoneNumbers: phoneNumbers,
          createdAt: cachedUser.createdAt,
          updatedAt: cachedUser.updatedAt,
          mainServiceId: null,
          bio: tech?.bio,
          rating: tech?.rating ?? 5.0,
          completedJobs: tech?.completedJobs ?? 0,
          isVerified: tech?.isVerified ?? false,
          isAvailable: tech?.isAvailable ?? false,
          serviceArea: tech?.serviceArea,
        );
      } else {
        final client = cachedProfile;
        return CustomerProfile(
          uid: cachedUser.uid,
          firstName: cachedUser.firstName,
          lastName: cachedUser.lastName,
          email: cachedUser.email,
          accountStatus: UserStatus.values.firstWhere(
            (e) => e.name == cachedUser.accountStatus,
            orElse: () => UserStatus.active,
          ),
          gender: cachedUser.gender,
          avatarUrl: cachedUser.avatarUrl,
          roles: roles,
          phoneNumbers: phoneNumbers,
          createdAt: cachedUser.createdAt,
          updatedAt: cachedUser.updatedAt,
          preferredPaymentMethod: 'cash',
          addresses: client?.addresses.map((a) => AddressMapper.fromModel(a)).toList() ?? const [],
        );
      }
    }
    return null;
  }

  Future<void> _syncToCache(
    UserRemoteModel userModel,
    CustomerProfileRemoteModel clientProfileModel,
    TechnicianProfileRemoteModel? technicianProfileModel,
  ) async {
    await localDataSource.cacheUser(UserProfileMapper.remoteToHive(userModel));
    await localDataSource.cacheClientProfile(
      ClientProfileHiveModel(
        uid: clientProfileModel.userId,
        addresses: clientProfileModel.addresses,
        phoneNumbers: clientProfileModel.phoneNumbers,
      ),
    );
    if (technicianProfileModel != null) {
      await localDataSource.cacheTechnicianProfile(
        TechnicianProfileHiveModel(
          userId: technicianProfileModel.userId,
          bio: technicianProfileModel.bio,
          rating: technicianProfileModel.rating,
          completedJobs: technicianProfileModel.completedJobs,
          isVerified: technicianProfileModel.isVerified,
          isAvailable: technicianProfileModel.isAvailable,
          serviceArea: technicianProfileModel.serviceArea,
          createdAt: technicianProfileModel.createdAt,
          updatedAt: technicianProfileModel.updatedAt,
        ),
      );
    }
  }

  Future<UserProfile> _getUnifiedProfile(
    String uid, {
    bool forceRemote = false,
  }) async {
    if (!forceRemote) {
      final cached = _fromCache();
      if (cached != null && cached.uid == uid) {
        return cached;
      }
    }

    final userModel = await userRemoteDataSource.getUserById(uid);
    if (userModel == null) {
      throw const SupabaseExceptionApp(
        'User profile not found in database',
        code: 'profile_not_found',
      );
    }
    final clientProfileRemoteModel = await _requireClientProfile(uid);
    final techProfileRemoteModel = await _fetchTechnicianProfile(
      uid,
      userModel,
    );

    await _syncToCache(
      userModel,
      clientProfileRemoteModel,
      techProfileRemoteModel,
    );

    return UserProfileMapper.remoteToEntity(
      userModel: userModel,
      customerModel: clientProfileRemoteModel,
      technicianModel: techProfileRemoteModel,
    );
  }

  @override
  Future<Either<Failure, UserProfile>> loadProfile() async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) {
        return Left(
          AuthFailure(message: 'unauthenticated', code: 'unauthenticated'),
        );
      }

      final cached = _fromCache();
      if (cached != null && cached.uid == uid) {
        return Right(await _enrichTechnicianProfile(cached));
      }

      final unified = await _getUnifiedProfile(uid);
      return Right(await _enrichTechnicianProfile(unified));
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExternalServiceError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> updateUserName({
    required String firstName,
    required String lastName,
  }) async {
    try {
      final current = await _requireCurrentUserModel();
      final updated = current.copyWith(
        firstName: firstName,
        lastName: lastName,
        updatedAt: DateTime.now(),
      );
      await userRemoteDataSource.updateUser(user: updated);

      final clientProfile = await _requireClientProfile(current.id);
      final techProfile = await _fetchTechnicianProfile(current.id, updated);
      await _syncToCache(updated, clientProfile, techProfile);

      final unified = await _getUnifiedProfile(current.id, forceRemote: true);
      return Right(await _enrichTechnicianProfile(unified));
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExternalServiceError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> updateProfile({
    String? firstName,
    String? lastName,
    String? gender,
    String? avatarUrl,
  }) async {
    try {
      final current = await _requireCurrentUserModel();
      final updated = current.copyWith(
        firstName: firstName ?? current.firstName,
        lastName: lastName ?? current.lastName,
        gender: gender ?? current.gender,
        avatarUrl: avatarUrl ?? current.avatarUrl,
        updatedAt: DateTime.now(),
      );
      await userRemoteDataSource.updateUser(user: updated);

      final clientProfile = await _requireClientProfile(current.id);
      final techProfile = await _fetchTechnicianProfile(current.id, updated);
      await _syncToCache(updated, clientProfile, techProfile);

      final unified = await _getUnifiedProfile(current.id, forceRemote: true);
      return Right(await _enrichTechnicianProfile(unified));
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExternalServiceError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  Future<UserRemoteModel> _getOrFetchUserRemote(String uid) async {
    final cached = _fromCache();
    if (cached != null && cached.uid == uid) {
      return UserProfileMapper.entityToRemote(cached);
    }
    final model = await userRemoteDataSource.getUserById(uid);
    if (model == null) {
      throw const SupabaseExceptionApp(
        'User profile not found in database',
        code: 'profile_not_found',
      );
    }
    return model;
  }

  @override
  Future<Either<Failure, UserProfile>> updatePhoneNumbers({
    required List<Phone> phoneNumbers,
  }) async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) {
        throw const AppAuthException(
          'unauthenticated',
          code: 'unauthenticated',
        );
      }

      final profile = await _requireClientProfile(uid);
      final updated = CustomerProfileRemoteModel(
        userId: uid,
        preferredPaymentMethod: profile.preferredPaymentMethod,
        addresses: profile.addresses,
        phoneNumbers: phoneNumbers.map((e) => PhoneMapper.toModel(e)).toList(),
      );
      await clientProfileRemoteDataSource.saveClientProfile(updated);

      final unified = await _getUnifiedProfile(uid, forceRemote: true);
      return Right(await _enrichTechnicianProfile(unified));
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExternalServiceError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> addAddress({
    required Address address,
  }) async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) {
        throw const AppAuthException(
          'unauthenticated',
          code: 'unauthenticated',
        );
      }

      final profile = await _requireClientProfile(uid);
      final updatedAddresses = List.of(profile.addresses)
        ..add(AddressMapper.toModel(address));

      final updated = CustomerProfileRemoteModel(
        userId: uid,
        preferredPaymentMethod: profile.preferredPaymentMethod,
        addresses: updatedAddresses,
        phoneNumbers: profile.phoneNumbers,
      );
      await clientProfileRemoteDataSource.saveClientProfile(updated);

      final unified = await _getUnifiedProfile(uid, forceRemote: true);
      return Right(await _enrichTechnicianProfile(unified));
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExternalServiceError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> updateAddress({
    required int index,
    required Address address,
  }) async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) {
        throw const AppAuthException(
          'unauthenticated',
          code: 'unauthenticated',
        );
      }

      final profile = await _requireClientProfile(uid);
      if (index < 0 || index >= profile.addresses.length) {
        return Left(
          ServerFailure(message: 'address_not_found', code: 'not_found'),
        );
      }

      final updatedAddresses = List.of(profile.addresses);
      updatedAddresses[index] = AddressMapper.toModel(address);

      final updated = CustomerProfileRemoteModel(
        userId: uid,
        preferredPaymentMethod: profile.preferredPaymentMethod,
        addresses: updatedAddresses,
        phoneNumbers: profile.phoneNumbers,
      );
      await clientProfileRemoteDataSource.saveClientProfile(updated);

      final unified = await _getUnifiedProfile(uid, forceRemote: true);
      return Right(await _enrichTechnicianProfile(unified));
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExternalServiceError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> deleteAddress({
    required int index,
  }) async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) {
        throw const AppAuthException(
          'unauthenticated',
          code: 'unauthenticated',
        );
      }
      final profile = await _requireClientProfile(uid);
      if (index < 0 || index >= profile.addresses.length) {
        return Left(
          ServerFailure(message: 'address_not_found', code: 'not_found'),
        );
      }

      final updatedAddresses = List.of(profile.addresses)..removeAt(index);

      final updated = CustomerProfileRemoteModel(
        userId: uid,
        preferredPaymentMethod: profile.preferredPaymentMethod,
        addresses: updatedAddresses,
        phoneNumbers: profile.phoneNumbers,
      );
      await clientProfileRemoteDataSource.saveClientProfile(updated);

      final unified = await _getUnifiedProfile(uid, forceRemote: true);
      return Right(await _enrichTechnicianProfile(unified));
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExternalServiceError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  Future<List<CapacityPool>> _fetchRemoteCapacityPools(String uid) async {
    try {
      final response = await supabase
          .from('capacity_pools')
          .select()
          .eq('technician_id', uid)
          .order('created_at');
      return (response as List)
          .map((json) => CapacityPoolRemoteModel.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error fetching capacity pools: $e');
      return [];
    }
  }

  Future<List<TechnicianSkill>> _fetchRemoteTechnicianSkills(String uid) async {
    try {
      final response = await supabase
          .from('technician_skills')
          .select()
          .eq('technician_id', uid)
          .eq('is_active', true);
      return (response as List)
          .map((json) => TechnicianSkillRemoteModel.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error fetching technician skills: $e');
      return [];
    }
  }

  Future<Map<String, String>> _fetchSubServiceNames(List<String> subServiceIds) async {
    if (subServiceIds.isEmpty) return {};
    try {
      final response = await supabase
          .from('services')
          .select('id, title')
          .inFilter('id', subServiceIds);
      final Map<String, String> names = {};
      for (var item in (response as List)) {
        final id = item['id'] as String;
        final titleMap = item['title'] as Map<String, dynamic>?;
        final arName = titleMap?['ar'] as String? ?? id;
        names[id] = arName;
      }
      return names;
    } catch (e) {
      debugPrint('Error fetching sub service names: $e');
      return {};
    }
  }

  Future<UserProfile> _enrichTechnicianProfile(UserProfile profile) async {
    if (profile is TechnicianProfile) {
      final pools = await _fetchRemoteCapacityPools(profile.uid);
      final skills = await _fetchRemoteTechnicianSkills(profile.uid);
      final names = await _fetchSubServiceNames(skills.map((s) => s.subServiceId).toList());
      
      return TechnicianProfile(
        uid: profile.uid,
        firstName: profile.firstName,
        lastName: profile.lastName,
        email: profile.email,
        accountStatus: profile.accountStatus,
        gender: profile.gender,
        avatarUrl: profile.avatarUrl,
        roles: profile.roles,
        phoneNumbers: profile.phoneNumbers,
        createdAt: profile.createdAt,
        updatedAt: profile.updatedAt,
        mainServiceId: profile.mainServiceId,
        bio: profile.bio,
        rating: profile.rating,
        completedJobs: profile.completedJobs,
        isVerified: profile.isVerified,
        isAvailable: profile.isAvailable,
        serviceArea: profile.serviceArea,
        capacityPools: pools,
        technicianSkills: skills,
        subServiceNames: names,
      );
    }
    return profile;
  }
}
