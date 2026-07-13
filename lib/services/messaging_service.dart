import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import '../models/message.dart';
import 'supabase_service.dart';

class MessagingService {
  final _sb = SupabaseService.instance;

  Future<String> getOrCreateConversation({
    required String propertyId,
    required String ownerId,
  }) async {
    final me = _sb.uid!;
    final existing = await _sb.client
        .from(Tables.conversations)
        .select('id')
        .eq('property_id', propertyId)
        .or('and(user_a.eq.$me,user_b.eq.$ownerId),'
            'and(user_a.eq.$ownerId,user_b.eq.$me)')
        .maybeSingle();
    if (existing != null) return existing['id'].toString();

    final created = await _sb.client
        .from(Tables.conversations)
        .insert({
          'property_id': propertyId,
          'user_a': me,
          'user_b': ownerId,
        })
        .select('id')
        .single();
    return created['id'].toString();
  }

  Future<List<Conversation>> fetchConversations() async {
    final me = _sb.uid!;
    // Reads from a view `conversation_list` that pre-joins names/last message.
    final data = await _sb.client
        .from('conversation_list')
        .select()
        .or('user_a.eq.$me,user_b.eq.$me')
        .order('last_at', ascending: false);
    return (data as List)
        .map((e) => Conversation.fromMap(e, me))
        .toList();
  }

  Stream<List<Message>> streamMessages(String conversationId) {
    return _sb.client
        .from(Tables.messages)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((rows) => rows.map((m) => Message.fromMap(m)).toList());
  }

  Future<void> send(String conversationId, String body) async {
    await _sb.client.from(Tables.messages).insert({
      'conversation_id': conversationId,
      'sender_id': _sb.uid,
      'body': body,
      'read': false,
    });
    await _sb.client.from(Tables.conversations).update({
      'last_message': body,
      'last_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);
  }

  Future<void> markRead(String conversationId) async {
    await _sb.client
        .from(Tables.messages)
        .update({'read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', _sb.uid!)
        .eq('read', false);
  }
}
