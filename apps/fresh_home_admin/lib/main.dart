import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fresh_home_admin/core/di/injection_container.dart' as di;
import 'package:shared_features/shared_features.dart';
import 'firebase_options.dart';
import 'fresh_home_admin_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // Initialize background handling
      await FirebaseMessagingHandler.initializeBackgroundHandling();
    } catch (e) {
      debugPrint('🚨 Firebase Initialization failed: $e');
    }
  } else {
    debugPrint('ℹ️ Firebase initialization skipped on Web.');
  }

  // 2. Initialize DI (includes shared features and navigation)
  await di.initAppDI();

  runApp(const FreshHomeAdminApp());
}
