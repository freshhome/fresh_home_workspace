import 'package:shared/data/user/mappers/user_roles_mappers.dart';
import 'package:shared/data/user/models/local/user_hive_model.dart';
import 'package:shared/data/user/models/remote/user_remote_model.dart';
import 'package:shared/domain/user/entities/user/user.dart';
import 'package:shared/domain/user/enums/user_status.dart';

class UserMapper {
  // من هايف لانتتي
  static User hiveToEntity(UserHiveModel model) {
    return User(
      customId: model.customId,
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
      roles: userRoleFromCode(codes: model.rolesCodes),
      phones: model.phones,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  // من انتتي لهايف
  static UserHiveModel entityToHive(User model) {
    return UserHiveModel(
      customId: model.customId,
      uid: model.uid,
      firstName: model.firstName,
      lastName: model.lastName,
      email: model.email,
      accountStatus: model.accountStatus.name,
      gender: model.gender,
      avatarUrl: model.avatarUrl,
      rolesCodes: userRoleToCode(userRoles: model.roles),
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      phones: model.phones,
    );
  }

  // من انتتي لريموت
  static UserRemoteModel entityToRemote(User model) {
    return UserRemoteModel(
      id: model.uid, // Map uid to id
      firstName: model.firstName,
      lastName: model.lastName,
      email: model.email,
      accountStatus: model.accountStatus,
      gender: model.gender,
      avatarUrl: model.avatarUrl,
      roles: model.roles,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  // من ريموت لانتتي
  static User remoteToEntity(UserRemoteModel model) {
    return User(
      customId: 0, // Not in Supabase profiles table
      uid: model.id, // Map id to uid
      firstName: model.firstName,
      lastName: model.lastName,
      email: model.email,
      accountStatus: model.accountStatus,
      gender: model.gender,
      avatarUrl: model.avatarUrl,
      roles: model.roles,
      phones: model.phones?.map((p) => p.phoneNumber).toList() ?? [],
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  // من ريموت لهايف
  static UserHiveModel remoteToHive(UserRemoteModel model) {
    return UserHiveModel(
      customId: 0, // Not in Supabase
      uid: model.id, // Map id back to uid for local storage
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

  // من هايف لريموت
  static UserRemoteModel hiveToRemote(UserHiveModel model) {
    return UserRemoteModel(
      id: model.uid,
      firstName: model.firstName,
      lastName: model.lastName,
      email: model.email,
      accountStatus: UserStatus.values.firstWhere(
        (e) => e.name == model.accountStatus,
        orElse: () => UserStatus.active,
      ),
      gender: model.gender,
      avatarUrl: model.avatarUrl,
      roles: userRoleFromCode(codes: model.rolesCodes),
      phones: model.phones
          .map((p) => UserPhoneRemoteModel(
                id: '',
                phoneNumber: p,
                isPrimary: false,
                isVerified: false,
              ))
          .toList(),
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
}
