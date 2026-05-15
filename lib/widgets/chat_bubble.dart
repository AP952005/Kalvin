import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,

      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),

        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),

        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: message.isUser
              ? AppTheme.primaryBlue
              : const Color(0xFF1B2230),

          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),

            bottomLeft: message.isUser
                ? const Radius.circular(18)
                : const Radius.circular(4),

            bottomRight: message.isUser
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
        ),

        child: Text(
          message.text,

          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
