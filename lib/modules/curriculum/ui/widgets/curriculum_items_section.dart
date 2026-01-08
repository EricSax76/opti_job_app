import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_styles.dart';

class CurriculumItemsSection extends StatelessWidget {
  const CurriculumItemsSection({
    super.key,
    required this.title,
    required this.items,
    required this.emptyHint,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final String title;
  final List<CurriculumItem> items;
  final String emptyHint;
  final VoidCallback onAdd;
  final Future<void> Function(int index, CurriculumItem item) onEdit;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ],
        ),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cvBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cvBorder),
            ),
            child: Text(
              emptyHint,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cvMuted),
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < items.length; i++)
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(
                      items[i].title.isEmpty ? 'Sin título' : items[i].title,
                    ),
                    subtitle: Text(
                      [
                        if (items[i].subtitle.trim().isNotEmpty)
                          items[i].subtitle.trim(),
                        if (items[i].period.trim().isNotEmpty)
                          items[i].period.trim(),
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await onEdit(i, items[i]);
                        } else if (value == 'remove') {
                          onRemove(i);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'remove', child: Text('Eliminar')),
                      ],
                    ),
                    onTap: () => onEdit(i, items[i]),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

Future<CurriculumItem?> showCurriculumItemDialog(
  BuildContext context, {
  CurriculumItem? initial,
}) {
  final initialItem = initial ?? CurriculumItem.empty();
  final titleController = TextEditingController(text: initialItem.title);
  final subtitleController = TextEditingController(text: initialItem.subtitle);
  final periodController = TextEditingController(text: initialItem.period);
  final descriptionController = TextEditingController(
    text: initialItem.description,
  );

  return showDialog<CurriculumItem>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(initial == null ? 'Agregar' : 'Editar'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: subtitleController,
                decoration: const InputDecoration(labelText: 'Subtítulo'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: periodController,
                decoration: const InputDecoration(labelText: 'Periodo'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(
                CurriculumItem(
                  title: titleController.text.trim(),
                  subtitle: subtitleController.text.trim(),
                  period: periodController.text.trim(),
                  description: descriptionController.text.trim(),
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  ).whenComplete(() {
    titleController.dispose();
    subtitleController.dispose();
    periodController.dispose();
    descriptionController.dispose();
  });
}
