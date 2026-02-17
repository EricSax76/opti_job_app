import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';

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
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: uiSpacing4 / 2,
    );

    return Scaffold(
      appBar: AppBar(title: Text(title, style: titleStyle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child:
                body ??
                const StateMessage(
                  title: 'Sesion no disponible',
                  message: 'No se pudo abrir el contenido del chat.',
                ),
          ),
          if (inputArea != null) inputArea!,
        ],
      ),
    );
  }
}
