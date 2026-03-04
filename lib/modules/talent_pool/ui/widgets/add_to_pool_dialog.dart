import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/inline_state_message.dart';
import 'package:opti_job_app/modules/talent_pool/models/talent_pool.dart';

class AddToPoolDialog extends StatefulWidget {
  const AddToPoolDialog({super.key, required this.pools, required this.onAdd});

  final List<TalentPool> pools;
  final Function(List<String> poolIds, List<String> tags) onAdd;

  @override
  State<AddToPoolDialog> createState() => _AddToPoolDialogState();
}

class _AddToPoolDialogState extends State<AddToPoolDialog> {
  final Set<String> _selectedPoolIds = {};
  final TextEditingController _tagsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add to Talent Pool'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select one or more pools:'),
            const SizedBox(height: uiSpacing8),
            ...widget.pools.map(
              (pool) => CheckboxListTile(
                title: Text(pool.name),
                value: _selectedPoolIds.contains(pool.id),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedPoolIds.add(pool.id);
                    } else {
                      _selectedPoolIds.remove(pool.id);
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: uiSpacing16),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Add Tags (comma separated)',
                hintText: 'e.g. priority, frontend, potential',
              ),
            ),
            const SizedBox(height: uiSpacing8),
            const InlineStateMessage(
              icon: Icons.verified_user_outlined,
              message:
                  'A consent request will be sent to the candidate if required.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedPoolIds.isEmpty
              ? null
              : () {
                  final tags = _tagsController.text
                      .split(',')
                      .map((t) => t.trim())
                      .where((t) => t.isNotEmpty)
                      .toList();
                  widget.onAdd(_selectedPoolIds.toList(), tags);
                  Navigator.pop(context);
                },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
