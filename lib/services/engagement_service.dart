import '../core/constants/app_constants.dart';
import '../models/property.dart';
import 'supabase_service.dart';

/// Recently viewed + favorites.
class EngagementService {
  final _sb = SupabaseService.instance;

  Future<void> recordView(String propertyId) async {
    if (_sb.uid == null) return;
    await _sb.client.from(Tables.recentlyViewed).upsert({
      'user_id': _sb.uid,
      'property_id': propertyId,
      'viewed_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,property_id');
  }

  Future<List<Property>> recentlyViewed() async {
    if (_sb.uid == null) return [];
    final data = await _sb.client
        .from(Tables.recentlyViewed)
        .select('properties(*, property_media(*), '
            'profiles!properties_owner_id_fkey(full_name, phone, account_type))')
        .eq('user_id', _sb.uid!)
        .order('viewed_at', ascending: false)
        .limit(12);
    return (data as List)
        .where((e) => e['properties'] != null)
        .map((e) => Property.fromMap(e['properties']))
        .toList();
  }

  Future<Set<String>> favoriteIds() async {
    if (_sb.uid == null) return {};
    final data = await _sb.client
        .from(Tables.favorites)
        .select('property_id')
        .eq('user_id', _sb.uid!);
    return (data as List).map((e) => e['property_id'].toString()).toSet();
  }

  Future<void> toggleFavorite(String propertyId, bool isFav) async {
    if (_sb.uid == null) return;
    if (isFav) {
      await _sb.client.from(Tables.favorites).insert({
        'user_id': _sb.uid,
        'property_id': propertyId,
      });
    } else {
      await _sb.client
          .from(Tables.favorites)
          .delete()
          .eq('user_id', _sb.uid!)
          .eq('property_id', propertyId);
    }
  }

  Future<List<Property>> favorites() async {
    if (_sb.uid == null) return [];
    final data = await _sb.client
        .from(Tables.favorites)
        .select('properties(*, property_media(*), '
            'profiles!properties_owner_id_fkey(full_name, phone, account_type))')
        .eq('user_id', _sb.uid!);
    return (data as List)
        .where((e) => e['properties'] != null)
        .map((e) => Property.fromMap(e['properties']))
        .toList();
  }
}
