import 'package:flutter/material.dart';
import 'package:fresh_home_staff/fresh_home_staff_app.dart';
import 'package:shared_features/shared_features.dart';
import 'core/di/injection_container.dart' as di;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Initialize background handling
    await FirebaseMessagingHandler.initializeBackgroundHandling();
  } catch (e) {
    debugPrint('🚨 Firebase Initialization failed: $e');
  }

  // 2. Initialize DI (includes shared features)
  await di.initAppDI();

  runApp(const FreshHomeStaffApp());
}
