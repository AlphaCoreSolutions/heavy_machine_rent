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
                final bubbleColor = m.me ? cs.primary : cs.surfaceVariant;
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
