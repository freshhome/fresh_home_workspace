# Fresh Home Address System V2 Specification

---

## 1. Executive Summary & Document Overview (ملخص وثيقة المواصفات الرسمية)

تمثل هذه الوثيقة **المرجع المعماري والتنفيذي الرسمي والوحيد (Single Source of Truth)** لنظام العناوين بمشروع **Fresh Home** في إصداره الثاني (V2).

تحدد هذه الوثيقة الفلسفة التصميمية، قواعد العمل، نموذج البيانات، دورة الحياة، وتكامل العنوان مع نظام الطلبات (Bookings Engine)، بما يضمن استقرار المنصة وقابليتها للتوسع من القاهرة والجيزة إلى كافة محافظات جمهورية مصر العربية، ولدعم العملاء الأفراد والشركات والمؤسسات (Enterprise) مستقبلاً.

---

## 2. Address Philosophy (فلسفة العنوان واعتناديته)

1. **كيان مستقل قائم بذاته (Independent Domain Entity):**
   العنوان ليس مجرد نصوص ملحقة بالطلب، بل هو كيان مستقل في طبقة النطاق (Domain Layer) له دورة حياة مستقلة وله معرّف فريد (`id`).

2. **التسلسل الهرمي للكيانات (Entity Relationship Hierarchy):**
   ```
   User (المستخدم)
      │
      ├──► Addresses (عناوين متعددة قابلة لإعادة الاستخدام)
      │
      └──► Bookings (الطلبات)
              │
              └──► Address Snapshot (لقطة عنوان مروسة وغير قابلة للتعديل)
   ```

3. **استقلالية الطلبات عن العناوين القابلة للتعديل (Immutability):**
   الطلبات التاريخية لا تعتمد بأي شكل من الأشكال على السجل الـ Mutable للعنوان. أي تعديل أو حذف ينفذه العميل على عنوانه المخزن لا تؤثر نهائياً على أي طلب سابـق أو قائم تم إنشاؤه بهذا العنوان.

---

## 3. Business Rules (قواعد العمل المعتمدة)

* **العناوين المتعددة:** يحق للعميل (User) حفظ عناوين متعددة على حساب شخصي واحد.
* **العنوان الرئيسي الفريد (Single Primary Address Constraint):**
  - **القاعدة المعمارية الحاكمة:** *"There must never exist more than one active primary address for the same user"* (لا يجوز نهائياً وجود أكثر من عنوان رئيسي نشط واحد لنفس المستخدم).
  - العنوان الأول الذي يضيفه المستخدم يصبح تلقائياً هو العنوان الرئيسي (Automatic Primary).
  - عند تغيير العنوان الرئيسي إلى عنوان آخر، يتم تبديل المؤشر تلقائياً ليكون عنوان واحد فقط هو الرئيسي.
  - **قيد نزاهة البيانات وقواعد التزامن (Database Structural Constraint):**
    إن تطبيق هذه القاعدة بداخل تطبيق Flutter أو UseCases أو API لا يكفي بمفرده، نظراً لأن الطلبات المتزامنة (Concurrent Requests) قد تؤدي إلى حالات سباق (Race Conditions) تنتج حسابات تملك أكثر من عنوان رئيسي نشط في نفس الوقت.
    لذلك، يُقر الهيكل المعماري حتمية فرض هذه القاعدة على مستوى المحرك في Phase 2 عبر مؤشر فريد جزئي (PostgreSQL Partial Unique Index):
    ```sql
    CREATE UNIQUE INDEX idx_user_primary_address
    ON public.user_addresses(user_id)
    WHERE is_primary = TRUE
    AND deleted_at IS NULL;
    ```
    هذا القيد إجباري وصارم لضمان نزاهة البيانات (Data Integrity).

* **إعادة الاستخدام (Reusability):** يمكن استخدام نفس العنوان المخزن لإجراء عشرات الطلبات المختلفة.
* **الحذف المرن (Soft Delete):**
  - يمكن للعميل حذف أي عنوان لا ترتبط به طلبات سابقة حذفاً كاملاً (Hard Delete).
  - إذا كان العنوان مرتبطاً بأي طلب تاريخي أو قائم في جدول الطلبات (`bookings`)، يتحول الحذف تلقائياً إلى **حذف مرن (Soft Delete)** عبر تعيين `deleted_at = NOW()` لحفظ سلامة البيانات وروافد التقارير.
* **إلزامية واختيارية البيانات الجغرافية:**
  - `Governorate` (المحافظة) - **إجباري**
  - `City` (المدينة) - **إجباري**
  - `District` (الحي / المنطقة) - **إجباري**
  - `Street / Compound` (الشارع أو المجمع السكني) - **إجباري**
  - `Building Identifier` (معرّف العقار / اسم البرج أو رقم المبنى) - **إجباري**
  - `Floor` (الطابق) - *اختياري*
  - `Apartment / Unit` (الشقة أو وحدة المكتب) - *اختياري*
  - `Landmark` (المعلم البارز) - *اختياري*
  - `Latitude / Longitude` (إحداثيات الخريطة) - ***اختياري***

---

## 4. Address Lifecycle (دورة حياة العنوان)

توضح المحطات التالية دورة حياة كيان العنوان (`Address`) بداخل نظام Fresh Home منذ لحظة إنشائه وحتى أرشفته:

```
Create Address (إنشاء العنوان)
        ↓
Validate (التحقق من قواعد النطاق والمعمارية)
        ↓
Save (الحفظ في قاعدة البيانات)
        ↓
Automatic Primary (تعيين رئيسي تلقائياً إذا كان الأول)
        ↓
Reuse in Multiple Bookings (إعادة الاستخدام في طلبات متعددة)
        ↓
Update (تعديل بيانات العنوان عند رغبة العميل)
        ↓
Booking Snapshot Creation (التقاط لقطة تجميدية غير قابلة للتعديل عند كل حجز)
        ↓
Delete Request (طلب حذف العنوان)
        ↓
Hard Delete OR Soft Delete (حذف كلي للجديد / حذف مرن للمرتبط بطلبات)
        ↓
Archived (أرشفة السجل عبر تعيين deleted_at)
```

### قواعد حاسمة في دورة الحياة:
* **العنوان الكلي (Address Entity):** كيان **قابل للتعديل (Mutable)** أثناء دورة حياته عبر الحساب الشخصي للعميل.
* **لقطة حجز العنوان (Booking Address Snapshot):** كيان **غير قابل للتعديل (Immutable)** بمجرد تجميده بداخل الطلب، ولا يتأثر إطلاقاً بأي تعديل أو حذف (مرن أو كلي) يطرأ على كيان العنوان الأصلي في المراحل اللاحقة.

---

## 5. Address Data Model V1 (نموذج بيانات العنوان V1)

### أ. حقول البيانات الرسمية لإصدار V1

| اسم الحقل (Domain / DB) | نوع البيانات (Data Type) | الحالة (Constraint) | الوصف والملاحظات المعمارية |
| :--- | :--- | :--- | :--- |
| **id** | `UUID` | Primary Key | المعرّف الفريد للعنوان |
| **user_id** | `UUID` | Foreign Key | معرف المستخدم صاحب العنوان |
| **governorate** | `String` / `TEXT` | **Required** | اسم المحافظة (مثل: القاهرة، الجيزة) |
| **city** | `String` / `TEXT` | **Required** | اسم المدينة (مثل: القاهرة الجديدة، 6 أكتوبر) |
| **district** | `String` / `TEXT` | **Required** | اسم الحي أو المنطقة (مثل: التجمع الخامس، الحي المتميز) |
| **street_or_compound** | `String` / `TEXT` | **Required** | اسم الشارع أو الكومباوند السكني/التجاري |
| **building_identifier** | `String` / `TEXT` | **Required** | اسم العقار/البرج/المبنى أو رقمه (حيادي ومناسب لجميع الأغراض) |
| **floor** | `String?` / `TEXT` | Optional | رقم الطابق (معلومات حساسة PII) |
| **apartment_or_unit** | `String?` / `TEXT` | Optional | رقم الشقة أو المكتب (معلومات حساسة PII) |
| **landmark** | `String?` / `TEXT` | Optional | معلم بارز بالقرب من العقار (معلومات حساسة PII) |
| **latitude** | `double?` / `DOUBLE PRECISION` | Optional | خط العرض الجغرافي (معلومات حساسة PII) |
| **longitude** | `double?` / `DOUBLE PRECISION` | Optional | خط الطول الجغرافي (معلومات حساسة PII) |
| **is_primary** | `bool` / `BOOLEAN` | Internal / Default `false` | مؤشر العنوان الرئيسي (محمية بـ Partial Unique Index) |
| **deleted_at** | `DateTime?` / `TIMESTAMPTZ` | Internal / Soft Delete | تاريخ وساعة الحذف المرن |
| **created_at** | `DateTime` / `TIMESTAMPTZ` | Internal | تاريخ إنشاء السجل |
| **updated_at** | `DateTime` / `TIMESTAMPTZ` | Internal | تاريخ آخر تحديث |

---

## 6. Domain Model & Value Objects Readiness (نموذج النطاق والقيم التجريدية)

### أ. الجاهزية للـ Domain Value Objects
لتجريد طبقة النطاق (Domain Layer) عن تفاصيل التخزين الحالية (نصوص مسطحة `TEXT`) أو المستقبلية (مفاتيح أجنبية `Lookup IDs`)، يتم تغليف العناصر الجغرافية داخل **Value Objects**:

* `GovernorateValue`
* `CityValue`
* `DistrictValue`

يتعامل الكيان في طبقة النطاق مع هذه الـ Value Objects بدلاً من النصوص المجردة، مما يسمح بالتحول المستقبلي لقواعد البيانات المنمطة دون الحاجة إلى تعديل الكلاسات الأساسية في الـ Domain.

### ب. تعريف الكيان في Dart (`Address` Entity Specification)

في طبقة النطاق (`packages/shared/lib/domain/user/entities/user/address.dart`):

```dart
import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final String id;
  final String userId;
  final String governorate;
  final String city;
  final String district;
  final String streetOrCompound;
  final String buildingIdentifier; // اسم أكثر حيادية ودعماً لجميع أنواع العقارات
  final String? floor;
  final String? apartmentOrUnit;
  final String? landmark;
  final double? latitude;
  final double? longitude;
  final bool isPrimary;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Address({
    required this.id,
    required this.userId,
    required this.governorate,
    required this.city,
    required this.district,
    required this.streetOrCompound,
    required this.buildingIdentifier,
    this.floor,
    this.apartmentOrUnit,
    this.landmark,
    this.latitude,
    this.longitude,
    this.isPrimary = false,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasCoordinates => latitude != null && longitude != null;
  bool get isDeleted => deletedAt != null;

  @override
  List<Object?> get props => [
        id,
        userId,
        governorate,
        city,
        district,
        streetOrCompound,
        buildingIdentifier,
        floor,
        apartmentOrUnit,
        landmark,
        latitude,
        longitude,
        isPrimary,
        deletedAt,
        createdAt,
        updatedAt,
      ];
}
```

---

## 7. Booking Relationship & Versioned Immutable Snapshot (العلاقة بالطلبات واللقطة التاريخية المروسة)

> [!IMPORTANT]
> **قاعدة عدم التعديل المطلقة (Immutable Address Snapshot Rule):**
> بمجرد إنشاء الحجز (Booking Creation)، يصبح `address_snapshot` غير قابل للتعديل نهائياً، ولا يجوز تحديثه أو إعادة بنائه أو استبداله تحت أي ظرف من الظروف، حتى في حال تم تعديل العنوان الأصلي في حساب العميل أو حذفه مرناً أو كلياً.

عند إنشاء طلب جديد في نظام الحجز (Booking Engine):

1. **الربط الإسنادي:** يتم تخزين معرّف العنوان `address_id` في جدول الطلبات `bookings`.
2. **اللقطة التاريخية الهيكلية المروسة بـ Version (Versioned Address Snapshot):**
   يتم التقاط لقطة تجميدية مروسة برقم إصدار واضح (`snapshot_version`) وتخزينها داخل حقل `address_snapshot` بصيغة JSONB في جدول `bookings`:

```json
{
  "snapshot_version": 1,
  "address": {
    "address_id": "c39a8e91-7d21-4f81-8b20-91a0210bc112",
    "governorate": "القاهرة",
    "city": "القاهرة الجديدة",
    "district": "التجمع الخامس",
    "street_or_compound": "شارع التسعين الجنوبي",
    "building_identifier": "برج اللؤلؤة (مبنى B)",
    "floor": "الدور الثالث",
    "apartment_or_unit": "مكتب 302",
    "landmark": "خلف مستشفى الجوي التخصصي",
    "latitude": 30.0275,
    "longitude": 31.4361,
    "snapshot_created_at": "2026-08-03T10:30:00Z"
  }
}
```

### الأهمية المعمارية لتحديد الإصدار (`snapshot_version`):
يضمن وجود رقم الإصدار التوافقية التنازلية والمستقبلية (Forward & Backward Compatibility). إذا تم إدخال حقول جديدة في إصدارات مستقبلية (مثل رقم الكومباوند المنمط أو وسم العنوان في V2/V3)، ستتم زيادة `snapshot_version` إلى 2، وسيكون نظام قراءة الطلبات قادراً على قراءة اللقطات القديمة والحديثة بسلاسة وبدون خطأ في الـ Deserialization.

---

## 8. Address Validation Rules (قواعد التحقق والتصحيح المعمارية)

تطبق طبقة النطاق (Domain Layer) قواعد التحقق المعمارية التالية بشكل مستقل عن برمجيات Flutter أو SQL:

| اسم الحقل | الحالة | قواعد التحقق المعمارية |
| :--- | :--- | :--- |
| **governorate** | Required | نص غير فارغ، حذف المسافات الزائدة (Trim)، الحد الأدنى 2 حرف، الحد الأقصى 100 حرف. |
| **city** | Required | نص غير فارغ، حذف المسافات الزائدة (Trim)، الحد الأدنى 2 حرف، الحد الأقصى 100 حرف. |
| **district** | Required | نص غير فارغ، حذف المسافات الزائدة (Trim)، الحد الأدنى 2 حرف، الحد الأقصى 100 حرف. |
| **street_or_compound** | Required | نص غير فارغ، حذف المسافات الزائدة (Trim)، الحد الأدنى 3 أحرف، الحد الأقصى 255 حرف. |
| **building_identifier** | Required | نص غير فارغ، Trim، الحد الأدنى 1 حرف/رقم، الحد الأقصى 100 حرف. |
| **floor** | Optional | يقبل `null` أو نص فارغ، وعند الإدخال بحد أقصى 50 حرف (مثل: "3" أو "الدور الثالث"). |
| **apartment_or_unit** | Optional | يقبل `null` أو نص فارغ، وعند الإدخال بحد أقصى 50 حرف (مثل: "12" أو "مكتب 4B"). |
| **landmark** | Optional | يقبل `null` أو نص فارغ، وعند الإدخال بحد أقصى 255 حرف. |
| **latitude** | Optional | يقبل `null`، وعند وجوده يجب أن يقع ضمن نطاق `-90.0` إلى `+90.0` (ونطاق مصر: `22.0` إلى `31.7`). |
| **longitude** | Optional | يقبل `null`، وعند وجوده يجب أن يقع ضمن نطاق `-180.0` إلى `+180.0` (ونطاق مصر: `24.0` إلى `37.0`). |

> **قاعدة عامة:** يتم تنقية جميع المدخلات النصية من المسافات الفارغة المزدوجة والتوسيعات الخاطئة (Sanitation & Trimming) للحفاظ على جودة ونظافة البيانات.

---

## 9. Address Formatter Service (خدمة تنسيق واستعراض العنوان)

لتفادي قيام كل شاشة في Flutter ببناء شكل العنوان نصياً بطريقة مختلفة، تلتزم البنية التحتية بتوفير خدمة مستقلة داخل الـ Domain أو Shared Layer باسم **`AddressFormatter`**:

### الصيغ النصية المعيارية المعتمدة:
1. **`toSingleLine(Address / Snapshot)`:**
   > "التجمع الخامس، شارع التسعين الجنوبي، برج اللؤلؤة (مبنى B)، الدور الثالث، مكتب 302 (خلف مستشفى الجوي التخصصي) - القاهرة الجديدة، القاهرة"
2. **`toMultiLine(Address / Snapshot)`:**
   تنسيق متعدد الأسطر مناسب لفواتير الشراء وشاشات التفاصيل.
3. **`toShortSummary(Address / Snapshot)`:**
   > "التجمع الخامس - شارع التسعين الجنوبي (برج اللؤلؤة)"
4. **`toTechnicianSummary(Address / Snapshot)`:**
   يركز على تفاصيل وصول الفني في الـ 100 متر الأخيرة (المبنى، الطابق، الشقة، والمعلم البارز).
5. **`toGoogleMapsQuery(Address / Snapshot)`:**
   صياغة نص البحث الجغرافي الموجه للتطبيقات الملاحة الخارجية (Google Maps / Waze) دون الارتباط بـ SDK خارجي.
   > **مثال الاستخراج:** "التجمع الخامس، شارع التسعين، برج اللؤلؤة، القاهرة الجديدة، القاهرة"

---

## 10. Repository Naming Architecture Review (`deleteAddress` vs `archiveAddress`)

### تقييم واجهة المستودع:
* اسم الواجهة الحالي في طبقة النطاق: `deleteAddress(String addressId)`
* **التقييم المعماري:**
  في تصميم النطاق (Domain-Driven Design)، يعكس الاسم `deleteAddress` أو `removeAddress` **قصد المستخدم (User Intent)** عند الضغط على "حذف العنوان من قائمة عناويني". 
  
  من الناحية المعمارية، يُفضل الإبقاء على اسم الدالة `deleteAddress(String addressId)` في عقود الـ Repository مع توثيق منطق التنفيذ الداخلي (Implementation Logic) الذي يقوم بحذف كامل (Hard Delete) إذا لم تكن هناك طلبات ملازمة، أو أرشفة وحذف مرن (`deleted_at = NOW()`) إذا كانت هناك طلبات سابقة.

---

## 11. UX Principles & Booking Flow Integration (مبادئ تجربة المستخدم وشاشة الموقع)

### أ. إعادة تسمية المرحلة في رحلة الحجز
تغيير اسم خطوة العنوان رسمياً في رحلة الحجز لتصبح:
**"Service Location" (موقع الخدمة)**
بدلاً من:
"Address & Contact" أو "Address".

### ب. تسلسل خطوات الحجز المعتمد:
```
Service (اختيار الخدمة)
   ↓
Pricing (تفاصيل الأسعار والإضافات)
   ↓
Schedule (تحديد التاريخ والوقت)
   ↓
Service Location (تحديد موقع الخدمة)
   ↓
Booking Confirmation (مراجعة وتأكيد الطلب)
```

### ج. مرونة تحديد الموقع على الخريطة (Optional Map Pin)
* تحديد موقع الخريطة **اختياري تماماً** وليس شرطاً لإتمام الحجز.
* **المبرر المعماري:** العديد من الخدمات (مثل نظافة ما بعد التشطيب، تجهيز الفيلات المؤجرة، أو خدمات الشركات) يتم حجزها بواسطة العميل أثناء تواجده في مكان مختلف عن موقع الخدمة. إجبار العميل على وضع Pin على الخريطة يؤدي لإدخال إحداثيات خاطئة.

---

## 12. Future Scalability & Feature Readiness (التوسع المستقبلي وجاهزية الميزات)

تم تصميم هذا النموذج المعماري ليكون متوافقاً ومتكاملاً مع التحسينات والتوسعات المستقبلية التالية دون كسر البنية الحالية:

1. **قاعدة قيود المعرفات الجغرافية (Geographic Lookup Constraint Rule):**
   > [!IMPORTANT]
   > في الإصدار الحالي (V1) يتم استخدام النصوص الحرّة (`governorate`, `city`, `district`). ولكن عند الانتقال إلى جداول اللوك أب (Lookup Tables) مستقبلاً، يجب أن تعتمد جميع قواعد العمل (Business Logic) مثل حساب الأسعار، التعيين الآلي للفنيين، والتغطية الجغرافية حصرياً على الـ `IDs`. وتُستخدم النصوص الحرّة فقط لأغراض العرض والواجهات (Display Purposes). يمنع منعاً باتاً كتابة أي منطق أعمال يعتمد على النصوص الحرّة بعد تفعيل Lookup Tables.

2. **النص المجهز للبحث السريع (`searchable_text`):**
   حقل تنفيذي تنشئه وتديره بنية النظام تلقائياً (**Internal System-Managed Field**).
   - **قواعد معمارية:**
     - يتم توليده تلقائياً بواسطة النظام عبر دمج (المحافظة + المدينة + الحي + الشارع + المبنى + المعلم البارز).
     - لا يمكن للمستخدم تعديله نهائياً.
     - يمنع كتابة أي منطق أعمال (Business Logic) يعتمد على `searchable_text`.
     - الغرض الوحيد منه هو تحسين أداء الفهرسة والبحث السريع (Full-Text Search & Indexing).

3. **مصدر الإحداثيات الجغرافية (`coordinates_source`):**
   حقل مستقبلي اختياري لتتبع كيفية التقاط الإحداثيات لتحسين الجودة والتحليلات:
   - `manual` (إدخال يدوي أو تحريك الدبوس)
   - `gps` (التقاط عبر GPS الجهاز الحالي)
   - `map_picker` (اختيار من البحث في Google Places)
   - `imported` (استيراد من أنظمة CRM ومؤسسات)

4. **بيانات التدقيق للحذف المرن (Soft Delete Audit Metadata):**
   إضافة حقول تدقيق مستقبلية في جداول العناوين:
   - `deleted_by` (UUID الخاص بالمستخدم أو الآدمن أو النظام الذي قام بالحذف)
   - `deleted_reason` (سبب الحذف: طلب العميل، دمج سجلات، تنظيف بيانات مكررة)

5. **التوسع الجغرافي والمؤسسي:**
   دعم الإسكندرية وجميع المحافظات، بالإضافة للعملاء الأفراد والمكاتب والشركات والمؤسسات (Enterprise Customers).

---

## 13. Data Privacy & Security Architecture (سرية البيانات وخصوصية العناوين)

> [!IMPORTANT]
> **قاعدة حماية البيانات الشخصية والأمان المعماري (Address Data Privacy & PII Rule):**
> تلتزم منصة Fresh Home بتصنيف وتأمين بيانات العناوين الخاصة بالعملاء وفق أعلى معايير الخصوصية الدولية والقوانين المنظمة لحماية البيانات الشخصية.

### أ. تصنيف البيانات الشخصية الحساسة (PII Classification)
تُصنف الحقول التالية صراحةً كبيانات شخصية محدِدة للهوية **(PII - Personally Identifiable Information)**:
* `floor`
* `apartment_or_unit`
* `landmark`
* `latitude`
* `longitude`

### ب. حظر طباعة البيانات في السجلات التشخيصية (Log Masking Contract)
* **يُمنع منعاً باتاً** ظهور الحقول أعلاه بنص صريح (Plain Text) في أي سجل من سجلات التطبيق (Application Logs)، أو أنظمة تتبع الأخطاء مثل (Sentry, Datadog)، أو أدوات التحليلات (Analytics Streams).
* يجب أن تلتزم دالة `Address.toString()` أو أي Formatter مخصص للسجلات بتعمية وتكميم (Masking) القيم الحساسة:
  ```
  Apartment: ***
  Floor: ***
  Latitude: ***
  Longitude: ***
  ```
* لا يجوز لأي سجل تشخيص أو تقرير أخطاء استلام كائن العنوان كاملاً بصيغته المكشوفة.

> **ملاحظة معمارية:** هذه القاعدة تعتبر **قانوناً معمارياً ثابتاً (Architectural Rule)** وليس مجرد تفصيل تنفيذي ثانوي.

### ج. التحكم في الوصول على مستوى قاعدة البيانات (Row Level Security - RLS)
يُحظر الوصول المباشر لجداول العناوين بدون سياسات أمان صريحة. تعتمد قاعدة البيانات في Supabase على سياسات **Row Level Security (RLS)** لضمان وصول العنوان الكامل فقط إلى:
1. **صاحب العنوان (Address Owner):** المطابق لـ `auth.uid() = user_id`.
2. **الفني المخصص للطلب (Assigned Technician):** المعين رسمياً على طلب فعال مرتبطة به لقطة العنوان.
3. **المستخدمين الإداريين المصرّح لهم (Authorized Administrative Users):** أصحاب الصلاحيات المعتمدة في لوحة التحكم Admin Dashboard.

---

## 14. Non-Goals / Postponed Features (الميزات المؤجلة عمداً لـ V1)

الميزات التالية تم استبعادها **عمداً وتأجيلها** من الإصدار V1 لتبسيط الواجهات وتقليل الاحتكاك:
* ❌ `Property Type` (نوع العقار: شقة / فيلا / كومباوند)
* ❌ `Elevator Status` (وجود حالة المصعد)
* ❌ `Gate Instructions` (تعليمات الأمن والبوّابات)
* ❌ `Address Notes` (ملاحظات العنوان العائمة)
* ❌ `Address Label` (وسم العنوان: منزل / عمل / بيت العائلة)
* ❌ `Compound Entity` (كيان منمط مستقل للكومباوند)
* ❌ `Contact Information` داخل نموذج العنوان (بيانات التواصل تظل منفصلة في كيان `Contact`).
