import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/message.dart';
import '../../services/messaging_service.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});
  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _service = MessagingService();
  List<Conversation> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _items = await _service.fetchConversations();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const EmptyState(
                  icon: Icons.forum_outlined,
                  title: 'No conversations yet',
                  message:
                      'Message a property owner and your chats will appear here.',
                )
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 76),
                  itemBuilder: (_, i) {
                    final c = _items[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.terracottaSoft,
                        child: Text(
                            initialOf(c.otherUserName),
                            style: const TextStyle(
                                color: AppColors.terracottaDark,
                                fontWeight: FontWeight.w700)),
                      ),
                      title: Text(c.otherUserName,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        c.lastMessage ?? 'Start the conversation',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (c.lastAt != null)
                            Text(Formatters.timeAgo(c.lastAt!),
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.inkFaint)),
                          if (c.unread > 0) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                  color: AppColors.terracotta,
                                  shape: BoxShape.circle),
                              child: Text('${c.unread}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ChatScreen(
                                conversationId: c.id,
                                title: c.otherUserName)),
                      ).then((_) => _load()),
                    );
                  },
                ),
    );
  }
}
