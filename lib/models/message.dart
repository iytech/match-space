class Conversation {
  final String id;
  final String propertyId;
  final String? propertyTitle;
  final String? propertyCover;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String? lastMessage;
  final DateTime? lastAt;
  final int unread;

  const Conversation({
    required this.id,
    required this.propertyId,
    this.propertyTitle,
    this.propertyCover,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.lastMessage,
    this.lastAt,
    this.unread = 0,
  });

  factory Conversation.fromMap(Map<String, dynamic> m, String currentUserId) {
    final isUserA = m['user_a'] == currentUserId;
    return Conversation(
      id: m['id'].toString(),
      propertyId: m['property_id'].toString(),
      propertyTitle: m['property_title'] as String?,
      propertyCover: m['property_cover'] as String?,
      otherUserId: (isUserA ? m['user_b'] : m['user_a']) as String,
      otherUserName: (isUserA ? m['user_b_name'] : m['user_a_name'])
              as String? ?? 'User',
      otherUserAvatar:
          (isUserA ? m['user_b_avatar'] : m['user_a_avatar']) as String?,
      lastMessage: m['last_message'] as String?,
      lastAt: DateTime.tryParse(m['last_at']?.toString() ?? ''),
      unread: (m['unread'] ?? 0) as int,
    );
  }
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final bool read;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    this.read = false,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> m) => Message(
        id: m['id'].toString(),
        conversationId: m['conversation_id'].toString(),
        senderId: m['sender_id'] as String,
        body: (m['body'] ?? '') as String,
        read: (m['read'] ?? false) as bool,
        createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}
