import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/message.dart';
import '../../services/messaging_service.dart';
import '../../services/supabase_service.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String title;
  const ChatScreen(
      {super.key, required this.conversationId, required this.title});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _service = MessagingService();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _myId = SupabaseService.instance.uid;

  @override
  void initState() {
    super.initState();
    _service.markRead(widget.conversationId);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    await _service.send(widget.conversationId, text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _service.streamMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                _service.markRead(widget.conversationId);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scroll.hasClients) {
                    _scroll.jumpTo(_scroll.position.maxScrollExtent);
                  }
                });
                if (messages.isEmpty) {
                  return const Center(
                      child: Text('Say hello 👋',
                          style: TextStyle(color: AppColors.inkSoft)));
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[i];
                    final mine = m.senderId == _myId;
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.7),
                        decoration: BoxDecoration(
                          color:
                              mine ? AppColors.terracotta : AppColors.surface,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(mine ? 16 : 4),
                            bottomRight: Radius.circular(mine ? 4 : 16),
                          ),
                          border: mine
                              ? null
                              : Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.body,
                                style: TextStyle(
                                    color:
                                        mine ? Colors.white : AppColors.ink)),
                            const SizedBox(height: 3),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(Formatters.timeAgo(m.createdAt),
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      color: mine
                                          ? Colors.white70
                                          : AppColors.inkFaint)),
                              if (mine) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  m.read ? Icons.done_all : Icons.done,
                                  size: 14,
                                  color: m.read
                                      ? Colors.white
                                      : Colors.white60,
                                ),
                              ],
                            ]),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  onSubmitted: (_) => _send(),
                  decoration:
                      const InputDecoration(hintText: 'Type a message…'),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppColors.terracotta,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _send,
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
