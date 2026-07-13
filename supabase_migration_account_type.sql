-- ============================================================================
-- MIGRATION: add account_type to an EXISTING profiles table
-- Run this ONCE in your project's SQL editor if you already created the
-- profiles table before account types existed.
-- Safe to run multiple times.
-- ============================================================================

alter table public.profiles
  add column if not exists account_type text not null default 'seeker';

-- Re-apply the signup trigger so new signups store their chosen account type.
-- (Full definition; run supabase_auth_trigger.sql instead if you prefer.)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email, phone, role, account_type, tier)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', 'User'),
    new.email,
    new.raw_user_meta_data->>'phone',
    'user',
    coalesce(new.raw_user_meta_data->>'account_type', 'seeker'),
    'free'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================================
-- Land & lease fields (run if your properties table predates them)
-- ============================================================================
alter table public.properties
  add column if not exists lease_term_years int,
  add column if not exists title_document text;

-- ============================================================================
-- Availability (mark as sold / rented) — run if properties predates it
-- ============================================================================
alter table public.properties
  add column if not exists available boolean not null default true,
  add column if not exists closed_reason text;
