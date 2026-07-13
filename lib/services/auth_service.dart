import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';

class AuthService {
  final _sb = SupabaseService.instance;

  Stream<AuthState> get onAuthChange => _sb.auth.onAuthStateChange;

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    AccountType accountType = AccountType.seeker,
  }) async {
    final res = await _sb.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone': phone,
        'account_type': accountType.name,
      },
    );
    final user = res.user;
    // Try to create the profile row from the client. If a DB trigger already
    // handles this (recommended), or if there's no active session yet because
    // email confirmation is on, this insert may be skipped or fail — that's
    // fine and should NOT block sign-up. The trigger is the source of truth.
    if (user != null && _sb.currentUser != null) {
      try {
        await _sb.client.from(Tables.profiles).upsert({
          'id': user.id,
          'full_name': fullName,
          'email': email,
          'phone': phone,
          'role': UserRole.user.name,
          'account_type': accountType.name,
          'tier': SubscriptionTier.free.name,
        });
      } catch (_) {
        // Profile will be created by the DB trigger; ignore.
      }
    }
  }

  Future<void> signIn(String email, String password) =>
      _sb.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _sb.auth.signOut();

  Future<UserProfile?> fetchProfile(String userId) async {
    final data = await _sb.client
        .from(Tables.profiles)
        .select()
        .eq('id', userId)
        .maybeSingle();
    return data == null ? null : UserProfile.fromMap(data);
  }

  Future<void> updateProfile(UserProfile p) async {
    await _sb.client.from(Tables.profiles).update(p.toMap()).eq('id', p.id);
  }
}
