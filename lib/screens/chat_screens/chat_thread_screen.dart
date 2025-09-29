import 'package:flutter/material.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';
import 'package:heavy_new/l10n/app_localizations.dart';
import 'package:heavy_new/core/api/api_handler.dart' as api;

extension _L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({super.key, required this.threadId, this.title});
  final int threadId;
  final String? title;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  bool _sending = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await api.Api.getThreadMessages(widget.threadId);
      _msgs
        ..clear()
        ..addAll(
          rows.map(
            (m) => _Msg(
              text: m.text ?? '',
              me: m.isMine ?? false,
              at: m.createdAt ?? DateTime.now(),
            ),
          ),
        );
    } catch (_) {
      // demo fallback
      _msgs
        ..clear()
        ..addAll([
          _Msg(
            text: 'Hello! Looking to rent a loader.',
            me: true,
            at: DateTime.now().subtract(const Duration(minutes: 60)),
          ),
          _Msg(
            text: 'Hi! We have availability tomorrow.',
            me: false,
            at: DateTime.now().subtract(const Duration(minutes: 55)),
          ),
          _Msg(
            text: 'Great. What time can you deliver?',
            me: true,
            at: DateTime.now().subtract(const Duration(minutes: 40)),
          ),
          _Msg(
            text: 'Morning delivery is possible.',
            me: false,
            at: DateTime.now().subtract(const Duration(minutes: 35)),
          ),
        ]);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);

    // optimistic add
    final m = _Msg(text: text, me: true, at: DateTime.now());
    setState(() {
      _msgs.add(m);
      _input.clear();
    });

    try {
      await api.Api.sendThreadMessage(widget.threadId, text);
    } catch (_) {
      // keep optimistic; optionally show a toast
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        await Future.delayed(const Duration(milliseconds: 80));
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? context.l10n.chatTitle(widget.threadId)),
        actions: [
          IconButton(
            icon: AIcon(AppGlyph.info, color: cs.primary),
            onPressed: () {
              AppSnack.info(context, context.l10n.threadActionsSoon);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              itemCount: _msgs.length,
              itemBuilder: (_, i) {
                final m = _msgs[i];
                final align = m.me
                    ? Alignment.centerRight
                    : Alignment.centerLeft;
                final bubbleColor = m.me ? cs.primary : cs.surfaceContainerHighest;
                final textColor = m.me ? Colors.white : cs.onSurface;
                return Align(
                  alignment: align,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(14),
                          topRight: const Radius.circular(14),
                          bottomLeft: Radius.circular(m.me ? 14 : 4),
                          bottomRight: Radius.circular(m.me ? 4 : 14),
                        ),
                      ),
                      child: Text(m.text, style: TextStyle(color: textColor)),
                    ),
                  ),
                );
              },
            ),
          ),
          Glass(
            radius: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: AInput(
                        controller: _input,
                        hint: context.l10n.messageHint,
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _sending ? null : _send,
                      icon: AIcon(
                        AppGlyph.send,
                        color: Colors.white,
                        selected: true,
                      ),
                      label: Text(
                        _sending
                            ? context.l10n.sendingEllipsis
                            : context.l10n.actionSend,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool me;
  final DateTime at;
  _Msg({required this.text, required this.me, required this.at});
}


/*
// lib/screens/chat_thread_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';
import 'package:heavy_new/l10n/app_localizations.dart';
import 'package:heavy_new/core/api/api_handler.dart' as api;

extension _L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({super.key, required this.threadId, this.title});
  final int threadId;
  final String? title;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  bool _sending = false;
  bool _loading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final rows = await api.Api.getThreadMessages(widget.threadId);
      _msgs
        ..clear()
        ..addAll(rows.map((m) => _Msg(
              id: m.messageId ?? 0,
              text: m.text ?? '',
              me: m.isMine ?? false,
              at: m.createdAt ?? DateTime.now(),
            )));
      // Oldest first for chat list
      _msgs.sort((a, b) => a.at.compareTo(b.at));
      await _scrollToBottom();
    } catch (e) {
      _loadError = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _scrollToBottom() async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);

    // optimistic message
    final temp = _Msg(
      id: DateTime.now().microsecondsSinceEpoch * -1, // temp negative id
      text: text,
      me: true,
      at: DateTime.now(),
      pending: true,
    );
    setState(() {
      _msgs.add(temp);
      _input.clear();
    });
    await _scrollToBottom();

    try {
      final sent = await api.Api.sendThreadMessage(widget.threadId, text);
      // Replace temp with server echo if you have it
      final idx = _msgs.indexWhere((m) => m.id == temp.id);
      if (idx >= 0) {
        _msgs[idx] = _Msg(
          id: sent.messageId ?? temp.id,
          text: sent.text ?? text,
          me: sent.isMine ?? true,
          at: sent.createdAt ?? temp.at,
        );
      }
    } catch (e) {
      // Mark the temp message as failed (optional) or keep it as is.
      final idx = _msgs.indexWhere((m) => m.id == temp.id);
      if (idx >= 0) {
        _msgs[idx] = temp.copyWith(pending: false, failed: true);
      }
      if (mounted) {
        AppSnack.error(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        await _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? context.l10n.chatTitle(widget.threadId)),
        actions: [
          IconButton(
            icon: AIcon(AppGlyph.info, color: cs.primary),
            onPressed: () {
              AppSnack.info(context, context.l10n.threadActionsSoon);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_loadError != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _loadError!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.error),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                itemCount: _msgs.length,
                itemBuilder: (_, i) {
                  final m = _msgs[i];
                  final align =
                      m.me ? Alignment.centerRight : Alignment.centerLeft;
                  final bubbleColor = m.me
                      ? (m.failed == true
                          ? cs.error
                          : (m.pending == true
                              ? cs.primary.withOpacity(0.7)
                              : cs.primary))
                      : cs.surfaceVariant;
                  final textColor = m.me ? Colors.white : cs.onSurface;
                  return Align(
                    alignment: align,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            topRight: const Radius.circular(14),
                            bottomLeft: Radius.circular(m.me ? 14 : 4),
                            bottomRight: Radius.circular(m.me ? 4 : 14),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: m.me
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(m.text, style: TextStyle(color: textColor)),
                            if (m.pending == true || m.failed == true)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  m.failed == true
                                      ? context.l10n.errorFailedToLoadOptions
                                      : context.l10n.sendingEllipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                          color: m.failed == true
                                              ? Colors.white
                                              : Colors.white70),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Glass(
            radius: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: AInput(
                        controller: _input,
                        hint: context.l10n.messageHint,
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _sending ? null : _send,
                      icon: AIcon(AppGlyph.send,
                          color: Colors.white, selected: true),
                      label: Text(_sending
                          ? context.l10n.sendingEllipsis
                          : context.l10n.actionSend),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final int id;
  final String text;
  final bool me;
  final DateTime at;
  final bool? pending; // optimistic state
  final bool? failed;  // send failed

  _Msg({
    required this.id,
    required this.text,
    required this.me,
    required this.at,
    this.pending,
    this.failed,
  });

  _Msg copyWith({
    int? id,
    String? text,
    bool? me,
    DateTime? at,
    bool? pending,
    bool? failed,
  }) =>
      _Msg(
        id: id ?? this.id,
        text: text ?? this.text,
        me: me ?? this.me,
        at: at ?? this.at,
        pending: pending ?? this.pending,
        failed: failed ?? this.failed,
      );
}

*/