import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';

/// Single entry point for Supabase init + shared client access.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  SupabaseClient get client => Supabase.instance.client;
  GoTrueClient get auth => client.auth;
  User? get currentUser => auth.currentUser;
  String? get uid => currentUser?.id;
}
