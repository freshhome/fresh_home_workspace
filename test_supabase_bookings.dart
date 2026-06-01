import 'dart:convert';
import 'dart:io';

void main() async {
  // قم بوضع الرابط والمفتاح الخاص بمشروعك هنا (يمكنك أخذها من ملفات المشروع)
  const supabaseUrl = 'https://dsddwqdixsdhaspfafuy.supabase.co';
  const supabaseKey =  'sb_publishable_vNlyMzHSX84GUhL-JWXqLA_S7shZml_';

  if (supabaseUrl == 'YOUR_SUPABASE_URL') {
    print('⚠️ يرجى فتح الملف وتعديل SUPABASE_URL و SUPABASE_KEY أولاً');
    return;
  }

  print('🔄 جاري الاتصال بقاعدة بيانات Supabase لجلب بيانات جدول الطلبات (bookings)...');
  
  try {
    final uri = Uri.parse('$supabaseUrl/rest/v1/bookings?limit=1');
    final request = await HttpClient().getUrl(uri);
    
    // إضافة الهيدرز المطلوبة للسوبا بيز
    request.headers.add('apikey', supabaseKey);
    request.headers.add('Authorization', 'Bearer $supabaseKey');
    request.headers.add('Content-Type', 'application/json');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(responseBody);
      if (data.isNotEmpty) {
        final Map<String, dynamic> row = data.first;
        print('\n✅ تم جلب البيانات بنجاح! جدول الطلبات (bookings) يحتوي على الأعمدة التالية:\n');
        
        row.forEach((key, value) {
          // طباعة اسم العمود ونوع البيانات الموجودة فيه حالياً
          print('🔸 $key : ${value?.runtimeType ?? "null (بدون قيمة حالياً)"}');
        });
        
        print('\n✨ انسخ هذه النتيجة بالكامل وأرسلها لي لنرى هل هي مناسبة للمشروع أم تحتاج إلى تعديل!');
      } else {
        print('\n⚠️ الاتصال نجح، ولكن الجدول فارغ (لا يوجد طلبات حالياً) فلا يمكن استخراج أسماء الأعمدة من البيانات.');
        print('💡 البديل: يمكنك نسخ الكود الموجود في ملف `schema_discovery.sql` وتشغيله في صفحة SQL Editor في لوحة تحكم Supabase لمعرفة الأعمدة بدقة.');
      }
    } else {
      print('\n❌ حدث خطأ أثناء الاتصال (كود ${response.statusCode}):');
      print(responseBody);
    }
  } catch (e) {
    print('\n❌ حدث خطأ غير متوقع: $e');
  }
}
