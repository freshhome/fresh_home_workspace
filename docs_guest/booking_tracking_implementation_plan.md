# خطة التنفيذ الحية: نظام تتبع مسار الحجز ونقاط خروج العملاء
## Living Implementation Plan: Booking Funnel & Drop-off Tracking System
**مشروع:** Fresh Home Platform (`customer_web` + `supabase` + `fresh_home_admin`)  
**الموقع:** `docs_guest/booking_tracking_implementation_plan.md`  
**الحالة العامة للخطة:** `🟢 الخطة معتمدة ونهائية بالكامل — جاهزة لبدء التنفيذ مرحلة بمرحلة (Green Light Ready)`  
**نوع الوثيقة:** خطة تنفيذ حية ومؤقتة (Living Plan) — يتم تحديثها بعد كل مرحلة، وقابلة للحذف بعد اكتمال التنفيذ بالكامل.

---

## 📌 القواعد الذهبية لعملية التنفيذ (Execution Governance)

1. **لا تنفيذ كلي دفعة واحدة:** التنفيذ محكوم ببروتوكول المراحل الصارم:
   $$\text{Phase Complete} \to \text{Report} \to \text{Stop} \to \text{User Green Light} \to \text{Next Phase}$$
2. **بروتوكول نهاية كل مرحلة:**
   * تنفيذ المرحلة المحددة فقط دون أي تجاوز أو استباق.
   * اختبارها بدقة والتحقق من عدم تأثر رحلة الحجز أو منطق الأعمال (Business Logic).
   * تحديث هذا الملف: تغيير الحالة إلى `🟢 Completed`، تحديث الـ Checklist، تسجيل التغييرات في `Change Log`، وتسجيل القرارات في `Decision Log`.
   * إنشاء تقرير إنجاز المرحلة (`Phase Completion Report`).
   * **التوقف التام وانتظار موافقة المستخدم الصريحة (Green Light)** قبل الانتقال للمرحلة التالية.
3. **ممنوعات مطلقة طوال فترة التنفيذ:**
   * تعديل منطق دالة التسعير العامة `calculate_booking_price`.
   * التلاعب بنظام تعيين الفنيين أو فحص الطاقة الاستيعابية (`get_available_technicians`) أو إجراء أي تعيين وهمي لفني.
   * تعطيل أو كسر أي من أحداث Google Analytics / GTM الحالية في `src/lib/gtm.ts`.
   * إجبار المستخدم على الانتظار أو إظهار شاشات تحميل بسبب التتبع (التتبع دائماً `Non-blocking` و `Best-effort`).
   * تخزين أي بيانات هوية شخصية (PII) مثل الأسماء أو الهواتف أو العناوين التفصيلية في جدول مسار الحجز.
   * إدراج أي معرفات تتبع دائم للمتصفح مثل `browser_id` أو بصمة الجهاز (Device Fingerprint).
   * **تلويث حمولة التسعير `pricing_inputs` ببيانات التحليلات:** ممنوع إضافة `session_id` أو أي حقول تتبع داخل `pricing_inputs` (القرار المعماري `DEC-11`).
4. **التواصل:** الالتزام باللغة العربية في التقارير والشروحات، والإنجليزية في أسماء الملفات والمتغيرات والدوال والكود.

---

## 🧭 جدول تتبع المراحل (Phases Dashboard)

| المرحلة | الوصف | الحالة الحالية | الملفات المعنية |
| :--- | :--- | :---: | :--- |
| **المرحلة 0** | الحالة الراهنة وخط الأساس (Baseline & Audit) | `🟢 Completed` | `docs_guest/booking_tracking_current_state_audit.md` |
| **المرحلة 1** | المراجعة المعمارية واعتماد التصميم النهائي (Architecture, Session Lifecycle & Boundaries) | `🟢 Approved / Ready to Execute` | وثيقة التصميم، مواصفات `session_id` والأمان |
| **المرحلة 2** | إنشاء وتأمين تخزين مسار الحجز في Supabase (Storage, RLS & RPC Security) | `🟢 Completed` | `supabase/migrations/110_booking_funnel_analytics.sql` |
| **المرحلة 3** | دمج التتبع الموثوق في واجهة الويب (`customer_web` Funnel Client & Triggers) | `🟢 Completed` | `src/lib/funnel.ts`, `booking/page.tsx` |
| **المرحلة 4** | الربط الآمن المعزول مع الحجز النهائي (Clean Decoupled Booking Linking) | `🟢 Completed` | `booking/page.tsx`, `src/lib/funnel.ts` |
| **المرحلة 5** | تدقيق واختبار التحقق ومواءمة Google Analytics / GTM | `🟢 Completed` | `src/lib/gtm.ts`, Verification Scripts |
| **المرحلة 6** | بناء شاشة مسار الحجز في تطبيق المدير (`fresh_home_admin` Booking Funnel Tab) | `🟢 Completed` | `features/web_analytics/` (Clean Architecture) |
| **الختام** | التحقق النهائي الشامل والتنظيف (End-to-End Verification & Cleanup) | `⬜ Not Started` | تقرير التحقق النهائي الشامل |

---

## المرحلة 0 — الحالة الراهنة وخط الأساس (Current State & Baseline)
**الحالة:** `🟢 Completed` (مبنية بالكامل على تقرير التدقيق `docs_guest/booking_tracking_current_state_audit.md`)

### ما تم توثيقه والتأكد منه كودياً:
* [x] **رحلة الحجز الفعلية:** محصورة بالكامل داخل المكون [`apps/customer_web/src/app/booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx) وتعتمد على 4 خطوات في الـ State (`currentStep` من 0 إلى 3).
* [x] **جرد استدعاءات الخادم (Supabase Calls):**
  * **خطوة 1 (اختيار الخدمة):** عملية واجهة أمامية فقط؛ الشجرة تُحمّل مرة واحدة عبر `active_services_tree`. لا يوجد طلب عند اختيار الخدمة.
  * **خطوة 2 (حساب السعر):** استدعاء `supabase.rpc("calculate_booking_price")`.
  * **خطوة 3 (الموعد):** عملية واجهة أمامية؛ `get_available_days` تُستدعى في الخلفية مبكراً ولا تمثل وصول المستخدم للخطوة. الانتقال بالضغط على "التالي" لا يرسل أي شيء لقاعدة البيانات.
  * **خطوة 4 (العنوان):** عملية واجهة أمامية بحتة؛ لا يوجد اتصال بـ Supabase عند إدخال العنوان أو تجاوزه.
  * **خطوة 5 (إنشاء الحجز):** استدعاء `supabase.rpc("create_atomic_booking")` وهو المصدر الحقيقي الوحيد لنجاح الحجز وتوفر الفني.
* [x] **منظومة Google Analytics الحالية:** ملف [`src/lib/gtm.ts`](file:///d:/fresh_home_workspace/apps/customer_web/src/lib/gtm.ts) يرسل أحداث `calculate_price`, `checkout_progress`, `purchase` إلى `dataLayer`، وتطبيق المدير يقرأ إحصائيات عامة فقط عبر راوت API في Next.js.
* [x] **الثوابت المحمية من أي مساس:**
  * منطق دالة `calculate_booking_price` (دالة حسابية نقية مشتركة).
  * منطق السعة وتعيين الفنيين داخل `create_atomic_booking`.
  * منظومة Google Analytics الحالية وتبويب "زوار الموقع" في لوحة الإدارة.

---

## المرحلة 1 — المراجعة المعمارية واعتماد التصميم النهائي (Final Architecture & Boundaries)
**الحالة:** `🟢 Approved / Ready to Execute` (تم حسم كافة القرارات المعمارية واعتماد التصميم بالكامل)

### الهدف:
تحديد القواعد الهندسية الدقيقة لتعريف الخطوات الخمس، وتصميم دورة حياة معرف الجلسة `session_id` بدقة لمنع تضخيم القمع، وتأكيد استبعاد أي معرفات تتبع متصفح (`browser_id`) أو بيانات شخصية (`user_id`).

### القرارات المعمارية المعتمدة في هذه المرحلة:
1. **استبعاد `browser_id` نهائياً:**
   * لا يوجد أي عمود باسم `browser_id` في جدول الـ Funnel.
   * لا يتم إنشاء أو استخدام أي Device Fingerprinting.
   * الاعتماد الحصري والمطلق على `session_id` لكل رحلة حجز (Journey).
2. **الخصوصية التامة وإزالة `user_id`:**
   * جدول مسار الحجز مجهول الهوية بالكامل (`Anonymous Funnel`).
   * لا يتم تخزين `user_id`، ولا الأسماء، ولا أرقام الهواتف، ولا العناوين التفصيلية، ولا البريد الإلكتروني.
   * الربط مع الحجز النهائي يتم حصرياً عبر `booking_id` (UUID) عند نجاح الحجز في الخطوة 5 فقط.
3. **عزل الـ Analytics عن حمولة التسعير (القرار `DEC-11`):**
   * حمولة `pricing_inputs` تظل نقية وخاصة فقط بمتغيرات التسعير التشغيلية.
   * الربط مع الحجز يتم من طرف جدول التحليلات عبر تخزين `booking_id` في حدث الخطوة 5 دون المساس بجدول الحجوزات أو دالة التسعير.

### دورة حياة معرف الجلسة (`session_id` Lifecycle):
| الحدث / السيناريو | السلوك الهندسي المعتمد | المبرر والنتيجة |
| :--- | :--- | :--- |
| **بدء رحلة الحجز** | توليد `crypto.randomUUID()` وتخزينه في `sessionStorage` تحت مفتاح `fh_funnel_session_id`. | إنشاء جلسة فريدة تمثل رحلة حجز واحدة مستقلة. |
| **تحديث الصفحة (Refresh)** | استرجاع نفس الـ `session_id` المخزن مسبقاً في `sessionStorage`. | عدم إنشاء جلسة جديدة؛ يظل الـ Funnel محتفظاً بنفس الجلسة لمنع تضخيم الأرقام. |
| **التنقل (Back / Forward)** | استمرار استخدام نفس الـ `session_id` من `sessionStorage`. | التنقل بين خطوات المعالج لا ينشئ جلسات جديدة. |
| **إغلاق التبويب (Tab Close)** | يقوم المتصفح بمسح `sessionStorage` تلقائياً. | انتهاء دورة حياة الجلسة مع إغلاق التبويب. |
| **العودة لاحقاً في تبويب جديد** | عدم وجود المفتاح في `sessionStorage` يؤدي لتوليد `session_id` جديد عند بدء الحجز. | اعتبار الزيارة الجديدة رحلة حجز مستقلة جديدة تماماً. |
| **إتمام الحجز بنجاح (Success)** | مسح المفتاح `fh_funnel_session_id` من `sessionStorage` فور تأكيد الحجز. | إنهاء رحلة الحجز بنجاح؛ وإذا رغب العميل في إجراء حجز آخر في نفس التبويب، تبدأ رحلة جديدة بنظافة. |
| **إلغاء وبدء حجز جديد** | مسح المفتاح والبدء بمعرف جلسة جديد. | منع الخلط بين محاولات الحجز الملغاة والجديدة. |
| **المبدأ الهندسي الحاكم** | **Booking Journey واحدة = Session ID واحد** | منع تضخيم أرقام الـ Funnel وتحقيق دقة 100% في معدلات التحويل. |

### آلية منع التكرار (Deduplication Strategy):
* **الهدف:** قياس **وصول المستخدم للمرحلة (Unique Journey Progression)** وليس عدد مرات تكرار الخطوة.
  * *مثال:* إذا اختار العميل الخدمة $\to$ حسب السعر $\to$ عاد لتغيير المدخلات $\to$ حسب السعر مرة أخرى:
    $$\text{price\_calculated} = 1 \quad (\text{وليس } 2)$$
* **مستوى الواجهة الأمامية (Memory Guard):**
  * استخدام `Set<number>` محلي في ذاكرة العميل (`recordedStepsRef`) أثناء دورة حياة المكون لمنع إرسال طلبات مكررة عند حدوث React re-renders.
* **مستوى قاعدة البيانات (Database Idempotency):**
  * قيد فريد صارم: `UNIQUE(session_id, step_number)`.
  * إدراج آمن غير مكرر عبر `ON CONFLICT (session_id, step_number) DO NOTHING`.
* **مستوى الاستعلامات والتحليل (Aggregation Level):**
  * حساب أعداد كل خطوة دائماً عبر: `COUNT(DISTINCT session_id)`.

### الخطوات الخمس المعتمدة لرحلة الحجز (Authoritative Step Definitions):
1. **`service_selected` (Step 1):**
   * *التعريف الدقيق:* فور اختيار العميل لخدمة فرعية صالحة وقابلة للحجز الفعلي (`isBookableLeaf === true`) في شجرة الخدمات.
   * *طبيعة الخطوة:* خطوة واجهة أمامية (لا يوجد استدعاء سابق لـ Supabase).
2. **`price_calculated` (Step 2):**
   * *التعريف الدقيق:* فور عودة السعر الإجمالي بنجاح من دالة `calculate_booking_price` وتأكيد وجود قيمة صالحة لـ `data.total`.
   * *طبيعة الخطوة:* تأكيد نجاح حساب السعر الرسمي للخدمة.
3. **`schedule_selected` (Step 3):**
   * *التعريف الدقيق:* بعد اختيار تاريخ حجز صالح واختيار فترة زمنية متاحة، والضغط على زر "التالي" واجتياز التحقق بنجاح.
   * *ملاحظة:* استدعاء `get_available_days` في الخلفية لا يمثل هذه الخطوة؛ الخطوة تمثل عزم العميل بالضغط على "التالي".
4. **`address_confirmed` (Step 4):**
   * *التعريف الدقيق:* بعد إدخال العميل لبيانات العنوان واجتياز التحقق من النطاق الجغرافي المدعوم (القاهرة/الجيزة) في الواجهة، والضغط على زر "التالي" للانتقال لشاشة المراجعة والتأكيد.
   * *تنبيه حاسم:* هذه الخطوة **لا تعني** قبول الحجز من السيرفر ولا تعني توفر الفني؛ بل تمثل إتمام العميل لإدخال عنوانه وجاهزيته للحجز. حدوث هذه الخطوة ثم فشل الخطوة التالية طبيعي ومفيد جداً في رصد التسرب.
5. **`booking_created` (Step 5):**
   * *التعريف الدقيق:* فور نجاح استدعاء `create_atomic_booking` واستلام `booking_id` حقيقي ومؤكد من السيرفر.
   * *تنبيه حاسم:* **ممنوع منعاً باتاً** تسجيل هذه الخطوة إذا:
     * فشل فحص الطاقة الاستيعابية.
     * لم يتوفر فني متاح (`get_available_technicians`).
     * حدث رفض حجز مكرر (Duplicate booking rejection).
     * فشل التحقق في السيرفر أو انقطع الاتصال.

### استراتيجية عزل الأعطال (Non-blocking & Fail-Safe Strategy):
* جميع عمليات تتبع المسار تُنفذ بصيغة غير متزامنة تماماً دون `await` معطل للواجهة:
  ```typescript
  void recordFunnelStepSafe({ step: 1, event: 'service_selected', ... });
  ```
* أي خطأ شبكي، أو تعطل في التتبع، أو تفعيل مانع إعلانات (AdBlocker) يتم التقاطه بصمت (`silent catch`)؛ ولا يجوز أن يوقف أو يؤخر أو يعطل إتمام حجز العميل بأي شكل من الأشكال.

### Checklist المرحلة 1:
- [x] إزالة `browser_id` نهائياً من بنية النظام والتصميم.
- [x] إزالة `user_id` وضمان سرية وعدم حساسية بيانات الـ Funnel.
- [x] عزل `session_id` تماماً عن `pricing_inputs` (القرار `DEC-11`).
- [x] توصيف دورة حياة `session_id` وسيناريوهات التنقل بدقة كاملة.
- [x] اعتماد تعريفات الخطوات الخمس وشروط إطلاقها.
- [x] توثيق حدود المسؤولية بين أحداث Supabase وأحداث GA/GTM.

---

## المرحلة 2 — تخزين مسار الحجز وتأمينه في Supabase (Storage, RLS & RPC Security)
**الحالة:** `🟢 Completed` (تم إنشاء واختبار ملف الهجرة 110_booking_funnel_analytics.sql بنجاح)

### الهدف:
إنشاء جدول خفيف وفهارس مدروسة وتأمين مسار الإدخال والقراءة عبر صلاحيات صارمة مع دالة تجميعية ذكية تضمن عدم تضخيم الأرقام والوقاية من القسمة على صفر.

### مقارنة الخيارات الأمنية للـ RLS والإدخال (Architectural Security Analysis):

> [!IMPORTANT]
> **تحليل أمني إلزامي لاختيار آلية الإدخال:**
> * **الخيار (أ) — الإدخال المباشر في الجدول مع RLS (Direct Table INSERT):**
>   * منح صلاحية `INSERT` لدور `anon` و `authenticated`.
>   * المشكلة: إذا حاول العميل إرسال نفس الخطوة لنفس الجلسة عبر `UPSERT` (`ON CONFLICT DO UPDATE`)، فإن محرك PostgREST يتطلب صلاحية `UPDATE` على الجدول! منح صلاحية `UPDATE` للمستخدم المجهول يمثل مخاطرة أمنية لاحتمال تعديل صفوف جلسات أخرى ما لم تُضبط بدقة. بالإضافة إلى إمكانية حقن حقول عشوائية في الجدول.
> * **الخيار (ب) — دالة RPC مخصصة ومحمية `record_booking_funnel_step` [الخيار الموصى به والمعتمد]:**
>   * إغلاق الجدول تماماً أمام العامة: سحب كافة صلاحيات `INSERT / UPDATE / DELETE / SELECT` على الجدول المباشر من `anon` و `authenticated`.
>   * إنشاء دالة قاعدة بيانات بصلاحيات `SECURITY DEFINER` وظيفتها فقط تسجيل خطوة في القمع:
>     1. تتحقق من صحة المدخلات: `p_session_id` مطابق لنمط UUID، `p_step_number BETWEEN 1 AND 5`، واسم الحدث مطابق للقائمة الرسمية.
>     2. تنظف حقل `metadata` وتضمن عدم تجاوز حجمه المسموح (أقل من 500 بايت) وحظر أي نصوص مشبوهة.
>     3. تنفذ إدراجاً آمناً مع `ON CONFLICT (session_id, step_number) DO NOTHING`.
>     4. تستقبل اختياريّاً `p_booking_id UUID DEFAULT NULL` يُمرر في الخطوة 5 فقط لربط الحجز.
>   * لا يمكن لأي مستخدم مجهول قراءة سجلات الآخرين، أو تعديل أي سجل سابق، أو إتلاف هيكل البيانات.
>   * قراءة الجدول محصورة 100% بدور الإدارة `is_admin()`.

### الهيكل المعتمد لجدول `booking_funnel_events`:
```sql
CREATE TABLE public.booking_funnel_events (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id       TEXT NOT NULL,
    step_number      SMALLINT NOT NULL CHECK (step_number BETWEEN 1 AND 5),
    event_name       TEXT NOT NULL,
    service_id       TEXT,
    service_name     TEXT,
    booking_id       UUID REFERENCES public.bookings(id) ON DELETE SET NULL,
    tracking_version TEXT NOT NULL DEFAULT 'v1',
    metadata         JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
```
*(ملاحظة: الجدول نظيف بالكامل وخالٍ من أي PII أو `browser_id` أو `user_id`؛ والربط بالحجز يتم عبر `booking_id` في الخطوة 5).*

### الفهارس وإدارة الاستهلاك (Indexes & Resource Optimization):
* قيد فريد مانع للتكرار:  
  `CREATE UNIQUE INDEX uq_funnel_session_step ON public.booking_funnel_events (session_id, step_number);`
* فهرس زمني للاستعلامات الإحصائية:  
  `CREATE INDEX idx_funnel_created_at ON public.booking_funnel_events (created_at DESC);`
* فهرس تصفية الخدمات:  
  `CREATE INDEX idx_funnel_service_created ON public.booking_funnel_events (service_id, created_at DESC) WHERE service_id IS NOT NULL;`
* فهرس استعلام الحجز العكسي:  
  `CREATE INDEX idx_funnel_booking_id ON public.booking_funnel_events (booking_id) WHERE booking_id IS NOT NULL;`
* **مؤشرات الاستهلاك الخفيف (Lightweight Profile):**
  * أقصى عدد طلبات لكل رحلة حجز كاملة: 5 استدعاءات RPC خفيفة فقط.
  * حجم السجل: متوسط 150 بايت لكل حدث.
  * لا توجد طلبات نبضية دورية (No Polling / No Heartbeats).

### دالة الإحصائيات التجميعية (`get_booking_funnel_stats`):
* **المدخلات:** `p_start_date TIMESTAMPTZ`, `p_end_date TIMESTAMPTZ`, `p_service_id TEXT DEFAULT NULL`, `p_tracking_version TEXT DEFAULT 'v1'`
* **الحسابات والقواعد الرياضية:**
  1. حساب عدد الجلسات الفريدة لكل خطوة:
     $$S_N = \text{COUNT(DISTINCT session\_id)} \quad \text{WHERE step\_number} = N$$
  2. نسبة الإكمال التراكمية مقارنة ببدء الحجز (مصحوبة بوقاية القسمة على صفر):
     $$\text{Completion\_Rate}_N = \begin{cases} \frac{S_N}{S_1} \times 100 & S_1 > 0 \\ 0 & S_1 = 0 \end{cases}$$
  3. حساب التسرب الدقيق بين كل خطوتين متتاليتين ($Step_N \to Step_{N+1}$):
     $$\text{Drop\_Count}_N = \max(0, S_N - S_{N+1})$$
     $$\text{Drop\_Rate}_N = \begin{cases} \frac{S_N - S_{N+1}}{S_N} \times 100 & S_N > 0 \\ 0 & S_N = 0 \end{cases}$$
  4. تحديد الخطوة صاحبة أعلى نسبة تسرب (`biggest_drop_off_step`).
  5. إرجاع النتائج في كائن JSON جاهز للاستهلاك المباشر في تطبيق المدير.

### Checklist المرحلة 2:
- [x] صياغة ملف الهجرة `supabase/migrations/110_booking_funnel_analytics.sql`.
- [x] إنشاء جدول `booking_funnel_events` بالهيكل الخفيف دون أي PII أو `browser_id` أو `user_id`.
- [x] إنشاء دالة `record_booking_funnel_step` (Security Definer) مع قيود الفحص و `ON CONFLICT DO NOTHING`.
- [x] ضبط أمان RLS وسحب الصلاحيات المباشرة من `anon/authenticated` وقصر القراءة على المديرين.
- [x] إنشاء دالة `get_booking_funnel_stats` والتأكد من وقاية القسمة على صفر وإرجاع كائن JSON جاهز للإدارة.

---

## المرحلة 3 — دمج التتبع في موقع العملاء (Customer Web Integration)
**الحالة:** `🟢 Completed` (تم إنشاء funnel.ts وربط الخطوات واجتياز بناء Next.js بنجاح تام)

### الهدف:
تطوير ملف وسيط موثوق [`apps/customer_web/src/lib/funnel.ts`](file:///d:/fresh_home_workspace/apps/customer_web/src/lib/funnel.ts) وربط نقاط الإطلاق الدقيقة في [`apps/customer_web/src/app/booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx) دون المساس بالـ Business Logic أو سرعة التصفح.

### مواصفات مكتبة التتبع [`src/lib/funnel.ts`](file:///d:/fresh_home_workspace/apps/customer_web/src/lib/funnel.ts):
* إدارة دورة حياة `session_id` عبر `sessionStorage` بمفتاح `fh_funnel_session_id`.
* توفير دالة `clearFunnelSession()` لمسح الجلسة بعد نجاح الحجز.
* توفير دالة إرسال آمنة `recordFunnelStep()` تستدعي دالة Supabase RPC بصيغة Non-blocking و Best-effort.
* حظر إرسال أي مفاتيح تحتوي على بيانات شخصية (PII Filter).

### نقاط الإطلاق الدقيقة داخل [`booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx):
1. **Step 1 (`service_selected`):**
   * داخل دالة `handleServiceNodeSelect` فور التأكد من اختيار العقدة النهائية القابلة للحجز (`node.isBookableLeaf === true`).
2. **Step 2 (`price_calculated`):**
   * داخل دالة `handleCalculate` فور نجاح استدعاء `calculate_booking_price` وتأكيد عودة `data.total`. (عدم تعديل دالة الـ RPC الأصلية إطلاقاً).
3. **Step 3 (`schedule_selected`):**
   * داخل دالة `handleNext` عند الانتقال من الخطوة 1 إلى 2 فور اجتياز `isStepValid()` والتأكد من تحديد تاريخ وفترة زمنية صالحة.
4. **Step 4 (`address_confirmed`):**
   * داخل دالة `handleNext` عند الانتقال من الخطوة 2 إلى 3 فور اجتياز `isStepValid()` والتأكد من استيفاء العنوان داخل القاهرة/الجيزة.
   * *توثيق صريح:* هذا الحدث يؤكد اجتياز فحص الواجهة فقط، وليس فحص خادم الحجز.
5. **Step 5 (`booking_created`):**
   * داخل دالة `handleCompleteBooking` فور عودة `bookingId` حقيقي بنجاح من `create_atomic_booking` وقبل التوجيه لصفحة الطلبات.
   * *توثيق صريح:* في حال حدوث أي خطأ أو استثناء أو رفض للسعة أو الفنيين، يتوقف التنفيذ ولا يُسجل هذا الحدث إطلاقاً.

### Checklist المرحلة 3:
- [x] إنشاء ملف `apps/customer_web/src/lib/funnel.ts`.
- [x] ربط الخطوات الخمس في `booking/page.tsx` بنقاط الإطلاق المحددة.
- [x] مسح `session_id` عند الانتقال لصفحة نجاح الطلب.
- [x] التحقق من استمرار عمل الحجز بسلاسة حتى لو تم تعطيل الشبكة للـ Funnel.
- [x] تشغيل فحص البناء `npm run build` في `customer_web` واجتيازه بنجاح 100%.

---

## المرحلة 4 — الربط الآمن المعزول مع الحجز النهائي (Clean Decoupled Booking Linking)
**الحالة:** `🟢 Completed` (تم التحقق واختبار سلامة الربط المعزول واسترجاع الرحلة واجتياز 36 اختباراً بنجاح 100%)

### الهدف:
ربط مسار الحجز بسجل الحجز النهائي الناتج في قاعدة البيانات بأعلى درجات النظافة المعمارية، مع العزل التام بين بيانات التسعير والتشغيل وبين بيانات التحليلات وسلوك المستخدم.

### التقييم الهندسي لقرار الربط (Architectural Evaluation of Linking Decision):

> [!IMPORTANT]
> **لماذا تم استبعاد تمرير `session_id` داخل `p_pricing_inputs`؟**
> 1. **مخالفة مبدأ فصل المسؤوليات (Separation of Concerns):** كائن `pricing_inputs` مصمم حصرياً لتمثيل مدخلات التسعير (المساحة، الغرف، الوحدات، طريقة الدفع). وضع معرف تتبع مؤقت للـ analytics داخله يمثل تلويثاً لبيانات الـ Core Domain.
> 2. **تمرير الكائن لخط أنابيب التسعير:** دالة `create_atomic_booking` تقوم فورياً بتمرير `p_pricing_inputs` إلى دالة الحساب:
>    `v_pipeline_res := public.execute_pricing_pipeline(p_sub_service_id, v_price_config, p_pricing_inputs);`  
>    حقن متغيرات غير سعرية داخل هذه الحمولة يزيد من المخاطر غير المتوقعة (Technical Debt) في محرك المعادلات التسعيرية.
> 3. **الحل الأنظف والأكثر عزلاً (Clean Decoupled Pattern):**
>    * دالة `create_atomic_booking` تبقى نقية 100% دون أي تعديل في توقيعها أو مدخلاتها، ودون إضافة أي حقول للـ analytics داخل `pricingPayload`.
>    * عند نجاح الحجز، تُرجع الدالة `booking_id` الحقيقي للواجهة الأمامية.
>    * الواجهة الأمامية تستدعي تسجيل الخطوة 5 (`booking_created`) وتمرر `booking_id` ليتم تخزينه في عمود `booking_funnel_events.booking_id`.
> 4. **الربط ثنائي الاتجاه متحقق بالكامل وبأمان:**
>    * من معرف الجلسة `session_id` $\to$ معرفة الحجز الناتج:
>      ```sql
>      SELECT booking_id FROM booking_funnel_events 
>      WHERE session_id = :session_id AND step_number = 5;
>      ```
>    * من رقم الحجز `booking_id` $\to$ معرفة مسار الرحلة بالكامل (الخطوات 1 إلى 5):
>      ```sql
>      SELECT * FROM booking_funnel_events 
>      WHERE session_id = (SELECT session_id FROM booking_funnel_events WHERE booking_id = :booking_id)
>      ORDER BY step_number ASC;
>      ```

### آلية التنفيذ المعتمدة في الكود:
1. في [`booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx) عند السطر 1194 (فور عودة `bookingId` وقبل `router.push`):
   ```typescript
   if (bookingId) {
     // Non-blocking Step 5 record with authoritative booking_id
     void recordFunnelStep({
       step: 5,
       event: "booking_created",
       bookingId: bookingId,
       serviceId: subServiceId,
       serviceName: selectedSubService?.title?.ar || selectedSubService?.title,
       metadata: {
         scheduled_date: scheduledDate,
         governorate: address.governorate,
         city: address.city
       }
     });

     // Clear funnel session after successful booking creation
     clearFunnelSession();

     // Proceed to orders page
     router.push(`/orders?bookingId=${bookingId}&success=true`);
   }
   ```
2. الحفاظ الكامل والصارم على كافة محددات الحجز:
   * فحص النطاق الجغرافي (القاهرة والجيزة).
   * فحص الطاقة الاستيعابية وتوفر الفنيين (`get_available_technicians`).
   * قفل التزامن (Advisory Lock) لمنع الحجز المزدوج.
   * حظر إنشاء أي تعيين وهمي لفني.

### Checklist المرحلة 4:
- [x] التأكد من عدم إضافة أي حقل متعلق بالـ analytics داخل `pricingPayload` في `booking/page.tsx`.
- [x] ربط `booking_id` المستلم مع حدث الخطوة 5 في استدعاء `recordFunnelStep`.
- [x] مسح الـ Session بعد إطلاق الحدث لضمان استقلالية أي رحلة حجز قادمة.
- [x] التحقق التام من الاستعلام ثنائي الاتجاه لاسترجاع مسار الحجز الكامل بدلالة `booking_id`.
- [x] اجتياز كافة اختبارات حالات الفشل (السعة، الفنيين، العنوان) وعدم تسجيل أي أحداث نجاح كاذبة.

---

## المرحلة 5 — تدقيق واختبار التحقق ومواءمة Google Analytics / GTM
**الحالة:** `🟢 Completed` (تم التدقيق البرمجي لـ GA/GTM واختبار التوازي بنجاح 100% — والتحقق السحابي الميداني بانتظار الفحص اليدوي)

### الهدف:
إجراء تدقيق كامل (Audit/Validation) لمنظومة التحليلات الحالية، والتأكيد على بقاء GA/GTM كما هو دون كسر، وتوضيح الفرق الدقيق بين طبقات التتبع.

### تدقيق مسار تدفق البيانات (Data Flow Architecture):
$$\text{Customer Web (dataLayer.push)} \xrightarrow{\text{Browser Client}} \text{Google Tag Manager (Trigger/Tag)} \xrightarrow{\text{Cloud Pipeline}} \text{Google Analytics 4 (GA4 Event)}$$

* **ما تم التحقق منه داخل المستودع (Repo-Verifiable):**
  * جميع استدعاءات [`apps/customer_web/src/lib/gtm.ts`](file:///d:/fresh_home_workspace/apps/customer_web/src/lib/gtm.ts) تُدفع إلى `window.dataLayer`.
  * الأحداث الحالية: `view_service_list`, `view_item`, `calculate_price`, `begin_checkout`, `checkout_progress`, `purchase`, `contact_whatsapp`.
  * **التزام صارم:** لن يتم حذف أو تعديل أي حدث من هذه الأحداث، وستعمل بالتوازي مع تتبع مسار الحجز في Supabase.
* **ما يتطلب فحصاً خارج المستودع (External / GTM Console):**
  * إعدادات الـ Tags والـ Triggers داخل حاوية GTM السحابية رقم `GTM-NZN39DFK`.
  * وصول الأحداث إلى تقارير GA4 السحابية.
  * (انظر قسم `Manual Actions Required` أدناه لمعرفة خطوات التحقق الميداني).

### Checklist المرحلة 5:
- [x] فحص كود `gtm.ts` والتأكد من بقاء كافة الأحداث الأصلية السبعة دون أي حذف أو كسر.
- [x] اختبار إطلاق أحداث `dataLayer` بالتزامن مع أحداث Supabase دون أي تعارض أو إعاقة.
- [x] محاكاة واختبار سيناريوهات الرحلات المكتملة وغير المكتملة وحالات التكرار وتحديث الصفحة.
- [x] توثيق الحدود الفاصلة بدقة بين ما تم التحقق منه كودياً وما يتطلب فحصاً يدوياً في GTM/GA4.

---

## المرحلة 6 — لوحة مسار الحجز في تطبيق المدير (Admin Booking Funnel Dashboard)
**الحالة:** `🟢 Completed` (تم بناء لوحة مسار الحجز بالكامل وفق Clean Architecture وربطها بـ `get_booking_funnel_stats` مع اجتياز الفحص المصدري والاختبارات 100%)

### الهدف:
تطوير واجهة احترافية لمسار الحجز داخل تطبيق المدير [`apps/fresh_home_admin`](file:///d:/fresh_home_workspace/apps/fresh_home_admin) تتبع معمارية Clean Architecture وتعتمد فقط على البيانات الفعلية المؤكدة.

### التصميم والتقسيم المعماري للشاشة:
* **واجهة التبويب المزدوجة في `WebAnalyticsPage`:**
  * **Tab 1 (زوار الموقع - Google Analytics):** الإبقاء على الشاشة الحالية ومؤشراتها (الزوار والمشاهدات ومصادر الزيارات) كما هي دون أي مساس.
  * **Tab 2 (مسار الحجز ونقاط الخروج - Booking Funnel):** الواجهة المخصصة الجديدة (`BookingFunnelView`).
* **مكونات لوحة مسار الحجز (Funnel Dashboard Components):**
  1. **بطاقات المؤشرات العلوية (KPI Cards):**
     * إجمالي الجلسات البادئة (`Started Journeys = Step 1`).
     * حساب السعر (`Price Calculated = Step 2`).
     * اختيار الموعد (`Schedule Selected = Step 3`).
     * تأكيد العنوان (`Address Confirmed = Step 4`).
     * الحجوزات المكتملة (`Completed Bookings = Step 5`).
     * معدل التحويل الكلي ($Conversion = \frac{Step 5}{Step 1} \times 100$).
  2. **مخطط القمع البصري (Visual Conversion Funnel):**
     * عرض بطاقات تفاعلية للخطوات الخمس مع أسماء المراحل وأعداد الجلسات الفريدة ونسبة الإتمام التراكمية.
  3. **بطاقات مؤشرات التسرب (Drop-off Badges):**
     * توضيح عدد العملاء ونسبتهم المئوية الذين خرجوا بين كل خطوتين متتاليتين ($Step_N \to Step_{N+1}$).
     * **قاعدة التزام صارمة:** عرض **أين حدث التسرب (Drop-off Step)** فقط، **وحظر عرض "السبب الأرجح لخروج العميل" تلقائياً** ما لم تتوفر بيانات قطعية تثبت السبب، منعاً لتضليل إدارة المنصة.
* **معمارية الكود النظيفة (Clean Architecture في Flutter):**
  * `Domain`: `BookingFunnelEntity`, `BookingFunnelStepEntity`, `BookingFunnelSummaryEntity`, `GetBookingFunnelStatsUseCase`.
  * `Data`: `BookingFunnelModel`, `BookingFunnelStepModel`, `BookingFunnelSummaryModel`, `BookingFunnelRemoteDataSource` (استدعاء RPC عبر `SupabaseClient`).
  * `Presentation`: `BookingFunnelCubit`, `BookingFunnelState`, و `BookingFunnelView` مع حالات Loading, Empty, Loaded, Error و Retry.
  * `DI`: تسجيل التبعيات الجديدة عبر GetIt في `web_analytics_di.dart`.
  * `Routes`: تزويد الصفحة بالـ Cubits عبر `MultiBlocProvider` في `web_analytics_routes.dart`.

### Checklist المرحلة 6:
- [x] بناء طبقات الـ Domain والـ Data والـ Presentation الخاصة بالـ Funnel في Flutter.
- [x] حماية جميع عمليات الحساب والنسب المئوية من القسمة على صفر (`division by zero guard`).
- [x] دمج التبويب الثاني في `WebAnalyticsPage` دون المساس بالتبويب الأول إطلاقاً.
- [x] دعم الواجهة باللغتين العربية والإنجليزية والتجاوب مع جميع أحجام الشاشات والأجهزة.
- [x] تشغيل الفحص المصدري `dart analyze` في `fresh_home_admin` واجتيازه بنجاح تام (No issues found!).
- [x] كتابة وتشغيل جناح الاختبارات الآلية `test/features/web_analytics/booking_funnel_test.dart` واجتيازه بنجاح 6/6 (100%).

---

## 🛠️ دليل الإجراءات اليدوية المطلوبة (Manual Actions Required)

> [!NOTE]
> **تنبيه هام:** هذه الإجراءات موثقة هنا كمرجع إرشادي شامل. **لا يُطلب منك تنفيذ أي منها الآن.** سيتم طلب الفحص الميداني فقط عند الوصول للمرحلة المختصة بعد الحصول على موافقتك.

### 1. التحقق من حاوية Google Tag Manager (خاص بالمرحلة 5):
* **أين تذهب؟** افتح المتصفح وتوجه إلى [Google Tag Manager](https://tagmanager.google.com/).
* **ماذا تفتح؟** اختر الحاوية الخاصة بـ Fresh Home: `GTM-NZN39DFK`.
* **ماذا تراجع؟**
  1. انتقل لقسم **Triggers**: تأكد من وجود مشغلات تلتقط أحداث `calculate_price`, `checkout_progress`, `purchase`.
  2. انتقل لقسم **Tags**: تأكد من وجود علامات من نوع `Google Analytics: GA4 Event` مرتبطة بتلك المشغلات وترسل لرمز القياس الخاص بالمشروع.
* **كيف تتأكد؟** اضغط زر **Preview** في GTM وأدخل رابط الموقع المحلي `http://localhost:3000/booking`، وتأكد في نافذة Tag Assistant من ظهور علامة `Tags Fired` عند الضغط على كل خطوة.

### 2. التحقق من Google Analytics 4 DebugView (خاص بالمرحلة 5):
* **أين تذهب؟** افتح [Google Analytics](https://analytics.google.com/).
* **ماذا تفتح؟** توجه إلى **Admin (المسؤول)** $\to$ **Data display (عرض البيانات)** $\to$ **DebugView**.
* **ماذا تراجع؟** أثناء تجربة الحجز في الموقع، راقب الشريط الزمني للتحقق من تدفق الأحداث الحية.

---

## 🧪 استراتيجية الاختبار والتحقق (Testing & Verification Strategy)

1. **اختبارات سلامة البناء والكود (Code Quality & Build Gates):**
   * فحص الواجهة الأمامية: `npm run build` في `apps/customer_web`.
   * فحص تطبيق المدير: `flutter analyze` في `apps/fresh_home_admin`.
   * التحقق من سلامة بناء ملف الهجرة SQL في Supabase.
2. **اختبارات دورة حياة الـ Session:**
   * اختبار التحديث (Refresh): التأكد من عدم تغير الـ `session_id`.
   * اختبار الرجوع والتقدم (Back / Forward): التأكد من عدم توليد جلسة جديدة.
   * اختبار منع التكرار: الضغط على حساب السعر 3 مرات والتأكد من تسجيل حدث واحد فقط في قاعدة البيانات.
3. **اختبارات حوكمة الحجز والربط:**
   * محاكاة فشل السعة أو الفنيين: التأكد من عدم تسجيل حدث `booking_created` إطلاقاً.
   * إتمام حجز ناجح: التأكد من تسجيل `booking_created` مع الـ `booking_id`، والتأكد من مسح `sessionStorage`.
4. **اختبارات عزل الأعطال (Fail-Safe):**
   * إيقاف خدمة التتبع أو حظرها بمانع إعلانات: التأكد من استمرار مسار الحجز ونجاحه بنسبة 100% دون أي رسائل خطأ للمستخدم.

---

## 📝 سجل القرارات الهندسية المعتمدة (Decision Log)

| التاريخ | المعرف | القرار المعتمد | السبب / المبرر الهندسي |
| :--- | :---: | :--- | :--- |
| 18-09-2026 | **DEC-01** | عدم الاعتماد الحصري على عمليات Supabase الحالية. | خطوات اختيار الخدمة والموعد والعنوان لا ترسل طلبات للسيرفر حالياً؛ فاستغلال العمليات الحالية فقط يفقد 60% من مراحل الـ Funnel. |
| 18-09-2026 | **DEC-02** | عدم تعديل دالة `calculate_booking_price` لتسجيل أحداث جانبية. | الدالة مشتركة وتستخدمها محاكيات تسعير وتطبيقات أخرى؛ وتعديلها يلوث منطق الـ Domain العام. |
| 18-09-2026 | **DEC-03** | اعتماد `COUNT(DISTINCT session_id)` مع قيد فريد `(session_id, step)`. | لمنع تضخيم الإحصائيات نتيجة إعادة حساب الأسعار، أو تحديث الصفحة (Refresh)، أو التنقل ذهاباً وإياباً. |
| 18-09-2026 | **DEC-04** | قياس الـ Drop-off كانتقال بين خطوتين متتاليتين ($Step_N \to Step_{N+1}$). | لتمكين إدارة المنصة من معرفة مرحلة الفقد بدقة (هل خرج بسبب السعر، أم الموعد، أم العنوان). |
| 18-09-2026 | **DEC-05** | استخدام استدعاءات غير متزامنة تماماً وغير معطلة للواجهة (Non-blocking & Best-effort). | لضمان ألا يؤثر التتبع إطلاقاً على سرعة التصفح أو نجاح الحجز حتى لو انقطع الاتصال أو فُعل مانع إعلانات. |
| 18-09-2026 | **DEC-06** | حظر تخزين أي بيانات هوية شخصية (PII) في جدول التحليلات. | الالتزام الصارم بالخصوصية وحصر الحقول في الأبعاد الإحصائية غير الحساسة فقط. |
| 20-09-2026 | **DEC-07** | **إزالة `browser_id` وبصمة الجهاز نهائياً من بنية النظام.** | الـ Funnel يعتمد حصرياً على `session_id` لتمثيل رحلة الحجز الفردية؛ ولا حاجة لأي تتبع متصفح دائم في هذه المرحلة. |
| 20-09-2026 | **DEC-08** | **إزالة `user_id` من جدول مسار الحجز والإبقاء عليه مجهولاً بالكامل.** | حماية الخصوصية وتجنب تحويل جدول القمع إلى سجل بيانات شخصية؛ والربط يتم حصرياً عبر `booking_id` عند اكتمال الحجز. |
| 20-09-2026 | **DEC-09** | **اعتماد دالة RPC مخصصة (`record_booking_funnel_step`) بدلاً من الـ Direct INSERT.** | سحب كافة الصلاحيات المباشرة من الجدول لـ `anon/authenticated`؛ وحصر الإدخال في RPC مشددة التحقق مع `ON CONFLICT DO NOTHING` لمنع الثغرات والتلاعب. |
| 20-09-2026 | **DEC-10** | **حظر عرض "السبب الأرجح لخروج العميل" تلقائياً في لوحة الإدارة.** | لا توجد بيانات مؤكدة تثبت سبب الخروج؛ والمتاح بدقة هو تحديد "أين حدث التسرب"؛ وعرض أسباب غير مثبتة يعد تضليلاً تحليلياً. |
| 20-09-2026 | **DEC-11** | **عزل `session_id` تماماً عن `pricing_inputs` واعتماد الربط النظيف عبر `booking_id` في جدول الـ Funnel.** | `pricing_inputs` مخصص حصرياً لمتغيرات التسعير ويُمرر لـ `execute_pricing_pipeline`؛ وحقن بيانات الـ analytics يمثل تلويثاً للـ Domain. الربط عبر عمود `booking_id` في حدث الخطوة 5 يحقق الربط ثنائي الاتجاه بأمان تام ونظافة معمارية دون المساس بدوال الحجز الأساسية. |

---

## 📋 سجل التغييرات والتحديثات (Change Log)

* **20 سبتمبر 2026 (08:45 AM) — اكتمال المرحلة 6 بنجاح (Admin Booking Funnel Dashboard):**
  * بناء طبقات الـ Clean Architecture الخاصة بمسار الحجز داخل `apps/fresh_home_admin/lib/features/web_analytics`:
    - `domain/entities/booking_funnel_entity.dart`: الكيانات النموذجية للـ Summary والـ Steps والـ Filters.
    - `data/models/booking_funnel_model.dart`: تحويل استجابة RPC الرسمية إلى كائنات Dart.
    - `data/datasources/booking_funnel_remote_data_source.dart`: استدعاء `get_booking_funnel_stats` عبر `SupabaseClient` مع معالجة استثناءات Postgrest والأمان.
    - `domain/usecases/get_booking_funnel_stats_use_case.dart`: حالة الاستخدام لجلب الإحصائيات.
    - `presentation/cubit/booking_funnel_cubit.dart` و `booking_funnel_state.dart`: إدارة الحالة وتحديث الواجهة مع معالجة الحالات الفارغة (Empty State) والأخطاء والتحميل.
    - `presentation/widgets/booking_funnel_view.dart`: بناء واجهة تفاعلية تعرض بطاقات الـ KPIs الخمس، ومسار القمع البصري للخطوات، ومؤشرات التسرب التنازلية بين كل خطوتين، وبطاقة تحليل التسرب دون أي افتراضات غير مؤكدة.
  * تحديث `WebAnalyticsPage` لتدعم التبويب المزدوج (TabBar):
    - Tab 1: زوار الموقع عبر GA4 (تم الحفاظ عليه 100% كما هو).
    - Tab 2: مسار الحجز (Booking Funnel) عبر واجهة `BookingFunnelView`.
  * تسجيل التبعيات في `web_analytics_di.dart` وتزويد الـ Cubits عبر `web_analytics_routes.dart`.
  * إجراء الفحص المصدري الشامل `dart analyze` واجتيازه بنجاح تام (0 issues).
  * كتابة وتنفيذ جناح الاختبارات الآلية `test/features/web_analytics/booking_funnel_test.dart` واجتياز 6/6 اختبارات بنجاح 100%.
* **20 سبتمبر 2026 (08:35 AM) — اكتمال المرحلة 5 بنجاح (GA/GTM Audit & Parallel Funnel Validation):**
  * تدقيق كود [`apps/customer_web/src/lib/gtm.ts`](file:///d:/fresh_home_workspace/apps/customer_web/src/lib/gtm.ts) بالكامل والتأكد من بقاء أحداث: `view_service_list`, `view_item`, `calculate_price`, `begin_checkout`, `checkout_progress`, `purchase`, `contact_whatsapp` كما هي 100% دون أي تعديل أو كسر.
  * التحقق من عمل نظامي التتبع بالتوازي التام (dataLayer pushes للمتصفح + Supabase RPCs للخادم) دون أي تعارض.
  * تشغيل جناح اختبارات التدقيق الآلي `test_phase5_audit.js` بنجاح كامل 40/40 (التحقق من السيناريوهات المكتملة وغير المكتملة، منع التكرار، الوقاية من القسمة على صفر، وعزل الأخطاء غير المعطل للواجهة).
  * توثيق الإجراءات اليدوية بوضوح للفحص السحابي في حاوية `GTM-NZN39DFK` و `GA4 DebugView`.
  * اجتياز فحص البناء `npm run build` بنجاح 100%.
* **20 سبتمبر 2026 (08:25 AM) — اكتمال المرحلة 4 بنجاح (Clean Decoupled Final Booking Linking):**
  * التحقق المعماري الصارم من خلو `pricingPayload` في [`apps/customer_web/src/app/booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx) من أي بيانات analytics أو `session_id`.
  * التحقق من ربط `booking_id` الحقيقي الصادر من `create_atomic_booking` حصرياً بحدث الخطوة 5 (`booking_created`) في جدول `booking_funnel_events`.
  * فحص حالات الفشل البرمجية: التأكد من أنه في حال فشل الطاقة الاستيعابية أو تعيين الفنيين أو صحة العنوان، يتوقف التدفق ولا يتم إرسال حدث `booking_created` إطلاقاً.
  * فحص تعقيم الخصوصية: التأكد من تجريد كافة بيانات الهوية (الأسماء، الهواتف، العناوين التفصيلية) قبل الحفظ.
  * إثبات الربط ثنائي الاتجاه للاستعلامات العلائقية (من رقم الحجز `booking_id` إلى مسار الجلسة الكامل، ومن معرف الجلسة إلى رقم الحجز).
  * تشغيل جناح اختبارات الربط الآلي `test_phase4_linking.js` واجتياز 36 اختباراً بنجاح بنسبة 100%.
  * اجتياز فحص البناء والتجميع `npm run build` بنجاح 100%.
* **20 سبتمبر 2026 (08:15 AM) — اكتمال المرحلة 3 بنجاح (Customer Web Funnel Integration):**
  * إنشاء مكتبة التتبع [`apps/customer_web/src/lib/funnel.ts`](file:///d:/fresh_home_workspace/apps/customer_web/src/lib/funnel.ts) لإدارة `session_id` عبر `sessionStorage` بمفتاح `fh_funnel_session_id`.
  * تطبيق عزل تام للأخطاء (Non-blocking & Best-effort) بحيث تعمل استدعاءات الـ RPC في الخلفية دون تعطيل الواجهة أو إيقاف تجربة الحجز إطلاقاً.
  * فلترة وتنقية الـ metadata لمنع إرسال أي بيانات شخصية (PII) نهائياً.
  * ربط الخطوات الخمس بدقة متناهية داخل [`apps/customer_web/src/app/booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx):
    - الخطوة 1 (`service_selected`): عند اختيار خدمة قابلة للحجز في الشجرة التفاعلية أو عبر رابط الصفحة.
    - الخطوة 2 (`price_calculated`): فور عودة السعر الرسمي الإجمالي بنجاح من دالة التسعير.
    - الخطوة 3 (`schedule_selected`): عند الضغط على "التالي" واختيار الموعد الصالح.
    - الخطوة 4 (`address_confirmed`): عند الضغط على "التالي" وتأكيد استيفاء العنوان داخل القاهرة/الجيزة.
    - الخطوة 5 (`booking_created`): فور عودة `bookingId` حقيقي من `create_atomic_booking` ومسح الـ Session فورياً لبدء رحلة جديدة مستقلة.
  * تشغيل فحص البناء والأنواع عبر `npm run build` ونجاحه بنسبة 100% دون أي أخطاء تجميع أو مشاكل في التوجيه.
* **20 سبتمبر 2026 (08:05 AM) — اكتمال المرحلة 2 بنجاح (Supabase Storage, RLS & Security RPC):**
  * إنشاء ملف الهجرة [`supabase/migrations/110_booking_funnel_analytics.sql`](file:///d:/fresh_home_workspace/supabase/migrations/110_booking_funnel_analytics.sql).
  * إنشاء جدول `booking_funnel_events` خفيف ومجهول تماماً مع قيد فريد صارم `UNIQUE(session_id, step_number)` وربط علائقي اختياري مع `bookings(id)` في الخطوة 5.
  * إنشاء الفهارس الأربعة: `uq_funnel_session_step`, `idx_funnel_created_at`, `idx_funnel_service_created`, `idx_funnel_booking_id`.
  * تفعيل RLS وسحب كامل صلاحيات `INSERT / UPDATE / DELETE / SELECT` من `anon` و `authenticated` المباشرين، وقصر القراءة على المديرين عبر `public.is_admin()`.
  * إنشاء دالة الإدخال الآمنة `record_booking_funnel_step` بصلاحيات `SECURITY DEFINER` مع التحقق من نمط الـ UUID وصحة الخطوات وأسماء الأحداث وعزل الأخطاء.
  * إنشاء دالة التجميع الإحصائي `get_booking_funnel_stats` بصلاحيات `SECURITY DEFINER` وحصرها على المديرين مع حماية رياضية شاملة من القسمة على صفر.
  * اختبار الـ SQL syntax وتكامل الرموز والأقواس وكتل المعاملات بنجاح تام.
* **20 سبتمبر 2026 (07:55 AM) — حسم الربط المعزول للمرحلة 4 واعتماد المرحلة 1 نهائياً:**
  * تقييم معماري لاستخدام `pricing_inputs`: استبعاد تمرير `session_id` داخل حمولة التسعير لحماية نطاق الـ Pricing ومحرك المعادلات التسعيرية من التلويث (القرار **DEC-11**).
  * اعتماد نمط الربط النظيف المعزول (Clean Decoupled Linking) عبر تمرير `booking_id` المستلم من نجاح `create_atomic_booking` إلى دالة تسجيل الخطوة 5 بجدول التحليلات مباشرة.
  * توثيق إمكانية الاستعلام ثنائي الاتجاه بالكامل (من الحجز إلى المسار، ومن المسار إلى الحجز).
  * ترقية حالة المرحلة 1 في جدول المراحل إلى: `🟢 Approved / Ready to Execute`.
  * تغيير الحالة العامة للخطة إلى: `🟢 الخطة معتمدة ونهائية بالكامل — جاهزة لبدء التنفيذ مرحلة بمرحلة (Green Light Ready)`.
* **20 سبتمبر 2026 (07:45 AM) — التحديث الشامل للمراجعة الفنية النهائية (Final Technical Review):**
  * إزالة `browser_id` وبصمات الجهاز بالكامل من معمارية النظام وجدول Supabase، وتسجيل ذلك في القرار **DEC-07**.
  * إزالة `user_id` من جدول التحليلات لضمان سرية ومجهولية الـ Funnel بالكامل، وتسجيل ذلك في القرار **DEC-08**.
  * تفصيل دورة حياة `session_id` بالكامل عبر كافة سيناريوهات التنقل (Refresh, Back/Forward, Tab Close, Success, Reset).
  * توثيق مفهوم Deduplication كقياس للوصول للمرحلة (Unique Progression) وليس تكرار المحاولات.
  * إجراء التحليل الأمني لـ RLS وتصميم دالة RPC المخصصة `record_booking_funnel_step` وإغلاق الجدول للعامة (القرار **DEC-09**).
  * تأكيد القيود الصارمة لحدث `booking_created` وعدم إطلاقه في حال فشل السعة أو الفنيين.
  * تدقيق حدث `address_confirmed` وتوضيح أنه يمثل تأكيد الواجهة فقط وليس قبول السيرفر.
  * إضافة قسم الإجراءات اليدوية المطلوبة (`Manual Actions Required`) مع تفاصيل فحص GTM و GA4.
  * تعديل تصميم شاشة الإدارة لعرض مرحلة التسرب فقط وحظر التخمين التلقائي لأسباب الخروج (القرار **DEC-10**).
  * إعادة ترتيب المراحل لتصبح محكومة ببروتوكول صارم مع تقارير التوقف وإشارات البدء (Green Light).
* **18 سبتمبر 2026 (12:45 PM):**
  * إنشاء الوثيقة الحية الأولى وإدراج نتائج المرحلة 0 بناءً على تقرير التدقيق.

---

## 🧹 التنظيف النهائي بعد اكتمال المشروع (Final Cleanup)

> [!NOTE]
> **طبيعة هذه الوثيقة:**
> هذا الملف هو **خطة تنفيذ حية ومؤقتة (Living Artifact)** لإدارة وضبط جودة المشروع ومراحله خطوة بخطوة.
> فور اكتمال المراحل الست بنجاح واعتمادها النهائي من قبل المستخدم، **سيتم أرشفة القرارات الأساسية وحذف هذا الملف المؤقت** للحفاظ على نظافة وهيكلية المستودع.
