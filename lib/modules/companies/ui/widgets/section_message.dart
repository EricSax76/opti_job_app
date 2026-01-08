import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

class SectionMessage extends StatelessWidget {
  const SectionMessage({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(uiCardRadius),
        border: Border.all(color: uiBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(color: uiMuted, height: 1.4),
      ),
    );
  }
}
