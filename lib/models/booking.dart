import '../core/constants/app_constants.dart';

class ViewingBooking {
  final String id;
  final String propertyId;
  final String? propertyTitle;
  final String requesterId;
  final String? requesterName;
  final String ownerId;
  final DateTime scheduledFor;
  final String? note;
  final BookingStatus status;
  final DateTime createdAt;

  const ViewingBooking({
    required this.id,
    required this.propertyId,
    this.propertyTitle,
    required this.requesterId,
    this.requesterName,
    required this.ownerId,
    required this.scheduledFor,
    this.note,
    this.status = BookingStatus.requested,
    required this.createdAt,
  });

  factory ViewingBooking.fromMap(Map<String, dynamic> m) => ViewingBooking(
        id: m['id'].toString(),
        propertyId: m['property_id'].toString(),
        propertyTitle: (m['properties']?['title']) as String?,
        requesterId: m['requester_id'] as String,
        requesterName: (m['profiles']?['full_name']) as String?,
        ownerId: m['owner_id'] as String,
        scheduledFor: DateTime.tryParse(m['scheduled_for']?.toString() ?? '') ??
            DateTime.now(),
        note: m['note'] as String?,
        status: BookingStatus.values.firstWhere(
          (s) => s.name == m['status'],
          orElse: () => BookingStatus.requested,
        ),
        createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}
