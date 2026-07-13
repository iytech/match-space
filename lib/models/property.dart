import '../core/constants/app_constants.dart';

class PropertyMedia {
  final String id;
  final String url;
  final bool isVideo;
  final int position;
  const PropertyMedia({
    required this.id,
    required this.url,
    this.isVideo = false,
    this.position = 0,
  });

  factory PropertyMedia.fromMap(Map<String, dynamic> m) => PropertyMedia(
        id: m['id'].toString(),
        url: m['url'] as String,
        isVideo: (m['is_video'] ?? false) as bool,
        position: (m['position'] ?? 0) as int,
      );
}

class Property {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final PropertyType type;
  final ListingPurpose purpose;
  final PropertyStatus status;
  final num price; // stored in NGN
  final String state;
  final String city;
  final String address;
  final int bedrooms;
  final int bathrooms;
  final num areaSqm;
  final int? leaseTermYears;   // for lease listings
  final String? titleDocument; // for land (e.g. 'C of O', 'Deed of Assignment')
  final List<String> amenities;
  final List<PropertyMedia> media;
  final bool featured;
  final bool available;      // false when sold/rented
  final String? closedReason; // 'sold' | 'rented'
  final int viewCount;
  final double? lat;
  final double? lng;
  final DateTime createdAt;

  // Joined / computed
  final String? ownerName;
  final String? ownerPhone;
  final String? ownerAccountType;
  final double avgRating;
  final int reviewCount;

  const Property({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.type,
    required this.purpose,
    required this.status,
    required this.price,
    required this.state,
    required this.city,
    required this.address,
    required this.bedrooms,
    required this.bathrooms,
    required this.areaSqm,
    this.leaseTermYears,
    this.titleDocument,
    required this.amenities,
    required this.media,
    this.featured = false,
    this.available = true,
    this.closedReason,
    this.viewCount = 0,
    this.lat,
    this.lng,
    required this.createdAt,
    this.ownerName,
    this.ownerPhone,
    this.ownerAccountType,
    this.avgRating = 0,
    this.reviewCount = 0,
  });

  String get coverUrl =>
      media.isNotEmpty ? media.first.url : '';

  bool get isLand => type == PropertyType.land;
  bool get isClosed => !available;
  String get closedLabel =>
      closedReason == 'rented' ? 'Rented' : 'Sold';
  bool get ownerIsAgent => ownerAccountType == 'agent';
  bool get isForRent => purpose == ListingPurpose.rent;
  bool get isForSale => purpose == ListingPurpose.sale;
  bool get isForLease => purpose == ListingPurpose.lease;
  bool get isShortlet => purpose == ListingPurpose.shortlet;
  // Rent and lease are annual; short-let is weekly; sale is one-off.
  bool get isRecurring => purpose != ListingPurpose.sale;
  // Human label for the price period, e.g. "per week" / "per year".
  String? get pricePeriod {
    switch (purpose) {
      case ListingPurpose.shortlet:
        return 'per week';
      case ListingPurpose.rent:
      case ListingPurpose.lease:
        return 'per year';
      case ListingPurpose.sale:
        return null;
    }
  }
  String get purposeBadge =>
      AppOptions.purposeBadges[purpose] ?? 'For Sale';

  factory Property.fromMap(Map<String, dynamic> m) {
    final mediaList = (m['property_media'] as List? ?? [])
        .map((e) => PropertyMedia.fromMap(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final owner = m['profiles'] as Map<String, dynamic>?;

    return Property(
      id: m['id'].toString(),
      ownerId: m['owner_id'] as String,
      title: (m['title'] ?? '') as String,
      description: (m['description'] ?? '') as String,
      type: PropertyType.values.firstWhere(
        (t) => t.name == m['type'],
        orElse: () => PropertyType.house,
      ),
      purpose: ListingPurpose.values.firstWhere(
        (p) => p.name == m['purpose'],
        orElse: () => ListingPurpose.sale,
      ),
      status: PropertyStatus.values.firstWhere(
        (s) => s.name == m['status'],
        orElse: () => PropertyStatus.pending,
      ),
      price: (m['price'] ?? 0) as num,
      state: (m['state'] ?? '') as String,
      city: (m['city'] ?? '') as String,
      address: (m['address'] ?? '') as String,
      bedrooms: (m['bedrooms'] ?? 0) as int,
      bathrooms: (m['bathrooms'] ?? 0) as int,
      areaSqm: (m['area_sqm'] ?? 0) as num,
      leaseTermYears: (m['lease_term_years'] as num?)?.toInt(),
      titleDocument: m['title_document'] as String?,
      amenities: (m['amenities'] as List? ?? []).map((e) => e.toString()).toList(),
      media: mediaList,
      featured: (m['featured'] ?? false) as bool,
      available: (m['available'] ?? true) as bool,
      closedReason: m['closed_reason'] as String?,
      viewCount: (m['view_count'] ?? 0) as int,
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ??
          DateTime.now(),
      ownerName: owner?['full_name'] as String?,
      ownerPhone: owner?['phone'] as String?,
      ownerAccountType: owner?['account_type'] as String?,
      avgRating: (m['avg_rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (m['review_count'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toInsert() => {
        'owner_id': ownerId,
        'title': title,
        'description': description,
        'type': type.name,
        'purpose': purpose.name,
        'status': status.name,
        'price': price,
        'state': state,
        'city': city,
        'address': address,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'area_sqm': areaSqm,
        'lease_term_years': leaseTermYears,
        'title_document': titleDocument,
        'amenities': amenities,
        'featured': featured,
        'available': available,
        'closed_reason': closedReason,
        'lat': lat,
        'lng': lng,
      };
}
