import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared/shared.dart';
import 'package:shared_features/src/features/notifications/presentation/cubit/notification_cubit.dart';

class FirebaseMessagingHandler {
  final NotificationCubit _notificationCubit;
  final NavigationService _navigationService;
  final UserRole _appRole;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  FirebaseMessagingHandler(this._notificationCubit, this._navigationService, this._appRole);

  static Future<void> initializeBackgroundHandling() async {
    if (kIsWeb) {
      debugPrint('🔔 [FirebaseMessagingHandler] Background handling skipped on Web.');
      return;
    }
    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('⚠️ [FirebaseMessagingHandler] Failed to initialize background handling: $e');
    }
  }

  bool _isInitialized = false;

  Future<void> initializeForegroundHandling() async {
    if (_isInitialized) return;
    _isInitialized = true;

    if (kIsWeb) {
      debugPrint('🔔 [FirebaseMessagingHandler] Foreground handling skipped on Web.');
      return;
    }

    // 1. Initialize Local Notifications (For Foreground System Tray)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 Notification clicked with payload: ${response.payload}');
        if (response.payload != null) {
          // Convert payload string back to data map if needed, 
          // but RemoteMessage already handles background clicks.
          // This is for foreground clicks.
        }
      },
    );

    // 2. Create High Importance Android Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'fresh_home_notifications', // id
      'Fresh Home Notifications', // title
      description: 'This channel is dedicated to order notifications and important messages.', // description
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Set iOS/MacOS presentation options
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 [FirebaseMessagingHandler] Got a message in the foreground!');
      
      if (message.notification != null) {
        // Refresh notifications list UI
        _notificationCubit.refresh();

        // Show standard system notification (No more snackerbar!)
        _showSystemNotification(message, channel);
      }
    });

    // 5. Handle messages that opened the app from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🚀 [FirebaseMessagingHandler] App opened from notification!');
      _handleNotificationClick(message);
    });

    // 6. Check for initial message (if app was terminated)
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🏁 [FirebaseMessagingHandler] App launched from terminated state via notification!');
      _handleNotificationClick(initialMessage);
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    final bookingId = message.data['booking_id'];
    if (bookingId == null) return;

    debugPrint('📍 [FirebaseMessagingHandler] Deep-linking to booking: $bookingId for role: $_appRole');

    String path;
    switch (_appRole) {
      case UserRole.admin:
        path = '/admin/bookings/detail/$bookingId';
        break;
      case UserRole.technician:
        path = '/technician-order-details/$bookingId';
        break;
      case UserRole.client:
        path = '/order-details/$bookingId';
        break;
    }

    _navigationService.push(path);
  }

  void _showSystemNotification(RemoteMessage message, AndroidNotificationChannel channel) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 [BackgroundHandler] Handling a background message: ${message.messageId}');
}
