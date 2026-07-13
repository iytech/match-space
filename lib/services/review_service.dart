import '../core/constants/app_constants.dart';
import '../models/review.dart';
import 'supabase_service.dart';

class ReviewService {
  final _sb = SupabaseService.instance;

  Future<List<Review>> forProperty(String propertyId) async {
    final data = await _sb.client
        .from(Tables.reviews)
        .select('*, profiles!reviews_author_id_fkey(full_name, avatar_url)')
        .eq('property_id', propertyId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Review.fromMap(e)).toList();
  }

  Future<void> add({
    required String propertyId,
    required int rating,
    required String comment,
  }) async {
    await _sb.client.from(Tables.reviews).insert({
      'property_id': propertyId,
      'author_id': _sb.uid,
      'rating': rating,
      'comment': comment,
    });
  }
}
