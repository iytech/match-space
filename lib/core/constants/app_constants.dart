/// App-wide constants: enums, table names, storage buckets, option lists.
class Tables {
  Tables._();
  static const profiles = 'profiles';
  static const properties = 'properties';
  static const propertyMedia = 'property_media';
  static const messages = 'messages';
  static const conversations = 'conversations';
  static const bookings = 'viewing_bookings';
  static const reviews = 'reviews';
  static const recentlyViewed = 'recently_viewed';
  static const subscriptions = 'subscriptions';
  static const favorites = 'favorites';
}

class Buckets {
  Buckets._();
  static const propertyMedia = 'property-media';
  static const avatars = 'avatars';
}

enum PropertyStatus { pending, approved, rejected }

enum PropertyType { house, apartment, duplex, bungalow, land, commercial }

enum ListingPurpose { sale, rent, lease, shortlet }

enum UserRole { user, owner, admin }

/// Self-selected account type (what the user does), separate from `role`
/// (their permission level). Owners and agents can create listings; seekers
/// browse, save, message, and book — and can switch to listing later.
enum AccountType { seeker, owner, agent }

enum BookingStatus { requested, confirmed, declined, completed }

enum SubscriptionTier { free, premium }

class AppOptions {
  AppOptions._();
  static const states = [
    'Plateau', 'Lagos', 'FCT Abuja', 'Rivers', 'Kano', 'Oyo', 'Kaduna',
    'Enugu', 'Delta', 'Edo', 'Anambra', 'Ogun', 'Cross River', 'Other',
  ];
  static const purposeBadges = {
    ListingPurpose.sale: 'For Sale',
    ListingPurpose.rent: 'For Rent',
    ListingPurpose.lease: 'For Lease',
    ListingPurpose.shortlet: 'Short-let',
  };
  static const accountTypeLabels = {
    AccountType.seeker: 'Seeker',
    AccountType.owner: 'Property Owner',
    AccountType.agent: 'Agent',
  };
  static const accountTypeDescriptions = {
    AccountType.seeker: 'Browse, save, message owners and book viewings',
    AccountType.owner: 'List and manage your own properties',
    AccountType.agent: 'List and manage properties for clients',
  };
  static const purposeChips = {
    ListingPurpose.sale: 'For sale',
    ListingPurpose.rent: 'For rent',
    ListingPurpose.lease: 'For lease',
    ListingPurpose.shortlet: 'Short-let',
  };
  static const propertyTypeLabels = {
    PropertyType.house: 'House',
    PropertyType.apartment: 'Apartment',
    PropertyType.duplex: 'Duplex',
    PropertyType.bungalow: 'Bungalow',
    PropertyType.land: 'Land',
    PropertyType.commercial: 'Commercial',
  };
  static const amenities = [
    'Borehole', '24/7 Power', 'Security', 'Parking', 'Air Conditioning',
    'Furnished', 'POP Ceiling', 'En-suite', 'Fenced', 'Gated Estate',
    'Water Heater', 'CCTV', 'Swimming Pool', 'Generator',
  ];
}
