import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  final _auth = AuthService();
  final _sb = SupabaseService.instance;

  UserProfile? _profile;
  bool _loading = true;

  UserProfile? get profile => _profile;
  bool get loading => _loading;
  bool get isLoggedIn => _sb.currentUser != null;
  bool get isAdmin => _profile?.isAdmin ?? false;

  AuthProvider() {
    _bootstrap();
    _auth.onAuthChange.listen((state) async {
      if (state.event == AuthChangeEvent.signedIn) {
        await _loadProfile();
      } else if (state.event == AuthChangeEvent.signedOut) {
        _profile = null;
        notifyListeners();
      }
    });
  }

  Future<void> _bootstrap() async {
    if (_sb.currentUser != null) await _loadProfile();
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    final uid = _sb.uid;
    if (uid != null) {
      _profile = await _auth.fetchProfile(uid);
      notifyListeners();
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signIn(email, password);
      await _loadProfile();
      return null;
    } catch (e) {
      return _friendly(e);
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    AccountType accountType = AccountType.seeker,
  }) async {
    try {
      await _auth.signUp(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
          accountType: accountType);
      await _loadProfile();
      return null;
    } catch (e) {
      return _friendly(e);
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> refreshProfile() => _loadProfile();

  Future<void> saveProfile(UserProfile p) async {
    await _auth.updateProfile(p);
    _profile = p;
    notifyListeners();
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('Invalid login')) return 'Wrong email or password.';
    if (s.contains('already registered')) return 'That email is already in use.';
    if (s.contains('User already registered')) return 'That email is already in use.';
    if (s.contains('Password should be')) {
      return 'Password is too short (minimum 6 characters).';
    }
    if (s.contains('row-level security') || s.contains('violates row-level')) {
      return 'Account created, but saving your profile was blocked by '
          'database security rules. Check the profiles RLS policy.';
    }
    if (s.contains('confirmation') || s.contains('confirm your email')) {
      return 'Check your email to confirm your account, then sign in.';
    }
    // Show the real error so the cause is visible during setup.
    return 'Sign-up failed: $s';
  }
}
