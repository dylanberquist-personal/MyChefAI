// lib/components/restart_chat_dialog.dart
import 'package:flutter/material.dart';

class RestartChatDialog extends StatelessWidget {
  final VoidCallback onRestartConfirmed;

  const RestartChatDialog({
    Key? key,
    required this.onRestartConfirmed,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onRestartConfirmed,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => RestartChatDialog(
        onRestartConfirmed: onRestartConfirmed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text('Start a new recipe?'),
      content: Text(
        'This will clear the current conversation and let you start fresh with a new recipe idea.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[700],
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onRestartConfirmed();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFFFFC1),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Text('New Recipe'),
        ),
      ],
    );
  }
}