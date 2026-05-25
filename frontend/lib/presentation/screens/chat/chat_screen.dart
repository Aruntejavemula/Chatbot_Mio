import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, this.chatId});

  final String? chatId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(chatId != null ? 'Chat: $chatId' : 'Chat'),
      ),
    );
  }
}
