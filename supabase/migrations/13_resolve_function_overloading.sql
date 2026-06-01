-- ==============================================================================
-- Fresh Home: Resolve Function Overloading Conflict (PGRST203)
-- Description: Drop the old 6-parameter version of transition_booking to resolve
--              ambiguity for PostgREST when the 7-parameter version is used.
-- ==============================================================================

-- 1. حذف النسخة القديمة ذات الـ 6 معاملات
-- ملاحظة: النسخة الأحدث (7 معاملات) التي تم إنشاؤها في 10_smart_assignment.sql
-- ستقوم بمعالجة كافة الاستدعاءات الحالية والمستقبلية نظراً لأن المعامل السابع له قيمة افتراضية (DEFAULT NULL).
DROP FUNCTION IF EXISTS public.transition_booking(
    UUID,                -- p_booking_id
    public.order_status_v2, -- p_new_status
    UUID,                -- p_actor_id
    TEXT,                -- p_actor_role
    TEXT,                -- p_reason
    TEXT                 -- p_notes
);

COMMENT ON FUNCTION public.transition_booking(UUID, public.order_status_v2, UUID, TEXT, TEXT, TEXT, UUID) 
IS 'Central transition engine (7-params). Handles status changes, admin overrides, and auto-reassignment logic.';
