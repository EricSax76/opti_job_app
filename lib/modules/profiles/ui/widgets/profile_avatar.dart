import 'dart:typed_data';
import 'package:flutter/material.dart';

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
    const backgroundColor = Color(0xFFF8FAFC);
    const inkColor = Color(0xFF0F172A);
    const mutedColor = Color(0xFF475569);

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
              borderRadius: BorderRadius.circular(18),
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
