import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_session_cubit.dart';
import 'package:opti_job_app/modules/interviews/models/interview_message.dart';
import 'package:opti_job_app/modules/interviews/repositories/interview_repository.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class InterviewChatPage extends StatelessWidget {
  const InterviewChatPage({super.key, required this.interviewId});

  final String interviewId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InterviewSessionCubit(
        repository: context.read<InterviewRepository>(),
        interviewId: interviewId,
      )..markAsSeen(),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _messageController = TextEditingController();

  void _sendMessage() {
    final content = _messageController.text;
    if (content.trim().isEmpty) return;
    context.read<InterviewSessionCubit>().sendMessage(content);
    _messageController.clear();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrevista')),
      body: BlocListener<InterviewSessionCubit, InterviewSessionState>(
        listenWhen: (previous, current) => current is InterviewSessionActionError,
        listener: (context, state) {
          if (state is! InterviewSessionActionError) return;
          final message = state.error.trim();
          if (message.isEmpty) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: BlocBuilder<InterviewSessionCubit, InterviewSessionState>(
                builder: (context, state) {
                  if (state is InterviewSessionLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is InterviewSessionError) {
                    return Center(child: Text('Error: ${state.message}'));
                  }

                  InterviewSessionLoaded? loadedState;
                  if (state is InterviewSessionLoaded) {
                    loadedState = state;
                  } else if (state is InterviewSessionActionError) {
                    loadedState = state.previousState;
                  }

                  if (loadedState == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = loadedState.messages;
                  final meetingLink = loadedState.interview.meetingLink;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (meetingLink != null)
                        Container(
                          color: Colors.blue.shade100,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.video_camera_front,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Videollamada en curso',
                                  style: TextStyle(
                                    color: Colors.blue.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              FilledButton(
                                onPressed: () async {
                                  final uri = Uri.parse(meetingLink);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                },
                                child: const Text('Unirse'),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: messages.isEmpty
                            ? const Center(child: Text('No hay mensajes aún.'))
                            : ListView.builder(
                                reverse: true,
                                padding: const EdgeInsets.all(16),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final msg = messages[index];
                                  return _MessageBubble(message: msg);
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
            _buildInputArea(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (date == null) return;

                if (!context.mounted) return;

                final time = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 10, minute: 0),
                );
                if (time == null) return;

                final dateTime = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );

                if (context.mounted) {
                  // Ask for time zone or assume local?
                  // For MVP assume local of the device proposing.
                  final timeZone = DateTime.now().timeZoneName;
                  context.read<InterviewSessionCubit>().proposeSlot(
                    dateTime,
                    timeZone,
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.video_call),
              onPressed: () async {
                // For MVP: Show dialog to enter link or generate dummy
                final controller = TextEditingController(
                  text: 'https://meet.google.com/new',
                );
                final link = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Iniciar Videollamada'),
                    content: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Enlace de la reunión',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, controller.text),
                        child: const Text('Iniciar'),
                      ),
                    ],
                  ),
                );

                if (link != null && link.isNotEmpty && context.mounted) {
                  context.read<InterviewSessionCubit>().startMeeting(link);
                }
              },
            ),
            IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final InterviewMessage message;

  const _MessageBubble({required this.message});

  String _safeFormatDateTime(DateTime date, String pattern) {
    try {
      return DateFormat(pattern).format(date);
    } catch (_) {
      return date.toLocal().toIso8601String();
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return _buildBubble(context);
    } catch (_) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: const Text('No se pudo renderizar este mensaje.'),
        ),
      );
    }
  }

  Widget _buildBubble(BuildContext context) {
    // Alignment logic... placeholder:
    // Ideally we need currentUserUid.
    // For MVP, render simple card.
    // Let's differentiate System vs User text.

    final isSystem = message.type == MessageType.system;

    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(message.content, style: const TextStyle(fontSize: 12)),
        ),
      );
    }

    return Align(
      alignment: isSystem
          ? Alignment.center
          : Alignment.centerLeft, // We need to fix alignment.
      // Let's assume left is "other" and right is "me".
      // Since we don't know who "me" is easily, let's just align left for now or fix later.
      // Actually, we can check if senderUid matches current user.
      // But we don't have current user UID here.
      // Let's fetch it in the parent and pass it down?
      // Or just align left for MVP.
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSystem ? Colors.grey.shade200 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: message.type == MessageType.proposal
              ? Border.all(color: Colors.blue.shade200)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.type == MessageType.proposal) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Propuesta de entrevista',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (message.metadata?.proposedAt case final proposedAt?)
                Text(
                  _safeFormatDateTime(proposedAt, 'EEEE d MMM, h:mm a'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 8),
            ],
            Text(message.content),

            if (message.type == MessageType.proposal) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      context.read<InterviewSessionCubit>().respondToSlot(
                        message.id,
                        true,
                      );
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aceptar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 40),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<InterviewSessionCubit>().respondToSlot(
                        message.id,
                        false,
                      );
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size(0, 40),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 4),
            Text(
              _safeFormatDateTime(message.createdAt, 'jm'),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
