import 'dart:convert';
import 'dart:io';

void main() async {
  const supabaseUrl = 'https://dsddwqdixsdhaspfafuy.supabase.co';
  const supabaseKey = 'sb_publishable_vNlyMzHSX84GUhL-JWXqLA_S7shZml_';

  print('🔄 Testing database calculate_computed_fields RPC...');
  try {
    final uri = Uri.parse('$supabaseUrl/rest/v1/rpc/calculate_computed_fields');
    final request = await HttpClient().postUrl(uri);
    request.headers.add('apikey', supabaseKey);
    request.headers.add('Authorization', 'Bearer $supabaseKey');
    request.headers.contentType = ContentType.json;
    
    final payload = {
      'p_inputs': {
        'width': 4.0,
        'height': 5.0,
      },
      'p_computed_fields': [
        {
          'id': 'area',
          'formula': '{width} * {height}',
          'label': {'ar': 'المساحة', 'en': 'Area'}
        }
      ]
    };
    
    final bodyBytes = utf8.encode(json.encode(payload));
    request.contentLength = bodyBytes.length;
    request.add(bodyBytes);
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      print('✅ Success! Output: $responseBody');
    } else {
      print('❌ Failed: ${response.statusCode} - $responseBody');
    }
  } catch (e) {
    print('❌ Unexpected error: $e');
  }
}
