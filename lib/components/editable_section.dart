// lib/components/editable_section.dart
import 'package:flutter/material.dart';
import '../components/header_text.dart';
import '../components/text_card.dart';

class EditableSection extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final bool isEditing;
  final Function(bool) onEditToggle;
  final bool isMultiline;
  final Function() onSave;
  final double contentSpacing;
  final double sectionSpacing;

  const EditableSection({
    Key? key,
    required this.title,
    required this.controller,
    required this.isEditing,
    required this.onEditToggle,
    required this.onSave,
    this.isMultiline = true,
    this.contentSpacing = 12.0,
    this.sectionSpacing = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            HeaderText(text: title),
            IconButton(
              icon: Icon(isEditing ? Icons.check : Icons.edit),
              onPressed: () async {
                if (isEditing) {
                  await onSave();
                }
                onEditToggle(!isEditing);
              },
            ),
          ],
        ),
        SizedBox(height: contentSpacing),
        TextCard(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: isEditing
                ? TextField(
                    controller: controller,
                    maxLines: isMultiline ? null : 1,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter your $title',
                    ),
                  )
                : Text(
                    controller.text.isNotEmpty
                        ? controller.text
                        : 'No $title specified',
                    style: TextStyle(
                      fontSize: 16,
                      color: controller.text.isNotEmpty 
                          ? Colors.black 
                          : Colors.grey[600],
                    ),
                  ),
          ),
        ),
        SizedBox(height: sectionSpacing),
      ],
    );
  }
}