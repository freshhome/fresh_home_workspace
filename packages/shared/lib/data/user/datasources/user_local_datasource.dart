
import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';
import 'package:shared/data/user/models/local/user_hive_model.dart';
import 'package:shared/core/error/exceptions.dart';

abstract class UserLocalDataSource {
  // Methods for the logged-in user session
  Future<void> cacheCurrentUser(UserHiveModel user);
  Future<UserHiveModel?> getCurrentUser();
  Future<void> clearUser();

  // Methods for caching any user profile by ID
  Future<void> cacheUser(UserHiveModel user);
  Future<UserHiveModel?> getUserById(String uid);
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  Future<Box> _openBox() async {
    if (!Hive.isBoxOpen(HiveBoxNames.userBox)) {
      return await Hive.openBox(HiveBoxNames.userBox);
    }
    return Hive.box(HiveBoxNames.userBox);
  }

  @override
  Future<void> cacheCurrentUser(UserHiveModel user) async {
    try {
      final box = await _openBox();
      await box.put('current_user', user);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> cacheUser(UserHiveModel user) async {
    try {
      final box = await _openBox();
      await box.put(user.uid, user); // Use UID for general cache
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> clearUser() async {
    try {
      final box = await _openBox();
      await box.clear();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<UserHiveModel?> getCurrentUser() async {
    try {
      final box = await _openBox();
      final data = box.get('current_user');
      return data as UserHiveModel?;
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<UserHiveModel?> getUserById(String uid) async {
    try {
      final box = await _openBox();
      final data = box.get(uid);
      return data as UserHiveModel?;
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
