# Fresh Home — Customer Journey & Tracking Readiness Report
## تقرير التحليل الشامل لرحلة العميل وبنية التتبع الرقمي (Web Analytics & Tracking Architecture)

---

## 1. Executive Summary (الملخص التنفيذي)

يُعد تطبيق **Customer Web** الخاص بـ **Fresh Home** تطبيق ويب مبنياً على إطار عمل **Next.js (App Router)** و **Supabase Backend**، ومُصمماً لخدمة السوق المصري في مجالات النظافة الشاملة، الصيانة المنزلية، ومكافحة الحشرات.

من منظور هندسة القياس والتتبع الرقمي (**Web Analytics & Tracking Architecture**):
* **نظام التسعير صارم ومحمي (Backend-Driven Pricing)**: لا يعتمد النظام على أسعار ثابتة من طرف العميل (Client-Side)، بل تُحسب القيمة بدقة متناهية عبر دوال قاعدة البيانات (`RPC: calculate_booking_price` و `execute_pricing_pipeline`) مع حفظ لقطة غير قابلة للتلاعب (`price_snapshot`).
* **عملية إنشاء الحجز ذرية وموثوقة (Atomic Booking Transaction)**: تتم عبر دالة `RPC: create_atomic_booking` التي تُنشئ الحجز، وتُعيّن الفني المتاح، وتُولّد معرّف الحجز (`booking_id` / `readable_id`).
* **مسار الحجز واضح ومتعدد الخطوات (4-Step Modular Stepper)**: يتيح تتبع دقيق لكل مرحلة تحويل وسلوك (Funnel Step Progression).
* **دعم نوعين من العملاء**: عملاء مسجلون (**Authenticated Users**) وزوار (**Guest Checkout**)، مع وجود آلية تأكيد عبر WhatsApp للزوار لتقليل الحجوزات الوهمية.

---

## 2. Homepage Journey (تحليل رحلة الصفحة الرئيسية)

تبدأ رحلة المستخدم عند زيارة المسار الأساسي:
* **المسار (Route)**: `/`
* **الملف الأساسي**: [`page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/page.tsx)
* **المكونات المشاركة**:
  - [`Header.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/Header.tsx): شريط التنقل العلوي، التبديل بين الوضع الليلي/النهاري، روابط الأقسام، زر تسجيل الدخول أو صورة المستخدم، وتنبيه تسجيل الدخول عند الضغط على "طلباتي".
  - [`Hero.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/Hero.tsx): واجهة الترحيب الرئيسية وزر الحجز المباشر (`/booking`) وزر تصفح الخدمات (`#services`) وزر حاسبة التكلفة (`/booking`).
  - [`ServicesSection.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/ServicesSection.tsx): شريط البحث عن الخدمات، وفلاتر الأقسام الرئيسية، وسلايدرات تفاعلية لعرض الخدمات الفرعية.
  - [`PostConstructionBanner.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/PostConstructionBanner.tsx): قسم ترويجي متخصص لخدمة "تنظيف ما بعد التشطيب" مع صورة (قبل / بعد) وأزرار توجيه للحجز.
  - [`HowItWorksSection.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/HowItWorksSection.tsx): استعراض خطوات تقديم الخدمة الأربعة (اختر خدمتك، حدد الموعد، استقبل الفني، استمتع ببيتك).
  - [`PricingTeaser.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/PricingTeaser.tsx): توضيح شفافية التسعير وزر "جرب الآن" التوجيهي إلى `/booking`.
  - [`QualityAdvantage.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/QualityAdvantage.tsx) & [`TrustSection.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/TrustSection.tsx): عناصر بناء الثقة (ضمان الجودة، فنيون معتمدون، أمان المنزل).
  - [`LocationsSection.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/LocationsSection.tsx): مناطق التغطية (القاهرة والجيزة، القاهرة الجديدة، أكتوبر، الشيخ زايد، إلخ).
  - [`FaqSection.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/FaqSection.tsx): الأسئلة الشائعة والأجوبة.
  - [`BottomCtaBanner.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/BottomCtaBanner.tsx): بانر ختامي للتحويل السريع للحجز أو المحادثة المباشرة عبر واتساب.
  - [`Footer.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/Footer.tsx): روابط الخدمات المباشرة، التواصل الاجتماعي، وواتساب.

### 🧭 الرحلات التي يمكن للمستخدم القيام بها من الصفحة الرئيسية:
1. **رحلة استكشاف وحجز خدمة محددة**: (الرئيسية ⬅️ قسم الخدمات ⬅️ صفحة تفاصيل الخدمة ⬅️ معالج الحجز).
2. **رحلة الحجز المباشر السريع**: (الرئيسية ⬅️ زر "احجز الآن" في Hero / CTA ⬅️ معالج الحجز `/booking`).
3. **رحلة استكشاف الفئات**: (الرئيسية ⬅️ روابط الفئات / الفلاتر ⬅️ صفحة `/services?serviceId=...`).
4. **رحلة المحادثة المباشرة (WhatsApp Lead)**: (الرئيسية ⬅️ أزرار واتساب في البانر السفلي أو الفوتر ⬅️ فتح `https://wa.me/20...`).
5. **رحلة تسجيل الدخول / إنشاء حساب**: (Header ⬅️ `/login` أو `/register`).
6. **رحلة تتبع الحجوزات**: (Header ⬅️ زر "طلباتي" ⬅️ فتح مودال تسجيل الدخول للضيوف أو التوجيه لـ `/orders` للمسجلين).

---

## 3. Service Discovery Journey (رحلة اكتشاف وتصفح الخدمات)

### أ. صفحة دليل خدمات الفئة (`/services`)
* **المسار**: `/services?serviceId=FH-S-100001`
* **الملف المسؤول**: [`apps/customer_web/src/app/services/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/services/page.tsx)
* **المكون**: `ServicesListContent`
* **آلية العمل**:
  - جلب شجرة الخدمات من جدول / فيو `active_services_tree`.
  - جلب متوسط التقييمات الحقيقي من جدول `reviews`.
  - جلب رقم واتساب الفعال من `system_settings` (مفتاح `whatsapp_settings`).
* **تفاعلات المستخدم**:
  - التنقل بين تصنيفات الخدمات (Root Category Tabs).
  - البحث الفوري داخل القسم عبر `searchQuery`.
  - النقر على كارت الخدمة: إذا كانت قابلة للحجز (`is_bookable: true`)، يتم التوجيه إلى `/services/details?serviceId=...&subServiceId=...`. وإذا كانت فرعاً له تفريعات، يتم التوجيه إلى استعراض التفريعات.

### ب. صفحة تفاصيل الخدمة (`/services/details`)
* **المسار**: `/services/details?serviceId=FH-S-100001&subServiceId=FH-S-100009`
* **الملف المسؤول**: [`apps/customer_web/src/app/services/details/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/services/details/page.tsx)
* **المكون**: `ServiceDetailsContent`
* **الحالتان البرمجيتان للصفحة**:
  1. **حالة الفرع المتشعب (Branch Node)**: إذا كانت الخدمة تحتوي على خدمات فرعية (`childServices.length > 0` مثل "السباكة" أو "صيانة التكييف")، تعرض الصفحة شبكة الخدمات الفرعية مع مسار Breadcrumb وتوجيه لاختيار الخدمة المحددة.
  2. **حالة الخدمة القابلة للحجز النهائي (Leaf Bookable Node)**: مثل "تنظيف بعد التشطيب" أو "كشف تسريبات المياه".
* **البيانات المعروضة والمستخرجة**:
  - السعر الابتدائي/التقديري ونوعه (`fixed`, `per_square_meter`, `per_linear_meter`, `inspection`).
  - ما تشمله الخدمة (`inclusions / details`).
  - ما لا تشمله الخدمة (`exclusions / not_included`).
  - التعليمات والإرشادات (`instructions`).
  - تقييمات وتجارب العملاء (`view_reviews_with_details`).
  - زر الإضافة إلى المفضلة (`localStorage: favorites`).
* **أهم User Actions**:
  - الضغط على زر **"احجز الخدمة الآن"** ⬅️ يوجه إلى `/booking?serviceId=...&subServiceId=...`.
  - الضغط على **"استفسر عبر واتساب"** ⬅️ يفتح محادثة واتساب مع ملء اسم الخدمة تلقائياً.
  - الضغط على **"إشعاري فور توفر الخدمة"** (في حال كانت الخدمة بحالة `paused`).

---

## 4. Complete Customer Booking Journey (تحليل رحلة الحجز خطوة بخطوة)

* **المسار الأساسي**: `/booking`
* **الملف المسئول**: [`apps/customer_web/src/app/booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx)
* **المكون**: `BookingFlowContent`
* **معمارية تدفق الحجز (4 الخطوات المنطقية)**:

```
[ الخطوة 1: اختيار الخدمة وحساب السعر ]
                 ↓
[ الخطوة 2: تحديد الموعد والفترة الزمنية ]
                 ↓
[ الخطوة 3: إدخال أو اختيار العنوان ]
                 ↓
[ الخطوة 4: مراجعة الطلب والتأكيد النهائي ]
                 ↓
[ تنفيذ RPC: create_atomic_booking على الخادم ]
                 ↓
[ التحويل إلى صفحة النجاح والتتبع: /orders?bookingId=...&success=true ]
```

---

### تفصيل مراحل معالج الحجز (Step-by-Step Breakdown):

#### 🔹 الخطوة 1: اختيار الخدمة وحساب السعر التفاعلي (`Step 0: Price Calculation`)
* **الهدف**: تحديد الخدمة بدقة، ملء الحقول الديناميكية (Dynamic Pricing Fields)، واختيار الإضافات (Addons)، ثم إجراء الحساب الرسمي من الخادم.
* **الـ UI Interactions**:
  1. **التنقل في شجرة الخدمات**: اختيار الفئة الرئيسية ⬅️ اختيار الخدمة الفرعية القابلة للحجز (`is_bookable: true`).
  2. **توليد الحقول الديناميكية (`pricingInputs`)**:
     - حقول رقمية (`number`): المساحة بالمتر المربع (`area`)، عدد الغرف (`rooms_count`)، عدد الحمامات (`bathrooms_count`)، عدد الأجهزة (`units_count` / `ac_units_count`).
     - حقول التبديل (`toggle`): وجود شرفات (`has_balcony`)، الحاجة لشحن فريون (`needs_freon`).
     - حقول القوائم (`dropdown / select`).
  3. **اختيار الإضافات الاختيارية (`selectedAddons`)**: مثل تلميع باركيه، تطهير بالبخار، تعطير فندقي.
  4. **زر "احسب التكلفة الدقيقة"**:
     - التحقق من شروط المدخلات (`validationErrors`).
     - تنفيذ استدعاء الخادم: `supabase.rpc("calculate_booking_price", { p_sub_service_id, p_pricing_inputs })`.
     - استلام كائن السعر: `{ basePrice, extraFees, discount, total, metadata }`.
* **شرط الانتقال للخطوة التالية**: أن تكون `subServiceId !== ""` وأن تكون قيمة `priceDetails.total > 0` الناتجة من الخادم.

---

#### 🔹 الخطوة 2: اختيار الموعد والفترة الزمنية (`Step 1: Scheduling`)
* **الهدف**: اختيار اليوم والساعة المتاحة لتنفيذ الزيارة.
* **الـ UI Interactions ومصدر البيانات**:
  - عند اختيار الخدمة، يُنفذ استدعاء `supabase.rpc("get_available_days", { p_sub_service_id, p_start_date, p_end_date })` لجلب الأيام المتاحة فعلياً ومراعاة أوقات العمل وقدرة الفنيين الاستيعابية.
  - اختيار اليوم عبر شريط تقويم أفقي (`scheduledDate`) أو كتابة التاريخ يدوياً.
  - اختيار التوقيت المناسب (`scheduledTime`) من الفترات المتاحة (مثلاً: 09:00 ص، 12:00 م، 03:00 م، 06:00 م).
* **شرط الانتقال للخطوة التالية**: تحديد `scheduledDate` و `scheduledTime` مع التأكد من أن اليوم متاح (`availabilityMap[scheduledDate] !== false`).

---

#### 🔹 الخطوة 3: إدخال وتحديد العنوان (`Step 2: Address Details - Address V2`)
* **الهدف**: التقاط الموقع الدقيق للعميل في القاهرة والجيزة.
* **الـ UI Interactions والبيانات المجمعة**:
  - **للعميل المسجل (`Authenticated`)**: تظهر قائمة العناوين المحفوظة مسبقاً (`user_addresses`) مع خيار استخدام عنوان محفوظ أو إدخال عنوان جديد.
  - **للزائر (`Guest`)**: إدخال بيانات العنوان الجديد عبر الهرم الجغرافي (`GEOGRAPHIC_HIERARCHY` من [`geo.ts`](file:///d:/fresh_home_workspace/apps/customer_web/src/lib/geo.ts)):
    - المحافظة (`governorate`): القاهرة / الجيزة.
    - المدينة / المنطقة (`city`): مثل التجمع الخامس، مدينة نصر، الشيخ زايد، 6 أكتوبر.
    - الحي (`district`): الحي الأول، الياسمين، النرجس، إلخ.
    - الشارع / الكمبوند (`street_or_compound`).
    - رقم العمارة / المبنى (`building_identifier`).
    - الطابق (`floor`)، ورقم الشقة / الوحدة (`apartment_or_unit`).
    - علامة مميزة (`landmark`).
    - رابط الموقع على خرائط جوجل (`location_url` أو عبر زر "تحديد موقعي الحالي").
* **شرط الانتقال للخطوة التالية**: ملء الحقول الإلزامية: المحافظة، المدينة، الحي، الشارع، ورقم المبنى.

---

#### 🔹 الخطوة 4: مراجعة الطلب والتأكيد النهائي (`Step 3: Review & Confirmation`)
* **الهدف**: مراجعة ملخص الحجز بالكامل، إدخال بيانات الاتصال، واختيار طريقة الدفع، وتأكيد الحجز.
* **البيانات المجمعة**:
  - اسم العميل (`name`).
  - رقم الهاتف المصري (`phone` - يتم التحقق عبر Regex: `^(010|011|012|015)\d{8}$`).
  - طريقة الدفع (`paymentMethod`): نقداً للفني بعد إتمام الخدمة (`cash`).
  - كارت مراجعة شامل يحتوي على: اسم الخدمة، التاريخ، التوقيت، العنوان، وتفصيل السعر الإجمالي.
* **حدث الإرسال والتأكيد (Booking Submission)**:
  - استدعاء الدالة المركزية:
    ```typescript
    supabase.rpc("create_atomic_booking", {
      p_user_id: userId,
      p_sub_service_id: subServiceId,
      p_technician_id: null, // Auto-assigned by DB logic
      p_scheduled_day: scheduledDate,
      p_address_snapshot: addressSnapshot,
      p_service_snapshot: serviceSnapshot,
      p_pricing_inputs: pricingPayload,
      p_contact_name: name.trim(),
      p_contact_phones: [phone.trim()],
      p_start_time_slot: time24,
      p_is_whatsapp_confirmed: userId !== null // True for logged-in, False for guests
    })
    ```

---

#### 🔹 الخطوة 5: نتيجة العملية وما بعد الحجز (`Post-Booking State`)
* **في حالة النجاح (`Success`)**:
  - يُرجع الـ RPC معرّف الحجز `bookingId` (UUID).
  - يتم تخزين توقيت الإنشاء محلياً `booking_created_{bookingId}` لحساب العداد التنازلي للتأكيد.
  - يتم التوجيه التلقائي للمسار:
    ```
    /orders?bookingId=${bookingId}&success=true
    ```
* **في صفحة تتبع الطلبات ([`orders/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/orders/page.tsx))**:
  - يتم استدعاء دالة `get_guest_booking_details` لجلب كائن الحجز المكتمل والموثق من قاعدة البيانات.
  - **للعميل المسجل**: الحجز مؤكد مباشرة (`is_whatsapp_confirmed: true`).
  - **للعميل الزائر (Guest)**: يظهر بانر ومودال يوضح أن الحجز في انتظار التأكيد عبر رسالة واتساب مع عداد زمني (60 دقيقة) وزر إرسال رسالة التأكيد عبر واتساب المحتوية على تفاصيل الحجز.
  - الاستماع للتحديثات الحية عبر **Supabase Realtime Channel** لتحديث حالة الطلب فورياً عند تغييرها من قبل الإدارة أو الفني.

---

## 5. Authentication Journey (تحليل رحلة المصادقة وتسجيل الدخول)

### أ. تسجيل الدخول (`/login`)
* **الملف المسئول**: [`apps/customer_web/src/app/login/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/login/page.tsx)
* **المسارات والآليات**:
  1. **دخول بالبريد وكلمة المرور**: `supabase.auth.signInWithPassword({ email, password })`.
  2. **دخول بـ Google OAuth**: `supabase.auth.signInWithOAuth({ provider: 'google', options: { redirectTo } })`.
  3. **استعادة كلمة المرور**: `supabase.auth.resetPasswordForEmail(email)`.
  4. **دعم إعادة التوجيه الذكية (`redirectPath`)**: دعم استكمال ما كان يفعله المستخدم قبل تسجيل الدخول (مثل `redirect=/booking` أو `redirect=/orders`).

### ب. إنشاء حساب جديد (`/register`)
* **الملف المسئول**: [`apps/customer_web/src/app/register/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/register/page.tsx)
* **البيانات المجمعة**:
  - الاسم الأول (`firstName`) واسم العائلة (`lastName`).
  - البريد الإلكتروني (`email`).
  - رقم الهاتف (`phone` - يتم تخزينه والتحقق منه في جدول `user_phones`).
  - كلمة المرور وتأكيدها (`password` / `confirmPassword`).
* **آلية التنفيذ**: `supabase.auth.signUp(...)` مع إدراج الهاتف في `user_phones`.

### ج. الملف الشخصي وإدارة الحساب (`/profile`)
* **الملف المسئول**: [`apps/customer_web/src/app/profile/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/profile/page.tsx)
* **الوظائف**:
  - تعديل الاسم ومزامنة جدول `public.profiles`.
  - إدارة وحفظ أرقام الهواتف المتعددة في `user_phones`.
  - إدارة وحفظ دفتر العناوين المتعددة في `user_addresses` (تحديد العنوان الرئيسي، إضافة، حذف).
  - استعراض سجل الحجوزات السابقة والنشطة.
  - تسجيل الخروج: `supabase.auth.signOut()`.

---

## 6. Conversion Points & Commercial Classification (نقاط التحويل وتصنيفها التجاري)

تم حصر كافة نقاط التفاعل والتحويل داخل منصة Fresh Home وترتيبها حسب الأهمية الاستراتيجية والتجارية:

| نوع التحويل | اسم الحدث المقترح | مكان الحدوث في الكود | الوصف والقيمة التجارية |
| :--- | :--- | :--- | :--- |
| **Primary Conversion** | `purchase` / `booking_complete` | [`booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx#L883) (`handleCompleteBooking`) | نجاح إدراج الحجز في قاعدة البيانات وصدور `booking_id`. يمثل القيمة المالية المباشرة للشركة. |
| **Primary Conversion** | `whatsapp_confirmed` | [`booking/confirm/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/confirm/page.tsx#L48) (`confirm_whatsapp_booking`) | تأكيد الزائر لطلبه عبر رابط التحقق في واتساب، ليتحول من طلب مبدئي إلى طلب مؤكد للتنفيذ. |
| **Secondary Conversion** | `contact_whatsapp_click` | [`BottomCtaBanner.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/BottomCtaBanner.tsx#L46), [`Footer.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/Footer.tsx#L72), [`services/details/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/services/details/page.tsx#L687) | نقر العميل على زر التواصل عبر WhatsApp لطلب استفسار أو حجز خدمة. |
| **Secondary Conversion** | `sign_up` | [`register/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/register/page.tsx#L98) (`handleRegister`) | تسجيل مستخدم جديد وامتلاك بيانات الاتصال الخاصة به (Email & Phone). |
| **Secondary Conversion** | `login` | [`login/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/login/page.tsx#L56) (`handleLogin`) | نجاح جلسة تسجيل الدخول للعميل واستعادة نشاطه. |
| **Secondary Conversion** | `begin_checkout` | [`booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx#L860) عند الانتقال من Step 0 إلى Step 1 | إتمام حساب السعر والانتقال الفعلي لبدء عملية الحجز واختيار الموعد. |
| **Micro Conversion** | `calculate_price` | [`booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx#L557) (`handleCalculate`) | استدعاء دالة حساب السعر ومعرفة القيمة التقديرية للخدمة. |
| **Micro Conversion** | `view_item` | [`services/details/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/services/details/page.tsx#L88) | فتح صفحة تفاصيل خدمة معينة واستعراض مميزاتها وأسعارها. |
| **Micro Conversion** | `view_item_list` | [`services/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/services/page.tsx#L36) و [`ServicesSection.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/ServicesSection.tsx#L498) | استعراض قائمة أو شبكة الخدمات التابعة لفئة معينة. |
| **Micro Conversion** | `search_services` | [`ServicesSection.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/ServicesSection.tsx#L632) و [`services/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/services/page.tsx#L219) | قيام العميل بالبحث النصي عن خدمة محددة. |
| **Micro Conversion** | `add_to_wishlist` | [`services/details/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/services/details/page.tsx#L206) (`toggleFavorite`) | إضافة خدمة إلى قائمة المفضلة المحلية. |
| **Micro Conversion** | `checkout_step_view` | [`booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx#L860) | تتبع التقدم بين الخطوات الأربعة لمعالج الحجز (Funnel Tracking). |

---

## 7. Booking Success Analysis (تحليل التحقق الصارم لنجاح الحجز)

> [!IMPORTANT]
> **القاعدة الذهبية للتتبع المالي**: الضغط على زر "تأكيد الحجز" (`Button Click`) **ليس** دليلاً على نجاح الحجز مطلقاً، وقد يؤدي إطلاق الـ Pixel عنده إلى تسجيل مبيعات وهمية مكررة في حال حدوث خطأ في الاتصال أو التحقق.

### ما هو الشرط البرمجي الحقيقي الذي يعني "الحجز تم بنجاح"؟
يتحقق نجاح الحجز الفعلي عند استيفاء السلسلة التالية داخل الكود:
1. استجابة خادم Supabase لدالة `create_atomic_booking` بنجاح وعودة قيمة `bookingId` صالحة (UUID).
2. عدم إطلاق أي استثناء (`bookingError === null`).
3. قيام التطبيق بالتوجيه إلى مسار التتبع `/orders?bookingId=${bookingId}&success=true`.
4. قيام صفحة `/orders` باسترجاع تفاصيل الحجز عبر `get_guest_booking_details(bookingId)` وظهور حالة الطلب المسجلة (`status: "created"` أو أعلى).

### نقطة إطلاق حدث `Purchase`:
* **الموقع الأنسب هندسياً**:
  - إما داخل دالة `handleCompleteBooking` في [`booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx#L982) مباشرة بعد التحقق من `if (bookingId)` وقبل استدعاء `router.push`.
  - أو في صفحة [`orders/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/orders/page.tsx#L150) عندما يتحقق الشرط `if (isSuccess && bookingData)` مع وضع علامة فحص لمنع تكرار الإرسال عند عمل Refresh (`deduplicationKey: bookingId`).

---

## 8. Pricing & Value Tracking Analysis (تتبع مصدر السعر وقيمته الحقيقية)

يعتمد نظام Fresh Home على بنية تسعير ديناميكية محكمة خالية من الثغرات:
* **موقع حساب السعر**: يتم داخل الخادم عبر دالة Postgres:
  [`public.execute_pricing_pipeline(p_sub_service_id, v_price_config, p_pricing_inputs)`](file:///d:/fresh_home_workspace/supabase/migrations/83_payment_method_technician_collected.sql#L72).
* **هل السعر النهائي يأتي من الـ Backend؟**: **نعم 100%**. لا يستطيع المتصفح تعديل السعر لأن دالة `create_atomic_booking` تتجاهل أي أسعار مرسلة من المتصفح وتُعيد حساب السعر كلياً داخل قاعدة البيانات قبل عملية الإدراج.
* **أين يتم تخزين السعر النهائي؟**:
  - في جدول `public.bookings` داخل حقل `price_snapshot` من نوع `JSONB`.
  - الهيكل التخزيني للسعر:
    ```json
    {
      "basePrice": 850.00,
      "extraFees": 150.00,
      "discount": 0.00,
      "total": 1000.00,
      "metadata": {
        "pricing_version_id": "uuid-...",
        "formula_type": "unit_stepped_fixed"
      }
    }
    ```
* **متى يصبح السعر Final؟**:
  - يصبح السعر **نهائياً وموثقاً (Authoritative Final Price)** لحظة تنفيذ دالة `create_atomic_booking` وحفظه في `price_snapshot`.
* **الفرق بين Estimated Price و Final Price في المنصة**:
  1. **الحد الأدنى التقريبي (Starting Price)**: يُعرض في كروت الخدمات وصفحة التفاصيل كبداية (`تبدأ من 250 ج.م`) ويُستخلص من `services.price_config.min_price` أو `services.min_price`.
  2. **السعر المحسوب التفاعلي (Calculated Price)**: يتم بعد ملء حقول المساحة والغرف والإضافات عبر `calculate_booking_price` RPC.
  3. **السعر الفعلي النهائي (Final Booked Price)**: هو القيمة المعتمدة في `price_snapshot.total` الصادرة من `create_atomic_booking`.
* **النقطة الآمنة لإرسال معامل `value` في الـ Tracking**:
  - استخدام `priceDetails.total` المحسوبة بواسطة الخادم والموجودة في `price_snapshot.total`.
  - العملة الثابتة: `currency: "EGP"`.

---

## 9. Available Tracking Data (تحليل وتدقيق البيانات المتاحة لكل حدث)

يوضح الجدول التالي مدى توفر وموثوقية حقول البيانات لحظة وقوع كل حدث:

| الحقل (Data Field) | مصدره في الكود | اسم الكائن / المتغير | هل متاح لحظياً؟ | درجة الموثوقية | ملاحظات وتوصيات |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `service_id` | `active_services_tree` | `currentService.id` / `subServiceId` | ✅ متاح | موثوق 100% | معرف ثابت مثل `FH-S-100009`. |
| `service_name` | `active_services_tree` | `currentService.title.ar` | ✅ متاح | موثوق 100% | اسم الخدمة باللغة العربية. |
| `category_id` | `active_services_tree` | `currentService.parent_id` | ✅ متاح | موثوق 100% | معرف الفئة الرئيسية مثل `FH-S-100001`. |
| `category_name` | `active_services_tree` | `parentService.title.ar` | ✅ متاح | موثوق 100% | مثل "خدمات النظافة الشاملة". |
| `booking_id` | `create_atomic_booking` | `bookingId` / `readable_id` | ✅ متاح بعد الحجز | موثوق 100% | UUID ومعرف نصي مثل `FH-100293`. |
| `value` / `price` | `calculate_booking_price` | `priceDetails.total` | ✅ متاح بعد الحساب | موثوق 100% | محسوب من الخادم. |
| `currency` | كود التطبيق | `"EGP"` | ✅ متاح | ثابت | الجنيه المصري. |
| `scheduled_date` | State المعالج | `scheduledDate` | ✅ متاح | موثوق | بصيغة `YYYY-MM-DD`. |
| `scheduled_slot` | State المعالج | `scheduledTime` | ✅ متاح | موثوق | مثل `09:00 ص`. |
| `governorate` | State العنوان | `address.governorate` | ✅ متاح | موثوق | القاهرة / الجيزة. |
| `city` | State العنوان | `address.city` | ✅ متاح | موثوق | المدينة أو المنطقة. |
| `district` | State العنوان | `finalDistrict` | ✅ متاح | موثوق | الحي أو التجمع. |
| `payment_type` | State الدفع | `paymentMethod` | ✅ متاح | موثوق | `"cash"` |
| `user_type` | Supabase Auth | `isClientUserLoggedIn ? 'registered' : 'guest'` | ✅ متاح | موثوق 100% | تحديد صفة العميل. |
| `user_id` (Hashed) | Supabase Auth | `session.user.id` | ✅ متاح للمسجلين | موثوق 100% | لا يُرسل إلا بصيغة SHA-256 مشفرة. |

---

## 10. Proposed Tracking Events (قائمة الأحداث الموصى بها)

### 1. `view_service_list` (استعراض قائمة خدمات)
* **المشغل (Trigger)**: دخول صفحة `/services` أو وصول المستخدم لقسم الخدمات في الصفحة الرئيسية.
* **الأهمية**: قياس حجم الاهتمام بتصنيفات الخدمات.

### 2. `view_service_details` / `view_item` (عرض تفاصيل خدمة)
* **المشغل (Trigger)**: فتح صفحة تفاصيل الخدمة `/services/details`.
* **المعاملات الأساسية**: `item_id`, `item_name`, `item_category`, `price_starting_from`.

### 3. `calculate_price` (حساب تكلفة الخدمة)
* **المشغل (Trigger)**: الضغط على زر "احسب التكلفة الدقيقة" في معالج الحجز ونجاح الحساب.
* **المعاملات الأساسية**: `service_id`, `service_name`, `calculated_value`, `inputs_summary`.

### 4. `begin_checkout` (بدء تدفق الحجز)
* **المشغل (Trigger)**: الضغط على "متابعة لاختيار الموعد" بعد حساب السعر والانتقال للخطوة 1.
* **المعاملات الأساسية**: `service_id`, `service_name`, `value`, `currency`.

### 5. `checkout_progress` (متابعة خطوات الحجز)
* **المشغل (Trigger)**: إكمال كل خطوة من خطوات الحجز (الموعد ⬅️ العنوان ⬅️ المراجعة).
* **المعاملات الأساسية**: `checkout_step: 1|2|3|4`, `step_name`.

### 6. `purchase` (إتمام الحجز بنجاح)
* **المشغل (Trigger)**: استلام استجابة نجاح من `create_atomic_booking` وصدور المعرف `booking_id`.
* **المعاملات الأساسية**: `transaction_id`, `value`, `currency`, `items`, `service_id`, `service_name`, `governorate`, `city`, `customer_type`.

### 7. `whatsapp_lead_click` (النقر على زر التواصل عبر واتساب)
* **المشغل (Trigger)**: النقر على أي رابط أو زر يفتح واتساب.
* **المعاملات الأساسية**: `placement` (hero, banner, service_details, footer), `service_name_context`.

### 8. `sign_up` & `login` (إنشاء الحساب وتسجيل الدخول)
* **المشغل (Trigger)**: نجاح استدعاء `supabase.auth.signUp` أو `supabase.auth.signInWith...`.
* **المعاملات الأساسية**: `method` (email_password, google_oauth).

---

## 11. Proposed Data Layer Schema Architecture (تصميم هيكل Data Layer المقترح)

تم تصميم الهيكل ليتوافق مع معايير **Google Analytics 4 (GA4) E-commerce** ومواصفات **Meta Pixel Standard Events**:

```typescript
// =========================================================================
// 1. Data Layer Event: view_item
// =========================================================================
window.dataLayer.push({
  event: "view_item",
  ecommerce: {
    currency: "EGP",
    value: 250.00, // Starting price
    items: [
      {
        item_id: "FH-S-100009",
        item_name: "تنظيف بعد التشطيب",
        item_category: "خدمات النظافة الشاملة",
        price: 250.00,
        quantity: 1
      }
    ]
  }
});

// =========================================================================
// 2. Data Layer Event: calculate_price (Custom Business Event)
// =========================================================================
window.dataLayer.push({
  event: "calculate_price",
  service_data: {
    service_id: "FH-S-100009",
    service_name: "تنظيف بعد التشطيب",
    calculated_total: 1000.00,
    base_price: 850.00,
    extra_fees: 150.00,
    currency: "EGP",
    area_sqm: 120,
    rooms_count: 3
  }
});

// =========================================================================
// 3. Data Layer Event: begin_checkout
// =========================================================================
window.dataLayer.push({
  event: "begin_checkout",
  ecommerce: {
    currency: "EGP",
    value: 1000.00,
    items: [
      {
        item_id: "FH-S-100009",
        item_name: "تنظيف بعد التشطيب",
        item_category: "خدمات النظافة الشاملة",
        price: 1000.00,
        quantity: 1
      }
    ]
  }
});

// =========================================================================
// 4. Data Layer Event: purchase (Final Verified Booking)
// =========================================================================
window.dataLayer.push({
  event: "purchase",
  ecommerce: {
    transaction_id: "FH-100293", // readable_id or UUID
    value: 1000.00,
    currency: "EGP",
    tax: 0,
    shipping: 0,
    items: [
      {
        item_id: "FH-S-100009",
        item_name: "تنظيف بعد التشطيب",
        item_category: "خدمات النظافة الشاملة",
        price: 1000.00,
        quantity: 1
      }
    ]
  },
  booking_meta: {
    scheduled_date: "2026-09-02",
    scheduled_slot: "09:00:00",
    governorate: "القاهرة",
    city: "التجمع الخامس",
    district: "الحي الأول",
    payment_type: "cash",
    user_status: "guest" // or "registered"
  }
});

// =========================================================================
// 5. Data Layer Event: contact_whatsapp (Lead)
// =========================================================================
window.dataLayer.push({
  event: "contact_whatsapp",
  lead_details: {
    placement: "bottom_banner", // hero | footer | service_details | mobile_sticky
    service_context: "تنظيف بعد التشطيب"
  }
});
```

---

## 12. Meta Pixel & GA4 Integration Requirements

### أ. تغطية Meta Pixel (Facebook Ads)
* **الأحداث القياسية (Standard Events)**:
  - `fbq('track', 'PageView')` ⬅️ لجميع الصفحات.
  - `fbq('track', 'ViewContent', { content_name, content_category, content_ids, value, currency })` ⬅️ في صفحة تفاصيل الخدمة.
  - `fbq('track', 'InitiateCheckout', { content_ids, num_items: 1, value, currency })` ⬅️ عند بدء الحجز بعد حساب السعر.
  - `fbq('track', 'Purchase', { content_type: 'product', content_ids, value, currency, order_id })` ⬅️ عند نجاح الحجز.
  - `fbq('track', 'Lead', { content_name: 'WhatsApp Contact', content_category: placement })` ⬅️ عند النقر على واتساب.
  - `fbq('track', 'CompleteRegistration', { status: 'success' })` ⬅️ عند إنشاء حساب جديد.
* **جاهزية Conversions API (CAPI)**:
  - يمكن دعمها لاحقاً باستخدام `event_id` متطابق (مثل `booking_id`) لعمل Deduplication بين المتصفح والخادم.

### ب. تغطية Google Analytics 4 (GA4)
* **الأحداث القياسية والتجارة الإلكترونية**:
  - `page_view`
  - `view_item_list`
  - `view_item`
  - `begin_checkout`
  - `purchase`
  - `sign_up`
  - `login`
  - `generate_lead` (محادثات واتساب)
* **الأبعاد المخصصة المقترحة (Custom Dimensions)**:
  - `service_id` (معرف الخدمة)
  - `governorate` (المحافظة)
  - `city` (المدينة / المنطقة)
  - `booking_slot` (فترة الحجز)
  - `user_type` (زائر / مسجل)
  - `whatsapp_confirmed` (نعم / لا)

---

## 13. Privacy & Data Safety (حماية البيانات والخصوصية)

> [!CAUTION]
> **حظر البيانات الشخصية الصريح (PII Restrictions)**:
> تمنع سياسات Google Analytics و Meta بشكل قاطع إرسال أي بيانات تعريف شخصية واضحة (Personally Identifiable Information).

### 1. بيانات يُمنع إرسالها نهائياً بصيغة خام (Strictly Forbidden PII):
* ❌ رقم الهاتف المحمول (`phone` مثل `01012345678`).
* ❌ الاسم الصريح للعميل (`contact_name` / `firstName` / `lastName`).
* ❌ البريد الإلكتروني غير المشفر (`email`).
* ❌ العنوان التفصيلي الدقيق (رقم العمارة، رقم الشقة، الشارع الخاص).
* ❌ الروابط الجغرافية الدقيقة (`location_url`).

### 2. بيانات مسموح وموصى بإرسالها (Allowed Analytics Parameters):
* ✅ معرفات الخدمات والأقسام (`service_id`, `category_id`).
* ✅ أسماء الخدمات والأقسام العامة باللغة العربية.
* ✅ قيم الأسعار الإجمالية والعملة (`value: 1000`, `currency: 'EGP'`).
* ✅ معرف الحجز الفرعي (`transaction_id: FH-100293`).
* ✅ المحافظة والمدينة العامة (`governorate: 'القاهرة'`, `city: 'التجمع الخامس'`).
* ✅ تواريخ وأوقات الفترات المحجوزة (`2026-09-02`, `09:00 ص`).
* ✅ نوع المستخدم (`registered` / `guest`).
* ✅ طريقة الدفع (`cash`).
* ✅ التجزئة المشفرة (SHA-256 Hashed Email / Phone) في حال تفعيل الـ **Advanced Matching** لـ Meta Pixel بموافقة العميل.

---

## 14. Codebase Architecture & Feature Mapping

خريطة الربط الهندسي بين ميزات المنصة ومكوناتها البرمجية:

```
apps/customer_web/src/
├── app/
│   ├── layout.tsx                # [Root] GoogleTagManager Component (GTM-NZN39DFK)
│   ├── page.tsx                  # [Homepage] Schema.org JSON-LD & Page Assembler
│   ├── booking/
│   │   ├── page.tsx              # [Core Booking Flow] 4 Steps, Dynamic Pricing RPC, Atomic Booking
│   │   └── confirm/page.tsx      # [WhatsApp Verification] confirm_whatsapp_booking RPC
│   ├── services/
│   │   ├── page.tsx              # [Category View] active_services_tree & reviews
│   │   └── details/page.tsx      # [Service Leaf/Branch] Full details, Inclusions, Reviews, CTAs
│   ├── orders/
│   │   └── page.tsx              # [Order Tracking & Dashboard] get_guest_booking_details RPC & Realtime Channel
│   ├── login/page.tsx            # [Auth] Password & Google OAuth signIn
│   ├── register/page.tsx         # [Auth] User registration & user_phones binding
│   └── profile/page.tsx          # [Profile] Address V2, Phones, Account management
├── components/
│   ├── Header.tsx                # Dynamic Auth State, Session listener, Orders modal
│   ├── Hero.tsx                  # Primary CTA buttons (/booking, #services)
│   ├── ServicesSection.tsx       # Live search, Root tabs, Auto-scroll CategorySlider
│   ├── PostConstructionBanner.tsx# Before/After highlight & Calculator link
│   ├── PricingTeaser.tsx         # Transparent pricing progress teaser
│   ├── BottomCtaBanner.tsx       # Final Book Now & WhatsApp trigger
│   └── Footer.tsx                # Deep links, Social media, Customer support WhatsApp
└── lib/
    ├── supabase.ts               # Supabase Client Instance (createClient)
    ├── geo.ts                    # Hierarchical Geo Data (Cairo & Giza Governorates/Cities/Districts)
    └── whatsapp.ts               # formatWhatsAppNumber, buildWhatsAppUrl, useWhatsAppSettings Hook
```

---

## 15. Identified Tracking Gaps & Architectural Bottlenecks (اكتشاف الثغرات والتحديات التقنية)

خلال فحص الـ Codebase، تم رصد النقاط الهندسية التالية التي يجب مراعاتها عند تصميم وتنفيذ طبقة التتبع:

1. **طبيعة تطبيق Next.js App Router (Single Page Application Transitions)**:
   - التنقل بين الصفحات يتم من جانب العميل (`Client-Side Navigation` عبر `next/link` و `router.push`).
   - *التحدي*: قد لا يتم إطلاق `page_view` التقليدي في أدوات التتبع عند تغير المسار بدون تتبع مسارات الـ History في GTM.
2. **تأخير حساب السعر النهائي (Pricing Asynchronicity)**:
   - في خطوة الحجز الأولى، السعر النهائي لا يكون متاحاً فور فتح الصفحة، بل يتم جلبه بعد ضغط العميل على "احسب التكلفة" أو عند استدعاء الخادم.
   - *التحدي*: حدث `begin_checkout` يجب ألا يُطلق إلا **بعد** نجاح دالة `calculate_booking_price` وتوفر قيمة `priceDetails.total`.
3. **احتمالية تكرار إرسال الـ Purchase عند تحديث صفحة التتبع (Page Refresh Duplication)**:
   - صفحة `/orders?bookingId=...&success=true` تستقبل معامل `success=true`. إذا قام العميل بعمل Refresh للصفحة، قد يتم إطلاق حدث الشراء مرة أخرى.
   - *الحل المطلوب*: استخدام آلية كبح وتخزين محلي (Deduplication Flag في `sessionStorage` أو عبر فحص `booking_id`).
4. **حالة الحجز للزوار (Guest Verification Gap)**:
   - حجز الزائر يُنشأ بحالة `is_whatsapp_confirmed: false`.
   - *التحدي*: هل يُعتبر الحجز مكتملاً لحظة الإنشاء في الويب أم لحظة التأكيد عبر واتساب؟
   - *التوصية*: إرسال حدث `purchase` المالي عند الإنشاء في الويب مع وسم `status: pending_confirmation`، وإرسال حدث إضافي `whatsapp_verified` في صفحة [`confirm/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/confirm/page.tsx) عند التأكيد الفعلي.
5. **أزرار واتساب المتعددة (Multiple WhatsApp Touchpoints)**:
   - هناك أزرار واتساب في الهيدر، الفوتر، تفاصيل الخدمة، البانر السفلي، وصفحة تتبع الحجز.
   - *التحدي*: تفريق مصادر المحادثات بدقة.
   - *الحل المطلوب*: تضمين معلمة `placement` في كل حدث لتحديد المكون الأكثر جذباً للعملاء.

---

## 16. Recommended Event Priority Matrix (مصفوفة أولوية أحداث التتبع)

| الحدث (Event) | المشغل الدقيق (Trigger) | الصفحة / المكون | البيانات الأساسية (Payload) | الأولوية (Priority) | Meta Pixel | GA4 |
| :--- | :--- | :--- | :--- | :---: | :---: | :---: |
| **`purchase`** | استجابة `create_atomic_booking` بنجاح وعودة `booking_id` | [`booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx) | `transaction_id`, `value`, `currency`, `items`, `service_id` | **P0 (Critical)** | ✅ `Purchase` | ✅ `purchase` |
| **`begin_checkout`** | الضغط على زر المتابعة بعد حساب السعر الإجمالي | [`booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx) | `service_id`, `service_name`, `value`, `currency` | **P0 (Critical)** | ✅ `InitiateCheckout` | ✅ `begin_checkout` |
| **`view_item`** | فتح صفحة تفاصيل الخدمة وتحميل بياناتها | [`services/details/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/services/details/page.tsx) | `item_id`, `item_name`, `item_category`, `price` | **P0 (Critical)** | ✅ `ViewContent` | ✅ `view_item` |
| **`contact_whatsapp`** | النقر على أي زر محادثة واتساب | [`BottomCtaBanner.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/BottomCtaBanner.tsx), [`Footer.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/Footer.tsx), إلخ | `placement`, `service_context` | **P1 (High)** | ✅ `Lead` | ✅ `generate_lead` |
| **`calculate_price`** | نجاح استجابة دالة `calculate_booking_price` | [`booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx) | `service_id`, `calculated_value`, `area`, `rooms` | **P1 (High)** | ✅ Custom Event | ✅ Custom Event |
| **`sign_up`** | نجاح عملية التسجيل وإنشاء الحساب | [`register/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/register/page.tsx) | `method: email` | **P1 (High)** | ✅ `CompleteRegistration` | ✅ `sign_up` |
| **`login`** | نجاح جلسة تسجيل الدخول | [`login/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/login/page.tsx) | `method: password | google` | **P2 (Medium)** | ❌ | ✅ `login` |
| **`checkout_step_view`** | الانتقال بين خطوات الحجز (1، 2، 3، 4) | [`booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx) | `step_number`, `step_title` | **P2 (Medium)** | ❌ | ✅ `checkout_progress` |
| **`view_item_list`** | استعراض فئة الخدمات أو قسم الخدمات | [`services/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/services/page.tsx) | `item_list_id`, `item_list_name` | **P2 (Medium)** | ❌ | ✅ `view_item_list` |
| **`search`** | كتابة استعلام بحث في شريط البحث | [`ServicesSection.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/ServicesSection.tsx) | `search_term` | **P3 (Low)** | ❌ | ✅ `search` |
| **`add_to_wishlist`** | الضغط على زر إضافة للمفضلة | [`services/details/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/services/details/page.tsx) | `item_id`, `item_name` | **P3 (Low)** | ✅ `AddToWishlist` | ✅ `add_to_wishlist` |

---

## 17. Final Customer Journey Map (خريطة رحلة العميل الفعلية في Fresh Home)

توضح الخريطة التالية المسار الحقيقي المتكامل المطبق برمجياً في المنصة:

```
                     ┌──────────────────────────────────────────────┐
                     │            الصفحة الرئيسية (Homepage)        │
                     │                      /                       │
                     └──────────────────────┬───────────────────────┘
                                            │
               ┌────────────────────────────┴────────────────────────────┐
               │                                                         │
               ▼                                                         ▼
┌──────────────────────────────┐                         ┌──────────────────────────────┐
│  دليل الخدمات والأقسام       │                         │ زر الحجز المباشر             │
│  /services                   │                         │ /booking                     │
└──────────────┬───────────────┘                         └──────────────┬───────────────┘
               │                                                         │
               ▼                                                         │
┌──────────────────────────────┐                                         │
│ تفاصيل الخدمة والمميزات      │                                         │
│ /services/details            │                                         │
└──────────────┬───────────────┘                                         │
               │ (احجز الخدمة الآن)                                      │
               └────────────────────────────┬────────────────────────────┘
                                            │
                                            ▼
                     ┌──────────────────────────────────────────────┐
                     │           معالج الحجز: الخطوة 1               │
                     │     تحديد المواصفات وحساب السعر بدقة          │
                     │          RPC: calculate_booking_price        │
                     └──────────────────────┬───────────────────────┘
                                            │ (متابعة)
                                            ▼
                     ┌──────────────────────────────────────────────┐
                     │           معالج الحجز: الخطوة 2               │
                     │         تحديد اليوم والفترة الزمنية          │
                     │           RPC: get_available_days            │
                     └──────────────────────┬───────────────────────┘
                                            │ (متابعة)
                                            ▼
                     ┌──────────────────────────────────────────────┐
                     │           معالج الحجز: الخطوة 3               │
                     │  تحديد العنوان (المحافظة، المدينة، الشارع...) │
                     │       Address V2 / Saved Addresses           │
                     └──────────────────────┬───────────────────────┘
                                            │ (متابعة)
                                            ▼
                     ┌──────────────────────────────────────────────┐
                     │           معالج الحجز: الخطوة 4               │
                     │  مراجعة ملخص الطلب + إدخال الاسم ورقم الهاتف  │
                     └──────────────────────┬───────────────────────┘
                                            │ (تأكيد الحجز النهائي)
                                            ▼
                     ┌──────────────────────────────────────────────┐
                     │           تنفيذ عملية الحجز في الخادم         │
                     │          RPC: create_atomic_booking          │
                     │       تسجيل الحجز + تعيين الفني آلياً        │
                     └──────────────────────┬───────────────────────┘
                                            │ (التحويل التلقائي)
                                            ▼
                     ┌──────────────────────────────────────────────┐
                     │          صفحة نجاح الحجز وتتبع الطلب         │
                     │     /orders?bookingId=...&success=true       │
                     │         RPC: get_guest_booking_details       │
                     │             ⚡ إطلاق حدث Purchase             │
                     └──────────────────────────────────────────────┘
```

---

## 18. Implementation Recommendations (توصيات المرحلة القادمة)

عند البدء في مرحلة بناء وتطبيق الـ Data Layer وربط الأحداث مع GTM في الخطوة التالية، نوصي باتباع الممارسات الهندسية التالية:

1. **إنشاء طبقة مساعدة مركزية (`Analytics Helper Singleton`)**:
   - بناء ملف مساعد مثل `src/lib/analytics.ts` يحتوي على دوال Typed آمنة (مثل `trackViewItem`, `trackBeginCheckout`, `trackPurchase`, `trackWhatsAppClick`) للتأكد من دفع البيانات للـ `window.dataLayer` بصيغة متسقة وخالية من الأخطاء الإملائية.
2. **منع تكرار المبيعات (`Purchase Deduplication`)**:
   - استخدام `transaction_id` فريد في كل حدث Purchase والتحقق من عدم إطلاقه مرتين لنفس المعرف في نفس الجلسة.
3. **تتبع المحادثات مع السياق الكامل (`Contextual Lead Tracking`)**:
   - تمرير اسم الخدمة وموقع الزر (`placement`) مع كل نقرة على روابط الواتساب لتحديد الحملات الإعلانية والصفحات الأكثر توليداً للعملاء.
4. **تفعيل Google Tag Manager Custom Events Triggers**:
   - ضبط مشغلات GTM لتستمع لأحداث `Custom Event` القادمة من الـ Data Layer، وربطها بـ **Meta Pixel Tags** و **GA4 Event Tags**.
5. **الالتزام الصارم بـ Zero PII**:
   - التأكد من عدم تسريب رقم الهاتف أو العنوان التفصيلي في أي مصفوفة أحداث متجهة إلى Google أو Meta.
