import 'package:flutter/material.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<_NotifItem> _items;

  @override
  void initState() {
    super.initState();
    // Demo data; replace with API list later
    _items = [
      _NotifItem(
        id: 1,
        title: 'Request approved',
        body: 'REQ-101 has been approved by the vendor.',
        type: 'request_updated',
        createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
        entityId: 101,
      ),
      _NotifItem(
        id: 2,
        title: 'New message',
        body: '“We can deliver tomorrow morning.”',
        type: 'chat_message',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        entityId: 12,
      ),
      _NotifItem(
        id: 3,
        title: 'Contract opened',
        body: 'Contract CNT-311 is now active.',
        type: 'contract_open',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        entityId: 311,
      ),
    ];
  }

  void _go(_NotifItem n) {
    switch (n.type) {
      case 'chat_message':
        context.push('/chats/${n.entityId}');
        break;
      case 'contract_open':
        context.push('/contracts');
        break;
      case 'request_updated':
        context.push('/requests');
        break;
      default:
        // Stay here or future detail screen
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final n = _items[i];
          return Glass(
            radius: 16,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: AIcon(AppGlyph.bell, color: cs.onPrimaryContainer),
              ),
              title: Text(
                n.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(n.body),
              trailing: Text(
                _fmtAgo(n.createdAt),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              onTap: () => _go(n),
            ),
          );
        },
      ),
    );
  }

  String _fmtAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}

class _NotifItem {
  final int id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final int? entityId;
  _NotifItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.entityId,
  });
}
