import '../core/constants/app_constants.dart';
import '../models/property.dart';
import 'supabase_service.dart';

class PropertyFilter {
  final String? query;
  final PropertyType? type;
  final ListingPurpose? purpose;
  final String? state;
  final num? minPrice;
  final num? maxPrice;
  final int? minBeds;
  const PropertyFilter({
    this.query,
    this.type,
    this.purpose,
    this.state,
    this.minPrice,
    this.maxPrice,
    this.minBeds,
  });
}

class PropertyService {
  final _sb = SupabaseService.instance;

  static const _select =
      '*, property_media(*), profiles!properties_owner_id_fkey(full_name, phone, account_type)';

  Future<List<Property>> fetchApproved({PropertyFilter? filter}) async {
    var q = _sb.client
        .from(Tables.properties)
        .select(_select)
        .eq('status', PropertyStatus.approved.name)
        .eq('available', true);

    if (filter?.type != null) q = q.eq('type', filter!.type!.name);
    if (filter?.purpose != null) q = q.eq('purpose', filter!.purpose!.name);
    if (filter?.state != null) q = q.eq('state', filter!.state!);
    if (filter?.minPrice != null) q = q.gte('price', filter!.minPrice!);
    if (filter?.maxPrice != null) q = q.lte('price', filter!.maxPrice!);
    if (filter?.minBeds != null) q = q.gte('bedrooms', filter!.minBeds!);
    if (filter?.query != null && filter!.query!.trim().isNotEmpty) {
      q = q.or('title.ilike.%${filter.query}%,city.ilike.%${filter.query}%,'
          'address.ilike.%${filter.query}%');
    }

    final data = await q.order('featured', ascending: false)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Property.fromMap(e)).toList();
  }

  Future<List<Property>> fetchFeatured() async {
    final data = await _sb.client
        .from(Tables.properties)
        .select(_select)
        .eq('status', PropertyStatus.approved.name)
        .eq('featured', true)
        .limit(8);
    return (data as List).map((e) => Property.fromMap(e)).toList();
  }

  Future<Property?> fetchById(String id) async {
    final data = await _sb.client
        .from(Tables.properties)
        .select(_select)
        .eq('id', id)
        .maybeSingle();
    return data == null ? null : Property.fromMap(data);
  }

  Future<List<Property>> fetchByOwner(String ownerId) async {
    final data = await _sb.client
        .from(Tables.properties)
        .select(_select)
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Property.fromMap(e)).toList();
  }

  Future<List<Property>> fetchPending() async {
    final data = await _sb.client
        .from(Tables.properties)
        .select(_select)
        .eq('status', PropertyStatus.pending.name)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Property.fromMap(e)).toList();
  }

  Future<String> create(Property p, List<Map<String, dynamic>> media) async {
    final inserted = await _sb.client
        .from(Tables.properties)
        .insert(p.toInsert())
        .select('id')
        .single();
    final propertyId = inserted['id'].toString();
    if (media.isNotEmpty) {
      await _sb.client.from(Tables.propertyMedia).insert(
            media.map((m) => {...m, 'property_id': propertyId}).toList(),
          );
    }
    return propertyId;
  }

  Future<void> updateStatus(String id, PropertyStatus status) =>
      _sb.client.from(Tables.properties).update(
        {'status': status.name},
      ).eq('id', id);

  Future<void> setFeatured(String id, bool featured) =>
      _sb.client.from(Tables.properties).update(
        {'featured': featured},
      ).eq('id', id);

  /// Mark a listing sold/rented (available=false, reason set) or re-list it
  /// (available=true, reason cleared).
  Future<void> setAvailability(String id, bool available,
          {String? reason}) =>
      _sb.client.from(Tables.properties).update({
        'available': available,
        'closed_reason': available ? null : reason,
      }).eq('id', id);

  Future<void> delete(String id) =>
      _sb.client.from(Tables.properties).delete().eq('id', id);

  Future<void> incrementView(String id) async {
    await _sb.client.rpc('increment_view_count',
        params: {'p_property_id': id}).catchError((_) {});
  }
}
