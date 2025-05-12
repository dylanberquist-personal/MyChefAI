import 'package:flutter/material.dart';

class RecipeLoadingIndicator extends StatelessWidget {
  final String loadingMessage;

  const RecipeLoadingIndicator({
    Key? key,
    required this.loadingMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFFFFC1).withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFFFFFFC1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            loadingMessage,
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          LinearProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFFFC1)),
            backgroundColor: Colors.grey[200],
          ),
        ],
      ),
    );
  }
}