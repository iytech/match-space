enum NotificationKind { message, booking, bookingUpdate, listingApproved, listingRejected, review, system }

class AppNotification {
  final String id;
  final String userId;
  final NotificationKind kind;
  final String title;
  final String body;
  final String? route;        // where tapping it should take the user
  final String? routeArg;     // argument for that route (e.g. property id)
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.kind,
    required this.title,
    required this.body,
    this.route,
    this.routeArg,
    this.read = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
        id: m['id'].toString(),
        userId: m['user_id'] as String,
        kind: NotificationKind.values.firstWhere(
          (k) => k.name == m['kind'],
          orElse: () => NotificationKind.system,
        ),
        title: (m['title'] ?? '') as String,
        body: (m['body'] ?? '') as String,
        route: m['route'] as String?,
        routeArg: m['route_arg'] as String?,
        read: (m['read'] ?? false) as bool,
        createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}
