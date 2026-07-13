-- ============================================================================
-- MATCH SPACE — Supabase schema
-- Run this in the Supabase SQL editor for your project.
-- (Project URL in app_config.dart: wdzpcvdhheborukoivgc.supabase.co)
-- ============================================================================

-- PROFILES -------------------------------------------------------------------
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default 'User',
  email text,
  phone text,
  avatar_url text,
  role text not null default 'user',     -- user | owner | admin (permissions)
  account_type text not null default 'seeker', -- seeker | owner | agent
  tier text not null default 'free',     -- free | premium
  created_at timestamptz not null default now()
);

-- PROPERTIES -----------------------------------------------------------------
create table if not exists properties (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  description text default '',
  type text not null default 'house',
  purpose text not null default 'sale',  -- sale | rent | lease
  status text not null default 'pending',-- pending | approved | rejected
  price numeric not null default 0,
  state text,
  city text,
  address text,
  bedrooms int default 0,
  bathrooms int default 0,
  area_sqm numeric default 0,
  lease_term_years int,
  title_document text,
  amenities text[] default '{}',
  featured boolean default false,
  available boolean not null default true,
  closed_reason text,
  view_count int default 0,
  lat double precision,
  lng double precision,
  created_at timestamptz not null default now()
);
create index if not exists idx_properties_status on properties(status);
create index if not exists idx_properties_owner on properties(owner_id);

-- PROPERTY MEDIA -------------------------------------------------------------
create table if not exists property_media (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references properties(id) on delete cascade,
  url text not null,
  is_video boolean default false,
  position int default 0
);

-- CONVERSATIONS + MESSAGES ---------------------------------------------------
create table if not exists conversations (
  id uuid primary key default gen_random_uuid(),
  property_id uuid references properties(id) on delete set null,
  user_a uuid not null references profiles(id) on delete cascade,
  user_b uuid not null references profiles(id) on delete cascade,
  last_message text,
  last_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references conversations(id) on delete cascade,
  sender_id uuid not null references profiles(id) on delete cascade,
  body text not null,
  read boolean default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_messages_convo on messages(conversation_id);

-- conversation_list view: flattens names + unread count for the inbox.
create or replace view conversation_list as
select
  c.*,
  pa.full_name as user_a_name,
  pa.avatar_url as user_a_avatar,
  pb.full_name as user_b_name,
  pb.avatar_url as user_b_avatar,
  p.title as property_title,
  (select pm.url from property_media pm
     where pm.property_id = c.property_id order by pm.position limit 1)
     as property_cover,
  (select count(*) from messages m
     where m.conversation_id = c.id and m.read = false
       and m.sender_id <> auth.uid()) as unread
from conversations c
left join profiles pa on pa.id = c.user_a
left join profiles pb on pb.id = c.user_b
left join properties p on p.id = c.property_id;

-- VIEWING BOOKINGS -----------------------------------------------------------
create table if not exists viewing_bookings (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references properties(id) on delete cascade,
  requester_id uuid not null references profiles(id) on delete cascade,
  owner_id uuid not null references profiles(id) on delete cascade,
  scheduled_for timestamptz not null,
  note text,
  status text not null default 'requested',
  created_at timestamptz not null default now()
);

-- REVIEWS --------------------------------------------------------------------
create table if not exists reviews (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references properties(id) on delete cascade,
  author_id uuid not null references profiles(id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  comment text default '',
  created_at timestamptz not null default now()
);

-- RECENTLY VIEWED + FAVORITES ------------------------------------------------
create table if not exists recently_viewed (
  user_id uuid not null references profiles(id) on delete cascade,
  property_id uuid not null references properties(id) on delete cascade,
  viewed_at timestamptz not null default now(),
  primary key (user_id, property_id)
);

create table if not exists favorites (
  user_id uuid not null references profiles(id) on delete cascade,
  property_id uuid not null references properties(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, property_id)
);

-- SUBSCRIPTIONS --------------------------------------------------------------
create table if not exists subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  tier text not null,
  started_at timestamptz not null default now()
);

-- VIEW COUNTER RPC -----------------------------------------------------------
create or replace function increment_view_count(p_property_id uuid)
returns void language sql as $$
  update properties set view_count = view_count + 1 where id = p_property_id;
$$;

-- AVG RATING (optional helper columns via view) ------------------------------
-- The app reads avg_rating / review_count if present on the row. You can
-- expose them with a view or compute client-side. Example view:
create or replace view properties_with_ratings as
select p.*,
  coalesce(avg(r.rating), 0) as avg_rating,
  count(r.id) as review_count
from properties p
left join reviews r on r.property_id = p.id
group by p.id;

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================
alter table profiles enable row level security;
alter table properties enable row level security;
alter table property_media enable row level security;
alter table conversations enable row level security;
alter table messages enable row level security;
alter table viewing_bookings enable row level security;
alter table reviews enable row level security;
alter table recently_viewed enable row level security;
alter table favorites enable row level security;
alter table subscriptions enable row level security;

-- Profiles: readable by all, writable by self.
create policy "profiles read" on profiles for select using (true);
create policy "profiles upsert self" on profiles for insert
  with check (auth.uid() = id);
create policy "profiles update self" on profiles for update
  using (auth.uid() = id);

-- Properties: approved visible to all; owners manage their own; admins all.
create policy "properties read approved or own" on properties for select
  using (status = 'approved' or owner_id = auth.uid()
         or exists (select 1 from profiles where id = auth.uid()
                    and role = 'admin'));
create policy "properties insert own" on properties for insert
  with check (owner_id = auth.uid());
create policy "properties update own or admin" on properties for update
  using (owner_id = auth.uid()
         or exists (select 1 from profiles where id = auth.uid()
                    and role = 'admin'));
create policy "properties delete own or admin" on properties for delete
  using (owner_id = auth.uid()
         or exists (select 1 from profiles where id = auth.uid()
                    and role = 'admin'));

-- Property media: follows the parent property.
create policy "media read" on property_media for select using (true);
create policy "media write own" on property_media for all
  using (exists (select 1 from properties p
                 where p.id = property_id and p.owner_id = auth.uid()))
  with check (exists (select 1 from properties p
                 where p.id = property_id and p.owner_id = auth.uid()));

-- Conversations + messages: only the two participants.
create policy "convo participants" on conversations for all
  using (auth.uid() = user_a or auth.uid() = user_b)
  with check (auth.uid() = user_a or auth.uid() = user_b);
create policy "messages participants" on messages for all
  using (exists (select 1 from conversations c where c.id = conversation_id
                 and (c.user_a = auth.uid() or c.user_b = auth.uid())))
  with check (sender_id = auth.uid());

-- Bookings: requester or owner.
create policy "bookings parties" on viewing_bookings for all
  using (requester_id = auth.uid() or owner_id = auth.uid())
  with check (requester_id = auth.uid() or owner_id = auth.uid());

-- Reviews: readable by all; authored by self.
create policy "reviews read" on reviews for select using (true);
create policy "reviews insert self" on reviews for insert
  with check (author_id = auth.uid());

-- Engagement: self only.
create policy "recent self" on recently_viewed for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "favorites self" on favorites for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "subs self read" on subscriptions for select
  using (user_id = auth.uid());

-- ============================================================================
-- STORAGE BUCKETS (create in Dashboard -> Storage, both PUBLIC):
--   property-media
--   avatars
-- Then add policies allowing authenticated users to upload to a folder
-- matching their uid, e.g. (storage.foldername(name))[1] = auth.uid()::text
-- ============================================================================
