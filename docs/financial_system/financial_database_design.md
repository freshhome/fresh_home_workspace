# تصميم قواعد البيانات المالي المقترح (Financial Database Design)

## سجل المراجعة والتعديلات (Revision History)

| الإصدار (Version) | التاريخ (Date) | التفاصيل (Details) | الحالة (Status) |
| :--- | :--- | :--- | :--- |
| `v1.0 - Initial` | 2026-06-10 | التصميم المالي الأولي للجداول والفهارس وسياسات RLS. | مؤرشف |
| `v1.1 - Revision v1` | 2026-06-10 | إزالة حقل `net_balance` كعمود فيزيائي وتحويله لعمود افتراضي، وإضافة جدول `financial_adjustments` مع ربطه بجدول القيود المالية، وإضافة حقل `account_status` ومقيد التحقق الخاص به وتحديث سياسات الحماية والفهارس. | **معتمد ونشط** |

---

## 1. الهيكل الجدولي المقترح (Proposed Table Schemas)

### أ. جدول حساب الفني المالي (`technician_financial_accounts`)
يخزن تفاصيل الحساب المالي الإجمالي لكل فني وحالته التشغيلية.

| اسم الحقل (Column Name) | نوع البيانات (Data Type) | القيود والصفات (Constraints / Attributes) | الوصف والشرح (Description) |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | المعرف الفريد للحساب المالي. |
| `technician_id` | `UUID` | `UNIQUE`, `REFERENCES public.profiles(id) ON DELETE CASCADE` | المعرف الشخصي للفني. |
| `amount_owed_to_company` | `NUMERIC(12,2)` | `NOT NULL`, `DEFAULT 0.00`, `CHECK (amount_owed_to_company >= 0.00)` | المبالغ النقدية المحصلة والواجب سدادها للشركة (الدين). |
| `amount_owed_to_technician` | `NUMERIC(12,2)` | `NOT NULL`, `DEFAULT 0.00`, `CHECK (amount_owed_to_technician >= 0.00)` | الأرباح الإلكترونية المحتجزة للتحويل للفني. |
| `debt_limit` | `NUMERIC(12,2)` | `NOT NULL`, `DEFAULT 1000.00`, `CHECK (debt_limit >= 0.00)` | سقف الدين الأقصى المسموح به. |
| `account_status` | `TEXT` | `NOT NULL`, `DEFAULT 'active'`, `CHECK (account_status IN ('active', 'restricted', 'blocked'))` | **[جديد في Revision v1]** الحالة المالية والتشغيلية للفني. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT now()` | تاريخ إنشاء الحساب. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT now()` | تاريخ آخر تحديث للحساب. |

> [!TIP]
> **الاحتساب الديناميكي لصافي الرصيد (Dynamic net_balance):**
> يتم احتساب صافي الرصيد الجاري `net_balance` ديناميكياً على مستوى محرك الاستعلامات أو عبر **Generated Column (Virtual)** بداخل الجدول بالمعادلة التالية:
> `net_balance NUMERIC(12,2) GENERATED ALWAYS AS (amount_owed_to_technician - amount_owed_to_company) STORED;` (أو احتسابها كـ Virtual / View).

---

### ب. جدول التعديلات المالية الإدارية (`financial_adjustments`) **[جديد في Revision v1]**
يخزن تفاصيل الحوافز والخصومات التي يدخلها المسؤولون، ويخضع لموافقة واعتماد المدير المالي قبل كتابته في دفتر الأستاذ.

| اسم الحقل (Column Name) | نوع البيانات (Data Type) | القيود والصفات (Constraints / Attributes) | الوصف والشرح (Description) |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | المعرف الفريد لطلب التعديل. |
| `technician_id` | `UUID` | `NOT NULL`, `REFERENCES public.profiles(id) ON DELETE CASCADE` | الفني المرتبط بالتعديل. |
| `amount` | `NUMERIC(12,2)` | `NOT NULL`, `CHECK (amount > 0.00)` | القيمة المادية للتعديل (يجب أن تكون قيمة موجبة مطلقاً). |
| `adjustment_type` | `TEXT` | `NOT NULL`, `CHECK (adjustment_type IN ('bonus', 'penalty', 'adjustment'))` | تصنيف التعديل المالي. |
| `reason` | `TEXT` | `NOT NULL` | السبب العام للتعديل (يعرض للفني). |
| `notes` | `TEXT` | `NULLABLE` | ملاحظات داخلية سرية للإدارة والمدراء الماليين. |
| `attachment_url` | `TEXT` | `NULLABLE` | رابط ملف أو صورة إثبات مرفقة بالتعديل. |
| `status` | `TEXT` | `NOT NULL`, `DEFAULT 'pending'`, `CHECK (status IN ('pending', 'approved', 'rejected'))` | حالة المراجعة والاعتماد. |
| `created_by` | `UUID` | `NOT NULL`, `REFERENCES public.profiles(id) ON DELETE SET NULL` | الموظف الذي أنشأ الطلب. |
| `approved_by` | `UUID` | `NULLABLE`, `REFERENCES public.profiles(id) ON DELETE SET NULL` | المدير المالي الذي اعتمد الطلب أو رفضه. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT now()` | تاريخ إنشاء الطلب. |
| `approved_at` | `TIMESTAMPTZ` | `NULLABLE` | تاريخ المراجعة والاعتماد. |

---

### ج. جدول دفتر الأستاذ المعزز (`ledger_entries`)
يخزن القيود المالية التاريخية الدقيقة. **يمنع التحديث أو الحذف نهائياً.**

| اسم الحقل (Column Name) | نوع البيانات (Data Type) | القيود والصفات (Constraints / Attributes) | الوصف والشرح (Description) |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | المعرف الفريد للقيد المالي. |
| `account_id` | `UUID` | `NOT NULL`, `REFERENCES public.technician_financial_accounts(id) ON DELETE RESTRICT` | الحساب المالي المرتبط بالفني. |
| `booking_id` | `UUID` | `NULLABLE`, `REFERENCES public.bookings(id) ON DELETE SET NULL` | رقم الحجز المرتبط بالمعاملة (إن وجد). |
| `adjustment_id` | `UUID` | `NULLABLE`, `REFERENCES public.financial_adjustments(id) ON DELETE SET NULL` | **[جديد في Revision v1]** التعديل الإداري الذي أنتج هذا القيد. |
| `entry_type` | `TEXT` | `NOT NULL`, `CHECK (entry_type IN ('order_earnings', 'company_commission_debit', 'cash_collection_debit', 'manual_bonus', 'manual_penalty', 'manual_adjustment', 'settlement_reconciliation'))` | تصنيف المعاملة المالية. |
| `debit` | `NUMERIC(12,2)` | `NOT NULL`, `DEFAULT 0.00`, `CHECK (debit >= 0.00)` | القيمة المدينة (الخصم/تخفيض الرصيد). |
| `credit` | `NUMERIC(12,2)` | `NOT NULL`, `DEFAULT 0.00`, `CHECK (credit >= 0.00)` | القيمة الدائنة (الإضافة/زيادة الرصيد). |
| `running_balance` | `NUMERIC(12,2)` | `NOT NULL` | صافي الرصيد الكلي بعد هذا القيد مباشرة. |
| `description` | `TEXT` | `NOT NULL` | شرح تفصيلي لسبب المعاملة المالية. |
| `created_by` | `UUID` | `NULLABLE`, `REFERENCES public.profiles(id) ON DELETE SET NULL` | المعرف الشخصي للمسؤول الذي أجرى القيد. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT now()` | تاريخ تسجيل المعاملة. |

> [!CAUTION]
> قيد التحقق الخاص بدفتر الأستاذ:
> `CONSTRAINT chk_ledger_entry_values CHECK ((debit > 0.00 AND credit = 0.00) OR (credit > 0.00 AND debit = 0.00))`

---

### د. جدول طلبات التسوية المالية (`settlement_requests`)
يخزن عمليات تسوية النقدية وتحويل المستحقات.

| اسم الحقل (Column Name) | نوع البيانات (Data Type) | القيود والصفات (Constraints / Attributes) | الوصف والشرح (Description) |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | المعرف الفريد للطلب. |
| `technician_id` | `UUID` | `NOT NULL`, `REFERENCES public.profiles(id) ON DELETE CASCADE` | الفني صاحب الطلب. |
| `amount` | `NUMERIC(12,2)` | `NOT NULL`, `CHECK (amount > 0.00)` | القيمة المالية المطلوب تسويتها. |
| `method` | `TEXT` | `NOT NULL`, `CHECK (method IN ('vodafone_cash', 'instapay', 'bank_transfer', 'cash_handover', 'other'))` | وسيلة التحويل أو السداد. |
| `proof_image_url` | `TEXT` | `NOT NULL` | صورة إثبات المعاملة المرفوعة. |
| `status` | `TEXT` | `NOT NULL`, `DEFAULT 'pending'`, `CHECK (status IN ('pending', 'approved', 'rejected'))` | حالة الطلب الإدارية. |
| `admin_notes` | `TEXT` | `NULLABLE` | سبب الرفض أو ملاحظات إضافية من الإدارة. |
| `reviewed_by` | `UUID` | `NULLABLE`, `REFERENCES public.profiles(id) ON DELETE SET NULL` | المسؤول المراجع للطلب. |
| `reviewed_at` | `TIMESTAMPTZ` | `NULLABLE` | تاريخ المراجعة والتحقق. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT now()` | تاريخ تقديم طلب التسوية. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT now()` | تاريخ التحديث الأخير للطلب. |

---

### هـ. جدول القضايا والخلافات المالية (`financial_cases`)
يخزن النزاعات المالية والفروقات للطلبات.

| اسم الحقل (Column Name) | نوع البيانات (Data Type) | القيود والصفات (Constraints / Attributes) | الوصف والشرح (Description) |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | المعرف الفريد للقضية. |
| `booking_id` | `UUID` | `NOT NULL`, `UNIQUE`, `REFERENCES public.bookings(id) ON DELETE CASCADE` | الحجز المرتبط بالقضية المالية. |
| `reported_by` | `UUID` | `NOT NULL`, `REFERENCES public.profiles(id) ON DELETE SET NULL` | الشخص الذي قام بالتبليغ. |
| `discrepancy_type` | `TEXT` | `NOT NULL`, `CHECK (discrepancy_type IN ('refused_full_payment', 'partial_completion', 'admin_approved_discount', 'pricing_dispute', 'collection_discrepancy'))` | نوع الخلاف المالي. |
| `expected_amount` | `NUMERIC(12,2)` | `NOT NULL`, `CHECK (expected_amount >= 0.00)` | القيمة المالية المفترضة. |
| `collected_amount` | `NUMERIC(12,2)` | `NOT NULL`, `CHECK (collected_amount >= 0.00)` | القيمة المالية الفعلية المحصلة نقدياً. |
| `description` | `TEXT` | `NOT NULL` | شرح ووصف تفصيلي للحادثة. |
| `status` | `TEXT` | `NOT NULL`, `DEFAULT 'pending_review'`, `CHECK (status IN ('pending_review', 'in_investigation', 'resolved', 'dismissed'))` | حالة دراسة الخلاف. |
| `resolution_notes` | `TEXT` | `NULLABLE` | تفاصيل الحل النهائي والإجراء المتخذ. |
| `resolved_by` | `UUID` | `NULLABLE`, `REFERENCES public.profiles(id) ON DELETE SET NULL` | المسؤول الذي قام بفض النزاع. |
| `resolved_at` | `TIMESTAMPTZ` | `NULLABLE` | تاريخ تسجيل حل القضية. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT now()` | تاريخ تسجيل وتوليد القضية. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT now()` | تاريخ تحديث السجل المالي. |

---

### و. جدول سجل أحداث القضايا المالية (`financial_case_events`)
يخزن تفاصيل التحقيق الإداري وتغير الحالات ليكون بمثابة سجل تتبع وتدقيق للمنازعات المالية.

| اسم الحقل (Column Name) | نوع البيانات (Data Type) | القيود والصفات (Constraints / Attributes) | الوصف والشرح (Description) |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | المعرف الفريد للحدث. |
| `case_id` | `UUID` | `NOT NULL`, `REFERENCES public.financial_cases(id) ON DELETE CASCADE` | القضية المرتبطة. |
| `event_type` | `TEXT` | `NOT NULL` | نوع الحدث. |
| `actor_id` | `UUID` | `NOT NULL`, `REFERENCES public.profiles(id) ON DELETE SET NULL` | الشخص الذي قام بالإجراء. |
| `notes` | `TEXT` | `NOT NULL` | الملاحظات والتفاصيل المدونة. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT now()` | تاريخ وقوع الحدث وتسجيله. |

---

## 2. استراتيجية الفهرسة والتسريع (Index Strategy)

لضمان كفاءة عالية وسرعة استرجاع البيانات المالية وتخفيض استهلاك موارد قاعدة البيانات، يوصى بإنشاء الفهارس التالية:

1.  **فهرس البحث عن الحساب المالي للفني:**
    *   `CREATE UNIQUE INDEX idx_tech_financial_accounts_tech_id ON public.technician_financial_accounts(technician_id);`
2.  **فهرس متداخل لدفتر الأستاذ (البحث والترتيب التاريخي):**
    *   `CREATE INDEX idx_ledger_entries_lookup ON public.ledger_entries(account_id, created_at DESC);`
3.  **فهرس البحث عن طلبات التعديل الإدارية للفني:** **[جديد في Revision v1]**
    *   `CREATE INDEX idx_financial_adjustments_tech_status ON public.financial_adjustments(technician_id, status);`
    *   *لتسهيل جلب الحوافز والعقوبات الخاصة بكل فني والتحقق من حالتها.*
4.  **فهرس البحث عن تسويات الفني المعلقة:**
    *   `CREATE INDEX idx_settlement_requests_tech_status ON public.settlement_requests(technician_id, status);`
5.  **فهرس القضايا المالية والحجوزات:**
    *   `CREATE INDEX idx_financial_cases_booking_id ON public.financial_cases(booking_id);`

---

## 3. سياسات حماية البيانات وأمن قاعدة البيانات (RLS Strategy)

يجب تفعيل **Row Level Security (RLS)** بشكل إلزامي على جميع الجداول المالية لمنع تسرب البيانات وضمان أمن العمليات:

### أ. سياسات جدول `technician_financial_accounts`:
*   **للمدراء (Admin):** صلاحيات كاملة (SELECT, INSERT, UPDATE).
*   **للفنيين (Technician):** يُسمح فقط بعملية `SELECT` للسجل الخاص به:
    *   `USING (technician_id = auth.uid())`
*   **العملاء (Client):** حظر كامل لكافة العمليات (No Access).

### ب. سياسات جدول `financial_adjustments` **[جديد في Revision v1]**:
*   **للمدراء (Admin):** صلاحيات كاملة لقراءة وإنشاء وتحديث الحالات.
*   **للفنيين (Technician):** يُسمح فقط بـ `SELECT` لطلبات التعديل الخاصة به والموافق عليها أو المعلقة:
    *   `USING (technician_id = auth.uid())`
*   **العملاء (Client):** حظر كامل.

### ج. سياسات جدول `ledger_entries`:
*   **للمدراء (Admin):** صلاحيات `SELECT` و `INSERT` فقط. **تحديث أو حذف البيانات ممنوع تماماً للجميع لضمان عدم القابلية للتغيير.**
*   **للفنيين (Technician):** يُسمح فقط بعملية `SELECT` للقيود الخاصة بحسابه:
    *   `USING (account_id IN (SELECT id FROM public.technician_financial_accounts WHERE technician_id = auth.uid()))`
*   **العملاء (Client):** حظر كامل لكافة العمليات.

### د. سياسات جدول `settlement_requests`:
*   **للمدراء (Admin):** صلاحيات كاملة لقراءة وتحديث حالات الطلبات.
*   **للفنيين (Technician):** 
    *   `SELECT`: للطلبات التابعة له فقط (`technician_id = auth.uid()`).
    *   `INSERT`: لإنشاء طلب جديد باسمه مع فرض الحالة مبدئياً كـ `'pending'`.
    *   `UPDATE` / `DELETE`: ممنوع تماماً بمجرد إنشاء الطلب لتفادي التلاعب بالبيانات.

### هـ. سياسات جدول `financial_cases` و `financial_case_events`:
*   **للمدراء (Admin):** صلاحيات وصول وتعديل وحل كاملة.
*   **للفنيين (Technician):**
    *   يُسمح بعمليات `SELECT` فقط للقضايا المرتبطة بحجوزات تم تعيينهم لها:
        *   `USING (booking_id IN (SELECT id FROM public.bookings WHERE technician_id = auth.uid()))`
*   **العملاء (Client):**
    *   يُسمح بعمليات `SELECT` فقط للقضايا المرتبطة بالحجوزات التي قاموا بطلبها بأنفسهم:
        *   `USING (booking_id IN (SELECT id FROM public.bookings WHERE user_id = auth.uid()))`
