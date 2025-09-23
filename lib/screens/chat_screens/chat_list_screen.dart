// lib/screens/chat_list_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';
import 'package:heavy_new/l10n/app_localizations.dart';
import 'package:heavy_new/core/api/api_handler.dart' as api;

import 'chat_thread_screen.dart';

extension _L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _search = TextEditingController();
  final _debounceMs = 250;
  Timer? _deb;
  List<_ChatThread> _threads = [];
  List<_ChatThread> _filtered = [];
  bool _loading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _deb?.cancel();
    _search.removeListener(_onQueryChanged);
    _search.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _deb?.cancel();
    _deb = Timer(Duration(milliseconds: _debounceMs), _apply);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final rows = await api.Api.getChatThreads(); // <-- server impl
      _threads = rows
          .map(
            (m) => _ChatThread(
              id: m.threadId ?? 0,
              title: (m.title ?? '').trim().isNotEmpty
                  ? m.title!.trim()
                  : context.l10n.unnamedFactory, // reuse a neutral key
              lastMessage: (m.lastMessage ?? '').trim(),
              lastAt: m.lastAt ?? DateTime.now(),
              unread: m.unreadCount ?? 0,
            ),
          )
          .toList();

      // newest first
      _threads.sort((a, b) => b.lastAt.compareTo(a.lastAt));
    } catch (e) {
      _loadError = e.toString();
      _threads = [];
    } finally {
      _apply();
      if (mounted) setState(() => _loading = false);
    }
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
      appBar: AppBar(title: Text(context.l10n.chatsTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: AInput(
              controller: _search,
              label: context.l10n.searchChats,
              glyph: AppGlyph.search,
              onSubmitted: (_) => _apply(),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(),
            ),
          Expanded(
            child: RefreshIndicator(onRefresh: _load, child: _buildList(cs)),
          ),
        ],
      ),
    );
  }

  Widget _buildList(ColorScheme cs) {
    if (_loadError != null && _threads.isEmpty) {
      // Hard error state (no cache)
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(context.l10n.errorFailedToLoadOptions),
                const SizedBox(height: 8),
                Text(
                  _loadError!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.error),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _load,
                  child: Text(context.l10n.actionRetry),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_filtered.isEmpty) {
      // Empty or no matches
      final emptyText = _search.text.trim().isEmpty
          ? context.l10n.noChatsYet
          : context.l10n.mapNoResults; // reuse a generic "No results"
      return ListView(
        children: [
          Padding(padding: const EdgeInsets.all(24), child: Text(emptyText)),
        ],
      );
    }

    return ListView.separated(
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                  _ago(context, t.lastAt),
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
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ChatThreadScreen(threadId: t.id, title: t.title),
              ),
            ),
          ),
        );
      },
    );
  }

  String _ago(BuildContext context, DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return context.l10n.timeNow;
    if (d.inMinutes < 60) return context.l10n.timeMinutesShort(d.inMinutes);
    if (d.inHours < 24) return context.l10n.timeHoursShort(d.inHours);
    return context.l10n.timeDaysShort(d.inDays);
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
