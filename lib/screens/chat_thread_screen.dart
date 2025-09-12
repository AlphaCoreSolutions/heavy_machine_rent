import 'package:flutter/material.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({super.key, required this.threadId});
  final int threadId;
  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [
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
  ];
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
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
    await Future.delayed(const Duration(milliseconds: 220)); // simulate network

    // TODO: call your API: Api.sendMessage(threadId, text)
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat #${widget.threadId}'),
        actions: [
          IconButton(
            icon: AIcon(AppGlyph.info, color: cs.primary),
            onPressed: () {
              AppSnack.info(context, 'Thread actions coming soon');
            },
          ),
        ],
      ),
      body: Column(
        children: [
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
                        hint: 'Message',
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
                      label: const Text('Send'),
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
