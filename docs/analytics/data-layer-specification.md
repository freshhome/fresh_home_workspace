# Fresh Home — Data Layer Specification & Event Contract
**وثيقة المواصفات الفنية الرسمية لطبقة البيانات وعقود أحداث التتبع (Data Layer & Tracking Contract)**

* **الإصدار (Version)**: `1.1.0-Refined`
* **المشروع (Project)**: Fresh Home — Customer Web App (`apps/customer_web`)
* **الحالة (Status)**: معتمد للمواصفة الفنية (Approved Specification)
* **تاريخ التحديث (Date)**: 2026-08-30

---

## 1. مسار التحويل التجاري المعتمد (Official Business Funnel)

تم تثبيت المسار التجاري والسلوكي الرسمي لـ Fresh Home كالتالي:

```
                  ┌──────────────────────────────────────────────┐
                  │              view_service_list               │
                  │        (استعراض قائمة وتصنيفات الخدمات)      │
                  └──────────────────────┬───────────────────────┘
                                         │
                                         ▼
                  ┌──────────────────────────────────────────────┐
                  │                  view_item                   │
                  │          (عرض تفاصيل خدمة محددة)             │
                  └──────────────────────┬───────────────────────┘
                                         │
                                         ▼
                  ┌──────────────────────────────────────────────┐
                  │               calculate_price                │
                  │         (حساب السعر الدقيق من الخادم)        │
                  └──────────────────────┬───────────────────────┘
                                         │
                                         ▼
                  ┌──────────────────────────────────────────────┐
                  │                begin_checkout                │
                  │          (بدء معالج الحجز واختيار الموعد)    │
                  └──────────────────────┬───────────────────────┘
                                         │
                                         ▼
                  ┌──────────────────────────────────────────────┐
                  │              checkout_progress               │
                  │           (التقدم في خطوات الحجز)            │
                  └──────────────────────┬───────────────────────┘
                                         │
                                         ▼
                  ┌──────────────────────────────────────────────┐
                  │                   purchase                   │
                  │ (Primary Booking Conversion / نجاح إنشاء الطلب)│
                  └──────────────────────┬───────────────────────┘
                                         │
                                         ▼ (للضيوف عند الحاجة)
                  ┌──────────────────────────────────────────────┐
                  │              whatsapp_confirmed              │
                  │         (تأكيد الحجز لاحقاً عبر واتساب)      │
                  └──────────────────────────────────────────────┘
```

---

## 2. مبادئ التصميم والقرارات الهندسية والتجارية (Core Architectural Decisions)

### أ. تعريف تحويل الحجز الأساسي (`Primary Booking Conversion`)
1. **طبيعة حدث `purchase`**:
   - يُعرّف حدث `purchase` في Fresh Home بأنه **"Primary Booking Conversion / Successful Booking Creation"** (نجاح تسجيل الحجز الفعلي في النظام وتخصيص الفني المتاح)، وليس بالضرورة تحصيلاً نقدياً لحظياً لأن طريقة الدفع المعتمدة هي الدفع عند الاستلام/بعد التنفيذ (`cash`).
   - يحدث هذا التحويل حصراً وفورياً عند نجاح عملية إنشاء الحجز في الخادم عبر استدعاء:
     `supabase.rpc("create_atomic_booking", { ... })`
   - استلام معرّف الحجز (`booking_id` / `readable_id`) بنجاح يُعد دليلاً قاطعاً على اعتماد الحجز تشغيلياً وتسويقياً.
   - **لا يتم انتظار تأكيد الواتساب لإطلاق حدث `purchase`**.

2. **تأكيد الواتساب اللاحق للزوار (`whatsapp_confirmed`)**:
   - عند قيام الزائر بالضغط على رابط التأكيد في رسالة واتساب ونجاح دالة `confirm_whatsapp_booking`، يُطلق حدث منفصل تماماً باسم `whatsapp_confirmed`.
   - **الهدف التجاري من تأكيد الواتساب**: حماية تشغيلية وفلترة للحجوزات الوهمية (Anti-Spam / Quality Gate)، وليس تعريفاً لنقطة التحويل التسويقي الأولى.

---

### ب. قواعد الثبات والموثوقية والتسعير (Authoritative Data & Pricing Rules)
1. **قاعدة الإطلاق الفردي (`Single-Fire Rule`)**:
   - يُطلق حدث `purchase` **مرة واحدة فقط لا غير** لكل حجز (`Exactly ONCE per Booking`).
   - يُمنع إطلاق الحدث مجدداً عند قيام العميل بتحديث صفحة التتبع (`/orders?bookingId=...&success=true`) أو العودة إليها لاحقاً، وذلك باستخدام مفتاح كبح وتخزين محلي (`sessionStorage`).
2. **المعرفات المعتمدة (Authoritative Unique Identifiers)**:
   - `booking_id` (UUID): هو المعرف الفريد المطلق المعتمد للحجز، ويُستخدم حصراً كـ **Meta `event_id`** لضمان تطابق الـ Deduplication المستقبلي مع Meta Conversions API (CAPI).
   - `readable_id` (مثل `FH-100293`): هو المعرف التسلسلي الثابت والفريد المخصص لـ **GA4 `transaction_id`** لسهولة مراجعته وتتبعه محاسبياً.
3. **مصدر القيمة المالية (`purchase.value`)**:
   - القيمة المالية الإجمالية في حدث `purchase` تأتي **فقط وحصراً من لقطة السعر المعتمدة من الخادم** (`price_snapshot.total` / `priceDetails.total`).
   - يُحظر تماماً إعادة حساب أو تعديل السعر داخل GTM أو عبر أكواد JavaScript في المتصفح.
4. **منطق حالة تأكيد الواتساب (`is_whatsapp_confirmed`)**:
   - تعكس قيمة `is_whatsapp_confirmed` الحالة البرمجية الحقيقية المسترجعة من الـ Backend للحجز، ولا يتم افتراض قيمتها مسبقاً.

---

### ج. سياسة الخصوصية وحظر البيانات التعريفية (Strict Zero-PII Policy)
يُحظر وضع أي بيانات شخصية (Personally Identifiable Information) في الـ Data Layer الموجهة للتحليلات:
* ❌ **ممنوع نهائياً**: رقم الهاتف (`phone`)، الاسم الصريح (`name`)، البريد الإلكتروني (`email`)، العنوان التفصيلي الدقيق (الشارع، رقم المبنى، رقم الشقة)، ورابط خرائط جوجل (`location_url`).
* ✅ **مسموح ومشجع**: المعرفات العامة، أسماء الخدمات، المحافظة العامة (`governorate`)، المدينة (`city`)، الحي العام (`district`)، نوع المستخدم (`registered` / `guest`)، وطريقة الدفع (`cash`).
* ℹ️ **الاستعداد المستقبلي لـ Meta Advanced Matching / CAPI**: سيتم إدارته عبر الخادم مستقبلاً ولا يتم عمل أي Hashing محلي لبيانات PII في هذه المرحلة.

---

## 3. عقود الأحداث التفصيلية (Data Layer Event Contracts)

---

### 1. `view_service_list` (استعراض قائمة وتصنيفات الخدمات)
* **نوع الحدث**: `Micro Conversion`
* **المشغل الدقيق (Exact Trigger)**: عند تحميل صفحة دليل الخدمات `/services` أو وصول المستخدم لقسم شبكة الخدمات في الصفحة الرئيسية.
* **المصدر في الكود**: [`ServicesListContent`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/services/page.tsx#L23) في `services/page.tsx` و [`ServicesSection`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/ServicesSection.tsx#L491).
* **الحقول المطلوبة (Required Parameters)**:
  - `event` (string): `"view_service_list"`
  - `item_list_id` (string): معرّف القسم أو الفئة (مثل `"FH-S-100001"`).
  - `item_list_name` (string): اسم القسم (مثل `"خدمات النظافة الشاملة"`).
* **الحقول الاختيارية (Optional Parameters)**:
  - `items_count` (number): إجمالي عدد الخدمات المعروضة.
* **الربط (Mapping)**:
  - **GA4**: `view_item_list`
  - **Meta Pixel**: `Custom Event` (اختياري).

#### Example Payload:
```javascript
window.dataLayer.push({
  event: "view_service_list",
  event_id: "evt_list_" + Date.now(),
  ecommerce: {
    item_list_id: "FH-S-100001",
    item_list_name: "خدمات النظافة الشاملة",
    items_count: 5
  }
});
```

---

### 2. `view_item` (عرض تفاصيل خدمة محددة)
* **نوع الحدث**: `Micro Conversion`
* **المشغل الدقيق (Exact Trigger)**: عند اكتمال جلب وعرض تفاصيل خدمة قابلة للحجز (`is_bookable: true`) في صفحة `/services/details`.
* **المصدر في الكود**: [`ServiceDetailsContent`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/services/details/page.tsx#L73) بعد التحقق من `currentService && !loading`.
* **الحقول المطلوبة (Required Parameters)**:
  - `event` (string): `"view_item"`
  - `ecommerce.currency` (string): `"EGP"`
  - `ecommerce.value` (number): الحد الأدنى للسعر التقديري (`startingPrice`).
  - `ecommerce.items` (array of objects):
    - `item_id` (string): معرّف الخدمة (مثل `"FH-S-100009"`).
    - `item_name` (string): اسم الخدمة بالعربية (مثل `"تنظيف بعد التشطيب"`).
    - `item_category` (string): اسم الفئة الرئيسية (مثل `"خدمات النظافة الشاملة"`).
    - `item_category_id` (string): معرّف الفئة الرئيسية (مثل `"FH-S-100001"`).
    - `price` (number): السعر الابتدائي.
* **الحقول الاختيارية (Optional Parameters)**:
  - `price_type` (string): نوع التسعير (`"fixed"`, `"per_square_meter"`, `"inspection"`).
  - `status` (string): حالة توفر الخدمة (`"active"` أو `"paused"`).
* **الربط (Mapping)**:
  - **GA4**: `view_item`
  - **Meta Pixel**: `fbq('track', 'ViewContent', { content_ids: [item_id], content_name: item_name, content_category: item_category, value: price, currency: 'EGP' })`

#### Example Payload:
```javascript
window.dataLayer.push({
  event: "view_item",
  event_id: "evt_view_" + "FH-S-100009" + "_" + Date.now(),
  ecommerce: {
    currency: "EGP",
    value: 250.00,
    items: [
      {
        item_id: "FH-S-100009",
        item_name: "تنظيف بعد التشطيب",
        item_category: "خدمات النظافة الشاملة",
        item_category_id: "FH-S-100001",
        price: 250.00,
        quantity: 1
      }
    ]
  },
  service_meta: {
    price_type: "per_square_meter",
    status: "active"
  }
});
```

---

### 3. `calculate_price` (حساب التكلفة الدقيقة للخدمة)
* **نوع الحدث**: `Micro Conversion` (مؤشر قوي على نية الشراء العالية)
* **المشغل الدقيق (Exact Trigger)**: عند استجابة دالة الخادم `calculate_booking_price` بنجاح وعودة كائن السعر `data.total > 0`.
* **المصدر في الكود**: دالة [`handleCalculate`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx#L557) في `booking/page.tsx`.
* **الحقول المطلوبة (Required Parameters)**:
  - `event` (string): `"calculate_price"`
  - `service_id` (string): معرّف الخدمة.
  - `service_name` (string): اسم الخدمة.
  - `calculated_total` (number): السعر الإجمالي المحسوب من الخادم.
  - `base_price` (number): السعر الأساسي.
  - `currency` (string): `"EGP"`
* **الحقول الاختيارية (Internal Analytics Data - تُوجّه إلى GA4 فقط عبر GTM)**:
  - `area_sqm` (number | null): المساحة إن وجدت.
  - `rooms_count` (number | null): عدد الغرف.
  - `bathrooms_count` (number | null): عدد الحمامات.
  - `ac_units_count` (number | null): عدد أجهزة التكييف.
  - `addons_count` (number): عدد الإضافات المختارة.
  - `extra_fees` (number): الرسوم الإضافية.
  - `discount` (number): قيمة الخصم.
* **الربط (Mapping)**:
  - **GA4**: حدث مخصص `calculate_price` مع معلمات الخدمة والسعر.
  - **Meta Pixel**: لا يُرسل إلى Meta (أو Custom Event لجمهور النوايا العالية فقط).

#### Example Payload:
```javascript
window.dataLayer.push({
  event: "calculate_price",
  event_id: "evt_calc_" + "FH-S-100009" + "_" + Date.now(),
  service_id: "FH-S-100009",
  service_name: "تنظيف بعد التشطيب",
  calculated_total: 1000.00,
  base_price: 850.00,
  extra_fees: 150.00,
  discount: 0.00,
  currency: "EGP",
  pricing_inputs_summary: {
    area_sqm: 120,
    rooms_count: 3,
    bathrooms_count: 2,
    has_balcony: true,
    addons_selected_count: 1
  }
});
```

---

### 4. `begin_checkout` (بدء تدفق الحجز واختيار الموعد)
* **نوع الحدث**: `Secondary Conversion`
* **المشغل الدقيق (Exact Trigger)**: عند ضغط العميل على "متابعة لاختيار الموعد" والانتقال من الخطوة 0 إلى الخطوة 1 في معالج الحجز بعد التأكد من حساب السعر بنجاح.
* **المصدر في الكود**: دالة [`handleNext`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx#L860) في `booking/page.tsx` عندما تكون `currentStep === 0`.
* **الحقول المطلوبة (Required Parameters)**:
  - `event` (string): `"begin_checkout"`
  - `ecommerce.currency` (string): `"EGP"`
  - `ecommerce.value` (number): القيمة المحسوبة للحجز (`priceDetails.total`).
  - `ecommerce.items` (array of objects):
    - `item_id` (string): معرّف الخدمة.
    - `item_name` (string): اسم الخدمة.
    - `price` (number): القيمة المحسوبة.
    - `quantity` (number): `1`
* **الربط (Mapping)**:
  - **GA4**: `begin_checkout`
  - **Meta Pixel**: `fbq('track', 'InitiateCheckout', { content_ids: [item_id], content_name: item_name, value: value, currency: 'EGP', num_items: 1 })`

#### Example Payload:
```javascript
window.dataLayer.push({
  event: "begin_checkout",
  event_id: "evt_chk_" + "FH-S-100009" + "_" + Date.now(),
  ecommerce: {
    currency: "EGP",
    value: 1000.00,
    items: [
      {
        item_id: "FH-S-100009",
        item_name: "تنظيف بعد التشطيب",
        price: 1000.00,
        quantity: 1
      }
    ]
  }
});
```

---

### 5. `checkout_progress` (تتبع مراحل معالج الحجز)
* **نوع الحدث**: `Micro Conversion` (Funnel Step Analytics)
* **المشغل الدقيق (Exact Trigger)**: عند نجاح التحقق والانتقال بين خطوات الحجز (الخطوة 2: الموعد، الخطوة 3: العنوان، الخطوة 4: المراجعة).
* **المصدر في الكود**: دالة [`handleNext`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx#L860) في `booking/page.tsx`.
* **الحقول المطلوبة (Required Parameters)**:
  - `event` (string): `"checkout_progress"`
  - `checkout_step` (number): رقم الخطوة (`1` = حساب السعر، `2` = الموعد، `3` = العنوان، `4` = المراجعة).
  - `step_name` (string): اسم الخطوة (`"price_calculation"`, `"schedule_selection"`, `"address_entry"`, `"order_review"`).
  - `service_id` (string): معرّف الخدمة.
* **الحقول الاختيارية (Optional Parameters)**:
  - `scheduled_day` (string | null): اليوم المختار عند إكمال خطوة الموعد.
  - `governorate` (string | null): المحافظة عند إكمال خطوة العنوان.
  - `city` (string | null): المدينة عند إكمال خطوة العنوان.
* **الربط (Mapping)**:
  - **GA4**: `checkout_progress`
  - **Meta Pixel**: لا يُرسل إلى Meta.

#### Example Payload:
```javascript
window.dataLayer.push({
  event: "checkout_progress",
  event_id: "evt_step_" + "3" + "_" + Date.now(),
  checkout_step: 3,
  step_name: "address_entry",
  service_id: "FH-S-100009",
  step_data: {
    governorate: "القاهرة",
    city: "التجمع الخامس"
  }
});
```

---

### 6. `purchase` (Primary Booking Conversion / نجاح تسجيل الحجز الفعلي)
* **نوع الحدث**: `Primary Booking Conversion` (المعيار المالي والتسويقي الأول)
* **المشغل الدقيق (Exact Trigger)**: استجابة خادم Supabase لدالة `create_atomic_booking` بنجاح، وصدور معرّف الحجز (`booking_id`).
* **المصدر في الكود**: دالة [`handleCompleteBooking`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx#L883) في `booking/page.tsx` لحظة التحقق من `if (bookingId)`، واستقبالها في صفحة [`orders/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/orders/page.tsx#L150) مع فحص كبح التكرار (`Deduplication Check`).

#### مواصفات عقد الشراء (Purchase Contract):

##### أ. Event-level:
- `event` (string): `"purchase"`
- `event_id` (string): المعرف الفريد للحجز (UUID الخاص بـ `booking_id`) ليكون مفتاح الـ Deduplication مع Meta CAPI.
- `user_type` (string): نوع العميل (`"registered"` للمسجلين أو `"guest"` للزوار).
- `is_whatsapp_confirmed` (boolean): حالة التأكيد الفعلية للحجز في الخادم (`true` أو `false`).

##### ب. Ecommerce:
- `ecommerce.transaction_id` (string): المعرف التسلسلي الثابت للحجز (`readable_id` مثل `"FH-100293"`).
- `ecommerce.value` (number): القيمة الإجمالية النهائية المعتمدة من الخادم في `price_snapshot.total`.
- `ecommerce.currency` (string): `"EGP"`.
- `ecommerce.tax` (number): `0`.
- `ecommerce.shipping` (number): `0`.
- `ecommerce.items` (array of objects):
  - `item_id` (string): معرّف الخدمة (مثل `"FH-S-100009"`).
  - `item_name` (string): اسم الخدمة (مثل `"تنظيف بعد التشطيب"`).
  - `item_category` (string): اسم الفئة الرئيسية (مثل `"خدمات النظافة الشاملة"`).
  - `price` (number): القيمة الإجمالية للحجز المعتمدة من الخادم.
  - `quantity` (number): `1`.

##### ج. Service & Category Metadata:
- `service_id` (string): معرّف الخدمة.
- `service_name` (string): اسم الخدمة.
- `category_id` (string | null): معرّف الفئة الرئيسية.
- `category_name` (string | null): اسم الفئة الرئيسية.

##### د. Booking Operational Metadata:
- `scheduled_date` (string): تاريخ الزيارة المجدول (`"YYYY-MM-DD"`).
- `scheduled_slot` (string): فترة التوقيت (`"09:00:00"`).
- `governorate` (string): المحافظة العامة (`"القاهرة"` / `"الجيزة"`).
- `city` (string): المدينة / المنطقة (`"التجمع الخامس"`, `"الشيخ زايد"`).
- `district` (string): الحي العام (`"الحي الأول"`, `"الياسمين"`).
- `payment_type` (string): طريقة الدفع (`"cash"`).

* **الربط (Mapping)**:
  - **GA4**: `purchase`
  - **Meta Pixel**: `fbq('track', 'Purchase', { content_type: 'product', content_ids: [service_id], content_name: service_name, value: value, currency: 'EGP', order_id: transaction_id }, { eventID: event_id })`

#### Example Payload:
```javascript
window.dataLayer.push({
  event: "purchase",
  event_id: "a1b2c3d4-e5f6-7890-abcd-ef1234567890", // Exact booking UUID
  user_type: "guest",
  is_whatsapp_confirmed: false,
  ecommerce: {
    transaction_id: "FH-100293",
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
  booking_details: {
    service_id: "FH-S-100009",
    service_name: "تنظيف بعد التشطيب",
    category_id: "FH-S-100001",
    category_name: "خدمات النظافة الشاملة",
    scheduled_date: "2026-09-02",
    scheduled_slot: "09:00:00",
    governorate: "القاهرة",
    city: "التجمع الخامس",
    district: "الحي الأول",
    payment_type: "cash"
  }
});
```

---

### 7. `contact_whatsapp` (النقر على زر محادثة WhatsApp — Lead Generation)
* **نوع الحدث**: `Secondary Conversion` (مؤشر تواصل مباشر)
* **المشغل الدقيق (Exact Trigger)**: عند نقر المستخدم على أي رابط أو زر يفتح محادثة واتساب (`wa.me`).
* **المصدر في الكود**: [`BottomCtaBanner.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/BottomCtaBanner.tsx#L46), [`Footer.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/Footer.tsx#L72), [`services/details/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/services/details/page.tsx#L687), [`orders/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/orders/page.tsx#L497).
* **الحقول المطلوبة (Required Parameters)**:
  - `event` (string): `"contact_whatsapp"`
  - `placement` (string): موقع الزر في الواجهة (`"hero"`, `"bottom_banner"`, `"service_details_inquiry"`, `"service_details_paused"`, `"footer"`, `"orders_pending_verification"`).
  - `page_location` (string): المسار الحالي في الموقع.
* **الحقول الاختيارية (Optional Parameters)**:
  - `service_context` (string | null): اسم الخدمة المرتبطة بالسياق.
  - `booking_reference` (string | null): رقم الحجز إذا كانت النقرة من صفحة تتبع/تأكيد طلب ضيف.
* **الربط (Mapping)**:
  - **GA4**: `generate_lead`
  - **Meta Pixel**: `fbq('track', 'Lead', { content_name: 'WhatsApp Contact', content_category: placement })`

#### Example Payload:
```javascript
window.dataLayer.push({
  event: "contact_whatsapp",
  event_id: "evt_wa_" + Date.now(),
  lead_data: {
    placement: "service_details_inquiry",
    service_context: "تنظيف بعد التشطيب",
    page_location: "/services/details?serviceId=FH-S-100001&subServiceId=FH-S-100009"
  }
});
```

---

### 8. `whatsapp_confirmed` (تأكيد الحجز عبر رابط WhatsApp للزوار)
* **نوع الحدث**: `Secondary / Quality Gate Conversion`
* **المشغل الدقيق (Exact Trigger)**: عند فتح الزائر لرابط التأكيد المستلم على واتساب ونجاح دالة `confirm_whatsapp_booking` في الخادم (`data === true`).
* **المصدر في الكود**: دالة [`confirmBooking`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/confirm/page.tsx#L40) في `booking/confirm/page.tsx`.
* **الحقول المطلوبة (Required Parameters)**:
  - `event` (string): `"whatsapp_confirmed"`
  - `booking_id` (string): معرّف الحجز الذي تم تأكيده (UUID).
  - `status` (string): `"confirmed"`
* **الربط (Mapping)**:
  - **GA4**: حدث مخصص `whatsapp_confirmed`.
  - **Meta Pixel**: Custom Event (اختياري كإشارة جودة إضافية).

#### Example Payload:
```javascript
window.dataLayer.push({
  event: "whatsapp_confirmed",
  event_id: "evt_waconf_" + "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  booking_id: "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  confirmation_status: "confirmed"
});
```

---

### 9. `sign_up` (إنشاء حساب مستخدم جديد)
* **نوع الحدث**: `Secondary Conversion`
* **المشغل الدقيق (Exact Trigger)**: عند استجابة `supabase.auth.signUp` بنجاح وإنشاء حساب العميل.
* **المصدر في الكود**: دالة [`handleRegister`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/register/page.tsx#L68) في `register/page.tsx`.
* **الحقول المطلوبة (Required Parameters)**:
  - `event` (string): `"sign_up"`
  - `method` (string): طريقة التسجيل (`"email_password"` أو `"google_oauth"`).
* **الربط (Mapping)**:
  - **GA4**: `sign_up`
  - **Meta Pixel**: `fbq('track', 'CompleteRegistration', { status: 'success', content_name: 'Customer Registration' })`

#### Example Payload:
```javascript
window.dataLayer.push({
  event: "sign_up",
  event_id: "evt_signup_" + Date.now(),
  method: "email_password"
});
```

---

### 10. `login` (تسجيل الدخول)
* **نوع الحدث**: `Micro Conversion`
* **المشغل الدقيق (Exact Trigger)**: عند استجابة `supabase.auth.signInWithPassword` أو `signInWithOAuth` بنجاح.
* **المصدر في الكود**: دالة [`handleLogin`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/login/page.tsx#L44) في `login/page.tsx`.
* **الحقول المطلوبة (Required Parameters)**:
  - `event` (string): `"login"`
  - `method` (string): طريقة الدخول (`"password"` أو `"google"`).
* **الربط (Mapping)**:
  - **GA4**: `login`
  - **Meta Pixel**: لا يُرسل إلى Meta.

#### Example Payload:
```javascript
window.dataLayer.push({
  event: "login",
  event_id: "evt_login_" + Date.now(),
  method: "password"
});
```

---

## 4. مصفوفة عقود الأحداث الشاملة (Event Contract Matrix)

| # | اسم الحدث (Event Name) | التصنيف التجاري | المشغل البرمجي الدقيق | المعاملات الإلزامية (Required Parameters) | GA4 Mapping | Meta Pixel Mapping | Deduplication Key |
| :-: | :--- | :---: | :--- | :--- | :--- | :--- | :--- |
| **1** | `view_service_list` | Micro | تحميل صفحة `/services` أو قسم الخدمات | `item_list_id`, `item_list_name` | `view_item_list` | Custom Event (Optional) | `item_list_id` |
| **2** | `view_item` | Micro | تحميل تفاصيل خدمة قابلة للحجز في `/services/details` | `item_id`, `item_name`, `price`, `currency` | `view_item` | `ViewContent` | `item_id` |
| **3** | `calculate_price` | Micro (High Intent) | نجاح استدعاء `calculate_booking_price` وعودة السعر | `service_id`, `service_name`, `calculated_total`, `currency` | `calculate_price` (Custom) | Custom Event (Optional) | `evt_calc_id` |
| **4** | `begin_checkout` | Secondary | النقر على متابعة لاختيار الموعد بعد حساب السعر | `item_id`, `item_name`, `value`, `currency` | `begin_checkout` | `InitiateCheckout` | `service_id_session` |
| **5** | `checkout_progress` | Micro | الانتقال بين خطوات الحجز (الموعد / العنوان / المراجعة) | `checkout_step`, `step_name`, `service_id` | `checkout_progress` | ❌ لا يُرسل | `step_index` |
| **6** | `purchase` | **Primary Booking Conversion** | نجاح استدعاء `create_atomic_booking` وصدور `booking_id` | `transaction_id`, `value`, `currency`, `items`, `service_id`, `governorate`, `city` | **`purchase`** | **`Purchase`** | **`booking_id` (UUID)** |
| **7** | `contact_whatsapp` | Secondary | النقر على أي زر محادثة WhatsApp | `placement`, `page_location` | `generate_lead` | `Lead` | `evt_wa_id` |
| **8** | `whatsapp_confirmed` | Secondary / Quality Gate | نجاح التحقق في `/booking/confirm` عبر رابط الواتساب | `booking_id`, `status` | `whatsapp_confirmed` (Custom) | Custom Event (Optional) | `booking_id` |
| **9** | `sign_up` | Secondary | نجاح استدعاء `supabase.auth.signUp` | `method` | `sign_up` | `CompleteRegistration` | `user_id_hash` |
| **10**| `login` | Micro | نجاح جلسة تسجيل الدخول | `method` | `login` | ❌ لا يُرسل | `session_id` |
