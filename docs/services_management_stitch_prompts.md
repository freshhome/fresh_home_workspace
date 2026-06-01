# دليل إعادة تصميم واجهة إدارة الخدمات (Services Management UI Redesign Guide)

يركز هذا المستند على إعادة هيكلة وتصميم تجربة المستخدم (UI/UX) الخاصة بـ **إدارة الخدمات (Services Management)** في تطبيق الأدمن.

بناءً على مراجعة ملف الألوان الأساسي الخاص بالتطبيق [theme_colors.dart](file:///d:/fresh_home_workspace/packages/shared/lib/presentation/theme/components/colors/theme_colors.dart) ونظام اللغات (RTL)، تم تحديث جميع برومبتات التصميم لتوجيه أداة [Google Stitch](https://stitch.withgoogle.com/) لتوليد شاشات بالخصائص التالية:
- **الوضع الفاتح (Light Mode):** باستخدام لوحة الألوان الرسمية للبراند.
- **اللغة العربية (Arabic Language):** اتجاه واجهات من اليمين إلى اليسار (RTL) وباستخدام خط "Cairo".
- **التماشي مع البزنس:** نصوص وبيانات حقيقية مستوحاة مباشرة من خدمات مشروع Fresh Home (نظافة، سباكة، تكييف، أسعار بالريال السعودي SAR).

---

## 🎨 لوحة ألوان الهوية البصرية الرسمية (المضمنة في البرومبتات):
- **اللون الأساسي (Primary Blue):** `#0D327D` (أزرق داكن فخم للأزرار والـ AppBars والترويسات).
- **اللون الثانوي/النجاح (Secondary Green):** `#2ECC71` (أخضر حيوي لحالات النشاط وعلامات الصح).
- **تدرج الأزرار (Accent Gradient):** من الأزرق الداكن `#0D327D` إلى الأزرق السماوي `#22A5FC`.
- **الخلفية العامة (Background):** Slate Off-White `#F8FAFC`.
- **خلفية البطاقات (Card Background):** أبيض ناصع `#FFFFFF`.
- **الخطوط (Typography):** خط عربي حديث (Cairo) متناسق مع خط إنجليزي (Outfit/Inter).

---

## 1. مستكشف الخدمات الموحد (Unified Services Explorer)

### 📌 الهدف من الشاشة:
تجميع شاشات (فئات الخدمات والخدمات الفرعية) في شاشة واحدة منقسمة (Split-Screen) تتيح للمشرف رؤية الهيكل الشجري الكامل للخدمات باللغة العربية مع لوحة تفاصيل سريعة لكل خدمة محددة.

### 📝 البرومبت الخاص بـ Google Stitch:

```text
Create a premium, modern Light-Theme split-pane SaaS Dashboard UI for a "Unified Service Catalog Explorer" in a home services admin app.

Global Styling & Color Palette (Strictly Light Mode):
- Primary Brand Color: Deep Navy Blue (#0D327D) used for primary headers, active states, and major buttons.
- Secondary Accent: Bright Emerald Green (#2ECC71) used for active status indicators and success states.
- Button Gradients: Smooth transition from Deep Blue (#0D327D) to Cyan/Light Blue (#22A5FC).
- Base Background: Subtle Slate Off-White (#F8FAFC).
- Card Panel Backgrounds: Pure White (#FFFFFF) with very soft shadows (Color: #000000, 5% opacity, blur: 40px, offset: 0px 8px).
- Text Colors: Pitch black (#000000) for main headers, Slate Grey (#757575) for secondary/subtitle text.
- Typography: Use "Cairo" font for all Arabic text and "Outfit" for numbers.

Layout & RTL Specifications:
- The screen direction must be Right-to-Left (RTL) for Arabic language.
- Split-pane layout:
  1. Right Pane (Sidebar, width ~35%): Interactive hierarchical tree view labeled "دليل الخدمات".
     - Showing parent service categories: "خدمات التنظيف" (Cleaning), "خدمات السباكة" (Plumbing), "صيانة التكييف" (AC Maintenance).
     - Nested sub-services under "خدمات التنظيف": "التنظيف العميق للمنازل" (Deep Cleaning), "التنظيف الدوري" (Regular Cleaning), "تنظيف بعد التشطيب" (Post-construction).
     - Dashed guide lines indicating hierarchy level.
     - Drag-and-drop handle icons for reordering.
     - Badges indicating status: "نشط" (Active with green dot), "متوقف مؤقتاً" (Paused with orange dot), "مسودة" (Draft with grey dot).
     - Floating Action Button at the top: "+ إضافة تصنيف جديد".

  2. Left Pane (Detail View, width ~65%): Detailed preview card of the selected sub-service: "التنظيف العميق للمنازل".
     - Header: A beautiful light gradient card with a circular avatar container for a clean service icon.
     - Title: "التنظيف العميق للمنازل" (Bold 24px, #0D327D).
     - Description: "خدمة تنظيف شاملة وعميقة تشمل غسيل السجاد والستائر وتلميع الأرضيات وإزالة الدهون المستعصية." (14px, #757575).
     - Quick Stats Row (3 cards):
       - Card 1: "إجمالي الحجوزات" -> "١,٢٥٠ حجز"
       - Card 2: "الإيرادات" -> "٣٥,٠٠٠ ر.س"
       - Card 3: "الفنيين النشطين" -> "١٤ فني"
     - Pricing Box: "السعر الأساسي: ١٥٠ ر.س / ساعة" (using unit tag styled as secondary green outline).
     - Action Bar at the bottom: Secondary button "تعديل التفاصيل والتضمينات" (Edit Details), primary gradient button "ضبط محرك الأسعار" (Configure Price Engine), and outline warning button "أرشفة الخدمة" (Archive).

Ensure premium micro-interactions, clean spacing, and modern flat icons.
```

---

## 2. معالج إعداد وتفاصيل الخدمة (Unified Service Configurator Wizard)

### 📌 الهدف من الشاشة:
نموذج خطوات موحد باللغة العربية لإدخال وتعديل تفاصيل الخدمة (ما تشمله، ما لا تشمله، التعليمات، التراخيص) في صفحة واحدة مقسمة هندسياً.

### 📝 البرومبت الخاص بـ Google Stitch:

```text
Design a high-fidelity Light-Theme Stepper Wizard UI for configuring and editing Service details.

Global Styling & Color Palette (Strictly Light Mode):
- Primary Color: Deep Navy Blue (#0D327D) for completed step indicators and primary buttons.
- Secondary Accent: Emerald Green (#2ECC71) for checkmarks and success states.
- Base Background: Slate Off-White (#F8FAFC) with White (#FFFFFF) card panels.
- Border colors: Light Grey (#E2E8F0) with focus state glow.
- Typography: Use "Cairo" font for Arabic texts and "Outfit" for steps numbers.
- Text Direction: Right-to-Left (RTL).

Layout Structure:
1. Top Stepper (Horizontal Progress Bar):
   - Step 1: "المعلومات الأساسية" (Basic Info) - Completed state with a green checkmark icon inside a solid circle.
   - Step 2: "التفاصيل والتضمينات" (Inclusions & Details) - Active state with a solid Deep Blue circle and pulsing glow.
   - Step 3: "الاستثناءات والتعليمات" (Exclusions & Instructions) - Pending state with grey outline circle.

2. Content Body (Step 2 View Mockup):
   - Right Card Pane (width 50%): Labeled "ما تشمله الخدمة (التضمينات)".
     - List of items with a circular green checkmark icon:
       1. "تلميع وجلاء جميع أنواع الرخام والسيراميك"
       2. "غسيل السجاد والموكيت بأحدث الماكينات"
       3. "تنظيف وإزالة الدهون من المطابخ والحمامات"
     - Prominent button at the bottom: "+ إضافة نقطة جديدة" (dashed border style, #0D327D text color).
   
   - Left Card Pane (width 50%): Labeled "ما لا تشمله الخدمة (الاستثناءات)".
     - List of items with a circular orange/red X-mark icon:
       1. "إزالة الأنقاض الناتجة عن البناء الكبيرة"
       2. "تنظيف الواجهات الزجاجية الخارجية للأبراج"
     - Button: "+ إضافة استثناء جديد".

3. Sidebar Area (width 30% or bottom stack):
   - Box A: "تعليمات العميل" (Client Instructions) - A large text area with Arabic placeholder text: "يرجى إخلاء الأغراض الثمينة وتأمين مدخل المنزل قبل وصول الفريق..."
   - Box B: "مستندات وتراخيص الخدمة" - Drag-and-drop file uploader zone with a dotted border, showing a PDF document icon and text: "اسحب وأفلت ملف PDF الخاص بالتعليمات هنا أو تصفح الملفات".

4. Footer Action Bar (Sticky Translucent Glassmorphism):
   - Secondary button: "السابق" (Back) in grey outline.
   - Align Right buttons: "حفظ كمسودة" (Save Draft) and "التالي: محرك الأسعار والحقول" (Next: Price Engine & Fields) using the primary blue gradient.

Provide clear visual validation indicators and premium typography hierarchy.
```

---

## 3. محرك التسعير والمحاكي الديناميكي (Dynamic Pricing Engine & Simulator)

### 📌 الهدف من الشاشة:
واجهة متطورة جداً منقسمة لضبط قواعد التسعير وبناء حقول حجز العميل (مساحة، غرف، إضافات) مع محاكاة حية لطريقة عمل النموذج وحساب السعر بالريال السعودي.

### 📝 البرومبت الخاص بـ Google Stitch:

```text
Create a state-of-the-art Light-Theme Dashboard UI for an "Advanced Dynamic Pricing Engine & Client Simulator" in a home services admin app.

Global Styling & Color Palette (Strictly Light Mode):
- Primary Brand Color: Deep Navy Blue (#0D327D) for tabs, headings, and primary buttons.
- Secondary Accent: Emerald Green (#2ECC71) for active checkmarks, positive simulation results, and total prices.
- Base Background: Slate Off-White (#F8FAFC).
- Left Panel Cards: Pure White (#FFFFFF) with crisp thin borders.
- Code preview panel: Dark terminal theme (deep slate/black background #0F172A) for contrast.
- Typography: Use "Cairo" font for Arabic interface and "Fira Code" (monospace) for JSON codes.
- Text Direction: Right-to-Left (RTL) for Arabic language.

Layout Structure (Vertical Split Screen):
1. Right Panel (Pricing & Field Builder - width 55%):
   - Segmented Tabs at the top: "١. قواعد التسعير" (Pricing Rules), "٢. حقول الحجز" (Booking Fields), "٣. الميزات الإضافية" (Add-ons).
   - Under "حقول الحجز" (Booking Fields), list the custom inputs:
     - Field 1 (Number type): ID "area", Label: "المساحة الإجمالية (م²)", Min: 30, Unit: "م²", Modifier: "+ ١.٥ ر.س لكل متر إضافي".
     - Field 2 (Toggle type): ID "heavy_stains", Label: "إزالة البقع والدهون المستعصية", Modifier: "مضاعف السعر x١.٢".
     - Action Button: "+ إضافة حقل حجز مخصص" (using outline Deep Blue style).
   - Under "الميزات الإضافية" (Add-ons) section:
     - Option 1: "استخدام مواد صديقة للبيئة (+٥٠ ر.س)".
     - Option 2: "تعطير وتطهير إضافي للمنزل (+٣٠ ر.س)".

2. Left Panel (Live Client Simulator & JSON Output - width 45%):
   - Title: "محاكي نموذج حجز العميل" (Client Form Simulator).
   - Box A (The Client Mobile View): A realistic light-themed smartphone layout mockup rendering the active form:
     - A slider control for "المساحة الإجمالية" (set to 120 م²).
     - A switch toggle button for "إزالة البقع والدهون المستعصية" (switched ON).
     - Checkboxes for add-ons (with "استخدام مواد صديقة للبيئة" checked).
     - Large animated floating Price box showing live calculation in Arabic: "السعر الأساسي: ٣٠٠ ر.س + الإضافات: ٥٠ ر.س = الإجمالي: ٣٥٠ ر.س" (styled with a large bold font in Emerald Green).
   - Box B (JSON Schema Preview): A clean dark terminal box showing the auto-generated JSON structure, with a "نسخ الكود" (Copy Code) button at the top-right corner.

Ensure rich interactive details, highly refined spacing, and clean dashboard widgets.
```

---

## 📂 كيفية استخدام هذه البرومبتات المعدلة:

1. تم تحديث هذا الملف بالكامل في مسار المشروع: [services_management_stitch_prompts.md](file:///d:/fresh_home_workspace/docs/services_management_stitch_prompts.md).
2. افتح موقع [Stitch by Google](https://stitch.withgoogle.com/).
3. انسخ البرومبت بالكامل لكل شاشة.
4. الصقه في Stitch. سيقوم الآن بتوليد الشاشات باللغة **العربية (RTL)** وبالألوان **الرسمية لـ Fresh Home (أزرق داكن وأخضر وتدرجات سماوية على خلفية فاتحة)** بدلاً من الوضع الداكن واللغة الإنجليزية الافتراضية.
