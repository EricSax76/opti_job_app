import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';

class TalentSearchBar extends StatelessWidget {
  const TalentSearchBar({
    super.key,
    required this.onSearch,
    this.initialValue = '',
    this.hintText = 'Search by skills, tags, or name...',
  });

  final void Function(String query) onSearch;
  final String initialValue;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.fromLTRB(
        uiSpacing16,
        uiSpacing8,
        uiSpacing16,
        0,
      ),
      padding: EdgeInsets.zero,
      child: TextField(
        onChanged: onSearch,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: uiSpacing12,
            vertical: uiSpacing12,
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              // TODO: Advanced filters (location, experience, category)
            },
          ),
        ),
      ),
    );
  }
}
