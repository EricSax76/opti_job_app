import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.avatarBytes,
    this.avatarUrl,
    required this.onPickImage,
  });

  final Uint8List? avatarBytes;
  final String? avatarUrl;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    const backgroundColor = uiBackground;
    const inkColor = uiInk;
    const mutedColor = uiMuted;

    final imageProvider = _getImageProvider();

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: backgroundColor,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(Icons.person, size: 40, color: mutedColor)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: onPickImage,
              borderRadius: BorderRadius.circular(uiTileRadius),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: inkColor,
                child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _getImageProvider() {
    if (avatarBytes != null) return MemoryImage(avatarBytes!);
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return NetworkImage(avatarUrl!);
    }
    return null;
  }
}
