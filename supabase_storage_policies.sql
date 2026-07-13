-- ============================================================================
-- STORAGE BUCKET POLICIES
-- Run AFTER creating two PUBLIC buckets in Storage:
--   property-media
--   avatars
-- (Create the buckets in the dashboard first; this only adds access rules.)
-- ============================================================================

-- Anyone can READ files in both buckets (public listing images / avatars).
create policy "public read property-media"
  on storage.objects for select
  using (bucket_id = 'property-media');

create policy "public read avatars"
  on storage.objects for select
  using (bucket_id = 'avatars');

-- Authenticated users can UPLOAD into a folder named after their own user id.
-- The app uploads to:  {auth.uid()}/{filename}
create policy "users upload own property-media"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'property-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "users upload own avatars"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Allow users to UPDATE / overwrite their own avatar (app uses upsert: true).
create policy "users update own avatars"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Allow users to DELETE their own files (e.g. removing a listing photo).
create policy "users delete own property-media"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'property-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
