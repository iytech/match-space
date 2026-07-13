-- ============================================================================
-- AUTO-CREATE PROFILE ON SIGNUP
-- Run this ONCE in your new project's SQL editor.
-- This makes a profiles row appear automatically whenever a user signs up,
-- so the client never has to insert it (which is what was failing).
-- ============================================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer            -- runs with elevated rights, bypasses RLS safely
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

-- Drop old trigger if re-running, then create it.
drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
