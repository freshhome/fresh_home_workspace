-- ==============================================================================
-- Fresh Home: Core Schema (v2.2)
-- Description: Base Identities, Roles, and Service Definitions
-- ==============================================================================

-- 1. EXTENSIONS & TYPES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DO $$ BEGIN
    CREATE TYPE account_status AS ENUM ('active', 'pending', 'suspended', 'banned');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE gender_type AS ENUM ('male', 'female', 'unspecified');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE service_status AS ENUM ('draft', 'review', 'ready', 'active', 'paused', 'archived');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- 2. CORE IDENTITY TABLES
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    gender gender_type DEFAULT 'unspecified',
    avatar_url TEXT,
    account_status account_status DEFAULT 'active',
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.roles (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

INSERT INTO public.roles (name) VALUES ('client'), ('technician'), ('admin') ON CONFLICT (name) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.user_roles (
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    role_id INTEGER REFERENCES public.roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. CONTACT SYSTEM
CREATE TABLE IF NOT EXISTS public.user_phones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    phone_number TEXT NOT NULL,
    is_primary BOOLEAN DEFAULT false,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.user_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    governorate TEXT NOT NULL,
    city TEXT NOT NULL,
    street TEXT NOT NULL,
    building_number TEXT NOT NULL,
    floor TEXT,
    apartment TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. SERVICE DEFINITIONS
CREATE TABLE IF NOT EXISTS public.main_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title JSONB NOT NULL,
    description JSONB NOT NULL,
    image TEXT,
    status service_status DEFAULT 'active',
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.sub_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    main_service_id UUID REFERENCES public.main_services(id) ON DELETE CASCADE,
    title JSONB NOT NULL,
    description JSONB NOT NULL,
    image TEXT,
    status service_status DEFAULT 'active',
    price_config JSONB NOT NULL,
    details JSONB DEFAULT '[]'::JSONB,
    not_included JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. TECHNICIAN PROFILES
CREATE TABLE IF NOT EXISTS public.technician_profiles (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    bio TEXT,
    rating DECIMAL(3,2) DEFAULT 5.0,
    completed_jobs INT DEFAULT 0,
    is_verified BOOLEAN DEFAULT false,
    is_available BOOLEAN DEFAULT false,
    service_area JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
