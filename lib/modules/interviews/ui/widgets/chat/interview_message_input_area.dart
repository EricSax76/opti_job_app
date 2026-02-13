import 'package:flutter/material.dart';

class InterviewMessageInputArea extends StatelessWidget {
  const InterviewMessageInputArea({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onProposeSlot,
    required this.onStartMeeting,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final Future<void> Function() onProposeSlot;
  final Future<void> Function() onStartMeeting;

  @override
  Widget build(BuildContext context) {
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
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: onProposeSlot,
            ),
            IconButton(
              icon: const Icon(Icons.video_call),
              onPressed: onStartMeeting,
            ),
            IconButton(icon: const Icon(Icons.send), onPressed: onSend),
          ],
        ),
      ),
    );
  }
}
