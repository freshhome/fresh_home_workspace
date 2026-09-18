# خطة التطوير والتنفيذ لنظام حجز الزوار (Guest Booking Development Plan)
**مشروع: منصة فريش هوم (Fresh Home Platform)**  
**التاريخ: 18 سبتمبر 2026**  
**الحالة: خطة معمارية وتوثيق فقط (Architecture & Planning Only — No Implementation)**  
**المسار: `docs_guest/guest_booking_development_plan.md`**

---

## 1. الملخص التنفيذي وأهداف الخطة (Executive Summary & Goals)

تحدد هذه الخطة الخطوات البرمجية والمعمارية لتنفيذ نظام حجز الزوار (Guest Booking System) وفقاً للقواعد النهائية المعتمدة في وثيقة [`guest_booking_rules.md`](file:///d:/fresh_home_workspace/docs_guest/guest_booking_rules.md).

تعتبر هذه الخطة **Implementation Plan مبنية على الـ Rules ومقيدة بها تماماً**، وتعتمد على الفحص الدقيق الموثق في تقرير التدقيق الفني [`guest_booking_audit.md`](file:///d:/fresh_home_workspace/guest_booking_audit.md) لمعالجة المشاكل الحالية في الكود:
1. **القضاء على ثغرة استنزاف الطاقة الاستيعابية:** إيقاف احتساب الحجوزات غير المؤكدة ضد طاقة الفنيين ومنع إسنادها مسبقاً.
2. **المرجعية المطلقة للـ Backend:** فرض سلطة قاعدة البيانات الحتمية، وحظر التجاوز المباشر عبر الـ RPC، وتجاهل أي معاملات تأكيد قادمة من الـ Client للزوار.
3. **التطبيق الدقيق لقاعدتي حجز الزائر:**
   * **الحجز الأول للـ Guest:** يمر بسلاسة تامة كحجز مؤكد فوري ومسند لفني ومستهلك للسعة، دون أي عوائق (لا تسجيل دخول، لا OTP، لا CAPTCHA، ولا WhatsApp).
   * **الحجز الثاني لنفس الـ Guest لنفس اليوم ونفس نوع الخدمة:** يتحول حصرياً لحالة تأكيد الواتساب (WhatsApp Confirmation Required).
   * الحجز لنفس الخدمة في **يوم مختلف**، أو في نفس اليوم **لخدمة مختلفة**، يمر كحجز طبيعي مؤكد.
4. **حماية خصوصية بيانات العميل (PII Exposure):** سد الثغرة في استعلامات تفاصيل حجز الزائر.
5. **معالجة خلل البحث بالرقم المقروء (`FH-XXXXXX`):** تصحيح البحث في شاشة التتبع دون أخطاء في نوع البيانات (UUID parsing error).

---

## 2. مراحل خطة التطوير (Development Phases)

---

### Phase 1 — Database / Booking State Design (هندسة حالات الحجز وقاعدة البيانات)

#### المشكلة الحالية في الكود القائم:
* في Migration رقم [104_fix_coverage_guard_address_snapshot_v2.sql#L149-L168](file:///d:/fresh_home_workspace/supabase/migrations/104_fix_coverage_guard_address_snapshot_v2.sql#L149-L168):  
  كل حجز زائر يُنشأ يتم تحويله فوراً عبر `transition_booking` إلى الحالة **`assigned`**، ويُخصص له فني فعلي (`technician_id = v_tech_id`) حتى لو كان `is_whatsapp_confirmed = false`!
* في Migration رقم [95_reschedule_logic_capacity_overrides.sql#L59](file:///d:/fresh_home_workspace/supabase/migrations/95_reschedule_logic_capacity_overrides.sql#L59):  
  دالة `get_available_technicians` تستبعد فقط `cancelled, expired, failed_no_show`. وبالتالي، الحجز غير المؤكد يُحسب كحمل كامل (`assigned_load`) على الفني ويغلق اليوم أمام باقي العملاء لمدة 60 دقيقة كاملة.

#### التعديلات المعمارية المخططة:

1. **إعادة ضبط دورة حياة الحجز المعلق بانتظار الواتساب (WhatsApp Pending State):**
   * الحجز الذي يتطلب تأكيد واتساب يجب أن يستقر في قاعدة البيانات وفق المعايير الصارمة التالية:
     * **`status = 'created'`** (أو حالة ابتدائية غير مفعلة، ولا يدخل `assigned` نهائياً).
     * **`is_whatsapp_confirmed = false`**.
     * **`technician_id = NULL`** (لا يُخصص له فني إطلاقاً).
     * **`whatsapp_confirmation_expires_at = NOW() + INTERVAL '60 minutes'`**.
     * **`whatsapp_confirmation_token = gen_random_uuid()`**.
     * **لا يتم استدعاء** `transition_booking(..., 'assigned')` مطلقاً قبل نجاح التأكيد.

2. **تحديث دالة حساب الطاقة الاستيعابية (`get_available_technicians`):**
   * تعديل استعلام حساب الأحمال في Migration رقم 95 ليشترط استبعاد الحجوزات غير المؤكدة عبر الواتساب من حساب الأحمال المسندة وغير المسندة:
     ```sql
     -- تعديل شرط حساب الأحمال في pool_load:
     AND (b.is_whatsapp_confirmed = true)
     ```
   * **النتيجة الحتمية:** أي حجز زائر ينتظر الواتساب ستكون طاقته الاستيعابية المستهلكة = **صفر**، ولن يؤثر إطلاقاً على توفر الفنيين للعملاء الآخرين.

3. **التعامل مع إشارات المتصفح والتتبع (Browser ID & Signals Evaluation):**
   * **مبدأ الفحص أولاً قبل التعديل:**  
     قبل اتخاذ قرار بإضافة أي أعمدة جديدة (مثل `guest_browser_id`) أو إنشاء Migrations جديدة:
     1. يتم أولاً فحص الـ existing schema والـ existing implementation في جداول المشروع (مثل `bookings.metadata` أو `pricing_inputs` أو سجلات الجلسات) لمعرفة هل يوجد بالفعل معرّف للمتصفح أو ما يعادله ويمكن إعادة استخدامه.
     2. إذا كان موجوداً أو يمكن تمريره وتخزينه ضمن البنية الحالية دون مساس بالجدول، يُعاد استخدامه فوراً لتفادي تكرار البيانات.
     3. فقط إذا تبيّن عدم وجود أي وسيلة لتخزينه وكان ضرورياً لتنفيذ القاعدة، يُحدد المكان والأسلوب الأنسب لتخزينه دون إنشاء جداول أو أعمدة فائضة عن الحاجة.
   * دراسة الفهارس المساعدة (Indexes) اللازمة لتسريع استعلامات البحث عن الحجوزات السابقة للخدمة واليوم المحدد، مع مراعاة البنية الفعلية للجدول.

---

### Phase 2 — Backend Booking Logic (منطق الحجز الذري في الـ Backend)

#### الهدف:
جعل دالة `create_atomic_booking` هي السلطة المركزية الحتمية والوحيدة لاتخاذ قرار الحجز وفرض قاعدة الواتساب، دون أي اعتماد على الواجهة الأمامية.

#### التعديلات المخططة في `create_atomic_booking`:
* **الموقع:** إعداد Migration تكميلي يحل محل [104_fix_coverage_guard_address_snapshot_v2.sql](file:///d:/fresh_home_workspace/supabase/migrations/104_fix_coverage_guard_address_snapshot_v2.sql).

1. **المرجعية وسلطة الـ Backend الحتمية (Authoritative Backend Decision):**
   * الـ Backend هو صاحب القرار النهائي بنسبة 100%.
   * إذا كان المتصل مجهولاً أو زائر (`auth.uid() IS NULL` أو `p_user_id IS NULL`):
     * يتجاهل الـ Backend كلياً أي قيمة قادمة من الـ Client للمعامل `p_is_whatsapp_confirmed`.
     * أي محاولة من العميل لتمرير `p_is_whatsapp_confirmed = true` كـ Guest **لا يجب أن تسمح له بتجاوز فحص التكرار**.
   * أما إذا كان المستخدم مسجلاً ومسجل الدخول (`auth.uid() IS NOT NULL`)، فيستمر في مسار الحجز المؤكد الطبيعي.

2. **منطق فحص الحجز السابق للزائر (Duplicate Detection via Correlation Signals):**
   * **طبيعة الإشارات (Signals):**  
     رقم هاتف الاتصال (`contact_phone`)، معرّف المتصفح (`browser_id`)، عنوان الـ IP، والـ User-Agent، كلها **Correlation Signals مساعدة** للـ Backend للربط بين الحجوزات:
     * لا يوجد Signal واحد يُعتبر هوية مؤكدة للمستخدم بمفرده.
     * لا يتم اعتبار رقم الهاتف Primary Key قطعي.
     * لا يتم اعتبار `browser_id` هوية مطلقة بمفرده (ولا يُجعل شرطاً منفرداً إلزامياً إذا كان سيؤدي لنتائج إيجابية خاطئة).
     * لا يتم استخدام IP وحده لتحديد نفس المستخدم نظراً لاشتراك مستخدمين متعددين في نفس الـ Public IP.
   * **آلية الفحص:**
     * يبحث الـ Backend في جدول `public.bookings` عن أي حجز زائر سابق نشط (غير ملغي):
       1. لنفس اليوم المجدول (`scheduled_day = p_scheduled_day`).
       2. ولنفس نوع الخدمة (`service_id = p_sub_service_id` أو نفس الفئة الرئيسية حسب الـ Service Tree الفعلي).
     * يقوم الـ Backend بعمل correlation تقني موثوق بين الحجز الحالي وتلك الحجوزات باستخدام الإشارات المتاحة، وفق الآلية التي سيتم تحديدها وتثبيتها بعد مراجعة الـ schema والـ existing implementation.
     * **النتيجة:**
       * إذا تأكد وجود حجز سابق نشط لنفس الزائر لنفس اليوم ونفس الخدمة ➔ يتقرر أن الحجز يحتاج تأكيد الواتساب (`requires_whatsapp := true`).
       * إذا لم يوجد حجز سابق مطابق (أول حجز) ➔ يتقرر أنه حجز طبيعي ومؤكد فوراً (`requires_whatsapp := false`).
   * **التزام النطاق:** تظل الآلية بسيطة ومباشرة ومطابقة للقواعد المعتمدة، **بدون أي Risk Score، وبدون Multi-level Risk، وبدون تحليل سلوكي، وبدون نظام Anti-Fraud معقد**.

3. **مسارا التنفيذ الذري المتفرعان (The Forked Execution Paths):**

   * **المسار الأول: أول حجز للزائر أو حجز ليوم/خدمة مختلفة (Normal Confirmed Flow):**
     * `requires_whatsapp = false`.
     * استدعاء `get_available_technicians` لتحديد الفني المتاح `v_tech_id`.
     * تطبيق القفل التنافسي `pg_advisory_xact_lock(v_tech_id, p_scheduled_day)`.
     * إدراج الحجز كحجز مؤكد: `is_whatsapp_confirmed = true`، `technician_id = v_tech_id`، وحجز الطاقة الاستيعابية.
     * نقل الحالة عبر `transition_booking` إلى `assigned`.
     * تفعيل الإشعارات للفني والعميل فوراً.

   * **المسار الثاني: حجز مكرر لنفس اليوم ونفس الخدمة (WhatsApp Pending Flow):**
     * `requires_whatsapp = true`.
     * **عدم** تخصيص أي فني نهائياً (`technician_id := NULL`).
     * **عدم** حجز أي أقفال تنافسية (No Advisory Locks).
     * **عدم** حجز أي طاقة استيعابية للفنيين (Zero Capacity Reserved).
     * إدراج الحجز بحالة **`created`**، مع `is_whatsapp_confirmed = false`، وتحديد مهلة الصلاحية وتوليد التوكن.
     * **عدم** استدعاء `transition_booking` إلى `assigned`.
     * إرجاع معرّف الحجز إلى الواجهة مع مؤشر واضح بحاجته لتأكيد الواتساب.

---

### Phase 3 — WhatsApp Confirmation Flow (مسار ودورة تأكيد الواتساب)

#### فحص الواقع الحالي:
* في تقرير التدقيق الفني، وُجد أن العميل عند النقر على رابط الواتساب ينتقل لمحادثة عادية مع رقم الدعم، وتأكيد الحجز يتم حالياً يدوياً من موظف الإدارة عبر دالة `admin_confirm_whatsapp_booking`.
* توجد بنية أساسية لدالة تأكيد برابط خارجي `confirm_whatsapp_booking` وصفحة `booking/confirm/page.tsx`.

#### التعديلات المخططة في دورة التأكيد:

1. **إعادة فحص السعة وتخصيص الفني عند التأكيد (Dynamic Assignment upon Confirmation):**
   * بما أن الحجز بانتظار الواتساب لم يُخصص له فني ولم يستهلك سعة مسبقاً:
     * عند استدعاء التأكيد (سواء ذاتياً عبر `confirm_whatsapp_booking` أو يدوياً عبر `admin_confirm_whatsapp_booking`):
       1. التحقق من صلاحية التوكن وعدم انتهاء مهلة الـ 60 دقيقة.
       2. **إعادة فحص السعة الاستيعابية في تلك اللحظة:** استدعاء `get_available_technicians` للتأكد من وجود فني متاح في ذلك اليوم للخدمة.
       3. **في حال توفر فني:**
          * إسناد الفني للحجز (`technician_id = v_tech_id`).
          * حجز الطاقة الاستيعابية الرسمية.
          * تحديث `is_whatsapp_confirmed = true` ومسح مؤقت الانتهاء.
          * نقل حالة الحجز إلى **`assigned`** عبر محرك الحالات.
          * تفعيل الإشعارات وتنبيه الفني بالطلب الجديد.
       4. **في حال نفاد السعة (Capacity Exhaustion during Waiting):**
          * معالجة الحالة برفق دون انهيار: إخطار الإدارة للتنسيق مع العميل هاتفياً، أو توجيه العميل لاختيار أقرب موعد بديل.

2. **تحديث دالة تأكيد الآدمن `admin_confirm_whatsapp_booking`:**
   * تمكين الآدمن من التأكيد مع إمكانية التخصيص الآلي للفني المتاح أو تحديد فني يدوي، ونقل الحجز من `created` إلى `assigned`.

3. **تكامل روابط الواتساب في الواجهة (`lib/whatsapp.ts` & `confirm/page.tsx`):**
   * التأكد من أن رسالة الواتساب تتضمن رقم الطلب المقروء بشكل واضح يسهل على موظف خدمة العملاء مراجعته والبحث عنه.

---

### Phase 4 — Guest Tracking & Security (تتبع حجز الزائر والأمان والخصوصية)

#### المشاكل الحالية:
1. **تسريب بيانات العملاء الشخصية (PII Exposure):** دالة `get_guest_booking_details` في [80_add_pricing_inputs_to_guest_booking_details.sql](file:///d:/fresh_home_workspace/supabase/migrations/80_add_pricing_inputs_to_guest_booking_details.sql) ترجع العنوان الدقيق وأرقام الهواتف لأي شخص يمتلك `booking_id UUID` فقط دون أي إثبات ملكية!
2. **خلل البحث بالرقم المقروء (`FH-100293`):** دالة البحث في الواجهة ترسل الرقم المقروء كـ UUID فيحدث خطأ في قاعدة البيانات `invalid input syntax for type uuid`.

#### التعديلات المخططة:

1. **تأمين استعلام تفاصيل حجز الزائر (`get_guest_booking_details`):**
   * اشتراط معامل إضافي لإثبات الارتباط بالحجز (مثل مطابقة رقم الهاتف أو رمز الحجز التابع للجلسة)، بحيث لا يُسمح لمن يمتلك UUID عشوائي بقراءة العنوان الدقيق أو الاسم الكامل.
   * إخفاء وتصفير أي بيانات فني إذا كان الحجز ما زال بحالة غير مؤكدة (`is_whatsapp_confirmed = false`).

2. **حل مشكلة البحث بالرقم المقروء في شاشة التتبع (`orders/page.tsx`):**
   * دعم البحث الآمن إما عبر الرقم المقروء (`FH-XXXXXX`) أو عبر `UUID` بدون أن يتسبب ذلك في انهيار استعلام الـ SQL.

---

### Phase 5 — Customer Web App UX/UI (واجهات العميل على الويب)

#### الملفات المعنية:
* [`apps/customer_web/src/app/booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx)
* [`apps/customer_web/src/app/orders/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/orders/page.tsx)

#### التعديلات المخططة في تجربة المستخدم (UI/UX):

1. **تحديث تدفق إنشاء الحجز في `booking/page.tsx`:**
   * إلغاء السلوك القديم الذي كان يفرض `p_is_whatsapp_confirmed: false` لجميع الزوار.
   * تمرير إشارات الجلسة المتاحة للـ Backend، وترك الـ Backend يتخذ القرار الحتمي.

2. **شاشة تتبع الطلب ومراعاة حالتي الزائر (`orders/page.tsx`):**
   * **في حالة الحجز الأول (طبيعي ومؤكد):**
     * تظهر شاشة النجاح الفورية مباشرة دون أي بانر تحذيري ودون إظهار نافذة تأكيد الواتساب المربكة، مع عرض مسار التتبع المعتاد للفني.
   * **في حالة الحجز المكرر لنفس اليوم والخدمة (يحتاج واتساب):**
     * عرض الرسالة التوضيحية المحترمة والواضحة:  
       *"لديك حجز بالفعل لهذه الخدمة في نفس اليوم. لتأكيد الحجز الحالي، يرجى التأكيد عبر WhatsApp."*
     * إظهار عداد الـ 60 دقيقة التنازلي وزر الانتقال لمحادثة الواتساب.
     * إخفاء خطوة "الفني" من التايم لاين حتى يتم التأكيد، نظراً لعدم تخصيص فني بعد.

3. **معالجة التحديث اللحظي للزائر (Polling Fallback):**
   * توفير استطلاع دوري خفيف في صفحة التتبع لتحديث حالة الطلب فور قيام الآدمن أو العميل بتأكيده، لتفادي حجب Realtime عن المتصلين الزوار.

---

### Phase 6 — Admin / Staff Applications (لوحة تحكم الإدارة وتطبيق الفني)

#### الملفات المعنية:
* [`apps/fresh_home_admin/lib/features/booking_management/presentation/pages/admin_booking_details_screen.dart`](file:///d:/fresh_home_workspace/apps/fresh_home_admin/lib/features/booking_management/presentation/pages/admin_booking_details_screen.dart)
* [`apps/fresh_home_admin/lib/features/booking_management/presentation/cubit/admin_booking_details_cubit.dart`](file:///d:/fresh_home_workspace/apps/fresh_home_admin/lib/features/booking_management/presentation/cubit/admin_booking_details_cubit.dart)
* تطبيقات الفنيين الميدانية (`apps/technician_app`).

#### التعديلات المخططة:

1. **لوحة تحكم الإدارة (`fresh_home_admin`):**
   * إظهار الحجوزات المعلقة بانتظار تأكيد الواتساب في تصنيف واضح ("بانتظار تأكيد الواتساب — غير مسند لفني").
   * زر "تأكيد حجز العميل وتنشيط الطلب" يقوم بتشغيل المنطق الجديد (فحص السعة وتخصيص الفني ونقل الحالة إلى `assigned`).
   * عدم احتساب هذه الحجوزات ضمن طاقة الفنيين المحجوزة أو تقارير توزيع الأحمال اليومية.

2. **تطبيق الفنيين الميداني (`technician_app`):**
   * التأكد التام من أن سياسات الأمان (RLS) ومحرك الإشعارات تمنع وصول أي إشعار أو ظهور أي حجز غير مؤكد للفني على الإطلاق، نظراً لأن الحجز لم يُسند له أصلاً (`technician_id IS NULL`).

---

### Phase 7 — Comprehensive Testing Plan (خطة وسيناريوهات الاختبار الشاملة)

تتضمن خطة التحقق 7 سيناريوهات اختبار إلزامية تغطي القواعد بدقة:

| رقم الاختبار | السيناريو (Scenario) | المدخلات والشروط | النتيجة المتوقعة (Expected Output) |
| :--- | :--- | :--- | :--- |
| **Test 1** | **أول حجز لعميل زائر (First Guest Booking)** | زائر جديد ليس لديه حجوزات سابقة يحجز خدمة ليوم محدد. | • الحجز مؤكد فوراً (`is_whatsapp_confirmed = true`).<br>• الحالة = `assigned`.<br>• تخصيص فني فعلي واستهلاك السعة.<br>• لا تظهر أي نافذة واتساب أو تحذيرات. |
| **Test 2** | **حجز ثانٍ لنفس اليوم ونفس الخدمة (Duplicate Same-Day, Same-Service)** | نفس الزائر يحجز نفس نوع الخدمة لنفس اليوم المجدول. | • الحجز يتطلب واتساب (`is_whatsapp_confirmed = false`).<br>• الحالة = `created`.<br>• `technician_id = NULL`.<br>• السعة المستهلكة = **صفر**.<br>• ظهور الرسالة المهذبة ومؤقت الـ 60 دقيقة وزر الواتساب. |
| **Test 3** | **حجز ثانٍ في يوم مختلف لنفس نوع الخدمة (Different Day, Same Service)** | نفس الزائر يحجز نفس الخدمة ولكن ليوم مختلف. | • الحجز يمر كحجز طبيعي مؤكد فوراً (`is_whatsapp_confirmed = true`).<br>• الحالة = `assigned` ويتم تخصيص فني وحجز السعة. |
| **Test 4** | **حجز ثانٍ في نفس اليوم لخدمة مختلفة (Same Day, Different Service)** | نفس الزائر يحجز خدمة مختلفة في نفس اليوم. | • الحجز يمر كحجز طبيعي مؤكد فوراً (`is_whatsapp_confirmed = true`).<br>• الحالة = `assigned` ويتم تخصيص فني وحجز السعة. |
| **Test 5** | **محاولة تجاوز التحقق باستدعاء RPC مباشر (Direct Bypass Attempt)** | زائر يستدعي `create_atomic_booking` مباشرة عبر PostgREST ممرراً `p_is_whatsapp_confirmed = true` لحجز مكرر لنفس اليوم والخدمة. | • الباك إند يتجاهل المعامل المفروض من العميل كلياً.<br>• يكتشف التكرار ويفرض `is_whatsapp_confirmed = false` وحالة `created` بدون فني وبدون سعة. |
| **Test 6** | **التحقق من حجب السعة والفني للحجز غير المؤكد (Zero Capacity & No Assignment)** | فحص مخرجات `get_available_technicians` وجدول الفني بعد إنشاء حجز بانتظار الواتساب. | • طاقة الفنيين لم تنقص إطلاقاً (سعة اليوم كاملة ومتاحة).<br>• الفني لا يرى الحجز في تطبيقه ولا يصله أي إشعار. |
| **Test 7** | **تأكيد حجز الواتساب وتنشيطه (Confirmation & Dynamic Assignment)** | تأكيد الحجز المعلق من Test 2 (سواء برابط التأكيد أو من خلال الآدمن). | • يتم فحص السعة آنياً وتخصيص الفني المتاح.<br>• يتحول الحجز إلى `is_whatsapp_confirmed = true` وحالة `assigned`.<br>• حجز السعة وإرسال الإشعارات وظهور الحجز للفني. |

---

## 3. ترتيب التنفيذ المعتمد (Implementation Order)

لضمان سلامة واستقرار النظام، يتم التنفيذ وفق التسلسل الخطي التالي:

```
[ المرحلة 1: فحص الـ Schema وإصلاح حساب السعة ]
   ├── مراجعة الـ schema الحالية وطريقة تخزين الإشارات المتاحة
   └── تحديث get_available_technicians لاستبعاد غير المؤكد من السعة
              │
              ▼
[ المرحلة 2: تحديث دالة الحجز الذرية المركزية (Backend Authority) ]
   └── تحديث create_atomic_booking وتفريع المسار وفرض القرار من الـ Backend
              │
              ▼
[ المرحلة 3: دوال التأكيد وتأمين الخصوصية ]
   ├── تحديث confirm_whatsapp_booking و admin_confirm للتخصيص الآني عند التأكيد
   └── تأمين get_guest_booking_details وحل مشكلة البحث بالرقم المقروء
              │
              ▼
[ المرحلة 4: واجهة العميل (Customer Web) ]
   └── تحديث booking/page.tsx و orders/page.tsx والرسائل التوضيحية
              │
              ▼
[ المرحلة 5: لوحة الإدارة وتطبيقات الفنيين (Admin & Tech Apps) ]
   └── تمييز الحجوزات المعلقة غير المسندة وضمان عزلها عن الفنيين
              │
              ▼
[ المرحلة 6: الاختبار والتحقق الشامل (Verification) ]
   └── تشغيل سيناريوهات الاختبار السبعة والتحقق من عدم حدوث أي Regression
```

---

## 4. قائمة الملفات المعنية بالتعديل (Files To Change)

*ملاحظة: جميع هذه الملفات موجودة ومحققة فعلياً في المشروع:*

### أولاً: قاعدة البيانات و Supabase Migrations
1. [`supabase/migrations/95_reschedule_logic_capacity_overrides.sql`](file:///d:/fresh_home_workspace/supabase/migrations/95_reschedule_logic_capacity_overrides.sql):
   * تعديل دالة `get_available_technicians` لاستبعاد الحجوزات التي لها `is_whatsapp_confirmed = false` من حساب الأحمال.
2. [`supabase/migrations/104_fix_coverage_guard_address_snapshot_v2.sql`](file:///d:/fresh_home_workspace/supabase/migrations/104_fix_coverage_guard_address_snapshot_v2.sql):
   * سيتم إصدار Migration تكميلي يحل محل الدالة القديمة لفرض منطق كشف التكرار والمسار المتفرع من الباك إند.
3. [`supabase/migrations/75_whatsapp_confirmation_flow.sql`](file:///d:/fresh_home_workspace/supabase/migrations/75_whatsapp_confirmation_flow.sql):
   * تحديث دالة `confirm_whatsapp_booking` لتشمل فحص السعة وتخصيص الفني المتاح آنياً عند التأكيد.
4. [`supabase/migrations/76_admin_confirm_whatsapp_booking.sql`](file:///d:/fresh_home_workspace/supabase/migrations/76_admin_confirm_whatsapp_booking.sql):
   * تحديث دالة `admin_confirm_whatsapp_booking` للتعامل مع تخصيص الفني ونقل الحجز من `created` إلى `assigned`.
5. [`supabase/migrations/80_add_pricing_inputs_to_guest_booking_details.sql`](file:///d:/fresh_home_workspace/supabase/migrations/80_add_pricing_inputs_to_guest_booking_details.sql):
   * تحديث دالة `get_guest_booking_details` لحماية خصوصية بيانات العميل وتصحيح البحث بالرقم المقروء (`FH-XXXXXX`).

### ثانياً: واجهة العميل (Customer Web)
6. [`apps/customer_web/src/app/booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx):
   * إزالة التمرير الإجباري لقيمة `p_is_whatsapp_confirmed` وترك الباك إند يقرر الحالة.
7. [`apps/customer_web/src/app/orders/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/orders/page.tsx):
   * تعديل عرض شاشة التتبع والرسالة الموجهة للعميل في حالة انتظار الواتساب وإصلاح البحث بالرقم المقروء.
8. [`apps/customer_web/src/lib/whatsapp.ts`](file:///d:/fresh_home_workspace/apps/customer_web/src/lib/whatsapp.ts):
   * تحسين نص رسالة الواتساب وربطه برقم الحجز المقروء.
9. [`apps/customer_web/src/app/booking/confirm/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/confirm/page.tsx):
   * تحسين صفحة التأكيد والتعامل السلس مع حالات توفر أو نفاد السعة عند التأكيد.

### ثالثاً: تطبيق الإدارة (Admin App)
10. [`apps/fresh_home_admin/lib/features/booking_management/presentation/pages/admin_booking_details_screen.dart`](file:///d:/fresh_home_workspace/apps/fresh_home_admin/lib/features/booking_management/presentation/pages/admin_booking_details_screen.dart):
    * تحديث واجهة تفاصيل الحجز لعرض حالة الحجز المعلق بانتظار الواتساب (غير مسند لفني) وزر التأكيد الإداري.
11. [`apps/fresh_home_admin/lib/features/booking_management/presentation/cubit/admin_booking_details_cubit.dart`](file:///d:/fresh_home_workspace/apps/fresh_home_admin/lib/features/booking_management/presentation/cubit/admin_booking_details_cubit.dart):
    * تحديث الكيوبت للتعامل مع تخصيص الفني واستجابة التأكيد وتحديث الواجهة.

---

## 5. سجل التعارضات الحالية مع الكود وطريقة حلها (Identified Discrepancies & Resolutions)

| العنصر البرمجي | السلوك في الكود القائم حالياً | السلوك المعتمد في الخطة وفق القواعد | آلية الحل المعتمدة |
| :--- | :--- | :--- | :--- |
| **سلطة فرض الواتساب** | الـ Frontend يفرض `p_is_whatsapp_confirmed = false` لكل زائر في [booking/page.tsx#L1185](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx#L1185). | الـ Backend هو السلطة الحصرية؛ أول حجز يمر مؤكداً دون واتساب، والتكرار لنفس اليوم والخدمة فقط يطلب واتساب. | تجاهل المعامل القادم من العميل في الـ SQL، وتطبيق فحص التكرار الداخلي الحتمي. |
| **تخصيص الفني للزائر** | يتم تخصيص فني فوراً لأي حجز زائر حتى لو كان غير مؤكد في [104#L87-L97](file:///d:/fresh_home_workspace/supabase/migrations/104_fix_coverage_guard_address_snapshot_v2.sql#L87-L97). | الحجز الذي يحتاج واتساب لا يُخصص له فني مطلقاً (`technician_id = NULL`). | تفريع مسار التنفيذ في `create_atomic_booking`؛ حصر تخصيص الفني على الحجز المؤكد فقط. |
| **استهلاك السعة الاستيعابية** | الحجز غير المؤكد يدخل حالة `assigned` ويستهلك طاقة الفني في [95#L59](file:///d:/fresh_home_workspace/supabase/migrations/95_reschedule_logic_capacity_overrides.sql#L59). | الحجز غير المؤكد لا يستهلك أي طاقة (Zero Capacity Consumption). | إبقاء الحجز بحالة `created` واستبعاد الحجوزات غير المؤكدة من دالة حساب السعة. |
| **أول حجز للزائر** | يطلب منه تأكيد واتساب ويظهر له بانر تحذيري بمهلة 60 دقيقة في [orders/page.tsx](file:///d:/fresh_home_workspace/apps/customer_web/src/app/orders/page.tsx). | تجربة سلسة وفورية كالحجز الطبيعي المؤكد فوراً دون أي نوافذ أو اشتراطات. | جعل الحجز الأول `is_whatsapp_confirmed = true` وحالة `assigned` تلقائياً دون إظهار أي تحذيرات. |
| **البحث بالرقم المقروء** | إدخال `FH-100293` في [orders/page.tsx#L404](file:///d:/fresh_home_workspace/apps/customer_web/src/app/orders/page.tsx#L404) ينهار بخطأ تحويل نوع البيانات. | دعم البحث السلس بالرقم المقروء أو الـ UUID. | معالجة الإدخال بأمان في الدالة المسؤولة عن الاستعلام. |
| **أمان بيانات الزائر (PII)** | دالة `get_guest_booking_details` في [80](file:///d:/fresh_home_workspace/supabase/migrations/80_add_pricing_inputs_to_guest_booking_details.sql) ترجع كامل البيانات لأي شخص بـ UUID فقط. | حماية البيانات واشتراط مطابقة إشارة تواصل (مثل رقم الهاتف) قبل كشف البيانات الحساسة. | إضافة ضابط تحقق في الدالة وحجب العنوان في حالة عدم التطابق. |
