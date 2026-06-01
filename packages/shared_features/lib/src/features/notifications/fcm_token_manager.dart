import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_features/src/features/notifications/domain/entities/fcm_token.dart';
import 'package:shared_features/src/features/notifications/domain/usecases/manage_fcm_token_use_case.dart';

class FcmTokenManager {
  final FirebaseMessaging? _fcm;
  final ManageFcmTokenUseCase _manageFcmTokenUseCase;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  FcmTokenManager(this._manageFcmTokenUseCase) : _fcm = _initFirebaseMessaging();

  static FirebaseMessaging? _initFirebaseMessaging() {
    if (kIsWeb) return null;
    try {
      return FirebaseMessaging.instance;
    } catch (e) {
      debugPrint('⚠️ [FcmTokenManager] FirebaseMessaging is not supported or not initialized: $e');
      return null;
    }
  }

  Future<void> initialize(String userId) async {
    final fcmInstance = _fcm;
    if (fcmInstance == null) {
      debugPrint('🔔 [FcmTokenManager] Firebase Messaging is disabled/unsupported on this platform.');
      return;
    }
    try {
      // 1. Request permissions
      NotificationSettings settings = await fcmInstance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('🔔 [FcmTokenManager] User granted permission');
        
        // 2. Get and Register Token
        await _registerCurrentToken(userId);

        // 3. Listen for token refresh
        fcmInstance.onTokenRefresh.listen((newToken) {
          _updateToken(userId, newToken);
        });
      } else {
        debugPrint('🔕 [FcmTokenManager] User declined or has not accepted permission');
      }
    } catch (e) {
      debugPrint('❌ [FcmTokenManager] Error during initialization: $e');
    }
  }

  Future<void> _registerCurrentToken(String userId) async {
    final fcmInstance = _fcm;
    if (fcmInstance == null) return;
    try {
      String? token = await fcmInstance.getToken();
      if (token != null) {
        await _updateToken(userId, token);
      }
    } catch (e) {
      debugPrint('❌ [FcmTokenManager] Error getting FCM token: $e');
    }
  }

  Future<void> _updateToken(String userId, String token) async {
    final deviceId = await _getDeviceId();
    final platform = kIsWeb ? 'web' : Platform.operatingSystem;

    final fcmToken = FcmToken(
      userId: userId,
      deviceId: deviceId,
      token: token,
      platform: platform,
    );

    final result = await _manageFcmTokenUseCase.register(fcmToken);
    result.fold(
      (failure) => debugPrint('❌ [FcmTokenManager] Failed to register token: ${failure.message}'),
      (_) => debugPrint('✅ [FcmTokenManager] Token registered successfully for user: $userId'),
    );
  }

  Future<void> deleteToken(String userId) async {
    final deviceId = await _getDeviceId();
    final result = await _manageFcmTokenUseCase.delete(userId, deviceId);
    result.fold(
      (failure) => debugPrint('❌ [FcmTokenManager] Failed to delete token: ${failure.message}'),
      (_) => debugPrint('🗑️ [FcmTokenManager] Token deleted successfully'),
    );
  }

  Future<String> _getDeviceId() async {
    if (kIsWeb) {
      final webBrowserInfo = await _deviceInfo.webBrowserInfo;
      return webBrowserInfo.userAgent ?? 'web_browser';
    }
    
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'ios_device';
    }
    
    return 'unknown_device';
  }
}
