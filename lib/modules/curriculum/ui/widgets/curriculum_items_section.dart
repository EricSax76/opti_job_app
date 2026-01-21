import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

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
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Agregar'),
            ),
          ],
        ),
        if (items.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(uiSpacing16),
            borderRadius: uiTileRadius,
            child: Text(
              emptyHint,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: uiMuted),
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: uiSpacing8),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    borderRadius: uiTileRadius,
                    onTap: () => onEdit(i, items[i]),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: uiSpacing12,
                        vertical: uiSpacing4,
                      ),
                      title: Text(
                        items[i].title.isEmpty ? 'Sin título' : items[i].title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        [
                          if (items[i].subtitle.trim().isNotEmpty)
                            items[i].subtitle.trim(),
                          if (items[i].period.trim().isNotEmpty)
                            items[i].period.trim(),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await onEdit(i, items[i]);
                          } else if (value == 'remove') {
                            onRemove(i);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined, size: 20),
                              title: Text('Editar'),
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'remove',
                            child: ListTile(
                              leading: Icon(Icons.delete_outline,
                                  size: 20, color: Colors.red),
                              title: Text('Eliminar',
                                  style: TextStyle(color: Colors.red)),
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),
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
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: uiSpacing12),
              TextFormField(
                controller: subtitleController,
                decoration: const InputDecoration(labelText: 'Subtítulo'),
              ),
              const SizedBox(height: uiSpacing12),
              TextFormField(
                controller: periodController,
                decoration: const InputDecoration(labelText: 'Periodo'),
              ),
              const SizedBox(height: uiSpacing12),
              TextFormField(
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

