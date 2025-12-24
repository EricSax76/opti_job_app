import 'package:flutter/material.dart';

class HighlightList extends StatelessWidget {
  const HighlightList({super.key, required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF3FA7A0);
    const ink = Color(0xFF0F172A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, color: accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(color: ink, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
