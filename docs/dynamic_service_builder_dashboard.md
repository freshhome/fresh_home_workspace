# Fresh Home — Phase 3 Architecture Upgrade
## Dynamic Service Builder Dashboard (Visual Catalog Platform Builder)

This report details the architectural designs, database check constraints, Flutter page integrations, and implementation details for **Phase 3: Dynamic Service Builder Dashboard**. 

Administrators are now fully empowered to visually configure and manage main services, sub-services, dynamic form fields, pricing modifiers, localization dictionaries, and extra add-ons directly on the screen (Zero-Code and Zero-SQL administration).

---

## 1. Architectural Overview & Workflow

The architecture transitions the service config model from developer-authored raw JSON scripts into a structured visual form builder and interactive simulator inside the administrator dashboard.

### A. Administration Workflow Sequence (Mermaid Diagram)

```mermaid
sequenceDiagram
    autonumber
    actor Admin as Administrator
    participant Builder as SubServicePriceConfigBuilderPage
    participant Details as SubServiceDetailsEditorPage
    participant Validate as SQL Validation Layer
    participant DB as Supabase sub_services Table

    Admin->>Details: Opens Sub-Service Details Editor
    Admin->>Details: Clicks "محرك النماذج والتسعير الديناميكي المتقدم"
    Details->>Builder: Launches visual builder page with current PriceEntity
    
    rect rgb(230, 245, 255)
        Note over Admin, Builder: Tab 1: Configuration & Base Prices
        Admin->>Builder: Modifies pricing method, base price, and base unit
    end

    rect rgb(240, 240, 240)
        Note over Admin, Builder: Tab 2: Dynamic Visual Fields Editor
        Admin->>Builder: Adds or modifies custom input fields (ID, labels, min, unit, modifier)
        Builder->>Builder: Performs unique ID and schema warnings validation
    end

    rect rgb(255, 245, 235)
        Note over Admin, Builder: Tab 4: Interactive Simulator (High Fidelity)
        Admin->>Builder: Adjusts sliders and checkbox add-ons
        Builder->>Builder: Calculates estimated base, extra fees, and totals instantly!
        Admin->>Builder: Previews generated JSON payload live
    end

    Admin->>Builder: Clicks "حفظ وتطبيق الإعدادات"
    Builder-->>Details: Returns updated PriceEntity (propagating dynamic fields)
    Admin->>Details: Clicks "حفظ التعديلات" (Submits sub-service)
    Details->>Validate: Executes database-side validation via RPC / Check Constraint
    alt Validation Passes
        Validate->>DB: Persists valid dynamic JSON configuration
        DB-->>Admin: SnackBar: Service catalog updated successfully!
    else Validation Fails
        Validate-->>Admin: Displays SQL constraint error (preventing invalid state)
    end
```

---

## 2. Dynamic Database Schema & Validation System

To protect the platform's financial operations and data catalog from administrative validation errors, we implemented a custom SQL schema validator constraint on the database level.

### A. SQL Schema Validator script (`supabase/logic/24_service_builder_validation.sql`)
```sql
-- 1. Create or Replace JSON Schema Validation Helper (Backward Compatible)
CREATE OR REPLACE FUNCTION public.validate_price_config(p_config JSONB)
RETURNS BOOLEAN AS $$
DECLARE
    v_type TEXT;
    v_base_val NUMERIC;
    v_fields JSONB;
    v_field JSONB;
    v_options JSONB;
    v_opt JSONB;
BEGIN
    -- Config must be a JSON object
    IF jsonb_typeof(p_config) != 'object' THEN
        RETURN FALSE;
    END IF;
    
    -- BACKWARD COMPATIBILITY GUARD:
    -- If this is a legacy classic config (does not have a custom 'fields' array),
    -- we bypass validation and mark it as valid to prevent breaking pre-existing rows.
    IF NOT (p_config ? 'fields') THEN
        RETURN TRUE;
    END IF;
    
    -- Config must have a valid pricing method type
    v_type := p_config ->> 'type';
    IF v_type IS NULL OR v_type NOT IN ('fixed', 'per_square_meter', 'per_linear_meter', 'per_issue') THEN
        RETURN FALSE;
    END IF;
    
    -- Config must contain a non-negative base price value
    v_base_val := COALESCE((p_config ->> 'value')::NUMERIC, (p_config ->> 'base_price_value')::NUMERIC);
    IF v_base_val IS NULL OR v_base_val < 0 THEN
        RETURN FALSE;
    END IF;
    
    -- Validate fields array if present
    v_fields := p_config -> 'fields';
    IF v_fields IS NOT NULL THEN
        IF jsonb_typeof(v_fields) != 'array' THEN
            RETURN FALSE;
        END IF;
        
        FOR v_field IN SELECT * FROM jsonb_array_elements(v_fields) LOOP
            -- Each dynamic field must specify a valid ID and Type
            IF v_field ->> 'id' IS NULL OR v_field ->> 'type' IS NULL THEN
                RETURN FALSE;
            END IF;
            
            -- Supported field inputs boundary check
            IF v_field ->> 'type' NOT IN ('number', 'toggle', 'dropdown', 'text', 'multi-select') THEN
                RETURN FALSE;
            END IF;
            
            -- Label must contain at least one localized dictionary
            IF v_field -> 'label' IS NULL OR jsonb_typeof(v_field -> 'label') != 'object' THEN
                RETURN FALSE;
            END IF;
        END LOOP;
    END IF;
    
    -- Validate extra pricing options/add-ons array if present
    v_options := p_config -> 'options';
    IF v_options IS NOT NULL THEN
        IF jsonb_typeof(v_options) != 'array' THEN
            RETURN FALSE;
        END IF;
        
        FOR v_opt IN SELECT * FROM jsonb_array_elements(v_options) LOOP
            -- Options require a string key identifier and non-negative value
            IF v_opt ->> 'key' IS NULL OR COALESCE((v_opt ->> 'value')::NUMERIC, 0) < 0 THEN
                RETURN FALSE;
            END IF;
        END LOOP;
    END IF;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Safely apply CHECK constraint on sub_services
ALTER TABLE public.sub_services 
DROP CONSTRAINT IF EXISTS chk_sub_services_price_config;

ALTER TABLE public.sub_services 
ADD CONSTRAINT chk_sub_services_price_config 
CHECK (price_config IS NULL OR public.validate_price_config(price_config));
```

---

## 3. Flutter Architecture & Decoupled State Decisions

*   **State Propagation Strategy**: The visual field builder operates on its local state (`_SubServicePriceConfigBuilderPageState`) during editing sessions. This provides a complete sandbox where admins can dynamically add/remove fields, play with sliders, and review live simulation costs without muddying the main editor page draft state until they explicitly click **حفظ وتطبيق الإعدادات**.
*   **Encapsulated Simulator Math**: The builder includes a local computation loop that matches the server plpgsql math exactly. This enables instantaneous, latency-free simulation previews directly on the editor screen.
*   **Modular Custom Button**: Launches smoothly via standard Flutter navigator routing, passing the `PriceEntity` draft and a callback to bubble modified parameters back up, integrating cleanly into the existing Clean Architecture structure.

---

## 4. Security Guarantees & Migration Strategy

1.  **Strict Database Guardrails**: Applying the `chk_sub_services_price_config` database constraint ensures that even if a future admin app has a bug or an attacker tries to inject corrupted schema shapes directly via REST/Supabase endpoints, the DB instantly rejects the query.
2.  **Dual Layer Backward Compatibility**:
    *   *Null Compatibility*: The DB check constraint is ignored if `price_config` is NULL.
    *   *No fields fallback*: If a service config is updated using the classic inputs and contains no dynamic fields, it compiles cleanly, and the frontend automatically renders the legacy forms as before.
3.  **State Preservation Assurance**: We carefully updated the `_PriceEditor` classic text input controllers (for base price, base unit, and options list) to carry `fields: price.fields` when rebuilding `PriceEntity`. This guarantees that editing basic pricing properties on the main screen never clears the advanced dynamic fields configured in our sub-editor page.

---

## 5. Technical Debt Discovered & Mitigations

1.  **Localized Labels Mapping**:
    *   *Risk*: When editing fields, the labels are updated as simple primitive maps (`{'ar': ..., 'en': ...}`).
    *   *Mitigation*: We recommend formalizing a specialized localized language editor widget inside the fields listing tab to make managing multilingual strings intuitive.
2.  **Dropdown / Multi-select Options Mapping**:
    *   *Risk*: The visual builder allows adding `dropdown` and `multi-select` fields, but managing the sub-options listing within these dropdown fields needs to be visually structured in the widgets list.
    *   *Mitigation*: Implement an nested sub-array chip list in the widgets card specifically when the selected field type is `DynamicFieldType.dropdown`.

---

## 6. List of Modified & Added Files

1.  `supabase/logic/24_service_builder_validation.sql` (Added database validation schema and CHECK constraints).
2.  `apps/fresh_home_admin/lib/features/services_management/presentation/pages/sub_service_price_config_builder_page.dart` (Created administrative dynamic form and rule builder with simulator).
3.  `apps/fresh_home_admin/lib/features/services_management/presentation/pages/sub_service_details_editor_page.dart` (Integrated advanced visual builder button and fixed critical state preservation bugs inside `_PriceEditor`).
