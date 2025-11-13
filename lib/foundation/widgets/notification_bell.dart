// lib/widgets/notifications_bell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:Ajjara/foundation/ui/app_icons.dart';
import 'package:Ajjara/foundation/ui/ui_extras.dart';
import 'package:Ajjara/foundation/widgets/notifications_store.dart';
import 'package:Ajjara/main.dart';

enum _MenuAction { seeAll }

class NotificationsBell extends StatefulWidget {
  const NotificationsBell({super.key});
  @override
  State<NotificationsBell> createState() => _NotificationsBellState();
}

class _NotificationsBellState extends State<NotificationsBell> {
  final _btnKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: notificationsStore,
      builder: (_, __) {
        final items = notificationsStore.items;
        final unread = items.length; // if you track read state, change this

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
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
      },
    );
  }

  void _showDropdown() async {
    final ctx = context;
    final rb = _btnKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;

    final overlay = Overlay.of(ctx).context.findRenderObject() as RenderBox;
    final pos = rb.localToGlobal(Offset.zero, ancestor: overlay);
    final size = rb.size;

    final entries = notificationsStore.recent(6);

    // We allow both NotifItem and _MenuAction from the same menu.
    final selected = await showMenu<Object?>(
      context: ctx,
      position: RelativeRect.fromLTRB(
        pos.dx,
        pos.dy + size.height + 6,
        overlay.size.width - pos.dx - size.width,
        0,
      ),
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 340),
      elevation: 0,
      color: Colors.transparent,
      items: <PopupMenuEntry<Object?>>[
        if (entries.isEmpty) ...[
          PopupMenuItem<Object?>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: Glass(
              radius: 12,
              child: ListTile(
                dense: true,
                title: const Text('No notifications'),
                subtitle: const Text('You’re all caught up.'),
              ),
            ),
          ),
          const PopupMenuDivider(height: 6),
          PopupMenuItem<Object?>(
            value: _MenuAction.seeAll,
            padding: EdgeInsets.zero,
            child: Glass(
              radius: 12,
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.inbox_outlined),
                title: const Text('See all notifications'),
              ),
            ),
          ),
        ] else ...[
          // Recent notifications
          ...List.generate(entries.length, (i) {
            final n = entries[i];
            final isLast = i == entries.length - 1;
            return PopupMenuItem<Object?>(
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
                      style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
          const PopupMenuDivider(height: 6),
          PopupMenuItem<Object?>(
            value: _MenuAction.seeAll,
            padding: EdgeInsets.zero,
            child: Glass(
              radius: 12,
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.inbox_outlined),
                title: const Text('See all notifications'),
              ),
            ),
          ),
        ],
      ],
    );

    if (selected == null) return;

    if (selected is _MenuAction && selected == _MenuAction.seeAll) {
      context.push('/notifications');
      return;
    }

    if (selected is NotifItem) {
      _routeFor(ctx, selected);
      notificationsStore.removeById(selected.id);
    }
  }

  void _routeFor(BuildContext context, NotifItem n) {
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
