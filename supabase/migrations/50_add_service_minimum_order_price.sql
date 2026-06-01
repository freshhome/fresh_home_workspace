-- Migration ID: 50_add_service_minimum_order_price
-- Description: Update stage_5_finalize_pricing to support service-level minimum price constraint ('min_price')
-- defined inside the service's price_config. Clamps the final total to min_price if it's lower.

BEGIN;

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
    
    v_trace        JSONB;
    v_trace_entry  JSONB;
BEGIN
    v_base_price := (p_context ->> 'base_price')::NUMERIC;
    v_subtotal := (p_context ->> 'subtotal')::NUMERIC;
    v_extra_fees := (p_context ->> 'extra_fees')::NUMERIC;
    v_discount := (p_context ->> 'discount')::NUMERIC;
    
    v_total := v_subtotal + v_extra_fees - v_discount;
    v_trace := COALESCE(p_context -> 'execution_trace', '[]'::JSONB);

    -- Fetch the service's price_config to check for minimum price limit
    SELECT price_config INTO v_price_config
    FROM public.services
    WHERE id = p_sub_service_id;

    IF v_price_config IS NOT NULL AND v_price_config ? 'min_price' THEN
        v_min_price := (v_price_config ->> 'min_price')::NUMERIC;
        IF v_min_price IS NOT NULL AND v_min_price > 0.0 AND v_total < v_min_price THEN
            -- Add trace entry before clamping
            v_trace_entry := jsonb_build_object(
                'stage', 'stage_5_finalize',
                'action', 'apply_min_price',
                'min_price', v_min_price,
                'before', v_total,
                'after', v_min_price,
                'details', 'Clamped total price to the service-specific minimum price limit.'
            );
            v_trace := v_trace || v_trace_entry;
            
            -- Clamp total
            v_total := v_min_price;
        END IF;
    END IF;

    v_trace_entry := jsonb_build_object(
        'stage', 'stage_5_finalize',
        'action', 'aggregate_totals',
        'subtotal', v_subtotal,
        'extra_fees', v_extra_fees,
        'discount', v_discount,
        'total', v_total
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
