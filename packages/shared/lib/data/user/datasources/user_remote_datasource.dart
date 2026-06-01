import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:shared/data/user/models/remote/user_remote_model.dart';
import 'package:shared/core/error/exceptions.dart';

abstract class UserRemoteDataSource {
  Future<void> createUser({required UserRemoteModel user});
  Future<UserRemoteModel?> getUserById(String uid);
  Future<List<UserRemoteModel>> getAllUsers();
  Future<void> updateUser({required UserRemoteModel user});
  Future<void> deleteUser(String uid);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final SupabaseClient _supabase;
  final String _tableName = 'profiles';

  UserRemoteDataSourceImpl(this._supabase);

  @override
  Future<void> createUser({required UserRemoteModel user}) async {
    try {
      await _supabase.from(_tableName).upsert(user.toJson());
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }

  @override
  Future<UserRemoteModel?> getUserById(String id) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('*, user_roles(roles(name)), user_phones(*)')
          .eq('id', id)
          .maybeSingle();
      
      if (response == null) return null;
      
      return UserRemoteModel.fromJson(response);

    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }

  @override
  Future<List<UserRemoteModel>> getAllUsers() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('*, user_roles(roles(name)), user_phones(*)')
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => UserRemoteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }

  @override
  Future<void> updateUser({required UserRemoteModel user}) async {
    try {
      await _supabase
          .from(_tableName)
          .update(user.toJson())
          .eq('id', user.id);
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', id);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }
}
