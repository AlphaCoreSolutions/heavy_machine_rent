// lib/screens/chat_list_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';
import 'package:heavy_new/l10n/app_localizations.dart';
import 'package:heavy_new/core/api/api_handler.dart' as api;

// If you have an ApiEnvelope type, import it; otherwise the code below
// simply treats unknown shapes defensively.

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
      final raw = await api.Api.getChatThreads();

      // —— Robustly coerce to List<dynamic> —— //
      final List<dynamic> rows = _asList(raw);

      // Map to view models (guard each field)
      _threads = rows.map((m) {
        // Support both strongly-typed models and Map responses
        final id = _pickInt(m, ['threadId', 'id']) ?? 0;
        final title =
            _pickString(m, ['title', 'name'])?.trim().isNotEmpty == true
            ? _pickString(m, ['title', 'name'])!.trim()
            : context.l10n.unnamedFactory; // neutral, already localized
        final lastMsg =
            _pickString(m, ['lastMessage', 'last_msg', 'message'])?.trim() ??
            '';
        final lastAt =
            _pickDate(m, ['lastAt', 'last_at', 'updatedAt']) ?? DateTime.now();
        final unread =
            _pickInt(m, ['unreadCount', 'unread', 'unread_count']) ?? 0;

        return _ChatThread(
          id: id,
          title: title,
          lastMessage: lastMsg,
          lastAt: lastAt,
          unread: unread,
        );
      }).toList();

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

  // ---- helpers to safely coerce dynamic API shapes ----
  List<dynamic> _asList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;

    // Common server patterns:
    // { data: [...] }, { model: [...] }, { items: [...] }
    if (raw is Map) {
      final candidates = [
        raw['data'],
        raw['model'],
        raw['items'],
        raw['threads'],
        raw['result'],
      ];
      for (final c in candidates) {
        if (c is List) return c;
      }
    }

    // If your client wraps results (e.g., ApiEnvelope), try raw.data, etc.
    try {
      final data = (raw as dynamic).data;
      if (data is List) return data;
    } catch (_) {}

    // Fallback: not a list
    return const [];
  }

  String? _pickString(dynamic m, List<String> keys) {
    if (m == null) return null;
    if (m is Map) {
      for (final k in keys) {
        final v = m[k];
        if (v is String) return v;
      }
      return null;
    }
    // object with fields
    try {
      for (final k in keys) {
        final v = (m as dynamic).toJson != null
            ? (m as dynamic).toJson()[k]
            : (m as dynamic).__getattribute__(k);
        if (v is String) return v;
      }
    } catch (_) {
      // Try direct field access
      // ignore: unused_local_variable
      for (final k in keys) {
        try {
          (m as dynamic)
              .toString(); // last resort – but avoid spamming title with whole object
          // don't use this for content fields
          // We won't return from here.
        } catch (_) {}
      }
    }
    // direct properties (best effort)
    try {
      for (final k in keys) {
        final v = (m as dynamic)[k];
        if (v is String) return v;
      }
    } catch (_) {}
    // strongly-typed model getters
    try {
      final v = (m as dynamic).title;
      if (v is String) return v;
    } catch (_) {}
    return null;
  }

  int? _pickInt(dynamic m, List<String> keys) {
    if (m == null) return null;
    if (m is Map) {
      for (final k in keys) {
        final v = m[k];
        if (v is int) return v;
        if (v is num) return v.toInt();
        if (v is String) return int.tryParse(v);
      }
      return null;
    }
    try {
      for (final k in keys) {
        final v = (m as dynamic)..[k]; // will throw; skip
        if (v is int) return v;
      }
    } catch (_) {}
    // common direct fields
    try {
      final v = (m as dynamic).threadId;
      if (v is int) return v;
    } catch (_) {}
    return null;
  }

  DateTime? _pickDate(dynamic m, List<String> keys) {
    if (m == null) return null;
    if (m is Map) {
      for (final k in keys) {
        final v = m[k];
        if (v is DateTime) return v;
        if (v is String) {
          final p = DateTime.tryParse(v);
          if (p != null) return p;
        }
        if (v is int) {
          // epoch seconds/ms heuristic
          if (v > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(v);
          if (v > 1000000000) {
            return DateTime.fromMillisecondsSinceEpoch(v * 1000);
          }
        }
      }
      return null;
    }
    try {
      for (final k in keys) {
        final v = (m as dynamic)..[k]; // will throw; skip
        if (v is DateTime) return v;
      }
    } catch (_) {}
    try {
      final v = (m as dynamic).lastAt;
      if (v is DateTime) return v;
    } catch (_) {}
    return null;
  }
  // ---- end helpers ----

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
                  textAlign: TextAlign.center,
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
      final emptyText = _search.text.trim().isEmpty
          ? context.l10n.noChatsYet
          : context.l10n.mapNoResults;
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
              backgroundColor: cs.surfaceContainerHighest,
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
