// import 'package:supabase_flutter/supabase_flutter.dart';

// void main() async {
//   print('🔍 Starting Notification System Diagnostic...');

//   const url = 'https://dsddwqdixsdhaspfafuy.supabase.co';
//   const anonKey = 'sb_publishable_vNlyMzHSX84GUhL-JWXqLA_S7shZml_';

//   try {
//     await Supabase.initialize(url: url, anonKey: anonKey);
//     final client = Supabase.instance.client;

//     print('✅ Supabase Connection: Success');

//     // 1. Check user_fcm_tokens
//     print('\n--- 📱 Checking Registered FCM Tokens ---');
//     final tokens = await client.from('user_fcm_tokens').select();
//     if (tokens.isEmpty) {
//       print('❌ ERROR: No FCM tokens found in user_fcm_tokens table.');
//       print('   TIP: Ensure the technician and customer apps are logged in.');
//     } else {
//       print('✅ Found ${tokens.length} registered tokens.');
//       for (var t in tokens) {
//         print('   - User: ${t['user_id']}, Platform: ${t['platform']}, Token: ${t['fcm_token'].toString().substring(0, 10)}...');
//       }
//     }

//     // 2. Check notifications table
//     print('\n--- 🔔 Checking Recent Notifications ---');
//     final notifications = await client
//         .from('notifications')
//         .select()
//         .order('created_at', ascending: false)
//         .limit(5);

//     if (notifications.isEmpty) {
//       print('⚠️ WARNING: No notifications found in notifications table.');
//     } else {
//       print('✅ Found ${notifications.length} recent notifications:');
//       for (var n in notifications) {
//         print('   - Time: ${n['created_at']}, Title: ${n['title']}, Body: ${n['body']}');
//       }
//     }

//     // 3. Check for specific status change notification (e.g. on_the_way)
//     print('\n--- 🚗 Checking for "On the Way" notifications ---');
//     final onTheWayNotifs = await client
//         .from('notifications')
//         .select()
//         .eq('title', 'الفني في الطريق إليك 🚗');
    
//     if (onTheWayNotifs.isEmpty) {
//       print('❌ ERROR: No "On the Way" notifications found.');
//       print('   This suggests the database trigger tr_on_booking_status_change_notify is NOT firing.');
//     } else {
//       print('✅ Success: Found ${onTheWayNotifs.length} "On the Way" notifications.');
//     }

//     print('\n--- 🏁 Diagnostic Complete ---');

//   } catch (e) {
//     print('❌ CRITICAL ERROR during diagnostic: $e');
//   }
// }
