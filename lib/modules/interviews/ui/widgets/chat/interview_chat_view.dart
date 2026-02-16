import 'package:flutter/material.dart';

class InterviewChatView extends StatelessWidget {
  const InterviewChatView({
    super.key,
    this.body,
    this.inputArea,
    this.title = 'Entrevista',
  });

  final Widget? body;
  final Widget? inputArea;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (body != null) Expanded(child: body!),
          if (inputArea != null) inputArea!,
        ],
      ),
    );
  }
}
