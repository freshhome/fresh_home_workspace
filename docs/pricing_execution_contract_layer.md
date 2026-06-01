# Fresh Home — Enterprise Pricing Engine Upgrade
## Phase 4 Step 2.5: Pricing Execution Contract Layer & Traceability

This document details the architectural specifications, unified contract schema, centralized controller, and high-fidelity trace audit trails for the **Phase 4 Step 2.5: Pricing Execution Contract Layer** of the Fresh Home platform.

---

## 1. What was the Fragmented Legacy State?

Previously, while we separated the pricing pipeline into 5 stages, the orchestration and execution remained logically fragmented:
*   **Variable stack dispersion**: Parameters were passed as disparate variables or unstructured inputs, which made rule tracing nearly impossible.
*   **Logical ordering ambiguity**: The orchestration depended on manual inline updates where stages could easily be reordered or bypassed, creating financial auditing risks.
*   **Opaque calculations**: Price calculations occurred in independent siloes without a unified tracing audit trail, making debugging and admin transparency difficult.

---

## 2. What is the New Execution Contract Layer?

We designed and implemented a **Deterministic Financial Execution Pipeline with Full Traceability** centered around three core concepts:

### A. The Unified Pricing Context Contract (`JSONB`):
A single immutable contract object that represents the shared state flowing sequentially through the pipeline stages:
```json
{
  "base_price": 0.0,
  "subtotal": 0.0,
  "extra_fees": 0.0,
  "discount": 0.0,
  "applied_rules": [],
  "applied_discounts": [],
  "selected_options": [],
  "execution_trace": [],
  "pricing_inputs": {}
}
```

### B. Decoupled Dynamic Stage Functions:
Each of our 5 stages is completely decoupled:
*   `stage_1_calculate_base_pricing(p_sub_service_id UUID, p_price_config JSONB, p_context JSONB) RETURNS JSONB`
*   `stage_2_apply_conditional_rules(p_sub_service_id UUID, p_context JSONB) RETURNS JSONB`
*   `stage_3_apply_options(p_sub_service_id UUID, p_price_config JSONB, p_context JSONB) RETURNS JSONB`
*   `stage_4_apply_discounts(p_sub_service_id UUID, p_context JSONB) RETURNS JSONB`
*   `stage_5_finalize_pricing(p_sub_service_id UUID, p_context JSONB) RETURNS JSONB`

Every stage:
1.  **Accepts a context copy**.
2.  **Performs calculation logic only**.
3.  **Appends structured logs** to the `execution_trace` array.
4.  **Returns the updated context contract copy** without altering global state or calculating final total independently.

---

## 3. Detailed Execution Traceability & Logging

To ensure 100% auditing transparency, every action, rule evaluation, and option aggregation writes a structured log to the context's `execution_trace` field:

### Sample Execution Trace Audit Array:
```json
[
  {
    "stage": "stage_1_base_pricing",
    "action": "calculate_base",
    "before": 0,
    "after": 150,
    "details": "Calculated base pricing based on catalog metadata."
  },
  {
    "stage": "stage_2_rules",
    "rule_id": "78c9ea24-9b24-4f28-a3f2-124b892a0149",
    "rule_name": "Premium Area Surcharge",
    "action": "multiply",
    "target": "subtotal",
    "before": 150,
    "after": 180
  },
  {
    "stage": "stage_3_options",
    "option_key": "furnished_cleaning",
    "action": "add",
    "before": 0,
    "after": 45
  },
  {
    "stage": "stage_4_discounts",
    "action": "evaluate",
    "before": 0,
    "after": 0,
    "details": "Discount stack evaluated (no active promo codes found)."
  },
  {
    "stage": "stage_5_finalize",
    "action": "aggregate_totals",
    "subtotal": 180,
    "extra_fees": 45,
    "discount": 0,
    "total": 225
  }
]
```
These logs are packed cleanly into the transaction `metadata` field, meaning they are saved directly with every transaction in the database and visible to any admin transparency dashboard!

---

## 4. Zero-Downtime Compatibility Assurances

To prevent any breaking changes:
1.  **The Public Bridge**: `calculate_booking_price(...)` remains structurally unchanged. It calls the orchestrator controller internally, extracts finalized totals, and returns the exact same camelCase layout expected by Flutter.
2.  **Transactional Booking Preservation**: `create_atomic_booking(...)` is fully preserved. It automatically benefits from the new pipeline engine trace logs and transaction integrity guarantees.

---

## 5. Next Steps & Recommendations

With this deterministic execution contract layer established, the system is now **100% ready for the dynamic discounts engine (Phase 4 Step 3)**. We can easily implement coupons and promo validation rules inside Stage 4, matching all business and marketing requirements.
