import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({
    super.key,
    required this.tagline,
    required this.title,
    required this.subtitle,
    required this.child,
    this.maxWidth = 440,
  });

  final String tagline;
  final String title;
  final String subtitle;
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: uiSpacing16,
          vertical: uiSpacing24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: AppCard(
            padding: const EdgeInsets.all(uiSpacing24 + 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  tagline: tagline,
                  title: title,
                  subtitle: subtitle,
                ),
                const SizedBox(height: uiSpacing24),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
