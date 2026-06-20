import 'package:shared/data/user/mappers/address_mapper.dart';
import 'package:shared/data/user/mappers/phone_mapper.dart';
import 'package:shared/data/user/mappers/user_roles_mappers.dart';
import 'package:shared/data/user/models/local/user_hive_model.dart';
import 'package:shared/data/user/models/remote/user_remote_model.dart';
import 'package:shared/data/user/models/remote/customer_profile_remote_model.dart';
import 'package:shared/data/user/models/remote/technician_profile_remote_model.dart';
import 'package:shared/data/user/models/remote/admin_profile_remote_model.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/user/entities/user/user_profile.dart';
import 'package:shared/domain/user/entities/user/phone.dart';
import 'package:shared/domain/user/entities/user/capacity_pool.dart';
import 'package:shared/domain/user/entities/user/technician_skill.dart';
import 'package:shared/domain/user/enums/user_role.dart';
import 'package:shared/domain/user/enums/user_status.dart';

class UserProfileMapper {
  UserProfileMapper._();

  /// Maps Remote models from database into domain entities
  static UserProfile remoteToEntity({
    required UserRemoteModel userModel,
    CustomerProfileRemoteModel? customerModel,
    TechnicianProfileRemoteModel? technicianModel,
    AdminProfileRemoteModel? adminModel,
    List<CapacityPool>? capacityPools,
    List<TechnicianSkill>? technicianSkills,
    Map<String, String>? subServiceNames,
  }) {
    final phoneNumbers = customerModel?.phoneNumbers.map((p) => PhoneMapper.fromModel(p)).toList() ?? 
                         userModel.phones?.map((p) => Phone(
                           id: p.id,
                           userId: userModel.id,
                           phoneNumber: p.phoneNumber,
                           isPrimary: p.isPrimary,
                           isVerified: p.isVerified,
                           createdAt: DateTime.now(),
                         )).toList() ?? const [];

    if (userModel.roles.contains(UserRole.admin)) {
      return AdminProfile(
        uid: userModel.id,
        firstName: userModel.firstName,
        lastName: userModel.lastName,
        email: userModel.email,
        accountStatus: userModel.accountStatus,
        gender: userModel.gender,
        avatarUrl: userModel.avatarUrl,
        roles: userModel.roles,
        phoneNumbers: phoneNumbers,
        createdAt: userModel.createdAt,
        updatedAt: userModel.updatedAt,
        adminPermissions: adminModel?.adminPermissions ?? const [],
      );
    } else if (userModel.roles.contains(UserRole.technician)) {
      return TechnicianProfile(
        uid: userModel.id,
        firstName: userModel.firstName,
        lastName: userModel.lastName,
        email: userModel.email,
        accountStatus: userModel.accountStatus,
        gender: userModel.gender,
        avatarUrl: userModel.avatarUrl,
        roles: userModel.roles,
        phoneNumbers: phoneNumbers,
        createdAt: userModel.createdAt,
        updatedAt: userModel.updatedAt,
        mainServiceId: technicianModel?.mainServiceId,
        bio: technicianModel?.bio,
        rating: technicianModel?.rating ?? 5.0,
        completedJobs: technicianModel?.completedJobs ?? 0,
        isVerified: technicianModel?.isVerified ?? false,
        isAvailable: technicianModel?.isAvailable ?? false,
        serviceArea: technicianModel?.serviceArea,
        capacityPools: capacityPools ?? const [],
        technicianSkills: technicianSkills ?? const [],
        subServiceNames: subServiceNames ?? const {},
      );
    } else {
      return CustomerProfile(
        uid: userModel.id,
        firstName: userModel.firstName,
        lastName: userModel.lastName,
        email: userModel.email,
        accountStatus: userModel.accountStatus,
        gender: userModel.gender,
        avatarUrl: userModel.avatarUrl,
        roles: userModel.roles,
        phoneNumbers: phoneNumbers,
        createdAt: userModel.createdAt,
        updatedAt: userModel.updatedAt,
        preferredPaymentMethod: customerModel?.preferredPaymentMethod ?? 'cash',
        addresses: customerModel?.addresses.map((a) => AddressMapper.fromModel(a)).toList() ?? 
                  userModel.addresses?.map((a) => Address(
                    id: a.id,
                    governorate: a.governorate,
                    city: a.city,
                    street: a.street,
                    buildingNumber: a.buildingNumber,
                    floorNumber: a.floor ?? '',
                    apartmentNumber: a.apartment ?? '',
                  )).toList() ?? const [],
      );
    }
  }

  /// Maps domain entity into UserRemoteModel for update/create database calls
  static UserRemoteModel entityToRemote(UserProfile entity) {
    return UserRemoteModel(
      id: entity.uid,
      firstName: entity.firstName,
      lastName: entity.lastName,
      email: entity.email,
      accountStatus: entity.accountStatus,
      gender: entity.gender,
      avatarUrl: entity.avatarUrl,
      roles: entity.roles,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Maps domain entity to Hive model for local caching
  static UserHiveModel entityToHive(UserProfile entity) {
    return UserHiveModel(
      uid: entity.uid,
      firstName: entity.firstName,
      lastName: entity.lastName,
      email: entity.email,
      accountStatus: entity.accountStatus.name,
      gender: entity.gender,
      avatarUrl: entity.avatarUrl,
      rolesCodes: userRoleToCode(userRoles: entity.roles),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      phones: entity.phoneNumbers.map((p) => p.phoneNumber).toList(),
    );
  }

  /// Maps Hive cache model to domain entity
  static UserProfile hiveToEntity(UserHiveModel model) {
    final roles = userRoleFromCode(codes: model.rolesCodes);
    final phoneNumbers = model.phones.map((p) => Phone(
      userId: model.uid,
      phoneNumber: p,
      isPrimary: false,
      isVerified: false,
      createdAt: DateTime.now(),
    )).toList();
    
    if (roles.contains(UserRole.admin)) {
      return AdminProfile(
        uid: model.uid,
        firstName: model.firstName,
        lastName: model.lastName,
        email: model.email,
        accountStatus: UserStatus.values.firstWhere(
          (e) => e.name == model.accountStatus,
          orElse: () => UserStatus.active,
        ),
        gender: model.gender,
        avatarUrl: model.avatarUrl,
        roles: roles,
        phoneNumbers: phoneNumbers,
        createdAt: model.createdAt,
        updatedAt: model.updatedAt,
        adminPermissions: const [],
      );
    } else if (roles.contains(UserRole.technician)) {
      return TechnicianProfile(
        uid: model.uid,
        firstName: model.firstName,
        lastName: model.lastName,
        email: model.email,
        accountStatus: UserStatus.values.firstWhere(
          (e) => e.name == model.accountStatus,
          orElse: () => UserStatus.active,
        ),
        gender: model.gender,
        avatarUrl: model.avatarUrl,
        roles: roles,
        phoneNumbers: phoneNumbers,
        createdAt: model.createdAt,
        updatedAt: model.updatedAt,
      );
    } else {
      return CustomerProfile(
        uid: model.uid,
        firstName: model.firstName,
        lastName: model.lastName,
        email: model.email,
        accountStatus: UserStatus.values.firstWhere(
          (e) => e.name == model.accountStatus,
          orElse: () => UserStatus.active,
        ),
        gender: model.gender,
        avatarUrl: model.avatarUrl,
        roles: roles,
        phoneNumbers: phoneNumbers,
        createdAt: model.createdAt,
        updatedAt: model.updatedAt,
        preferredPaymentMethod: 'cash',
        addresses: const [],
      );
    }
  }

  /// Maps UserRemoteModel directly to Hive model
  static UserHiveModel remoteToHive(UserRemoteModel model) {
    return UserHiveModel(
      uid: model.id,
      firstName: model.firstName,
      lastName: model.lastName,
      email: model.email,
      accountStatus: model.accountStatus.name,
      gender: model.gender,
      avatarUrl: model.avatarUrl,
      rolesCodes: userRoleToCode(userRoles: model.roles),
      phones: model.phones?.map((p) => p.phoneNumber).toList() ?? [],
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
}
