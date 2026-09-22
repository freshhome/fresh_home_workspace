-- ==============================================================================
-- Fresh Home: Convert Service Instructions to Multilingual Points Array
-- Migration ID: 112_convert_instructions_to_points_array
-- Description: Convert instructions in services table from plain text/object
-- to a list of bullet points {"ar": [...], "en": [...]}.
-- Backward compatibility: Existing non-empty string instructions are converted
-- into the first element of the points list.
-- ==============================================================================

BEGIN;

-- 1. Update existing services records safely
UPDATE public.services
SET instructions = jsonb_build_object(
    'ar', CASE 
        -- If already an array, keep it as is
        WHEN jsonb_typeof(instructions->'ar') = 'array' THEN instructions->'ar'
        -- If a non-empty string, convert it into the first element of the points array
        WHEN jsonb_typeof(instructions->'ar') = 'string' AND trim(instructions->>'ar') != '' 
            THEN jsonb_build_array(trim(instructions->>'ar'))
        -- Otherwise, empty array
        ELSE '[]'::jsonb
    END,
    'en', CASE 
        -- If already an array, keep it as is
        WHEN jsonb_typeof(instructions->'en') = 'array' THEN instructions->'en'
        -- If a non-empty string, convert it into the first element of the points array
        WHEN jsonb_typeof(instructions->'en') = 'string' AND trim(instructions->>'en') != '' 
            THEN jsonb_build_array(trim(instructions->>'en'))
        -- Otherwise, empty array
        ELSE '[]'::jsonb
    END
)
WHERE instructions IS NOT NULL;

-- 2. Alter column default for instructions to ensure future inserts have empty arrays
ALTER TABLE public.services 
    ALTER COLUMN instructions SET DEFAULT '{"ar": [], "en": []}'::jsonb;

COMMIT;
