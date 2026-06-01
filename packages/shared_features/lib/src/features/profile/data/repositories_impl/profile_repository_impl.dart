import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:shared/core/error/exceptions.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/core/error/error_mapper.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/user/entities/user/phone.dart';
import 'package:shared/data/user/mappers/address_mapper.dart';
import 'package:shared/data/user/mappers/user_mapper.dart';
import 'package:shared/data/user/mappers/client_profile_mapper.dart';
import 'package:shared/data/user/mappers/phone_mapper.dart';
import 'package:shared/data/user/models/local/client_profile_hive_model.dart';
import 'package:shared/data/user/models/remote/client_profile_remote_model.dart';
import 'package:shared/data/user/models/remote/user_remote_model.dart';
import 'package:shared/data/user/datasources/user_remote_datasource.dart';

import 'package:shared_features/src/features/authentication/data/authentication_data.dart';
import 'package:shared/domain/user/enums/user_role.dart';
import 'package:shared/data/user/mappers/technician_profile_mapper.dart';
import 'package:shared/data/user/models/remote/technician_profile_remote_model.dart';
import 'package:shared_features/src/features/profile/data/data_sources/technician_profile_remote_data_source.dart';
import 'package:shared_features/src/features/profile/data/data_sources/client_profile_remote_data_source.dart';
import 'package:shared_features/src/features/profile/domain/entities/user_with_profile.dart';
import 'package:shared_features/src/features/profile/domain/repositories/profile_repository.dart';

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

  Future<ClientProfileRemoteModel> _requireClientProfile(String uid) async {
    final profile = await clientProfileRemoteDataSource.getClientProfile(uid);
    if (profile == null) {
      final newProfile = ClientProfileRemoteModel(
        uid: uid,
        addresses: [],
        phoneNumbers: [],
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

  UserWithProfile? _fromCache() {
    final cachedUser = localDataSource.getCachedUser();
    final cachedProfile = localDataSource.getCachedClientProfile();
    final cachedTechProfile = localDataSource.getCachedTechnicianProfile();

    if (cachedUser != null) {
      return UserWithProfile(
        user: UserMapper.hiveToEntity(cachedUser),
        clientProfile: cachedProfile != null
            ? ClientProfileMapper.fromHive(cachedProfile)
            : null,
        technicianProfile: cachedTechProfile != null
            ? TechnicianProfileMapper.fromHive(cachedTechProfile)
            : null,
      );
    }
    return null;
  }

  Future<void> _syncToCache(
    UserRemoteModel userModel,
    ClientProfileRemoteModel clientProfileModel,
    TechnicianProfileRemoteModel? technicianProfileModel,
  ) async {
    await localDataSource.cacheUser(UserMapper.remoteToHive(userModel));
    await localDataSource.cacheClientProfile(
      ClientProfileHiveModel(
        uid: clientProfileModel.uid,
        addresses: clientProfileModel.addresses,
        phoneNumbers: clientProfileModel.phoneNumbers,
      ),
    );
    if (technicianProfileModel != null) {
      await localDataSource.cacheTechnicianProfile(
        TechnicianProfileMapper.toHive(technicianProfileModel),
      );
    }
  }

  Future<UserWithProfile> _getUnifiedProfile(
    String uid, {
    bool forceRemote = false,
  }) async {
    if (!forceRemote) {
      final cached = _fromCache();
      if (cached != null && cached.user.uid == uid) {
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

    final profile = UserWithProfile(
      user: UserMapper.remoteToEntity(userModel),
      clientProfile: ClientProfileMapper.fromRemote(clientProfileRemoteModel),
      technicianProfile: techProfileRemoteModel != null
          ? TechnicianProfileMapper.fromRemote(techProfileRemoteModel)
          : null,
    );

    return profile;
  }

  @override
  Future<Either<Failure, UserWithProfile>> loadProfile() async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) {
        return Left(
          AuthFailure(message: 'unauthenticated', code: 'unauthenticated'),
        );
      }

      final cached = _fromCache();
      if (cached != null && cached.user.uid == uid) {
        if (cached.clientProfile != null) {
          return Right(cached);
        } else {
          final clientProfile = await _requireClientProfile(uid);
          final userRemote = UserMapper.entityToRemote(cached.user);
          final techProfile = await _fetchTechnicianProfile(uid, userRemote);
          await _syncToCache(userRemote, clientProfile, techProfile);

          return Right(
            UserWithProfile(
              user: cached.user,
              clientProfile: ClientProfileMapper.fromRemote(clientProfile),
              technicianProfile: techProfile != null
                  ? TechnicianProfileMapper.fromRemote(techProfile)
                  : null,
            ),
          );
        }
      }

      final unified = await _getUnifiedProfile(uid);
      return Right(unified);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExternalServiceError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserWithProfile>> updateUserName({
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

      return Right(await _getUnifiedProfile(current.id));
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExternalServiceError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserWithProfile>> updateProfile({
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

      return Right(await _getUnifiedProfile(current.id));
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExternalServiceError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  Future<UserRemoteModel> _getOrFetchUserRemote(String uid) async {
    final cached = _fromCache();
    if (cached != null && cached.user.uid == uid) {
      return UserMapper.entityToRemote(cached.user);
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
  Future<Either<Failure, UserWithProfile>> updatePhoneNumbers({
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
      final updated = ClientProfileRemoteModel(
        uid: uid,
        addresses: profile.addresses,
        phoneNumbers: phoneNumbers.map((e) => PhoneMapper.toModel(e)).toList(),
      );
      await clientProfileRemoteDataSource.saveClientProfile(updated);

      final freshProfile = await _requireClientProfile(uid);
      final userModel = await _getOrFetchUserRemote(uid);
      final techProfile = await _fetchTechnicianProfile(uid, userModel);
      await _syncToCache(userModel, freshProfile, techProfile);

      return Right(
        UserWithProfile(
          user: UserMapper.remoteToEntity(userModel),
          clientProfile: ClientProfileMapper.fromRemote(freshProfile),
          technicianProfile: techProfile != null
              ? TechnicianProfileMapper.fromRemote(techProfile)
              : null,
        ),
      );
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExternalServiceError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserWithProfile>> addAddress({
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

      final updated = ClientProfileRemoteModel(
        uid: uid,
        addresses: updatedAddresses,
        phoneNumbers: profile.phoneNumbers,
      );
      await clientProfileRemoteDataSource.saveClientProfile(updated);

      final freshProfile = await _requireClientProfile(uid);
      final userModel = await _getOrFetchUserRemote(uid);
      final techProfile = await _fetchTechnicianProfile(uid, userModel);
      await _syncToCache(userModel, freshProfile, techProfile);

      return Right(
        UserWithProfile(
          user: UserMapper.remoteToEntity(userModel),
          clientProfile: ClientProfileMapper.fromRemote(freshProfile),
          technicianProfile: techProfile != null
              ? TechnicianProfileMapper.fromRemote(techProfile)
              : null,
        ),
      );
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExternalServiceError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserWithProfile>> updateAddress({
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

      final updated = ClientProfileRemoteModel(
        uid: uid,
        addresses: updatedAddresses,
        phoneNumbers: profile.phoneNumbers,
      );
      await clientProfileRemoteDataSource.saveClientProfile(updated);

      final freshProfile = await _requireClientProfile(uid);
      final userModel = await _getOrFetchUserRemote(uid);
      final techProfile = await _fetchTechnicianProfile(uid, userModel);
      await _syncToCache(userModel, freshProfile, techProfile);

      return Right(
        UserWithProfile(
          user: UserMapper.remoteToEntity(userModel),
          clientProfile: ClientProfileMapper.fromRemote(freshProfile),
          technicianProfile: techProfile != null
              ? TechnicianProfileMapper.fromRemote(techProfile)
              : null,
        ),
      );
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExternalServiceError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserWithProfile>> deleteAddress({
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

      final updated = ClientProfileRemoteModel(
        uid: uid,
        addresses: updatedAddresses,
        phoneNumbers: profile.phoneNumbers,
      );
      await clientProfileRemoteDataSource.saveClientProfile(updated);

      final freshProfile = await _requireClientProfile(uid);
      final userModel = await _getOrFetchUserRemote(uid);
      final techProfile = await _fetchTechnicianProfile(uid, userModel);
      await _syncToCache(userModel, freshProfile, techProfile);

      return Right(
        UserWithProfile(
          user: UserMapper.remoteToEntity(userModel),
          clientProfile: ClientProfileMapper.fromRemote(freshProfile),
          technicianProfile: techProfile != null
              ? TechnicianProfileMapper.fromRemote(techProfile)
              : null,
        ),
      );
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExternalServiceError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
