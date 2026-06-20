import 'dart:async';

abstract class WhatsAppSettingsRepository {
  Future<Map<String, dynamic>> getWhatsAppSettings();
  Future<void> saveWhatsAppSettings(Map<String, dynamic> settings);
}
