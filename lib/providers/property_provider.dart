import 'package:flutter/foundation.dart';
import '../models/property.dart';
import '../services/property_service.dart';
import '../services/engagement_service.dart';

class PropertyProvider extends ChangeNotifier {
  final _service = PropertyService();
  final _engagement = EngagementService();

  List<Property> _listings = [];
  List<Property> _featured = [];
  List<Property> _recentlyViewed = [];
  Set<String> _favoriteIds = {};
  bool _loading = false;
  PropertyFilter _filter = const PropertyFilter();

  List<Property> get listings => _listings;
  List<Property> get featured => _featured;
  List<Property> get recentlyViewed => _recentlyViewed;
  Set<String> get favoriteIds => _favoriteIds;
  bool get loading => _loading;
  PropertyFilter get filter => _filter;

  Future<void> loadHome() async {
    _loading = true;
    notifyListeners();
    try {
      _featured = await _service.fetchFeatured();
      _listings = await _service.fetchApproved(filter: _filter);
      _recentlyViewed = await _engagement.recentlyViewed();
      _favoriteIds = await _engagement.favoriteIds();
    } catch (e) {
      debugPrint('loadHome error: $e');
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> applyFilter(PropertyFilter filter) async {
    _filter = filter;
    _loading = true;
    notifyListeners();
    _listings = await _service.fetchApproved(filter: filter);
    _loading = false;
    notifyListeners();
  }

  /// Merge a query/state search from the hero bar with any filters already
  /// set in the filter sheet, rather than replacing them.
  Future<void> mergeSearch({String? query, String? state}) async {
    await applyFilter(PropertyFilter(
      query: query,
      state: state ?? _filter.state,
      type: _filter.type,
      purpose: _filter.purpose,
      minBeds: _filter.minBeds,
      minPrice: _filter.minPrice,
      maxPrice: _filter.maxPrice,
    ));
  }

  Future<void> toggleFavorite(String propertyId) async {
    final willFav = !_favoriteIds.contains(propertyId);
    if (willFav) {
      _favoriteIds.add(propertyId);
    } else {
      _favoriteIds.remove(propertyId);
    }
    notifyListeners();
    await _engagement.toggleFavorite(propertyId, willFav);
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);
}
