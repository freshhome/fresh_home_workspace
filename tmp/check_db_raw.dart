import 'dart:convert';
import 'dart:io';

void main() async {
  print('🔍 Starting Raw HTTP Diagnostic for Supabase...');

  const url = 'https://dsddwqdixsdhaspfafuy.supabase.co';
  const anonKey = 'sb_publishable_vNlyMzHSX84GUhL-JWXqLA_S7shZml_';

  final client = HttpClient();

  Future<void> checkTable(String tableName) async {
    print('\n--- 📂 Checking Table: $tableName ---');
    try {
      final request = await client.getUrl(Uri.parse('$url/rest/v1/$tableName?select=*&limit=5'));
      request.headers.add('apikey', anonKey);
      request.headers.add('Authorization', 'Bearer $anonKey');

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = json.decode(body) as List;
        if (data.isEmpty) {
          print('⚠️ Table "$tableName" is EMPTY.');
        } else {
          print('✅ Found ${data.length} records in "$tableName".');
          for (var item in data) {
            print('   - $item');
          }
        }
      } else {
        print('❌ ERROR: HTTP ${response.statusCode}');
        print('   Response: $body');
      }
    } catch (e) {
      print('❌ ERROR: $e');
    }
  }

  await checkTable('user_fcm_tokens');
  await checkTable('notifications');

  client.close();
  print('\n--- 🏁 Diagnostic Complete ---');
}
