# تقرير التدقيق الفني الشامل لنظام حجز الزوار (Guest Booking System Audit)
**مشروع: Fresh Home Platform**  
**التاريخ: 17 سبتمبر 2026**  
**طبيعة المستند: تقرير تدقيق ومراجعة فنية فقط (Audit / Review Only - No Implementation)**  

---

## 1. Executive Summary (الملخص التنفيذي)

نظام **حجز الزوار (Guest Booking)** الحالي في Fresh Home يتيح للعميل غير المسجل إتمام الحجز بالكامل عبر الويب (`apps/customer_web`) دون الحاجة إلى إنشاء حساب أو تسجيل دخول، ودون التحقق من هويته أو رقم هاتفه بأي كود تحقق (OTP) أو CAPTCHA.

### ما يحدث حالياً باختصار شديد:
1. **التعرف على الزائر:** يكتشف الـ Frontend غياب جلسة مسجلة (`session == null`)، فيرسل الحجز إلى الـ Database عبر دالة `create_atomic_booking` مع تمرير `p_user_id = NULL` ومعامل `p_is_whatsapp_confirmed = false`.
2. **إنشاء الحجز والحالة في قاعدة البيانات:** يُنشأ الحجز فوراً في جدول `public.bookings` وتأخذ خانة الحالة القيمة **`status = 'assigned'`** (وليس `pending`)، مع تخصيص فني فعلي للحجز من أسطول الشركة، ولكن يتم وسم الحجز بـ `is_whatsapp_confirmed = false` وتحديد مهلة 60 دقيقة في `whatsapp_confirmation_expires_at`.
3. **عزل الفني وحظر الإشعارات:** تمنع سياسات أمان قاعدة البيانات (RLS) الفني المخصص من رؤية الحجز طالما `is_whatsapp_confirmed = false`. كما يتوقف تريجر الإشعارات (`handle_booking_notification`) عن إرسال أي إشعارات.
4. **ظهور الحجز للإدارة:** يظهر الحجز فوراً في تطبيق الإدارة (`fresh_home_admin`) في قائمة الحجوزات، محاطاً ببطاقة تحذيرية صفراء تفيد بأنه "حجز معلق بانتظار التأكيد عبر واتساب". ويمتلك الآدمن زراً يدوياً لتأكيد الحجز وتنشيطه.
5. **تجربة العميل والواتساب:** يُحوَّل العميل إلى صفحة تتبع الطلب (`/orders?bookingId=...`) مع عداد تنازلي (60 دقيقة) وزر ينقله إلى رابط `wa.me` لإرسال نص رسالة عادية إلى رقم خدمة عملاء الشركة لتأكيد رغبته في الحجز.
6. **غياب نظام Anti-Spam حقيقي:** لا يوجد أي جدار حماية ضد التكرار أو الإغراق (لا IP Rate Limiting، لا Device Fingerprinting، لا CAPTCHA، ولا فحص تكرار رقم الهاتف). والاعتماد الأمني الوحيد حالياً هو تحويل عبء الفلترة اليدوية إلى إدارة الشركة (Admin Manual Confirmation)، مع وجود ثغرة تتيح للمهاجم حجز كامل طاقة الفنيين عبر استدعاء الـ RPC مباشرة.

---

## 2. Current Guest Booking Flow (تتبع التدفق الفعلي خطوة بخطوة)

المسار الفعلي End-to-End من واجهة الويب حتى قاعدة البيانات:

```
[ العميل كـ Guest ] 
       │
       ▼ (1. اختيار الخدمة وتعبئة المواصفات وحساب السعر)
[ apps/customer_web/src/app/booking/page.tsx ]
       │
       ▼ (2. اختيار التاريخ والوقت)
       │
       ▼ (3. إدخال العنوان: محافظة، مدينة، حي، تفاصيل)
       │
       ▼ (4. إدخال الاسم ورقم الهاتف واختيار الدفع)
       │
       ▼ (5. الضغط على "تأكيد وإتمام الحجز النهائي")
[ handleCompleteBooking() ]
       │ 
       ├─► فحص الجلسة: supabase.auth.getSession() ──► userId = null
       ├─► تجهيز الحمولة: p_is_whatsapp_confirmed = false
       │
       ▼ (6. استدعاء RPC مباشر عبر PostgREST)
[ supabase.rpc('create_atomic_booking', { ... }) ]
       │
       ▼ (7. تنفيذ الدالة داخل PostgreSQL - SECURITY DEFINER)
[ public.create_atomic_booking in 104_fix_coverage_guard_address_snapshot_v2.sql ]
       │
       ├─► تجاوز فحص المستخدم: auth.uid() IS NULL (لا اعتراض)
       ├─► فحص التغطية الجغرافية: القاهرة / الجيزة فقط
       ├─► قفل التزامن واختيار الفني: get_available_technicians()
       ├─► تسعير نهائي حتمي: execute_pricing_pipeline()
       ├─► قراءة مهلة التأكيد: system_settings -> whatsapp_settings (60 دقيقة)
       ├─► إدراج الحجز في public.bookings:
       │     - user_id: NULL
       │     - status: 'created'
       │     - is_whatsapp_confirmed: false
       │     - whatsapp_confirmation_expires_at: NOW() + 60 min
       │     - whatsapp_confirmation_token: gen_random_uuid()
       ├─► ضبط متغير الجلسة: app.trusted_internal_call = true
       └─► نقل الحالة فوراً: transition_booking(..., 'assigned')
             └── تحديث status إلى 'assigned' في نفس المعاملة
       │
       ▼ (8. استجابة الـ RPC وإرجاع bookingId UUID)
[ Frontend Web ]
       │
       ├─► حفظ مؤقت محلي: localStorage.setItem('booking_created_' + id)
       └─► توجيه فوري: router.push('/orders?bookingId=' + id + '&success=true')
       │
       ▼ (9. شاشة تتبع الطلب /orders)
[ apps/customer_web/src/app/orders/page.tsx ]
       │
       ├─► جلب البيانات عبر: supabase.rpc('get_guest_booking_details', { p_booking_id })
       ├─► إظهار نافذة منبثقة وبانر تحذيري: "طلبك في انتظار التأكيد عبر واتساب"
       ├─► تشغيل عداد تنازلي حي: 60 دقيقة
       └─► زر الواتساب: يفتح wa.me برقم الشركة مع نص تفاصيل الحجز
       │
       ├───────────────────────────────────────────────────────┐
       ▼ (مسار أ: انتهاء المهلة دون تأكيد)                 ▼ (مسار ب: تأكيد الآدمن)
[ pg_cron: check_whatsapp_confirmation_expiry() ]   [ fresh_home_admin App ]
       │                                                       │
       ▼                                                       ▼
يتحول الحجز تلقائياً إلى 'cancelled'                 الآدمن يضغط "تأكيد حجز العميل"
بسبب: WHATSAPP_CONFIRMATION_TIMEOUT                   │
تحرير طاقة الفني في قاعدة البيانات                   ▼
                                            استدعاء: admin_confirm_whatsapp_booking()
                                            تحديث: is_whatsapp_confirmed = true
                                            تفعيل تريجر الإشعارات handle_booking_notification()
                                            إشعار الفني بوجود مهمة جديدة
                                            ظهور الحجز في تطبيق الفني (RLS Unlocked)
```

---

## 3. Guest vs Authenticated Booking (مقارنة تفصيلية)

| وجه المقارنة | عميل زائر (Guest Booking) | عميل مسجل (Authenticated Customer) |
| :--- | :--- | :--- |
| **جلسة المصادقة (Session)** | غير موجودة (`supabase.auth.getSession()` يرجع `null`). | موجودة وتحمل JWT صالح للمستخدم في `auth.users`. |
| **معرّف المستخدم (`user_id`)** | **`NULL`** في جدول `bookings` (مسموح بعد Migration 77). | يحمل `UUID` الخاص بالمستخدم المسجل. |
| **التحقق من الهوية (Identity Verification)** | **معدوم تماماً.** لا يتم التحقق من صحة الرقم أو ملكيته للعميل. | تم التحقق مسبقاً عبر OTP أثناء إنشاء الحساب/الدخول. |
| **إدخال بيانات العنوان** | إدخال يدوي في كل حجز، ولا يُحفظ في جدول العناوين. | إمكانية اختيار عنوان محفوظ من `user_addresses` أو حفظ عنوان جديد تلقائياً. |
| **إدخال رقم الهاتف** | إدخال يدوي لأي رقم بصيغة مصرية صحيحة (010, 011, 012, 015). | يتم جلبه افتراضياً من الهاتف الأساسي المعتمد في `user_phones`. |
| **معامل `p_is_whatsapp_confirmed`** | يُرسل بقيمة **`false`** من الـ Frontend. | يُرسل بقيمة **`true`** من الـ Frontend. |
| **حالة الحجز الأولية بالـ DB** | **`status = 'assigned'`** مع `is_whatsapp_confirmed = false`. | **`status = 'assigned'`** مع `is_whatsapp_confirmed = true`. |
| **مهلة الصلاحية (`expires_at`)** | يتم ضبطها على `NOW() + 60 minutes`. | تكون **`NULL`** (حجز دائم غير معرض للمؤقت). |
| **رؤية الفني للحجز (Technician RLS)** | **محجوب تماماً.** سياسة RLS تشترط `is_whatsapp_confirmed = true`. | **مرئي فوراً.** يظهر في تطبيق الفني كحجز جديد. |
| **إشعارات الفني والعميل** | **موقوفة تماماً** حتى التأكيد اليدوي أو عبر الواتساب. | تُرسل فوراً عبر Outbox / FCM للطرفين بمجرد الإسناد. |
| **تأكيد الحجز (Confirmation)** | يتطلب تأكيداً من الآدمن أو رابط واتساب لتنشيطه. | مؤكد تلقائياً بمجرد إتمام خطوات الحجز. |
| **إلغاء الحجز من الويب** | **غير متاح نهائياً.** لا يوجد زر في الواجهة ولا توجد سياسة RLS تسمح للـ Guest بالتعديل. | **متاح للعميل** بضغطة زر داخل شاشة تتبع طلباتي. |
| **استعراض قائمة الحجوزات السابقة** | **غير متاح نهائياً.** لا توجد حسابات أو قائمة حجوزات سابقة. | تظهر قائمة كاملة بجميع الحجوزات السابقة والنشطة في `/orders`. |
| **تتبع الحجز (Order Tracking)** | يتطلب الاحتفاظ برابط الـ URL المباشر أو الـ UUID المخزن محلياً. | يظهر الحجز تلقائياً في صفحة "حجوزاتي" بمجرد الدخول. |
| **استهلاك طاقة الفني (Capacity)** | **يستهلك طاقة الفني فورياً** ويحجز خانته لمدة 60 دقيقة كاملة. | يستهلك طاقة الفني فورياً وبشكل دائم. |

---

## 4. Database Architecture (معمارية قاعدة البيانات والتبعيات)

### 1. الجداول المعنية (Tables Involved)
* **`public.bookings`**:
  * `user_id`: تم فك قيد `NOT NULL` ليصبح اختيارياً في `Migration 77_make_booking_user_id_nullable.sql`.
  * `is_whatsapp_confirmed`: أُضيف في `Migration 75_whatsapp_confirmation_flow.sql` (Default: `true`).
  * `whatsapp_confirmation_expires_at`: مؤقت الصلاحية للحجوزات غير المؤكدة.
  * `whatsapp_confirmation_token`: رمز `UUID` مشفر يُولّد تلقائياً لكل حجز لتأكيده.
* **`public.system_settings`**:
  * المفتاح `'whatsapp_settings'`: يحوي `{ "business_number": "+201000000000", "expiry_minutes": 60, "enabled_for_guests": true }`.
* **`public.booking_events`**:
  * يسجل أحداث `BOOKING_CREATION` و `WHATSAPP_CONFIRMED`.
* **`public.state_transitions`**:
  * جدول محرك الحالات (State Machine) يحدد الحركات المصرح بها للأدوار المختلفة.

### 2. دوال قاعدة البيانات (Database Functions & RPCs)
* **`public.create_atomic_booking`** (الموقع: [104_fix_coverage_guard_address_snapshot_v2.sql#L9-L171](file:///d:/fresh_home_workspace/supabase/migrations/104_fix_coverage_guard_address_snapshot_v2.sql#L9-L171)):
  * الصلاحيات: `GRANT EXECUTE TO anon, authenticated, service_role;`
  * الطبيعة: `SECURITY DEFINER` (تعمل بصلاحيات مالك قاعدة البيانات لتجاوز RLS وتخصيص الفنيين وإجراء العمليات الذرية).
  * تستقبل `p_user_id`, `p_sub_service_id`, `p_scheduled_day`, `p_address_snapshot`, `p_pricing_inputs`, `p_is_whatsapp_confirmed`.
* **`public.get_guest_booking_details`** (الموقع: [80_add_pricing_inputs_to_guest_booking_details.sql#L6-L69](file:///d:/fresh_home_workspace/supabase/migrations/80_add_pricing_inputs_to_guest_booking_details.sql#L6-L69)):
  * الصلاحيات: `GRANT EXECUTE TO anon, authenticated;`
  * الطبيعة: `SECURITY DEFINER`.
  * تتيح للزائر جلب تفاصيل الحجز والفني والأسعار بناءً على `p_booking_id UUID`.
* **`public.confirm_whatsapp_booking`** (الموقع: [75_whatsapp_confirmation_flow.sql#L381-L420](file:///d:/fresh_home_workspace/supabase/migrations/75_whatsapp_confirmation_flow.sql#L381-L420)):
  * الصلاحيات: `SECURITY DEFINER`.
  * تتحقق من تطابق `p_booking_id` و `whatsapp_confirmation_token` وتحدث `is_whatsapp_confirmed = true`.
* **`public.admin_confirm_whatsapp_booking`** (الموقع: [76_admin_confirm_whatsapp_booking.sql#L6-L34](file:///d:/fresh_home_workspace/supabase/migrations/76_admin_confirm_whatsapp_booking.sql#L6-L34)):
  * الصلاحيات: مقصورة على الإدارة (`public.is_admin()`).
  * تتيح للآدمن تفعيل حجز الزائر يدوياً ومسح مؤقت الإلغاء.
* **`public.check_whatsapp_confirmation_expiry`** (الموقع: [75_whatsapp_confirmation_flow.sql#L423-L455](file:///d:/fresh_home_workspace/supabase/migrations/75_whatsapp_confirmation_flow.sql#L423-L455)):
  * تعمل عبر `pg_cron` كل 5 دقائق (`*/5 * * * *`).
  * تبحث عن الحجوزات التي حققت: `is_whatsapp_confirmed = false AND status = 'assigned' AND whatsapp_confirmation_expires_at < NOW()` وتقوم بنقلها إلى `cancelled`.

### 3. التريجرات وسياسات الأمان (Triggers & RLS Policies)
* **التريجر `handle_booking_notification`**:
  * تم تعديله في [75_whatsapp_confirmation_flow.sql#L208-L226](file:///d:/fresh_home_workspace/supabase/migrations/75_whatsapp_confirmation_flow.sql#L208-L226) ليتحقق أولاً:
    ```sql
    IF NOT NEW.is_whatsapp_confirmed THEN
        RETURN NEW;
    END IF;
    ```
    وبالتالي يتم كتم كافة إشعارات الـ Push / FCM حتى التأكيد.
* **سياسة فنيي الصيانة على جدول `bookings`**:
  * في [75_whatsapp_confirmation_flow.sql#L61-L76](file:///d:/fresh_home_workspace/supabase/migrations/75_whatsapp_confirmation_flow.sql#L61-L76):
    ```sql
    CREATE POLICY "Technicians can view their assigned bookings" ON public.bookings
    FOR SELECT USING (
        auth.uid() = technician_id 
        AND is_whatsapp_confirmed = true
    );
    ```
    هذا يضمن أن الفني لا يرى الحجز في تطبيقه نهائياً طالما لم يتم تأكيده.

---

## 5. Booking Status Lifecycle (دورة حياة حالات الحجز)

### قائمة الحالات المعرفة في النظام (`public.order_status_v2` / Dart `OrderStatus`):
1. **`created`**: الحالة الابتدائية عند إدراج الصف في `public.bookings`.
2. **`assigned`**: تم تخصيص فني للحجز وتثبيت الموعد.
3. **`accepted`**: قام الفني بفتح تطبيقه وقبول مهمة العمل.
4. **`ready`**: الفني جاهز لبدء التحرك.
5. **`on_the_way`**: الفني في الطريق للعميل.
6. **`arrived`**: وصل الفني لموقع العميل.
7. **`in_progress`**: بدء تنفيذ أعمال الخدمة.
8. **`pending_inspection`**: الخدمة بانتظار معاينة أو اعتماد إضافي.
9. **`completed`**: تم إنهاء الخدمة بنجاح واستلام المبلغ.
10. **`cancelled`**: تم إلغاء الحجز (بواسطة العميل، الآدمن، أو النظام).
11. **`failed` / `failed_no_show`**: تعذر تنفيذ الخدمة لعدم تواجد العميل.
12. **`expired`**: انتهت صلاحية الطلب دون تخصيص فني.

### الحقيقة حول حالة حجز الـ Guest:
* **هل يدخل حجز الـ Guest في حالة `pending`؟**
  * **لا.** في قاعدة البيانات لا توجد حالة اسمها `pending` لحجز الـ Guest.
  * الحجز يُنشأ بـ `created` ثم يتم نقله **في نفس جزء من الثانية** عبر `transition_booking` إلى **`assigned`**.
* **الازدواجية في مصدر الحقيقة (Source of Truth Discrepancy):**
  * حالة الحجز في عمود `status` تكون: **`assigned`**.
  * حالة التفعيل الفعلي تكون في عمود منفصل: **`is_whatsapp_confirmed = false`**.
  * في الواجهة الأمامية (`orders/page.tsx`): يرى العميل بنية بصرية توحي بأن الحجز "قيد الانتظار والتأكيد"، بينما جدول قاعدة البيانات والـ capacity pool يعتبرانه محجوزاً ومسنداً لفني بالفعل!

---

## 6. Current Admin Confirmation Logic (منطق تأكيد الإدارة)

### أين يُفرض؟
يُفرض في شاشة تفاصيل الحجز بتطبيق الإدارة:
[admin_booking_details_screen.dart#L173-L268](file:///d:/fresh_home_workspace/apps/fresh_home_admin/lib/features/booking_management/presentation/pages/admin_booking_details_screen.dart#L173-L268).

### هل هو بسبب الـ Guest Booking تحديداً؟
* **نعم بنسبة 100%.**
* في الكود: واجهة الويب هي المصدر الوحيد الذي يرسل `p_is_whatsapp_confirmed = false`، وذلك عندما يكون `userId == null` ([booking/page.tsx#L1185](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx#L1185)).
* أما التطبيقات الأخرى (تطبيق العميل المسجل في Flutter)، فلا ترسل هذا المعامل، وبالتالي تأخذ القيمة الافتراضية للـ SQL وهي `true`.

### هل القرار يتم في الـ Frontend أم الـ Backend؟
* **القرار مفروض في الـ Frontend فقط.**
* لا يوجد في الـ Backend أي سطر كود يفرض: `IF p_user_id IS NULL THEN p_is_whatsapp_confirmed := false; END IF;`.
* الـ Backend يقبل ما يُرسل له في المعامل `p_is_whatsapp_confirmed`. وإذا لم يُرسل، قيمته الافتراضية في توقيع الدالة هي **`BOOLEAN DEFAULT true`**.

### هل هو Business Logic حقيقي أم مجرد Workaround للـ Anti-Spam؟
* الأدلة القاطعة في الكود والميجريشنز (خصوصاً [75_whatsapp_confirmation_flow.sql](file:///d:/fresh_home_workspace/supabase/migrations/75_whatsapp_confirmation_flow.sql)) تؤكد أنه **مجرد Workaround لحماية الفنيين من الذهاب لحجوزات وهمية (Fake Orders) يرسلها الزوار دون إمكانية محاسبتهم.**
* لم يتم بناء دورة عمل حقيقية (مثل إرسال رسالة آلية تحوي رابط تفعيل)، بل تم الاكتفاء بـ:
  1. حجب الحجز عن الفني (`RLS`).
  2. إظهار تحذير للآدمن ليقوم بالاتصال بالعميل أو مراجعة الواتساب ثم الضغط على "تأكيد الحجز".

---

## 7. Current Anti-Spam / Duplicate Protection (فحص آليات الحماية من السبام)

بعد فحص كامل ملفات المشروع ومستودع الكود:

| الآلية (Mechanism) | هل هي موجودة حالياً؟ | التفاصيل والدليل من الكود |
| :--- | :---: | :--- |
| **IP-based Tracking / Limiting** | ❌ **غير موجودة** | لا يوجد تسجيل لعنوان الـ IP في `bookings`، ولا يوجد أي فحص للـ IP في الـ RPC أو الـ Middleware. (مسار `api/geo-check` يقرأ فقط هيدر الدولة/المدينة من Vercel لعرض رسالة التغطية ولا يسجل IP). |
| **Browser ID / Fingerprinting** | ❌ **غير موجودة** | لا يتم توليد أو فحص أي بصمة متصفح أو جهاز. |
| **Cookies / Session Limiting** | ❌ **غير موجودة** | لا توجد كوكيز تمنع تكرار الطلب أو تحد من عدد الحجوزات. |
| **Rate Limiting (طلب لكل دقيقة)** | ❌ **غير موجودة** | لا يوجد أي Rate Limiter في Next.js ولا في Supabase PostgREST. |
| **CAPTCHA / Turnstile** | ❌ **غير موجودة** | توجد نصوص ترجمة لكلمة captcha في حزم Flutter فقط ([app_localizations_ar.dart](file:///d:/fresh_home_workspace/packages/shared/lib/presentation/localization/translations/app_localizations_ar.dart#L287))، ولكن لا يوجد أي دمج لـ reCAPTCHA أو Cloudflare Turnstile في صفحات الحجز بالويب. |
| **Phone Number Verification (OTP)** | ❌ **غير موجودة للـ Guest** | يتم فقط التحقق من صيغة الرقم عبر Regex محلي: `/^(010\|011\|012\|015)\d{8}$/`. أي رقم عشوائي مكون من 11 رقماً يُقبل فوراً. |
| **Duplicate Booking Detection** | ❌ **غير موجودة** | لا يوجد قيد فريد (Unique Constraint) في جدول `bookings` ولا فحص برمجي يمنع نفس رقم الهاتف أو نفس العنوان من حجز نفس الخدمة في نفس اليوم عدة مرات متتالية. |
| **LocalStorage Limitation** | ⚠️ **حفظ شكلي فقط** | الكود يقوم فقط بكتابة: `localStorage.setItem('booking_created_' + bookingId, ...)` في [booking/page.tsx#L1192](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx#L1192) لغرض حساب وقت العداد فقط، ولا يمنع العميل من بدء حجز جديد فوراً. |

**الخلاصة:**
النظام الحالي **لا يمتلك أي آلية Anti-Spam تقنية.** النظام يعتمد بنسبة 100% على حيلة:
**"اجعل الحجز غير مؤكد (`is_whatsapp_confirmed = false`) ودع موظف الإدارة يتعامل مع المشكلة يدوياً".**

---

## 8. Potential Abuse Scenarios (سيناريوهات إساءة الاستخدام المحتملة - نظرياً)

بدون تنفيذ أي هجوم حقيقي، التحليل النظري للكود يكشف السيناريوهات التالية:

1. **إغراق النظام بحجوزات وهمية (Denial of Service on Technician Capacity):**
   * دالة `get_available_technicians` تحسب الأحمال في [95_reschedule_logic_capacity_overrides.sql#L59](file:///d:/fresh_home_workspace/supabase/migrations/95_reschedule_logic_capacity_overrides.sql#L59) بناءً على جميع الحجوزات غير الملغاة.
   * حجوزات الزوار غير المؤكدة تكون بحالة `assigned`.
   * **النتيجة:** يمكن لأي شخص كتابة سكربت بسيط يستدعي دالة `create_atomic_booking` 10 أو 15 مرة لأي خدمة في يوم محدد، فيتم استهلاك الطاقة الاستيعابية اليومية لجميع فنيي تلك الخدمة. وبذلك يتعطل الحجز لجميع العملاء الحقيقيين ويظهر لهم "لا يوجد فني متاح لهذا اليوم" لمدة 60 دقيقة كاملة حتى يعمل الـ Cron Job.
2. **تجاوز شرط تأكيد الواتساب كلياً (Bypassing WhatsApp Confirmation via Direct RPC):**
   * بما أن الـ RPC ممنوحة للـ `anon` ومعامل `p_is_whatsapp_confirmed` له قيمة افتراضية `true`:
   * يستطيع أي شخص إرسال طلب HTTP مباشر لنقطة النهاية:
     `POST https://<project>.supabase.co/rest/v1/rpc/create_atomic_booking`
     مع تمرير: `"p_is_whatsapp_confirmed": true` و `"p_user_id": null`.
   * **النتيجة:** سيتم إنشاء الحجز كحجز زائر **مؤكد فوراً**، وستصل إشعارات تكليف للفني على هاتفه للذهاب إلى عنوان وهمي، دون أي تدخل من الإدارة!
3. **التكرار بنفس رقم الهاتف أو بأرقام عشوائية:**
   * لا يوجد فحص تكرار؛ يمكن إنشاء 20 حجوزاً متتالياً بنفس رقم الهاتف ونفس العنوان ونفس اليوم.
4. **التصفح الخفي (Incognito) وتغيير الـ IP:**
   * لا تأثير لهما لأن النظام لا يفحصهما أصلاً؛ الهجوم ينجح حتى من نفس المتصفح ونفس التبويب ونفس الـ IP.

---

## 9. Security Findings (النتائج والملاحظات الأمنية)

### 🔴 النتيجة 1: ثغرة تجاوز شرط التأكيد عبر استدعاء الـ RPC المباشر
* **Severity:** High
* **Location:** [104_fix_coverage_guard_address_snapshot_v2.sql#L9-L43](file:///d:/fresh_home_workspace/supabase/migrations/104_fix_coverage_guard_address_snapshot_v2.sql#L9-L43)
* **Current Behavior:** الدالة تفحص فقط إذا كان `auth.uid() IS NOT NULL` للتأكد من أن المستخدم يحجز لنفسه. أما إذا كان `auth.uid() IS NULL` (أي Guest)، فلا تفرض الدالة أي قيود على المعامل `p_is_whatsapp_confirmed`.
* **Risk:** يستطيع أي مهاجم تجاوز منطق الـ Frontend بالكامل وإنشاء حجز زائر مؤكد ومسند للفني مباشرة، مما يترتب عليه إرسال فنيين حقيقيين إلى مواقع وهمية.
* **Evidence:**
  ```sql
  -- خط الدفاع في create_atomic_booking لا يعمل مع الزوار:
  IF auth.uid() IS NOT NULL AND NOT public.is_admin() THEN
      IF p_user_id != auth.uid() THEN
          RAISE EXCEPTION 'Unauthorized: Users can only create bookings for themselves.' ...;
      END IF;
  END IF;
  -- ولا يوجد أي سطر يعيد ضبط p_is_whatsapp_confirmed إذا كان المتصل مجهولاً!
  ```

---

### 🔴 النتيجة 2: تسريب بيانات العملاء الشخصية (PII Exposure via Guest Tracking RPC)
* **Severity:** High
* **Location:** [80_add_pricing_inputs_to_guest_booking_details.sql#L6-L69](file:///d:/fresh_home_workspace/supabase/migrations/80_add_pricing_inputs_to_guest_booking_details.sql#L6-L69)
* **Current Behavior:** الدالة `get_guest_booking_details(p_booking_id UUID)` معرفة كـ `SECURITY DEFINER` وممنوحة للعامة (`TO anon`). وتكتفي باستقبال `booking_id` فقط دون اشتراط رقم هاتف، رمز سري، أو توكن.
* **Risk:** ترجع الدالة الاسم الكامل للعميل، أرقام هواتفه، العنوان التفصيلي بدقة (اسم الشارع، رقم العمارة، الدور، الشقة، الرابط على خرائط جوجل)، وأسماء الفنيين. أي شخص يحصل على معرّف الحجز (أو يختبر معرّفات) يستطيع قراءة هذه البيانات دون أي إثبات ملكية.
* **Evidence:**
  ```sql
  -- لا يوجد فحص لرقم الهاتف أو التوكن:
  SELECT b.* INTO v_booking FROM public.bookings b WHERE b.id = p_booking_id;
  ...
  RETURN jsonb_build_object(
      'contact_name', v_booking.contact_name,
      'contact_phones', v_booking.contact_phones,
      'address_snapshot', v_booking.address_snapshot, ...
  );
  ```

---

### 🟠 النتيجة 3: هجوم حجب الخدمة على طاقة الفنيين (Technician Capacity Exhaustion)
* **Severity:** Medium / High
* **Location:** [95_reschedule_logic_capacity_overrides.sql#L59](file:///d:/fresh_home_workspace/supabase/migrations/95_reschedule_logic_capacity_overrides.sql#L59)
* **Current Behavior:** دالة `get_available_technicians` تستبعد فقط الحالات `cancelled, expired, failed_no_show`.
* **Risk:** حجوزات الـ Guest غير المؤكدة تكون بحالة `assigned`، وبالتالي تُحسب فوراً ضد طاقة الفني اليومية. يستطيع أي طرف تعطيل إمكانية الحجز في مناطق معينة لعدة ساعات بإنشاء حجوزات وهمية مجانية.

---

### 🟡 النتيجة 4: انقطاع تحديثات الـ Realtime للزوار بسبب سياسات RLS
* **Severity:** Low / UX Impact
* **Location:** [orders/page.tsx#L218-L270](file:///d:/fresh_home_workspace/apps/customer_web/src/app/orders/page.tsx#L218-L270) مقابل سياسات الـ RLS.
* **Current Behavior:** كود الصفحة يشترك في قناة `supabase.channel('realtime-booking-' + bookingId)` للاستماع لتحديثات جدول `bookings`.
* **Risk:** في Supabase، لا ترسل خدمة Realtime أي أحداث للمتصل `anon` إذا لم تكن هناك سياسة `SELECT` تسمح للمتصل المجهول بقراءة الصف في جدول `bookings`. ونظراً لعدم وجود سياسة `SELECT` للـ `anon`، لن يتلقى متصفح العميل الزائر أي إشعار عند تأكيد الحجز من الآدمن أو تغيير حالته إلا إذا قام بإعادة تحميل الصفحة يدوياً.

---

## 10. Guest Booking UX Findings (ملاحظات تجربة المستخدم ونقاط الاحتكاك)

1. **خلل البحث برقم الحجز المقروء في شاشة التتبع (Search by Readable ID Bug):**
   * في شاشة التتبع ([orders/page.tsx#L404](file:///d:/fresh_home_workspace/apps/customer_web/src/app/orders/page.tsx#L404))، يُطلب من العميل إدخال رقم الحجز بالمثال: `FH-100293`.
   * عند إرسال النموذج، يستدعي الكود: `get_guest_booking_details({ p_booking_id: searchInput })`.
   * بما أن المعامل في PostgreSQL نوعه `UUID`، فإن إدخال `FH-100293` يُفشل الاستعلام بخطأ في البنية: `invalid input syntax for type uuid: "FH-100293"`.
   * **النتيجة:** العميل الذي ينسخ رقم طلبه الظاهر على الشاشة (`readable_id`) لا يستطيع تتبع طلبه إذا أغلق المتصفح وعاد للبحث!
2. **انعدام القدرة على الإلغاء أو التعديل:**
   * زر الإلغاء في [orders/page.tsx#L846](file:///d:/fresh_home_workspace/apps/customer_web/src/app/orders/page.tsx#L846) مشروط بوجود مستخدم مسجل (`{user && ...}`). الزائر لا يمتلك أي خيار لإلغاء الحجز أو تغيير الموعد ذاتياً.
3. **تشتت العميل مع رسائل التأكيد المتناقضة:**
   * الواجهة تعرض للعميل في التايم لاين أن الحجز "تم تعيين الفني" (بسبب حالة `assigned` بالخلفية)، وفي نفس الوقت تضع له بانراً كبيراً يحذره بأن الحجز غير مؤكد وسيلغى تلقائياً خلال 60 دقيقة ما لم يرسل رسالة واتساب!
4. **تكرار إدخال البيانات في كل حجز:**
   * لا توجد ذاكرة محلية ذكية تحتفظ باسم العميل أو عنوانه في المتصفح لتسهيل الحجوزات اللاحقة.

---

## 11. WhatsApp Integration Findings (حقيقة تكامل الواتساب)

عند تتبع تدفق الواتساب كاملاً وُجد الآتي:

1. **كيف يعمل الإرسال؟**
   * الزر في [orders/page.tsx#L523](file:///d:/fresh_home_workspace/apps/customer_web/src/app/orders/page.tsx#L523) يقوم فقط بتركيب رابط `https://wa.me/<business_number>?text=...` يفتحه المتصفح في تطبيق واتساب لدى العميل.
2. **محتوى الرسالة:**
   * رسالة نصية بسيطة تلخص: رقم الطلب المقروء، اسم الخدمة، السعر الإجمالي، التاريخ، وقت الزيارة، الاسم، الهاتف، والمحافظة/المدينة.
3. **الانقطاع بين الكود والواقع (The Missing Automated Link):**
   * في قاعدة البيانات، أُنشئت دالة لتأكيد الحجز آلياً: `confirm_whatsapp_booking(p_booking_id, p_token)` في [75_whatsapp_confirmation_flow.sql#L381](file:///d:/fresh_home_workspace/supabase/migrations/75_whatsapp_confirmation_flow.sql#L381).
   * وفي الـ Frontend، بُنيت صفحة مخصصة لاستقبال الرابط: [booking/confirm/page.tsx](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/confirm/page.tsx).
   * **ولكن في الواقع:** رسالة الواتساب التي يرسلها العميل للشركة **لا تحتوي على هذا الرابط ولا على التوكن (`whatsapp_confirmation_token`)**!
   * كما أنه لا يوجد Webhook أو خدمة WhatsApp Business API متصلة تقوم بالرد الآلي على العميل وإرسال الرابط له.
4. **النتيجة العملية:**
   * الآلية الحقيقية والوحيدة الشغالة حالياً في النظام لتأكيد حجوزات الـ Guest هي: **أن يرى موظف الدعم أو الآدمن الرسالة في واتساب الشركة، ثم يدخل إلى لوحة التحكم (`fresh_home_admin`) ويضغط زر "تأكيد حجز العميل وتنشيط الطلب" يدوياً.**

---

## 12. Architecture Findings (توزيع المنطق البرمجي)

* **انزياح منطق الأعمال للأطراف (Business Logic Leak to Presentation):**
  * قرار ما إذا كان الحجز يحتاج تأكيد واتساب أم لا تم اتخاذه في الـ Frontend (`p_is_whatsapp_confirmed: userId !== null`) بدلاً من أن يتم حسمه مركزياً في دالة الـ Backend بناءً على `auth.uid()`.
* **ازدواجية الحالة (State Duality):**
  * محرك الحالات الأساسي في النظام يعتمد على `public.state_transitions` وحالات مثل `created, assigned, accepted`.
  * تم إقحام منطق "تأكيد الواتساب" كحقل فرعي موازٍ (`is_whatsapp_confirmed`) مع مؤقت زمني وتريجر استثنائي، مما خلق تداخلاً بين حالة الحجز الرسمية في الـ State Machine وبين جاهزيته للتنفيذ.
* **فجوة الصلاحيات في RLS مقابل دوال SECURITY DEFINER:**
  * تم تأمين جدول `bookings` بسياسات RLS صارمة منعت الزائر المجهول من قراءة أي صف.
  * ولكن كحل بديل، تم فتح دالة `get_guest_booking_details` بصلاحيات كاملة دون مصادقة كافية، مما خلق ثغرة في حماية الخصوصية.

---

## 13. Relevant Files (سجل الملفات المعنية ومسؤولياتها)

### أولاً: تطبيقات الواجهة والعميل (Frontend)
1. [`apps/customer_web/src/app/booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx):
   * واجهة الحجز الرئيسية للويب؛ مسؤولة عن إدارة خطوات الحجز الأربعة، واكتشاف حالة الزائر (`session == null`)، واستدعاء دالة `create_atomic_booking`.
2. [`apps/customer_web/src/app/orders/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/orders/page.tsx):
   * صفحة تتبع الطلبات للعميل والزائر؛ تحسب المؤقت التنازلي للـ 60 دقيقة، وتظهر بانر ونافذة الواتساب، وتستدعي `get_guest_booking_details`.
3. [`apps/customer_web/src/app/booking/confirm/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/confirm/page.tsx):
   * صفحة تأكيد الحجز عند النقر على رابط خارجي؛ تستدعي دالة `confirm_whatsapp_booking`.
4. [`apps/customer_web/src/lib/whatsapp.ts`](file:///d:/fresh_home_workspace/apps/customer_web/src/lib/whatsapp.ts):
   * دوال مساعدة لتهيئة أرقام الهواتف وبناء روابط `wa.me`، وهوك `useWhatsAppSettings` لقراءة إعدادات النظام.

### ثانياً: تطبيق الإدارة (Admin App)
5. [`apps/fresh_home_admin/lib/features/booking_management/presentation/pages/admin_booking_details_screen.dart`](file:///d:/fresh_home_workspace/apps/fresh_home_admin/lib/features/booking_management/presentation/pages/admin_booking_details_screen.dart):
   * شاشة تفاصيل الحجز للإدارة؛ مسؤولة عن عرض بطاقة التحذير الصفراء للطلبات غير المؤكدة وزر "تأكيد حجز العميل وتنشيط الطلب".
6. [`apps/fresh_home_admin/lib/features/booking_management/presentation/cubit/admin_booking_details_cubit.dart`](file:///d:/fresh_home_workspace/apps/fresh_home_admin/lib/features/booking_management/presentation/cubit/admin_booking_details_cubit.dart):
   * يدير منطق تأكيد الحجز يدوياً عبر استدعاء `adminConfirmWhatsappBooking`.

### ثالثاً: قاعدة البيانات والـ Migrations (Supabase Backend)
7. [`supabase/migrations/104_fix_coverage_guard_address_snapshot_v2.sql`](file:///d:/fresh_home_workspace/supabase/migrations/104_fix_coverage_guard_address_snapshot_v2.sql):
   * النسخة الأحدث لدالة إنشاء الحجز الذرية `create_atomic_booking` وفحص التغطية وتخصيص الفني.
8. [`supabase/migrations/75_whatsapp_confirmation_flow.sql`](file:///d:/fresh_home_workspace/supabase/migrations/75_whatsapp_confirmation_flow.sql):
   * الميجريشن التأسيسي لتدفق الواتساب؛ يضيف أعمدة التأكيد لجدول `bookings`، وسياسات حجب الفنيين، وتعديل تريجر الإشعارات، ودالة الـ Cron Job لمراقبة انتهاء المهلة.
9. [`supabase/migrations/76_admin_confirm_whatsapp_booking.sql`](file:///d:/fresh_home_workspace/supabase/migrations/76_admin_confirm_whatsapp_booking.sql):
   * يُنشئ الدالة المصرحة للآدمن `admin_confirm_whatsapp_booking`.
10. [`supabase/migrations/77_make_booking_user_id_nullable.sql`](file:///d:/fresh_home_workspace/supabase/migrations/77_make_booking_user_id_nullable.sql):
    * فك قيد `NOT NULL` عن `bookings.user_id` للسماح بحجوزات الزوار، وتعديل توقيع دالة الحجز.
11. [`supabase/migrations/80_add_pricing_inputs_to_guest_booking_details.sql`](file:///d:/fresh_home_workspace/supabase/migrations/80_add_pricing_inputs_to_guest_booking_details.sql):
    * النسخة الأحدث لدالة قراءة تفاصيل حجز الزائر `get_guest_booking_details`.
12. [`supabase/migrations/95_reschedule_logic_capacity_overrides.sql`](file:///d:/fresh_home_workspace/supabase/migrations/95_reschedule_logic_capacity_overrides.sql):
    * تعريف دالة `get_available_technicians` ومحرك حساب الطاقة الاستيعابية.

---

## 14. Possible Future Directions (المسارات والخيارات المستقبلية الممكنة)

*ملاحظة حيادية تامة: تُعرض هذه المسارات كخيارات معمارية للدراسة فقط دون اختيار أو تفضيل مسار على آخر ودون أي تنفيذ:*

* **المسار الأول: الإبقاء على الوضع الحالي مع سد الثغرات الحرجة (Keep Current Model + Secure Gaps)**
  * الإبقاء على نموذج تأكيد الآدمن الحالي.
  * فرض `p_is_whatsapp_confirmed := false` في الـ Backend إذا كان المتصل `anon`.
  * تعديل دالة `get_guest_booking_details` لتقبل `readable_id` واشتراط رقم الهاتف للتحقق من هوية الزائر قبل عرض بياناته.
* **المسار الثاني: تفعيل حماية Anti-Spam متقدمة في الـ Backend (Backend Anti-Spam & Rate Limiting)**
  * إضافة فحص تكرار بالرقم والعنوان في قاعدة البيانات (منع حجزين لنفس الخدمة ونفس الهاتف خلال 24 ساعة).
  * تطبيق Rate Limiting على مستوى الـ RPC أو الـ API Routes عبر Redis / Upstash لمنع إغراق الطلبات.
  * استبعاد الحجوزات غير المؤكدة من حساب استهلاك طاقة الفنيين في `get_available_technicians` حتى لا يتم تعطيل اليوم للعملاء الآخرين.
* **المسار الثالث: التحقق السريع من الهوية بالواجهة (Lightweight Identity Verification)**
  * دمج Cloudflare Turnstile أو Google reCAPTCHA v3 في الخطوة الأخيرة من الـ Web UI لمنع الـ Bots.
  * أو إرسال رمز تحقق سريع عبر الواتساب أو الـ SMS (OTP) قبل استدعاء دالة إنشاء الحجز.
* **المسار الرابع: التحول إلى نموذج طلب حجز أولي (Booking Request vs Confirmed Booking)**
  * فصل حجوزات الزوار في جدول أو حالة واضحة منفصلة تماماً (مثل `pending_approval`) دون تخصيص فني ودون حجز طاقة مسبقة من الأسطول إلا بعد المراجعة الهاتفية من خدمة العملاء.

---

## 15. Recommended Next Investigation (الخطوات الاستقصائية الموصى بها لاحقاً)

قبل اتخاذ أي قرار أو بدء أي تعديلات برمجية، يُوصى بمناقشة واستقصاء النقاط التالية مع فريق العمل:
1. **مراجعة سجلات الحجوزات الحقيقية (Real Production Data):** كم عدد حجوزات الـ Guests الفعلية أسبوعياً مقارنة بالمسجلين؟ وما نسبة الحجوزات التي تلغى بسبب انتهاء مهلة الواتساب (60 دقيقة) دون تأكيد؟
2. **استراتيجية تأكيد الواتساب:** هل المطلوب مستقبلاً هو أتمتة كاملة للواتساب (عبر WhatsApp Cloud API ترسل رسالة فورية للعميل برابط تفاعلي)، أم الإبقاء على الاتصال البشري من خدمة العملاء؟
3. **قرار طاقة الفنيين (Capacity Allocation):** هل من المقبول بيزنسياً أن يظل حجز الزائر غير المؤكد حاجزاً لطاقة الفني لمدة ساعة كاملة ومانعاً لعملاء آخرين من الحجز في نفس اليوم؟
