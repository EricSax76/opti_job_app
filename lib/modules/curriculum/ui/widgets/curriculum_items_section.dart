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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: uiInk,
                  ),
                ),
                Text(
                  items.isEmpty ? 'Pendiente' : '${items.length} elementos',
                  style: const TextStyle(fontSize: 12, color: uiMuted),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Agregar'),
              style: TextButton.styleFrom(
                backgroundColor: uiAccentSoft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(uiPillRadius),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: uiSpacing16),
        if (items.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(uiSpacing24),
            borderColor: uiBorder,
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: uiMuted.withValues(alpha: 0.5),
                    size: 32,
                  ),
                  const SizedBox(height: uiSpacing8),
                  Text(
                    emptyHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: uiMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: uiSpacing12),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    onTap: () => onEdit(i, items[i]),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: uiSpacing16,
                        vertical: uiSpacing8,
                      ),
                      title: Text(
                        items[i].title.isEmpty ? 'Sin título' : items[i].title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: uiInk,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: uiSpacing4),
                        child: Text(
                          [
                            if (items[i].subtitle.trim().isNotEmpty)
                              items[i].subtitle.trim(),
                            if (items[i].period.trim().isNotEmpty)
                              items[i].period.trim(),
                          ].join(' · '),
                          style: const TextStyle(fontSize: 13, color: uiMuted),
                         ),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 20, color: uiMuted),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(uiTileRadius),
                        ),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await onEdit(i, items[i]);
                          } else if (value == 'remove') {
                            onRemove(i);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 20, color: uiInk),
                                SizedBox(width: uiSpacing12),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'remove',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 20, color: uiError),
                                SizedBox(width: uiSpacing12),
                                Text('Eliminar', style: TextStyle(color: uiError)),
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
