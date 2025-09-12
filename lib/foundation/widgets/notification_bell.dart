// lib/widgets/notifications_bell.dart (or inside home_screen.dart)
import 'package:flutter/material.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:go_router/go_router.dart';

class NotificationsBell extends StatefulWidget {
  const NotificationsBell({super.key});
  @override
  State<NotificationsBell> createState() => _NotificationsBellState();
}

class _NotificationsBellState extends State<NotificationsBell> {
  // Demo data; replace with API feed later
  List<_Notif> _items = [
    _Notif(
      id: 1,
      title: 'Request approved',
      body: 'Your request REQ-101 was approved.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
      type: 'request_updated',
      entityId: 101,
    ),
    _Notif(
      id: 2,
      title: 'New message',
      body: 'Vendor: “We can deliver tomorrow.”',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      type: 'chat_message',
      entityId: 12, // threadId
    ),
    _Notif(
      id: 3,
      title: 'Contract opened',
      body: 'Contract CNT-311 is now active.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      type: 'contract_open',
      entityId: 311,
    ),
  ];

  final _btnKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unread = _items.length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          key: _btnKey,
          tooltip: 'Notifications',
          icon: AIcon(AppGlyph.bell, color: cs.primary),
          onPressed: _showDropdown,
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cs.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unread > 9 ? '9+' : unread.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }

  void _showDropdown() async {
    final ctx = context;
    final rb = _btnKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;
    final overlay = Overlay.of(ctx).context.findRenderObject() as RenderBox;
    final pos = rb.localToGlobal(Offset.zero, ancestor: overlay);
    final size = rb.size;

    // A glassy dropdown menu with up to 6 recent notifications
    final entries = _items.take(6).toList();

    final selected = await showMenu<_Notif>(
      context: ctx,
      position: RelativeRect.fromLTRB(
        pos.dx,
        pos.dy + size.height + 6,
        overlay.size.width - pos.dx - size.width,
        0,
      ),
      items: List.generate(entries.length, (i) {
        final n = entries[i];
        final isLast = i == entries.length - 1;
        return PopupMenuItem<_Notif>(
          value: n,
          padding: EdgeInsets.zero,
          child: Padding(
       
            padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
            child: Glass(
              radius: 12,
              child: ListTile(
                dense: true,
                title: Text(
                  n.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    ctx,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  n.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  _fmtAgo(n.createdAt),
                  style: Theme.of(ctx).textTheme.labelSmall,
                ),
              ),
            ),
          ),
        );
      }),
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 340),
      elevation: 0,
      color: Colors.transparent, // keep transparent so the gaps show through
    );

    if (selected != null) {
      _routeFor(ctx, selected);
      setState(() => _items.removeWhere((e) => e.id == selected.id));
    }
  }

  void _routeFor(BuildContext context, _Notif n) {
    // Simple mapping; tweak as your detail screens appear
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
        context.push('/notifications');
    }
  }

  String _fmtAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}

class _Notif {
  final int id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String type; // 'chat_message', 'request_updated', 'contract_open', etc.
  final int? entityId; // threadId, requestId, contractId...
  _Notif({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.type,
    this.entityId,
  });
}
