import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/core/error/exceptions.dart';
import '../models/notification_campaign_model.dart';

abstract class NotificationManagementRemoteDataSource {
  Future<List<NotificationCampaignModel>> fetchCampaigns({required int limit, required int offset});
  Future<NotificationCampaignModel> insertCampaign(NotificationCampaignModel campaign);
  Future<NotificationCampaignModel> updateCampaignStatus(String id, String newStatus);
  Future<String> uploadImage(File file, String userId);
}

class NotificationManagementRemoteDataSourceImpl implements NotificationManagementRemoteDataSource {
  final SupabaseClient _supabase;
  final String _tableName = 'notification_campaigns';
  final String _bucketName = 'notification_images';

  NotificationManagementRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<NotificationCampaignModel>> fetchCampaigns({required int limit, required int offset}) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((e) => NotificationCampaignModel.fromJson(e)).toList();
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'fetch_campaigns_error');
    }
  }

  @override
  Future<NotificationCampaignModel> insertCampaign(NotificationCampaignModel campaign) async {
    try {
      final jsonPayload = campaign.toJson();
      // Remove ID for insertion so DB generates it
      jsonPayload.remove('id'); 
      jsonPayload['created_by'] = _supabase.auth.currentUser?.id;

      final response = await _supabase.from(_tableName).insert(jsonPayload).select().single();
      return NotificationCampaignModel.fromJson(response);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'insert_campaign_error');
    }
  }

  @override
  Future<NotificationCampaignModel> updateCampaignStatus(String id, String newStatus) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .update({'status': newStatus})
          .eq('id', id)
          .select()
          .single();
      return NotificationCampaignModel.fromJson(response);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'update_status_error');
    }
  }

  @override
  Future<String> uploadImage(File file, String userId) async {
    try {
      final ext = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.$ext';
      
      await _supabase.storage.from(_bucketName).upload(fileName, file);
      
      final publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'upload_image_error');
    }
  }
}
