# دليل إعداد الإشعارات (FCM Setup Guide)

لاستكمال تفعيل الإشعارات بنجاح، يرجى اتباع الخطوات التالية لربط Supabase بـ Firebase:

## 1. استخراج ملف مفتاح الخدمة (Service Account JSON)
من لوحة تحكم Firebase (Firebase Console):
1. اذهب إلى **Project Settings** > **Service Accounts**.
2. اضغط على **Generate New Private Key**.
3. سيتم تحميل ملف JSON. افتح هذا الملف وانسخ محتواه بالكامل.

---

## 2. إعداد المتغيرات في Supabase (Secrets)
يجب إضافة المحتوى الذي نسخته كـ `Secret` في مشروع Supabase الخاص بك. يمكنك فعل ذلك من خلال واجهة المستخدم (Dashboard) أو عبر الـ CLI:

### عبر واجهة المستخدم:
1. اذهب إلى **Settings** > **Edge Functions**.
2. أضف الـ Secrets التالية:
    - `FCM_PROJECT_ID`: معرف مشروع Firebase الخاص بك (مثلاً `fresh-home-12345`).
    - `FCM_SERVICE_ACCOUNT`: الصق محتوى ملف الـ JSON بالكامل هنا (بدون أي تعديل).

---

## 3. تفعيل التغييرات في قاعدة البيانات
تأكد من تشغيل ملف الهجرة الجديد [16_activate_push_notifications.sql](file:///d:/fresh_home_workspace/supabase/migrations/16_activate_push_notifications.sql) من خلال الـ SQL Editor في Supabase لتفعيل المحرك الذي يقوم بإرسال البيانات للـ Edge Function.

---

## 4. التحقق من العمل
بعد تنفيذ الخطوات السابقة:
1. قم بفتح تطبيق الفني وتأكد من تسجيل الدخول (سيتم إرسال الـ Token تلقائياً).
2. قم بتغيير حالة أي أوردر (مثلاً من القائمة) إلى "أنا في الطريق".
3. يجب أن يظهر إشعار فوري على هاتف العميل.

> [!IMPORTANT]
> تأكد من أن تطبيق الفني والعميل يحتويان على ملفات `google-services.json` (للأندرويد) و `GoogleService-Info.plist` (للـ iOS) الصحيحة والمتوافقة مع نفس المشروع.
