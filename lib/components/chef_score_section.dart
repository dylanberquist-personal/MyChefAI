// lib/components/chef_score_section.dart
import 'package:flutter/material.dart';
import '../components/header_text.dart';
import '../components/text_card.dart';

class ChefScoreSection extends StatelessWidget {
  final double chefScore;
  final double contentSpacing;
  final double sectionSpacing;

  const ChefScoreSection({
    Key? key,
    required this.chefScore,
    this.contentSpacing = 12.0,
    this.sectionSpacing = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeaderText(text: 'Chef Rating'),
        SizedBox(height: contentSpacing),
        TextCard(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                _buildChefScoreStars(chefScore),
                SizedBox(width: 8),
                Text(
                  '${chefScore.toStringAsFixed(1)}/5.0',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: sectionSpacing),
      ],
    );
  }

  Widget _buildChefScoreStars(double score) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < score ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 24,
        );
      }),
    );
  }
}