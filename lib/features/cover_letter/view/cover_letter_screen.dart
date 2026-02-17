import 'package:flutter/material.dart';
import 'package:opti_job_app/features/cover_letter/view/containers/cover_letter_container.dart';

class CoverLetterScreen extends StatelessWidget {
  const CoverLetterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Carta de presentación')),
      body: const CoverLetterContainer(),
    );
  }
}
