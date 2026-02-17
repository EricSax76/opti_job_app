import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class ProfileFormViewModel extends Equatable {
  const ProfileFormViewModel({
    required this.avatarBytes,
    required this.avatarUrl,
    required this.canSubmit,
    required this.isSaving,
    required this.sessionLabel,
  });

  final Uint8List? avatarBytes;
  final String? avatarUrl;
  final bool canSubmit;
  final bool isSaving;
  final String sessionLabel;

  @override
  List<Object?> get props => [
    avatarBytes,
    avatarUrl,
    canSubmit,
    isSaving,
    sessionLabel,
  ];
}
