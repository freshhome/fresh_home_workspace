import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_remote_model.dart';
import 'package:shared/core/error/exceptions.dart';

abstract class NotificationRemoteDataSource {
  Stream<List<NotificationRemoteModel>> watchNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> registerFcmToken({
    required String userId,
    required String deviceId,
    required String token,
    required String platform,
  });
  Future<void> deleteFcmToken(String userId, String deviceId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final SupabaseClient _supabase;
  final String _tableName = 'notifications';
  final String _tokensTable = 'user_fcm_tokens';

  NotificationRemoteDataSourceImpl(this._supabase);

  @override
  Stream<List<NotificationRemoteModel>> watchNotifications(String userId) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => NotificationRemoteModel.fromJson(json)).toList());
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from(_tableName)
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from(_tableName)
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }

  @override
  Future<void> registerFcmToken({
    required String userId,
    required String deviceId,
    required String token,
    required String platform,
  }) async {
    try {
      await _supabase.from(_tokensTable).upsert({
        'user_id': userId,
        'device_id': deviceId,
        'fcm_token': token,
        'platform': platform,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,device_id');
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }

  @override
  Future<void> deleteFcmToken(String userId, String deviceId) async {
    try {
      await _supabase
          .from(_tokensTable)
          .delete()
          .eq('user_id', userId)
          .eq('device_id', deviceId);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }
}
