import 'package:flutter/material.dart';

class InterviewListTileTitle extends StatelessWidget {
  const InterviewListTileTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.w600));
  }
}
