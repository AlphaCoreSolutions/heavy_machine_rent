import 'package:flutter/material.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';
import 'package:heavy_new/screens/chat_screens/chat_thread_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _search = TextEditingController();
  late List<_ChatThread> _threads;
  late List<_ChatThread> _filtered;

  @override
  void initState() {
    super.initState();
    // Demo inbox
    _threads = [
      _ChatThread(
        id: 12,
        title: 'Al Waha Rentals',
        lastMessage: 'We can deliver tomorrow morning.',
        lastAt: DateTime.now().subtract(const Duration(minutes: 6)),
        unread: 2,
      ),
      _ChatThread(
        id: 21,
        title: 'Riyadh Earthworks',
        lastMessage: 'Invoice sent.',
        lastAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      _ChatThread(
        id: 7,
        title: 'Gold Crane Co.',
        lastMessage: 'Thanks!',
        lastAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      ),
    ];
    _filtered = List.of(_threads);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _apply() {
    final q = _search.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.of(_threads)
          : _threads
                .where(
                  (t) =>
                      t.title.toLowerCase().contains(q) ||
                      t.lastMessage.toLowerCase().contains(q),
                )
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: AInput(
              controller: _search,
              label: 'Search chats',
              glyph: AppGlyph.search,
              onChanged: (_) => _apply(),
              onSubmitted: (_) => _apply(),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final t = _filtered[i];
                return Glass(
                  radius: 16,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cs.surfaceVariant,
                      child: AIcon(AppGlyph.chat, color: cs.onSurfaceVariant),
                    ),
                    title: Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      t.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _ago(t.lastAt),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        if (t.unread > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              t.unread.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatThreadScreen(threadId: t.id),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}

class _ChatThread {
  final int id;
  final String title;
  final String lastMessage;
  final DateTime lastAt;
  final int unread;
  _ChatThread({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.lastAt,
    this.unread = 0,
  });
}
