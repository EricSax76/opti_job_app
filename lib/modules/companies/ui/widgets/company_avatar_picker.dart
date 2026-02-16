import 'dart:typed_data';
import 'package:flutter/material.dart';

class CompanyAvatarPicker extends StatelessWidget {
  const CompanyAvatarPicker({
    super.key,
    this.avatarUrl,
    this.avatarBytes,
    required this.onPickAvatar,
  });

  final String? avatarUrl;
  final Uint8List? avatarBytes;
  final VoidCallback onPickAvatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceContainer = colorScheme.surfaceContainerHighest;
    final muted = colorScheme.onSurfaceVariant;

    ImageProvider? avatarImage;
    if (avatarBytes != null) {
      avatarImage = ResizeImage(
        MemoryImage(avatarBytes!),
        width: 256,
        height: 256,
      );
    } else if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      avatarImage = NetworkImage(avatarUrl!);
    }

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: surfaceContainer,
            backgroundImage: avatarImage,
            child: avatarImage == null
                ? Icon(
                    Icons.business_outlined,
                    size: 40,
                    color: muted,
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: onPickAvatar,
              borderRadius: BorderRadius.circular(16),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primary,
                child: Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
