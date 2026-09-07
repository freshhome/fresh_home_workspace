-- ==============================================================================
-- Migration: 103_seed_full_egypt_districts_and_admin_rls.sql
-- Description: Seed complete Cairo and Giza districts from EgyptGeographicHierarchy
--              and enable administrative CRUD Row-Level Security policies.
-- ==============================================================================

BEGIN;

-- 1. ADMIN RLS POLICIES FOR REFERENCE TABLES (GOVERNORATES, CITIES, DISTRICTS)
-- Allow Admins to INSERT, UPDATE, and DELETE geographic reference data

DROP POLICY IF EXISTS "Allow admin full access on governorates" ON public.governorates;
CREATE POLICY "Allow admin full access on governorates"
ON public.governorates
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Allow admin full access on cities" ON public.cities;
CREATE POLICY "Allow admin full access on cities"
ON public.cities
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Allow admin full access on districts" ON public.districts;
CREATE POLICY "Allow admin full access on districts"
ON public.districts
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- 2. SEED COMPLETE DISTRICTS FOR ALL CAIRO CITIES
-- Zamalek (101)
INSERT INTO public.districts (city_id, name_ar, name_en, is_active, sort_order)
VALUES
    (101, 'شارع 26 يوليو', '26th of July St', true, 1),
    (101, 'شارع أبو الفدا', 'Abu El Feda St', true, 2),
    (101, 'شارع البرازيل', 'Brazil St', true, 3),
    (101, 'شارع حسن صبري', 'Hassan Sabry St', true, 4),
    (101, 'شارع الجزيرة', 'Gezira St', true, 5)
ON CONFLICT (city_id, name_ar) DO UPDATE SET
    name_en = EXCLUDED.name_en,
    is_active = EXCLUDED.is_active;

-- Garden City (102)
INSERT INTO public.districts (city_id, name_ar, name_en, is_active, sort_order)
VALUES
    (102, 'شارع قصر العيني', 'Qasr El Aini St', true, 1),
    (102, 'شارع كورنيش النيل', 'Corniche El Nil', true, 2),
    (102, 'ميدان سيمون بوليفار', 'Simon Bolivar Sq', true, 3)
ON CONFLICT (city_id, name_ar) DO UPDATE SET
    name_en = EXCLUDED.name_en,
    is_active = EXCLUDED.is_active;

-- Maadi (103)
INSERT INTO public.districts (city_id, name_ar, name_en, is_active, sort_order)
VALUES
    (103, 'المعادي القديمة', 'Old Maadi', true, 1),
    (103, 'دجلة المعادي', 'Degla Maadi', true, 2),
    (103, 'سرايات المعادي', 'Sarayat Maadi', true, 3),
    (103, 'زهراء المعادي', 'Zahraa Maadi', true, 4),
    (103, 'كورنيش المعادي', 'Maadi Corniche', true, 5),
    (103, 'أوتوستراد المعادي', 'Maadi Autostrad', true, 6)
ON CONFLICT (city_id, name_ar) DO UPDATE SET
    name_en = EXCLUDED.name_en,
    is_active = EXCLUDED.is_active;

-- Heliopolis / مصر الجديدة (104)
INSERT INTO public.districts (city_id, name_ar, name_en, is_active, sort_order)
VALUES
    (104, 'الكوربة', 'Korba', true, 1),
    (104, 'روكسي', 'Roxy', true, 2),
    (104, 'هيليوبوليس', 'Heliopolis', true, 3),
    (104, 'ميدان تريومف', 'Triumph Sq', true, 4),
    (104, 'النزهة الجديدة', 'New Nozha', true, 5),
    (104, 'أرض الجولف', 'Ard El Golf', true, 6),
    (104, 'شيراتون المطار', 'Sheraton Heliopolis', true, 7),
    (104, 'ميدان الحجاز', 'Hegaz Sq', true, 8)
ON CONFLICT (city_id, name_ar) DO UPDATE SET
    name_en = EXCLUDED.name_en,
    is_active = EXCLUDED.is_active;

-- Fifth Settlement / التجمع الخامس (105) (Additional)
INSERT INTO public.districts (city_id, name_ar, name_en, is_active, sort_order)
VALUES
    (105, 'جنوب الأكاديمية', 'South Academy', true, 11)
ON CONFLICT (city_id, name_ar) DO UPDATE SET
    name_en = EXCLUDED.name_en,
    is_active = EXCLUDED.is_active;

-- New Cairo / القاهرة الجديدة (106) (Additional)
INSERT INTO public.districts (city_id, name_ar, name_en, is_active, sort_order)
VALUES
    (106, 'بيت الوطن', 'Beit El Watan', true, 5),
    (106, 'المستثمرين الشمالية', 'North Investors', true, 6),
    (106, 'المستثمرين الجنوبية', 'South Investors', true, 7),
    (106, 'منطقة التمر حنة', 'Tamr Henna Area', true, 8)
ON CONFLICT (city_id, name_ar) DO UPDATE SET
    name_en = EXCLUDED.name_en,
    is_active = EXCLUDED.is_active;

-- Rehab / الرحاب (107)
INSERT INTO public.districts (city_id, name_ar, name_en, is_active, sort_order)
VALUES
    (107, 'المرحلة الأولى', 'First Phase', true, 1),
    (107, 'المرحلة الثانية', 'Second Phase', true, 2),
    (107, 'منطقة الفيلات 1', 'Villas Zone 1', true, 3),
    (107, 'منطقة الفيلات 2', 'Villas Zone 2', true, 4),
    (107, 'السوق التجاري', 'Commercial Market', true, 5)
ON CONFLICT (city_id, name_ar) DO UPDATE SET
    name_en = EXCLUDED.name_en,
    is_active = EXCLUDED.is_active;

-- Madinaty / مدينتي (108)
INSERT INTO public.districts (city_id, name_ar, name_en, is_active, sort_order)
VALUES
    (108, 'منطقة B1', 'Zone B1', true, 1),
    (108, 'منطقة B2', 'Zone B2', true, 2),
    (108, 'منطقة B3', 'Zone B3', true, 3),
    (108, 'منطقة B6', 'Zone B6', true, 4),
    (108, 'منطقة B8', 'Zone B8', true, 5),
    (108, 'منطقة B10', 'Zone B10', true, 6),
    (108, 'منطقة B11', 'Zone B11', true, 7),
    (108, 'منطقة B12', 'Zone B12', true, 8),
    (108, 'منطقة الفيلات VG1', 'Villas Zone VG1', true, 9),
    (108, 'منطقة الفيلات VG2', 'Villas Zone VG2', true, 10),
    (108, 'منطقة الفيلات VG3', 'Villas Zone VG3', true, 11)
ON CONFLICT (city_id, name_ar) DO UPDATE SET
    name_en = EXCLUDED.name_en,
    is_active = EXCLUDED.is_active;

-- Nasr City / مدينة نصر (109)
INSERT INTO public.districts (city_id, name_ar, name_en, is_active, sort_order)
VALUES
    (109, 'المنطقة الأولى', 'First District', true, 1),
    (109, 'المنطقة السادسة', 'Sixth District', true, 2),
    (109, 'الحي السابع', 'Seventh District', true, 3),
    (109, 'الحي الثامن', 'Eighth District', true, 4),
    (109, 'الحي العاشر', 'Tenth District', true, 5),
    (109, 'شارع مكرم عبيد', 'Makram Ebeid St', true, 6),
    (109, 'شارع عباس العقاد', 'Abbas El Akkad St', true, 7),
    (109, 'شارع الطيران', 'Tayaran St', true, 8),
    (109, 'زهراء مدينة نصر', 'Zahraa Nasr City', true, 9)
ON CONFLICT (city_id, name_ar) DO UPDATE SET
    name_en = EXCLUDED.name_en,
    is_active = EXCLUDED.is_active;

-- Mokattam / المقطم (110)
INSERT INTO public.districts (city_id, name_ar, name_en, is_active, sort_order)
VALUES
    (110, 'الهضبة العليا', 'Upper Plateau', true, 1),
    (110, 'الهضبة الوسطى', 'Middle Plateau', true, 2),
    (110, 'شارع 9 الرئيسي', 'Street 9', true, 3),
    (110, 'حي الأسمرات', 'Asmarat District', true, 4)
ON CONFLICT (city_id, name_ar) DO UPDATE SET
    name_en = EXCLUDED.name_en,
    is_active = EXCLUDED.is_active;

-- Shorouk / الشروق (111)
INSERT INTO public.districts (city_id, name_ar, name_en, is_active, sort_order)
VALUES
    (111, 'الحي الأول شرق', 'First District East', true, 1),
    (111, 'الحي الثاني شرق', 'Second District East', true, 2),
    (111, 'الحي الثالث غرب', 'Third District West', true, 3),
    (111, 'حي النادي', 'Nadi District', true, 4),
    (111, 'منطقة الفيلات', 'Villas Area', true, 5)
ON CONFLICT (city_id, name_ar) DO UPDATE SET
    name_en = EXCLUDED.name_en,
    is_active = EXCLUDED.is_active;

-- 3. SEED COMPLETE DISTRICTS FOR ALL GIZA CITIES
-- Zayed / الشيخ زايد (201) (Additional)
INSERT INTO public.districts (city_id, name_ar, name_en, is_active, sort_order)
VALUES
    (201, 'الحي الثاني عشر', 'Twelfth District', true, 8),
    (201, 'الحي السادس عشر', 'Sixteenth District', true, 9),
    (201, 'كمبوند الياسمين', 'Yasmine Compound', true, 10),
    (201, 'كمبوند الكرما', 'Karma Compound', true, 11)
ON CONFLICT (city_id, name_ar) DO UPDATE SET
    name_en = EXCLUDED.name_en,
    is_active = EXCLUDED.is_active;

-- 6th of October / 6 أكتوبر (202) (Additional)
INSERT INTO public.districts (city_id, name_ar, name_en, is_active, sort_order)
VALUES
    (202, 'الحي السابع', 'Seventh District', true, 8),
    (202, 'الحي الثامن', 'Eighth District', true, 9),
    (202, 'الحي المتميز', 'Motamayez District', true, 10),
    (202, 'حدائق أكتوبر', 'October Gardens', true, 11),
    (202, 'أكتوبر الجديدة', 'New October', true, 12)
ON CONFLICT (city_id, name_ar) DO UPDATE SET
    name_en = EXCLUDED.name_en,
    is_active = EXCLUDED.is_active;

-- Mohandessin / المهندسين (203)
INSERT INTO public.districts (city_id, name_ar, name_en, is_active, sort_order)
VALUES
    (203, 'شارع جامعة الدول العربية', 'Gamaat El Dowal St', true, 1),
    (203, 'شارع البطل أحمد عبد العزيز', 'Batal Ahmed Abdel Aziz St', true, 2),
    (203, 'شارع شهاب', 'Shehab St', true, 3),
    (203, 'شارع سوريا', 'Syria St', true, 4),
    (203, 'شارع لبنان', 'Lebanon St', true, 5),
    (203, 'ميدان سفنكس', 'Sphinx Sq', true, 6),
    (203, 'شارع جزيرة العرب', 'Gezirat El Arab St', true, 7),
    (203, 'شارع السودان', 'Sudan St', true, 8)
ON CONFLICT (city_id, name_ar) DO UPDATE SET
    name_en = EXCLUDED.name_en,
    is_active = EXCLUDED.is_active;

-- Dokki / الدقي (204)
INSERT INTO public.districts (city_id, name_ar, name_en, is_active, sort_order)
VALUES
    (204, 'شارع مصدق', 'Mossadak St', true, 1),
    (204, 'شارع التحرير', 'Tahrir St', true, 2),
    (204, 'شارع محيي الدين أبو العز', 'Mohie El Din Abu El Ezz St', true, 3),
    (204, 'ميدان المساحة', 'Mesaha Sq', true, 4),
    (204, 'شارع إيران', 'Iran St', true, 5),
    (204, 'شارع وزارة الزراعة', 'Ministry of Agriculture St', true, 6)
ON CONFLICT (city_id, name_ar) DO UPDATE SET
    name_en = EXCLUDED.name_en,
    is_active = EXCLUDED.is_active;

-- Agouza / العجوزة (205)
INSERT INTO public.districts (city_id, name_ar, name_en, is_active, sort_order)
VALUES
    (205, 'شارع النيل', 'Nile St', true, 1),
    (205, 'شارع عبد المنعم رياض', 'Abdel Moneim Riad St', true, 2),
    (205, 'شارع شاهين', 'Shaheen St', true, 3),
    (205, 'ميدان أسوان', 'Aswan Sq', true, 4),
    (205, 'شارع الفالوجا', 'Falouja St', true, 5)
ON CONFLICT (city_id, name_ar) DO UPDATE SET
    name_en = EXCLUDED.name_en,
    is_active = EXCLUDED.is_active;

-- Hadayek Al Ahram / حدائق الأهرام (206)
INSERT INTO public.districts (city_id, name_ar, name_en, is_active, sort_order)
VALUES
    (206, 'البوابة الأولى (خوفو)', 'First Gate (Khufu)', true, 1),
    (206, 'البوابة الثانية (خفرع)', 'Second Gate (Khafre)', true, 2),
    (206, 'البوابة الثالثة (منقرع)', 'Third Gate (Menkaure)', true, 3),
    (206, 'البوابة الرابعة (مينا)', 'Fourth Gate (Mina)', true, 4),
    (206, 'منطقة أ', 'Zone A', true, 5),
    (206, 'منطقة ب', 'Zone B', true, 6),
    (206, 'منطقة ج', 'Zone C', true, 7),
    (206, 'منطقة د', 'Zone D', true, 8),
    (206, 'منطقة هـ', 'Zone E', true, 9),
    (206, 'منطقة ع', 'Zone Ein', true, 10)
ON CONFLICT (city_id, name_ar) DO UPDATE SET
    name_en = EXCLUDED.name_en,
    is_active = EXCLUDED.is_active;

-- Haram / الهرم (207)
INSERT INTO public.districts (city_id, name_ar, name_en, is_active, sort_order)
VALUES
    (207, 'شارع الهرم الرئيسي', 'Haram Main St', true, 1),
    (207, 'شارع العريش', 'Arish St', true, 2),
    (207, 'شارع ضياء', 'Deyaa St', true, 3),
    (207, 'شارع الطالبية', 'Talbiya St', true, 4),
    (207, 'شارع مدكور', 'Madkour St', true, 5),
    (207, 'شارع حسن محمد', 'Hassan Mohamed St', true, 6),
    (207, 'شارع ترسا (خاتم المرسلين)', 'Tersa St', true, 7)
ON CONFLICT (city_id, name_ar) DO UPDATE SET
    name_en = EXCLUDED.name_en,
    is_active = EXCLUDED.is_active;

-- Faisal / فيصل (208)
INSERT INTO public.districts (city_id, name_ar, name_en, is_active, sort_order)
VALUES
    (208, 'شارع فيصل الرئيسي', 'Faisal Main St', true, 1),
    (208, 'شارع العشرين', 'Eshreen St', true, 2),
    (208, 'شارع المحطة', 'Mahatta St', true, 3),
    (208, 'شارع التعاون', 'Taawon St', true, 4),
    (208, 'شارع المساحة فيصل', 'Mesaha Faisal St', true, 5)
ON CONFLICT (city_id, name_ar) DO UPDATE SET
    name_en = EXCLUDED.name_en,
    is_active = EXCLUDED.is_active;

-- Imbaba / إمبابة (209)
INSERT INTO public.districts (city_id, name_ar, name_en, is_active, sort_order)
VALUES
    (209, 'شارع الوحدة', 'Wehda St', true, 1),
    (209, 'شارع طلعت حرب', 'Talaat Harb St', true, 2),
    (209, 'شارع القومية العربية', 'Qawmiya Arabiya St', true, 3),
    (209, 'شارع النيل إمبابة', 'Nile Imbaba St', true, 4),
    (209, 'أرض الجمعية', 'Ard El Gameya', true, 5)
ON CONFLICT (city_id, name_ar) DO UPDATE SET
    name_en = EXCLUDED.name_en,
    is_active = EXCLUDED.is_active;

-- 4. RESET IDENTITY SEQUENCE TO PREVENT ID CONFLICTS
SELECT setval(
    pg_get_serial_sequence('public.districts', 'id'),
    COALESCE((SELECT MAX(id) FROM public.districts), 1)
);

COMMIT;
