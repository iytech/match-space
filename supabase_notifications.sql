-- ============================================================================
-- IN-APP NOTIFICATIONS
-- Creates the notifications table + triggers that auto-generate notifications
-- when: a message is sent, a viewing is requested or its status changes, and
-- a listing is approved or rejected. Run once in your SQL editor.
-- ============================================================================

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null,                 -- message | booking | bookingUpdate | listingApproved | listingRejected | review | system
  title text not null,
  body text not null default '',
  route text,                         -- app route to open on tap
  route_arg text,                     -- argument for that route
  read boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_notifications_user on public.notifications(user_id, created_at desc);

-- Realtime: make sure the table is in the realtime publication.
alter publication supabase_realtime add table public.notifications;

-- RLS: users see and update only their own notifications.
alter table public.notifications enable row level security;

drop policy if exists "notifications read own" on public.notifications;
create policy "notifications read own" on public.notifications
  for select using (user_id = auth.uid());

drop policy if exists "notifications update own" on public.notifications;
create policy "notifications update own" on public.notifications
  for update using (user_id = auth.uid());

-- Inserts happen from SECURITY DEFINER triggers below, so no insert policy is
-- needed for clients (they never insert directly).

-- ---------------------------------------------------------------------------
-- 1) New message -> notify the OTHER participant in the conversation
-- ---------------------------------------------------------------------------
create or replace function public.notify_on_message()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  recipient uuid;
  sender_name text;
begin
  select case when c.user_a = new.sender_id then c.user_b else c.user_a end
    into recipient
  from public.conversations c where c.id = new.conversation_id;

  select full_name into sender_name from public.profiles where id = new.sender_id;

  if recipient is not null then
    insert into public.notifications (user_id, kind, title, body, route)
    values (
      recipient, 'message',
      coalesce(sender_name, 'Someone') || ' sent you a message',
      left(new.body, 120),
      '/messages'
    );
  end if;
  return new;
end; $$;

drop trigger if exists trg_notify_message on public.messages;
create trigger trg_notify_message
  after insert on public.messages
  for each row execute function public.notify_on_message();

-- ---------------------------------------------------------------------------
-- 2) Viewing booking requested -> notify the OWNER
-- ---------------------------------------------------------------------------
create or replace function public.notify_on_booking()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  requester_name text;
  prop_title text;
begin
  select full_name into requester_name from public.profiles where id = new.requester_id;
  select title into prop_title from public.properties where id = new.property_id;

  insert into public.notifications (user_id, kind, title, body, route, route_arg)
  values (
    new.owner_id, 'booking',
    'New viewing request',
    coalesce(requester_name, 'Someone') || ' requested to view ' ||
      coalesce(prop_title, 'your property'),
    '/bookings', new.property_id::text
  );
  return new;
end; $$;

drop trigger if exists trg_notify_booking on public.viewing_bookings;
create trigger trg_notify_booking
  after insert on public.viewing_bookings
  for each row execute function public.notify_on_booking();

-- ---------------------------------------------------------------------------
-- 3) Booking status change -> notify the REQUESTER
-- ---------------------------------------------------------------------------
create or replace function public.notify_on_booking_update()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  prop_title text;
begin
  if new.status is distinct from old.status then
    select title into prop_title from public.properties where id = new.property_id;
    insert into public.notifications (user_id, kind, title, body, route, route_arg)
    values (
      new.requester_id, 'bookingUpdate',
      'Viewing ' || new.status,
      'Your viewing request for ' || coalesce(prop_title, 'a property') ||
        ' was ' || new.status || '.',
      '/bookings', new.property_id::text
    );
  end if;
  return new;
end; $$;

drop trigger if exists trg_notify_booking_update on public.viewing_bookings;
create trigger trg_notify_booking_update
  after update on public.viewing_bookings
  for each row execute function public.notify_on_booking_update();

-- ---------------------------------------------------------------------------
-- 4) Listing approved / rejected -> notify the OWNER
-- ---------------------------------------------------------------------------
create or replace function public.notify_on_listing_status()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status is distinct from old.status then
    if new.status = 'approved' then
      insert into public.notifications (user_id, kind, title, body, route, route_arg)
      values (new.owner_id, 'listingApproved', 'Listing approved',
        '"' || new.title || '" is now live on Match Space.',
        '/property', new.id::text);
    elsif new.status = 'rejected' then
      insert into public.notifications (user_id, kind, title, body, route)
      values (new.owner_id, 'listingRejected', 'Listing not approved',
        '"' || new.title || '" was not approved. Review and resubmit.',
        '/owner');
    end if;
  end if;
  return new;
end; $$;

drop trigger if exists trg_notify_listing_status on public.properties;
create trigger trg_notify_listing_status
  after update on public.properties
  for each row execute function public.notify_on_listing_status();
