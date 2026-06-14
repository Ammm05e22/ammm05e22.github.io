-- ============================================================
-- Relationship Clarity Dashboard — additive schema
-- Layered on top of supabase-schema.sql (profiles + auth + RLS).
-- Run this in your Supabase SQL Editor.
-- ============================================================

-- 1. PEOPLE -----------------------------------------------------
create table if not exists public.people (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    display_name text not null,
    relationship_type text,
    avatar_url text,
    notes text,
    archived boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
create index if not exists people_user_idx on public.people(user_id) where archived = false;

-- 2. ENTRIES ----------------------------------------------------
create table if not exists public.entries (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    person_id uuid references public.people(id) on delete cascade,
    raw_text text not null,
    occurred_at timestamptz not null default now(),
    created_at timestamptz not null default now()
);
create index if not exists entries_person_time_idx on public.entries(person_id, occurred_at desc);
create index if not exists entries_user_time_idx on public.entries(user_id, occurred_at desc);

-- 3. ENTRY_ANALYSIS --------------------------------------------
-- Separate table so analysis can be retried/versioned without rewriting entries.
create table if not exists public.entry_analysis (
    id uuid primary key default gen_random_uuid(),
    entry_id uuid not null references public.entries(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    model text,
    payload jsonb not null,
    created_at timestamptz not null default now()
);
create index if not exists entry_analysis_entry_idx on public.entry_analysis(entry_id, created_at desc);

-- 4. SCORES (current snapshot per person) -----------------------
create table if not exists public.scores (
    person_id uuid primary key references public.people(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    emotional_safety numeric not null default 50,
    consistency numeric not null default 50,
    reciprocity numeric not null default 50,
    growth_alignment numeric not null default 50,
    integrity numeric not null default 50,
    attraction numeric not null default 50,
    composite numeric not null default 50,
    status text not null default 'Watchlist',
    last_updated timestamptz not null default now()
);

-- 5. SCORE_HISTORY (append-only, for the trend chart) -----------
create table if not exists public.score_history (
    id uuid primary key default gen_random_uuid(),
    person_id uuid not null references public.people(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    composite numeric not null,
    axes jsonb not null,
    entry_id uuid references public.entries(id) on delete set null,
    created_at timestamptz not null default now()
);
create index if not exists score_history_person_time_idx on public.score_history(person_id, created_at desc);

-- 6. BOUNDARIES (non-negotiables) -------------------------------
create table if not exists public.boundaries (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    text text not null,
    sort_order int not null default 0,
    created_at timestamptz not null default now()
);
create index if not exists boundaries_user_idx on public.boundaries(user_id, sort_order);

-- 7. WEEKLY_SUMMARIES ------------------------------------------
create table if not exists public.weekly_summaries (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    person_id uuid references public.people(id) on delete cascade,
    iso_week text not null,
    payload jsonb not null,
    created_at timestamptz not null default now(),
    unique (person_id, iso_week)
);

-- 8. USER_SETTINGS ---------------------------------------------
create table if not exists public.user_settings (
    user_id uuid primary key references auth.users(id) on delete cascade,
    discipline_mode boolean not null default false,
    discipline_triggers jsonb not null default '[]'::jsonb,
    ai_server_url text,
    timezone text default 'UTC',
    updated_at timestamptz not null default now()
);

-- 9. RLS --------------------------------------------------------
alter table public.people           enable row level security;
alter table public.entries          enable row level security;
alter table public.entry_analysis   enable row level security;
alter table public.scores           enable row level security;
alter table public.score_history    enable row level security;
alter table public.boundaries       enable row level security;
alter table public.weekly_summaries enable row level security;
alter table public.user_settings    enable row level security;

-- Owner-only policy pattern, mirroring profiles policies.
do $$
declare t text;
begin
    for t in select unnest(array[
        'people','entries','entry_analysis','scores',
        'score_history','boundaries','weekly_summaries','user_settings'
    ])
    loop
        execute format($f$
            drop policy if exists "%1$s owner select" on public.%1$s;
            create policy "%1$s owner select" on public.%1$s
                for select to authenticated using (auth.uid() = user_id);

            drop policy if exists "%1$s owner insert" on public.%1$s;
            create policy "%1$s owner insert" on public.%1$s
                for insert to authenticated with check (auth.uid() = user_id);

            drop policy if exists "%1$s owner update" on public.%1$s;
            create policy "%1$s owner update" on public.%1$s
                for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

            drop policy if exists "%1$s owner delete" on public.%1$s;
            create policy "%1$s owner delete" on public.%1$s
                for delete to authenticated using (auth.uid() = user_id);
        $f$, t);
    end loop;
end $$;

-- 10. updated_at triggers (reuse handle_updated_at from base schema)
drop trigger if exists people_updated_at on public.people;
create trigger people_updated_at
    before update on public.people
    for each row execute function public.handle_updated_at();

drop trigger if exists user_settings_updated_at on public.user_settings;
create trigger user_settings_updated_at
    before update on public.user_settings
    for each row execute function public.handle_updated_at();
