-- ==============================================================================
-- Fresh Home: Customizable Service Commission & Backend Payout Calculations
-- Migration ID: 58_add_service_commission_rate
-- Description: Adds a commission_rate field per service, and calculates platform commission
--              and technician payout securely on the backend in stage_5_finalize_pricing.
-- ==============================================================================

BEGIN;

-- 1. Add commission_rate column to services table
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS commission_rate NUMERIC DEFAULT 0.20;

-- 2. Add check constraint to ensure commission_rate remains in [0.0, 1.0] range
ALTER TABLE public.services DROP CONSTRAINT IF EXISTS chk_services_commission_rate;
ALTER TABLE public.services ADD CONSTRAINT chk_services_commission_rate CHECK (commission_rate >= 0.0 AND commission_rate <= 1.0);

-- 3. Update stage_5_finalize_pricing function
CREATE OR REPLACE FUNCTION public.stage_5_finalize_pricing(
    p_sub_service_id TEXT,
    p_context JSONB
) RETURNS JSONB AS $$
DECLARE
    v_base_price   NUMERIC;
    v_subtotal     NUMERIC;
    v_extra_fees   NUMERIC;
    v_discount     NUMERIC;
    v_total        NUMERIC;
    v_price_config JSONB;
    v_min_price    NUMERIC;
    v_commission_rate NUMERIC;
    v_platform_commission NUMERIC;
    v_technician_payout NUMERIC;
    
    v_trace        JSONB;
    v_trace_entry  JSONB;
BEGIN
    v_base_price := (p_context ->> 'base_price')::NUMERIC;
    v_subtotal := (p_context ->> 'subtotal')::NUMERIC;
    v_extra_fees := (p_context ->> 'extra_fees')::NUMERIC;
    v_discount := (p_context ->> 'discount')::NUMERIC;
    
    v_trace := COALESCE(p_context -> 'execution_trace', '[]'::JSONB);

    -- Fetch the service's price_config and commission_rate
    SELECT price_config, COALESCE(commission_rate, 0.20) INTO v_price_config, v_commission_rate
    FROM public.services
    WHERE id = p_sub_service_id;

    IF v_price_config IS NOT NULL AND v_price_config ? 'min_price' THEN
        v_min_price := (v_price_config ->> 'min_price')::NUMERIC;
        IF v_min_price IS NOT NULL AND v_min_price > 0.0 AND v_base_price < v_min_price THEN
            -- Add trace entry before clamping base price
            v_trace_entry := jsonb_build_object(
                'stage', 'stage_5_finalize',
                'action', 'apply_min_price_to_base',
                'min_price', v_min_price,
                'before', v_base_price,
                'after', v_min_price,
                'details', 'Clamped base price to the service-specific minimum price limit.'
            );
            v_trace := v_trace || v_trace_entry;
            
            -- Clamp base price
            v_base_price := v_min_price;
            -- Re-evaluate subtotal (subtotal corresponds to the base price of the service)
            v_subtotal := v_base_price;
        END IF;
    END IF;

    -- Recalculate total with the clamped base price
    v_total := v_subtotal + v_extra_fees - v_discount;

    -- Calculate platform commission and technician payout
    -- Commissionable amount is based on subtotal (pre-discount base price) + extra fees
    v_platform_commission := (v_subtotal + v_extra_fees) * v_commission_rate;
    v_technician_payout := (v_subtotal + v_extra_fees) * (1.0 - v_commission_rate);

    v_trace_entry := jsonb_build_object(
        'stage', 'stage_5_finalize',
        'action', 'aggregate_totals',
        'subtotal', v_subtotal,
        'extra_fees', v_extra_fees,
        'discount', v_discount,
        'total', v_total,
        'commission_rate', v_commission_rate,
        'platform_commission', v_platform_commission,
        'technician_payout', v_technician_payout
    );
    v_trace := v_trace || v_trace_entry;

    -- Return the fully unified immutable Pricing Context Contract structure
    RETURN jsonb_build_object(
        'basePrice', v_base_price,
        'extraFees', v_extra_fees,
        'discount', v_discount,
        'total', v_total,
        'metadata', jsonb_build_object(
            'subtotal', v_subtotal,
            'platform_commission', v_platform_commission,
            'technician_payout', v_technician_payout,
            'commission_rate', v_commission_rate,
            'pricing_inputs', p_context -> 'pricing_inputs',
            'options_breakdown', p_context -> 'options_breakdown',
            'applied_rules', p_context -> 'applied_rules',
            'applied_discounts', p_context -> 'applied_discounts',
            'pricing_version_id', p_context -> 'pricing_version_id',
            'execution_trace', v_trace
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
