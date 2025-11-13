// ---- Compact chat button
import 'package:flutter/material.dart';
import 'package:ajjara/foundation/ui/app_icons.dart';
import 'package:ajjara/screens/chat_screens/chat_list_screen.dart';

class ChatActionButton extends StatelessWidget {
  const ChatActionButton({super.key});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: 'Chats',
      icon: AIcon(AppGlyph.chat, color: cs.primary),
      onPressed: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ChatListScreen())),
    );
  }
}
