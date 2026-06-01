
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared/core/constants/hive_constants.dart';
import 'package:shared/data/user/models/local/client_profile_hive_model.dart';
import 'package:shared/data/user/models/local/technician_profile_hive_model.dart';
import 'package:shared/data/user/models/local/user_hive_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserHiveModel user);
  UserHiveModel? getCachedUser();
  Future<void> cacheClientProfile(ClientProfileHiveModel profile);
  ClientProfileHiveModel? getCachedClientProfile();
  Future<void> cacheTechnicianProfile(TechnicianProfileHiveModel profile);
  TechnicianProfileHiveModel? getCachedTechnicianProfile();
  Future<void> clearCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  Box get _userBox => Hive.box(HiveBoxNames.userBox);

  AuthLocalDataSourceImpl();

  @override
  Future<void> cacheUser(UserHiveModel user) async {
    await _userBox.put('current_user', user);
  }

  @override
  UserHiveModel? getCachedUser() {
    return _userBox.get('current_user') as UserHiveModel?;
  }

  @override
  Future<void> cacheClientProfile(ClientProfileHiveModel profile) async {
    await _userBox.put('client_profile', profile);
  }

  @override
  ClientProfileHiveModel? getCachedClientProfile() {
    return _userBox.get('client_profile') as ClientProfileHiveModel?;
  }

  @override
  Future<void> cacheTechnicianProfile(TechnicianProfileHiveModel profile) async {
    await _userBox.put('technician_profile', profile);
  }

  @override
  TechnicianProfileHiveModel? getCachedTechnicianProfile() {
    return _userBox.get('technician_profile') as TechnicianProfileHiveModel?;
  }

  @override
  Future<void> clearCache() async {
    await _userBox.delete('current_user');
    await _userBox.delete('client_profile');
    await _userBox.delete('technician_profile');
  }
}
