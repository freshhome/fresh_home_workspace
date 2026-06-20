import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/whatsapp_settings_repository.dart';

class WhatsAppSettingsRepositoryImpl implements WhatsAppSettingsRepository {
  final SupabaseClient _client;

  WhatsAppSettingsRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<Map<String, dynamic>> getWhatsAppSettings() async {
    final response = await _client
        .from('system_settings')
        .select('value')
        .eq('key', 'whatsapp_settings')
        .maybeSingle();

    if (response != null && response['value'] != null) {
      return Map<String, dynamic>.from(response['value'] as Map);
    }
    return {};
  }

  @override
  Future<void> saveWhatsAppSettings(Map<String, dynamic> settings) async {
    final currentUserId = _client.auth.currentUser?.id;
    await _client.from('system_settings').upsert({
      'key': 'whatsapp_settings',
      'value': settings,
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': currentUserId,
    });
  }
}
