import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/modules/curriculum/logic/curriculum_items_section_logic.dart';
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
    final viewModel = CurriculumItemsSectionLogic.buildViewModel(items);
    final colorScheme = Theme.of(context).colorScheme;
    final ink = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ink,
                  ),
                ),
                Text(
                  viewModel.statusLabel,
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Agregar'),
              style: TextButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(uiPillRadius),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: uiSpacing16),
        if (viewModel.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(uiSpacing24),
            borderColor: colorScheme.outline,
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: muted.withValues(alpha: 0.5),
                    size: 32,
                  ),
                  const SizedBox(height: uiSpacing8),
                  Text(
                    emptyHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              for (final entry in viewModel.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: uiSpacing12),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    onTap: () => onEdit(entry.index, items[entry.index]),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: uiSpacing16,
                        vertical: uiSpacing8,
                      ),
                      title: Text(
                        entry.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ink,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: uiSpacing4),
                        child: Text(
                          entry.subtitle,
                          style: TextStyle(fontSize: 13, color: muted),
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          size: 20,
                          color: muted,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(uiTileRadius),
                        ),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await onEdit(entry.index, items[entry.index]);
                          } else if (value == 'remove') {
                            onRemove(entry.index);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: ink,
                                ),
                                const SizedBox(width: uiSpacing12),
                                const Text('Editar'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'remove',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: colorScheme.error,
                                ),
                                const SizedBox(width: uiSpacing12),
                                Text(
                                  'Eliminar',
                                  style: TextStyle(color: colorScheme.error),
                                ),
                              ],
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
