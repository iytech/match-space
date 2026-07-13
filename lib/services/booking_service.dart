import '../core/constants/app_constants.dart';
import '../models/booking.dart';
import 'supabase_service.dart';

class BookingService {
  final _sb = SupabaseService.instance;

  Future<void> request({
    required String propertyId,
    required String ownerId,
    required DateTime scheduledFor,
    String? note,
  }) async {
    await _sb.client.from(Tables.bookings).insert({
      'property_id': propertyId,
      'requester_id': _sb.uid,
      'owner_id': ownerId,
      'scheduled_for': scheduledFor.toIso8601String(),
      'note': note,
      'status': BookingStatus.requested.name,
    });
  }

  Future<List<ViewingBooking>> forOwner() async {
    final data = await _sb.client
        .from(Tables.bookings)
        .select('*, properties(title), profiles!viewing_bookings_requester_id_fkey(full_name)')
        .eq('owner_id', _sb.uid!)
        .order('scheduled_for', ascending: true);
    return (data as List).map((e) => ViewingBooking.fromMap(e)).toList();
  }

  Future<List<ViewingBooking>> forRequester() async {
    final data = await _sb.client
        .from(Tables.bookings)
        .select('*, properties(title), profiles!viewing_bookings_requester_id_fkey(full_name)')
        .eq('requester_id', _sb.uid!)
        .order('scheduled_for', ascending: true);
    return (data as List).map((e) => ViewingBooking.fromMap(e)).toList();
  }

  Future<void> setStatus(String id, BookingStatus status) =>
      _sb.client.from(Tables.bookings).update(
        {'status': status.name},
      ).eq('id', id);
}
