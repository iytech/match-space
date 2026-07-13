import '../core/constants/app_constants.dart';
import 'supabase_service.dart';

class OwnerAnalytics {
  final int totalListings;
  final int approved;
  final int pending;
  final int totalViews;
  final int totalBookings;
  final double avgRating;
  final Map<String, int> viewsByProperty;
  const OwnerAnalytics({
    required this.totalListings,
    required this.approved,
    required this.pending,
    required this.totalViews,
    required this.totalBookings,
    required this.avgRating,
    required this.viewsByProperty,
  });
}

class AnalyticsService {
  final _sb = SupabaseService.instance;

  Future<OwnerAnalytics> forOwner(String ownerId) async {
    final props = await _sb.client
        .from(Tables.properties)
        .select('id, title, status, view_count')
        .eq('owner_id', ownerId);
    final list = props as List;

    final bookings = await _sb.client
        .from(Tables.bookings)
        .select('id')
        .eq('owner_id', ownerId);

    int approved = 0, pending = 0, views = 0;
    final byProp = <String, int>{};
    for (final p in list) {
      if (p['status'] == 'approved') approved++;
      if (p['status'] == 'pending') pending++;
      final v = (p['view_count'] ?? 0) as int;
      views += v;
      byProp[(p['title'] ?? 'Untitled') as String] = v;
    }

    return OwnerAnalytics(
      totalListings: list.length,
      approved: approved,
      pending: pending,
      totalViews: views,
      totalBookings: (bookings as List).length,
      avgRating: 0,
      viewsByProperty: byProp,
    );
  }
}
