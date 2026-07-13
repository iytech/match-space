import '../models/app_notification.dart';
import 'supabase_service.dart';

class NotificationService {
  final _sb = SupabaseService.instance;

  Future<List<AppNotification>> fetch() async {
    if (_sb.uid == null) return [];
    final data = await _sb.client
        .from('notifications')
        .select()
        .eq('user_id', _sb.uid!)
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List).map((e) => AppNotification.fromMap(e)).toList();
  }

  /// Realtime stream of the current user's notifications (newest first).
  Stream<List<AppNotification>> stream() {
    final uid = _sb.uid;
    if (uid == null) return const Stream.empty();
    return _sb.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .map((rows) =>
            rows.map((m) => AppNotification.fromMap(m)).toList());
  }

  Future<void> markRead(String id) async {
    await _sb.client
        .from('notifications')
        .update({'read': true}).eq('id', id);
  }

  Future<void> markAllRead() async {
    if (_sb.uid == null) return;
    await _sb.client
        .from('notifications')
        .update({'read': true})
        .eq('user_id', _sb.uid!)
        .eq('read', false);
  }
}
