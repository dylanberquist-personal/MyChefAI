// In lib/components/restart_chat_dialog.dart
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Start a new recipe?',
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w700,
                color: Color(0xFF030303),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'This will clear the current conversation and let you start fresh with a new recipe idea.',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w500,
                color: Color(0xFF030303),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(color: Color(0xFFD3D3D3)),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF030303),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onRestartConfirmed();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFFFC1),
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'New Recipe',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}