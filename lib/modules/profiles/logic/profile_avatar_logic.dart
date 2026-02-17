import 'dart:typed_data';

import 'package:flutter/material.dart';

class ProfileAvatarLogic {
  const ProfileAvatarLogic._();

  static ImageProvider? resolveImageProvider({
    required Uint8List? avatarBytes,
    required String? avatarUrl,
  }) {
    if (avatarBytes != null) return MemoryImage(avatarBytes);

    final normalizedAvatarUrl = _normalizeText(avatarUrl);
    if (normalizedAvatarUrl == null) return null;
    return NetworkImage(normalizedAvatarUrl);
  }

  static String? _normalizeText(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}
