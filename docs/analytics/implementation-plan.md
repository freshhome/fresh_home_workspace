# Fresh Home — Data Layer Implementation Plan
**خطة التنفيذ البرمجية لطبقة البيانات والتتبع الرقمي (Tracking Implementation Plan)**

* **المشروع (Project)**: Fresh Home — Customer Web App (`apps/customer_web`)
* **الإصدار (Version)**: `1.0.0-Draft`
* **الحالة (Status)**: بانتظار المراجعة والموافقة قبل كتابة الكود (Pending Approval)
* **تاريخ التوثيق (Date)**: 2026-08-30

---

## 1. الهيكل المعماري لطبقة التتبع (Analytics Architecture)

لتجنب تشتت أكواد التتبع والحفاظ على نقاء الـ UI Components، سيتم إنشاء مكتبة مركزية موحدة:

```
apps/customer_web/src/
└── lib/
    └── gtm.ts                 # [New] Singleton Helper: Typed Data Layer Push Functions
```

### وظيفة الملف المركزي (`apps/customer_web/src/lib/gtm.ts`):
1. التحقق الآمن من بيئة المتصفح (`typeof window !== "undefined"`).
2. تهيئة `window.dataLayer = window.dataLayer || []`.
3. توفير دوال Typed صارمة لكل حدث تضمن التوافق الكامل مع الـ Contract وتمنع تمرير أي حقول PII.
4. إدارة الـ `sessionStorage` لمنع تكرار إرسال الأحداث المالية والحساسة.

---

## 2. خطة التنفيذ التفصيلية لكل حدث (Event-by-Event Implementation Plan)

---

### Event 1: `view_service_list`
* **الملفات المستهدفة للتعديل**:
  1. [`apps/customer_web/src/app/services/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/services/page.tsx)
  2. [`apps/customer_web/src/components/ServicesSection.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/ServicesSection.tsx)
* **المكان والدالة المسؤولة**:
  - داخل `useEffect` بعد نجاح جلب الخدمات (`fetchData` في `services/page.tsx` و `fetchFullServicesTree` في `ServicesSection.tsx`).
* **الـ Payload النهائي**:
  ```typescript
  trackViewServiceList({
    item_list_id: activeCategoryId, // e.g. "FH-S-100001"
    item_list_name: parentTitle,     // e.g. "خدمات النظافة الشاملة"
    items_count: subServices.length
  });
  ```
* **GA4 Mapping**: `view_item_list` (item_list_id, item_list_name).
* **Meta Pixel Mapping**: لا يُرسل (أو Custom Event اختياري).
* **Deduplication Strategy**: إطلاق الحدث مرة واحدة عند تغيير الفئة النشطة (`activeCategory`).
* **طريقة الاختبار (Verification)**:
  - فتح صفحة `/services?serviceId=FH-S-100001`.
  - مراجعة نافذة `dataLayer` في Console للتأكد من وجود `event: "view_service_list"` ومطابقة اسم الفئة.
* **النتيجة المتوقعة**: ظهور حدث `view_item_list` في GTM Preview و GA4 DebugView مع معرف الفئة.

---

### Event 2: `view_item`
* **الملف المستهدف للتعديل**:
  [`apps/customer_web/src/app/services/details/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/services/details/page.tsx)
* **المكان والدالة المسؤولة**:
  - داخل `useEffect` في دالة `loadTreeAndNode` لحظة التأكد من تحميل الخدمة القابلة للحجز (`current.is_bookable === true`).
* **الـ Payload النهائي**:
  ```typescript
  trackViewItem({
    service_id: currentService.id,
    service_name: currentService.title?.ar || currentService.title,
    category_id: rootAncestorId,
    category_name: breadcrumbs[0]?.title || "خدمات فريش هوم",
    price: startingPrice,
    currency: "EGP",
    price_type: currentService.price_config?.type || "fixed"
  });
  ```
* **GA4 Mapping**: `view_item` (items array مع id, name, category, price).
* **Meta Pixel Mapping**: `fbq('track', 'ViewContent', { content_ids: [service_id], content_name: service_name, content_category: category_name, value: price, currency: 'EGP' })`.
* **Deduplication Strategy**: إطلاق الحدث مرة واحدة عند تحميل الخدمة المحددة (`targetId`).
* **طريقة الاختبار (Verification)**:
  - فتح صفحة تفاصيل خدمة مثل `/services/details?serviceId=FH-S-100001&subServiceId=FH-S-100009`.
  - فحص `dataLayer` و Meta Pixel Helper للتأكد من التقاط `ViewContent`.
* **النتيجة المتوقعة**: تسجيل مشاهدة الخدمة مع السعر الابتدائي وتصنيف الفئة.

---

### Event 3: `calculate_price`
* **الملف المستهدف للتعديل**:
  [`apps/customer_web/src/app/booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx)
* **المكان والدالة المسؤولة**:
  - داخل دالة [`handleCalculate`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx#L557) مباشرة بعد نجاح استدعاء `supabase.rpc("calculate_booking_price", ...)` واستلام كائن السعر `data`.
* **الـ Payload النهائي**:
  ```typescript
  trackCalculatePrice({
    service_id: subServiceId,
    service_name: selectedSubService?.title?.ar || selectedSubService?.title || "خدمة منزلية",
    calculated_total: Number(data.total) || 0,
    base_price: Number(data.basePrice) || 0,
    extra_fees: Number(data.extraFees) || 0,
    discount: Number(data.discount) || 0,
    currency: "EGP",
    inputs_summary: {
      area_sqm: inputs.area ? Number(inputs.area) : undefined,
      rooms_count: inputs.rooms_count ? Number(inputs.rooms_count) : undefined,
      bathrooms_count: inputs.bathrooms_count ? Number(inputs.bathrooms_count) : undefined,
      ac_units_count: inputs.ac_units_count ? Number(inputs.ac_units_count) : undefined,
      addons_count: selectedAddons.length
    }
  });
  ```
* **GA4 Mapping**: حدث مخصص `calculate_price` مع معلمات السعر ومدخلات الخدمة.
* **Meta Pixel Mapping**: لا يُرسل إلى Meta (لحصر بيانات الإعلانات في التحويلات الأساسية).
* **Deduplication Strategy**: يُطلق مع كل عملية حساب ناجحة يقوم بها العميل.
* **طريقة الاختبار (Verification)**:
  - إدخال بيانات المساحة والغرف في خطوة الحجز الأولى والضغط على "احسب التكلفة الدقيقة".
  - التأكد من إطلاق الحدث ومطابقة السعر الإجمالي لقيمة الـ Banner.
* **النتيجة المتوقعة**: تسجيل حدث حساب السعر مع القيمة المعتمدة من الخادم.

---

### Event 4: `begin_checkout`
* **الملف المستهدف للتعديل**:
  [`apps/customer_web/src/app/booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx)
* **المكان والدالة المسؤولة**:
  - داخل دالة [`handleNext`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx#L860) عندما تكون `currentStep === 0` (الانتقال من مرحلة السعر إلى الموعد).
* **الـ Payload النهائي**:
  ```typescript
  trackBeginCheckout({
    service_id: subServiceId,
    service_name: selectedSubService?.title?.ar || selectedSubService?.title,
    category_id: selectedPath[0]?.id || null,
    value: priceDetails.total,
    currency: "EGP"
  });
  ```
* **GA4 Mapping**: `begin_checkout` (value, currency, items array).
* **Meta Pixel Mapping**: `fbq('track', 'InitiateCheckout', { content_ids: [service_id], content_name: service_name, value: value, currency: 'EGP', num_items: 1 })`.
* **Deduplication Strategy**: يُطلق عند النقر على متابعة بعد حساب السعر.
* **طريقة الاختبار (Verification)**:
  - الضغط على "متابعة لاختيار الموعد".
  - فحص Meta Pixel Helper للتأكد من ظهور `InitiateCheckout`.
* **النتيجة المتوقعة**: بدء مسار الـ Checkout الرسمي في GA4 و Meta.

---

### Event 5: `checkout_progress`
* **الملف المستهدف للتعديل**:
  [`apps/customer_web/src/app/booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx)
* **المكان والدالة المسؤولة**:
  - داخل دالة [`handleNext`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx#L860) عند الانتقال بين الخطوات (Step 1 ⬅️ Step 2 ⬅️ Step 3).
* **الـ Payload النهائي**:
  ```typescript
  trackCheckoutProgress({
    checkout_step: currentStep + 1,
    step_name: currentStep === 1 ? "schedule_selection" : currentStep === 2 ? "address_entry" : "order_review",
    service_id: subServiceId,
    step_data: {
      scheduled_date: currentStep === 1 ? scheduledDate : undefined,
      governorate: currentStep === 2 ? address.governorate : undefined,
      city: currentStep === 2 ? address.city : undefined
    }
  });
  ```
* **GA4 Mapping**: `checkout_progress` (مخصص لتحليل قمع التحويل Funnel Drop-off).
* **Meta Pixel Mapping**: لا يُرسل.
* **Deduplication Strategy**: يرتبط بكل تقدم ناجح بين الخطوات.
* **طريقة الاختبار (Verification)**:
  - التنقل بين خطوات الموعد والعنوان والمراجعة وملاحظة رقم الخطوة في الـ dataLayer.
* **النتيجة المتوقعة**: تسجيل خطوات القمع بالتسلسل 1 ⬅️ 2 ⬅️ 3 ⬅️ 4.

---

### Event 6: `purchase` (Primary Booking Conversion)
* **الملفات المستهدفة للتعديل**:
  1. [`apps/customer_web/src/app/booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx) (في `handleCompleteBooking`)
  2. [`apps/customer_web/src/app/orders/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/orders/page.tsx) (كشبكة أمان في صفحة تتبع الطلب مع فحص الـ Deduplication)
* **المكان والدالة المسؤولة**:
  - في [`booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx#L982) لحظة التحقق من عودة `bookingId` وقبل استدعاء `router.push`.
  - في [`orders/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/orders/page.tsx#L150) عندما يتحقق الشرط `if (isSuccess && bookingData)`.
* **آلية كبح التكرار الصارمة (Deduplication Mechanism)**:
  ```typescript
  const storageKey = `fh_purchase_tracked_${bookingId}`;
  if (typeof window !== "undefined" && !sessionStorage.getItem(storageKey)) {
    sessionStorage.setItem(storageKey, "true");
    
    trackPurchase({
      event_id: bookingId, // UUID used as Meta eventID for CAPI matching
      transaction_id: bookingData?.readable_id || readableId || bookingId,
      value: bookingData?.price_snapshot?.total || priceDetails.total,
      currency: "EGP",
      service_id: subServiceId,
      service_name: serviceTitle,
      category_id: categoryId,
      category_name: categoryName,
      user_type: isClientUserLoggedIn ? "registered" : "guest",
      is_whatsapp_confirmed: bookingData?.is_whatsapp_confirmed ?? (isClientUserLoggedIn ? true : false),
      scheduled_date: scheduledDate,
      scheduled_slot: timeSlot,
      governorate: address.governorate,
      city: address.city,
      district: finalDistrict,
      payment_type: "cash"
    });
  }
  ```
* **GA4 Mapping**: `purchase` (transaction_id, value, currency, tax: 0, shipping: 0, items array).
* **Meta Pixel Mapping**: `fbq('track', 'Purchase', { content_type: 'product', content_ids: [service_id], content_name: service_name, value: value, currency: 'EGP', order_id: transaction_id }, { eventID: event_id })`.
* **Zero-PII Compliance**: لا يتم إرسال أي أرقام هواتف أو أسماء صريحة أو عناوين تفصيلية.
* **طريقة الاختبار (Verification)**:
  - إكمال حجز تجريبي حقيقي والوصول لصفحة `/orders?bookingId=...&success=true`.
  - التحقق من إطلاق حدث `Purchase` في Meta Pixel Helper مع تطابق `eventID` و `value`.
  - عمل Refresh للصفحة والتأكد من **عدم إطلاق** الحدث مرة ثانية بفضل `sessionStorage`.
* **النتيجة المتوقعة**: تسجيل تحويل حجز ناجح بقيمته الموثقة من الـ Backend وبدون تكرار.

---

### Event 7: `contact_whatsapp` (Lead Generation)
* **الملفات المستهدفة للتعديل**:
  1. [`apps/customer_web/src/components/BottomCtaBanner.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/BottomCtaBanner.tsx)
  2. [`apps/customer_web/src/components/Footer.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/Footer.tsx)
  3. [`apps/customer_web/src/app/services/details/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/services/details/page.tsx)
  4. [`apps/customer_web/src/app/orders/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/orders/page.tsx)
* **المكان والدالة المسؤولة**:
  - إضافة `onClick` handler لجميع وسوم `<a>` التي تفتح روابط واتساب.
* **الـ Payload النهائي**:
  ```typescript
  trackContactWhatsApp({
    placement: "bottom_banner" | "service_details_inquiry" | "service_details_paused" | "footer" | "orders_verification",
    service_context: arTitle || undefined,
    page_location: window.location.pathname
  });
  ```
* **GA4 Mapping**: `generate_lead` (lead_type: "whatsapp", placement, service_context).
* **Meta Pixel Mapping**: `fbq('track', 'Lead', { content_name: 'WhatsApp Contact', content_category: placement })`.
* **طريقة الاختبار (Verification)**:
  - النقر على زر واتساب في البانر السفلي.
  - فحص الـ dataLayer للتأكد من تسجيل `placement: "bottom_banner"`.
* **النتيجة المتوقعة**: تتبع دقيق لكل قناة توليد محادثات واتساب.

---

### Event 8: `whatsapp_confirmed` (تأكيد حجز الزائر)
* **الملف المستهدف للتعديل**:
  [`apps/customer_web/src/app/booking/confirm/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/confirm/page.tsx)
* **المكان والدالة المسؤولة**:
  - داخل دالة [`confirmBooking`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/confirm/page.tsx#L40) لحظة تحقق الشرط `if (data === true)`.
* **الـ Payload النهائي**:
  ```typescript
  trackWhatsAppConfirmed({
    booking_id: id,
    status: "confirmed"
  });
  ```
* **GA4 Mapping**: حدث مخصص `whatsapp_confirmed` (booking_id, status).
* **Meta Pixel Mapping**: Custom Event (اختياري).
* **Deduplication Strategy**: يتم كبحه لمرة واحدة لنفس معرف الحجز.
* **طريقة الاختبار (Verification)**:
  - فتح رابط تأكيد حجز تجريبي `/booking/confirm?id=...&token=...`.
  - التأكد من إطلاق الحدث بعد نجاح التحقق في الخادم.
* **النتيجة المتوقعة**: قياس نسبة الحجوزات التي يتم تأكيدها فعلياً عبر واتساب.

---

### Event 9: `sign_up` & Event 10: `login`
* **الملفات المستهدفة للتعديل**:
  1. [`apps/customer_web/src/app/register/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/register/page.tsx) (في `handleRegister` و `handleGoogleLogin`)
  2. [`apps/customer_web/src/app/login/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/login/page.tsx) (في `handleLogin` و `handleGoogleLogin`)
* **الـ Payload النهائي**:
  ```typescript
  trackSignUp({ method: "email_password" | "google_oauth" });
  trackLogin({ method: "password" | "google" });
  ```
* **GA4 Mapping**: `sign_up` و `login`.
* **Meta Pixel Mapping**: `fbq('track', 'CompleteRegistration')` لـ `sign_up` فقط (لا يُرسل الـ login لـ Meta).
* **طريقة الاختبار (Verification)**:
  - تسجيل حساب جديد وتجربة تسجيل الدخول.
* **النتيجة المتوقعة**: تسجيل أحداث إنشاء الحساب والمصادقة بدون أي تسريب للبريد أو الهاتف.

---

## 3. قائمة الملفات التي سيتم إنشاؤها وتعديلها (File Modification Manifest)

| المسار (File Path) | نوع العملية | الغرض البرمجي |
| :--- | :---: | :--- |
| [`apps/customer_web/src/lib/gtm.ts`](file:///d:/fresh_home_workspace/apps/customer_web/src/lib/gtm.ts) | **[NEW]** | إنشاء مكتبة التتبع المركزية ودوال الـ Data Layer المكتوبة بنوعية صارمة (Strict TypeScript Types). |
| [`apps/customer_web/src/app/services/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/services/page.tsx) | **[MODIFY]** | استدعاء `trackViewServiceList` عند تحميل القسم. |
| [`apps/customer_web/src/components/ServicesSection.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/ServicesSection.tsx) | **[MODIFY]** | استدعاء `trackViewServiceList` عند تغيير التبويب أو تصفح الخدمات. |
| [`apps/customer_web/src/app/services/details/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/services/details/page.tsx) | **[MODIFY]** | استدعاء `trackViewItem` لصفحة تفاصيل الخدمة، و `trackContactWhatsApp` لأزرار الاستفسار. |
| [`apps/customer_web/src/app/booking/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/page.tsx) | **[MODIFY]** | استدعاء `trackCalculatePrice`, `trackBeginCheckout`, `trackCheckoutProgress`, و `trackPurchase`. |
| [`apps/customer_web/src/app/orders/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/orders/page.tsx) | **[MODIFY]** | إضافة شبكة أمان `trackPurchase` مع Deduplication، و `trackContactWhatsApp` لزر التأكيد. |
| [`apps/customer_web/src/app/booking/confirm/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/booking/confirm/page.tsx) | **[MODIFY]** | استدعاء `trackWhatsAppConfirmed` عند نجاح تأكيد حجز الضيف. |
| [`apps/customer_web/src/components/BottomCtaBanner.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/BottomCtaBanner.tsx) | **[MODIFY]** | إضافة `trackContactWhatsApp` عند النقر على زر واتساب. |
| [`apps/customer_web/src/components/Footer.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/components/Footer.tsx) | **[MODIFY]** | إضافة `trackContactWhatsApp` لروابط واتساب في الفوتر. |
| [`apps/customer_web/src/app/register/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/register/page.tsx) | **[MODIFY]** | استدعاء `trackSignUp` عند نجاح إنشاء الحساب. |
| [`apps/customer_web/src/app/login/page.tsx`](file:///d:/fresh_home_workspace/apps/customer_web/src/app/login/page.tsx) | **[MODIFY]** | استدعاء `trackLogin` عند نجاح تسجيل الدخول. |

---

## 4. ضمانات السلامة البرمجية (Engineering Safety Guarantees)

1. **عدم المساس بالـ Business Logic**:
   - لن يتم تغيير أي منطق في التسعير، المصادقة، أو دوال الـ Database RPCs (`create_atomic_booking`, `calculate_booking_price`, `confirm_whatsapp_booking`).
   - استدعاء دوال التتبع يكون ملحقاً فقط بعد اكتمال العمليات الأصلية بنجاح.
2. **عزل الأخطاء (Error Isolation)**:
   - جميع دوال `gtm.ts` محاطة بـ `try/catch` آمن داخلياً، لضمان عدم توقف واجهة المستخدم أو إعاقة رحلة العميل في حال حدث أي خطأ في بيئة المتصفح.
3. **التوافق مع بيئة الـ SSR (Next.js Server Side Rendering)**:
   - فحص `typeof window !== "undefined"` قبل أي وصول لكائن `window.dataLayer` لتفادي أخطاء Hydration / Build.
