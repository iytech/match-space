# Match Space

A real estate property listing platform for the Nigerian market, built with **Flutter (web)** and **Supabase**. Rebuilt with a feature-separated architecture and a fresh **"Terracotta & Slate"** design system.

---

## What's inside

Full feature parity with the previous build:

- **Browse & search** — hero search, filters (purpose, state), featured carousel, listings grid
- **Property detail** — image/video gallery, amenities, owner card, reviews, mortgage estimator
- **Auth** — email/password sign-up & sign-in (Supabase Auth)
- **Listings** — create with web-safe multi-image/video upload, free-tier cap (3 listings), submit-for-approval flow
- **Admin** — approve / reject pending listings, feature / unfeature
- **Messaging** — realtime chat with read receipts (✓✓)
- **Bookings** — request viewings, owner confirm / decline
- **Reviews & ratings** — 1–5 stars with comments
- **Owner dashboard + analytics** — listing management, views-by-property chart (fl_chart)
- **Recently viewed** & **favorites**
- **Subscriptions** — Free vs Premium tiers, Flutterwave checkout kickoff
- **Currency toggle** — NGN ₦ / USD $ across the app
- **Profile** — edit details, avatar upload

---

## 1. Add your keys

Open `lib/core/config/app_config.dart` and paste your **Supabase anon (public) key**:

```dart
static const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'PASTE_YOUR_SUPABASE_ANON_KEY_HERE',  // <-- here
);
```

The project URL is already set to your existing project (`wdzpcvdhheborukoivgc.supabase.co`). Optionally paste your **Flutterwave public key** for subscription checkout.

> Prefer not to hard-code keys? Pass them at build/run time instead:
> ```
> flutter run -d chrome --dart-define=SUPABASE_ANON_KEY=your_key
> ```

**Never** put the Supabase `service_role` key or Flutterwave **secret** key in this app — those belong only in server-side Edge Functions.

## 2. Set up the database

In the Supabase dashboard → **SQL Editor**, run the contents of [`supabase_schema.sql`](./supabase_schema.sql). It creates all tables, the `conversation_list` view, the `increment_view_count` RPC, and Row Level Security policies.

Then under **Storage**, create two **public** buckets:
- `property-media`
- `avatars`

## 3. Run it

```bash
flutter pub get
flutter run -d chrome
```

If you see the "Add your Supabase keys" screen, the anon key hasn't been set yet.

## 4. Deploy to Vercel

```bash
flutter build web --release
```

A `vercel.json` is included (build command + SPA rewrites). Connect the repo in Vercel, or run `vercel` from the project root. Add your keys as Vercel environment variables and reference them via `--dart-define` in the build command if you don't want them in source.

---

## Making yourself an admin

After signing up, set your role to `admin` once in the SQL editor:

```sql
update profiles set role = 'admin' where email = 'you@example.com';
```

The admin panel then appears in your profile menu.

## Project structure

```
lib/
  core/            config, theme, constants, utils, shared widgets, router
  models/          UserProfile, Property, Message, Booking, Review
  services/        Supabase, auth, storage, property, messaging, booking,
                   review, engagement, analytics, subscription
  providers/       auth, currency, property (state via Provider)
  features/        auth, home, listings, property_detail, messaging,
                   bookings, reviews, admin, analytics, subscription,
                   profile, tools  (each feature in its own folder/files)
```

## Notes on subscriptions

Flutterwave **payment verification must happen server-side**. The client opens the hosted payment link; a Supabase Edge Function (using your Flutterwave secret key, via webhook) should verify the transaction and flip the user's `tier` to `premium`. `SubscriptionService.setTier()` is provided for that server-side / manual upgrade step and local testing.
