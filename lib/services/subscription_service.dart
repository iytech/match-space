import '../core/constants/app_constants.dart';
import 'supabase_service.dart';

/// Subscription / Flutterwave integration.
///
/// IMPORTANT: Verifying a Flutterwave payment must happen server-side. The
/// client kicks off checkout; a Supabase Edge Function (or webhook) verifies
/// the transaction with your Flutterwave SECRET key and flips the user's tier.
/// This service handles the client side + reading current tier.
class SubscriptionService {
  final _sb = SupabaseService.instance;

  Future<SubscriptionTier> currentTier() async {
    if (_sb.uid == null) return SubscriptionTier.free;
    final data = await _sb.client
        .from(Tables.profiles)
        .select('tier')
        .eq('id', _sb.uid!)
        .maybeSingle();
    return SubscriptionTier.values.firstWhere(
      (t) => t.name == data?['tier'],
      orElse: () => SubscriptionTier.free,
    );
  }

  /// Called AFTER a verified payment (e.g. from the Edge Function response).
  /// Provided here for manual/admin upgrades and local testing.
  Future<void> setTier(String userId, SubscriptionTier tier) async {
    await _sb.client
        .from(Tables.profiles)
        .update({'tier': tier.name}).eq('id', userId);
    await _sb.client.from(Tables.subscriptions).insert({
      'user_id': userId,
      'tier': tier.name,
      'started_at': DateTime.now().toIso8601String(),
    });
  }

  /// How many active listings the user has, to enforce the free-tier cap.
  Future<int> activeListingCount(String ownerId) async {
    final data = await _sb.client
        .from(Tables.properties)
        .select('id')
        .eq('owner_id', ownerId)
        .neq('status', PropertyStatus.rejected.name);
    return (data as List).length;
  }
}
