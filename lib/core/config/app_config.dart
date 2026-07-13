/// ============================================================================
/// APP CONFIGURATION
/// ============================================================================
///
/// Paste your Supabase credentials below.
///
/// SECURITY NOTE:
///   - The `anonKey` is a PUBLIC client key and is safe to ship in a web app.
///   - NEVER put the Supabase `service_role` key in this file or anywhere in
///     client code. It belongs only in server-side Edge Functions.
///   - This file is intentionally NOT git-ignored so the app builds, but if you
///     prefer to keep keys out of source control, pass them at build time with:
///       flutter run -d chrome --dart-define=SUPABASE_URL=... \
///                                --dart-define=SUPABASE_ANON_KEY=...
///     and read them with String.fromEnvironment (see below).
/// ============================================================================

class AppConfig {
  AppConfig._();

  // Your existing Match Space project URL.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://pvmvvsdxhynalscksdqj.supabase.co',
  );

  // PASTE YOUR SUPABASE ANON (PUBLIC) KEY HERE.
  // Get it from: Supabase Dashboard -> Project Settings -> API -> anon public.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB2bXZ2c2R4aHluYWxzY2tzZHFqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI4MDIwNjUsImV4cCI6MjA5ODM3ODA2NX0.OeCJ1axToHSosUgjm3250nWtKiZafc_jh4NQa_4kYic',
  );

  // Flutterwave public key for subscription checkout (client-safe).
  // PASTE YOUR FLUTTERWAVE PUBLIC KEY HERE.
  static const String flutterwavePublicKey = String.fromEnvironment(
    'FLW_PUBLIC_KEY',
    defaultValue: 'PASTE_YOUR_FLUTTERWAVE_PUBLIC_KEY_HERE',
  );

  static bool get isConfigured =>
      supabaseAnonKey != 'PASTE_YOUR_SUPABASE_ANON_KEY_HERE' &&
      supabaseAnonKey.isNotEmpty;

  // Business rules
  static const int freeListingLimit = 3;
  static const double defaultMortgageRate = 18.0; // Nigeria default %
}
