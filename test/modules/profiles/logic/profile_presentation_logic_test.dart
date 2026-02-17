import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_form_state.dart';
import 'package:opti_job_app/modules/profiles/logic/profile_avatar_logic.dart';
import 'package:opti_job_app/modules/profiles/logic/profile_form_logic.dart';

void main() {
  group('ProfileFormLogic', () {
    test('validates required first and last name fields', () {
      expect(
        ProfileFormLogic.validateFirstName(' '),
        ProfileFormLogic.requiredNameMessage,
      );
      expect(
        ProfileFormLogic.validateLastName(''),
        ProfileFormLogic.requiredLastNameMessage,
      );
      expect(ProfileFormLogic.validateFirstName('Ana'), isNull);
      expect(ProfileFormLogic.validateLastName('Lopez'), isNull);
    });

    test('buildViewModel trims avatar url and resolves candidate label', () {
      const state = ProfileFormState(
        candidateName: '  Ana Perez ',
        avatarUrl: ' https://cdn.example.com/avatar.png ',
        canSubmit: true,
        isSaving: false,
      );

      final viewModel = ProfileFormLogic.buildViewModel(state);

      expect(viewModel.sessionLabel, 'Sesión activa como Ana Perez');
      expect(viewModel.avatarUrl, 'https://cdn.example.com/avatar.png');
      expect(viewModel.canSubmit, isTrue);
      expect(viewModel.isSaving, isFalse);
    });

    test('buildViewModel falls back to default candidate label', () {
      const state = ProfileFormState(candidateName: '   ');

      final viewModel = ProfileFormLogic.buildViewModel(state);

      expect(viewModel.sessionLabel, 'Sesión activa como Candidato');
    });

    test('shouldHandleNotice reacts to notice changes only', () {
      const previous = ProfileFormState();
      const current = ProfileFormState(
        notice: ProfileFormNotice.success,
        noticeMessage: 'Perfil actualizado.',
      );
      const unchanged = ProfileFormState(
        notice: ProfileFormNotice.success,
        noticeMessage: 'Perfil actualizado.',
      );

      expect(
        ProfileFormLogic.shouldHandleNotice(
          previous: previous,
          current: current,
        ),
        isTrue,
      );
      expect(
        ProfileFormLogic.shouldHandleNotice(
          previous: current,
          current: unchanged,
        ),
        isFalse,
      );
    });

    test('resolveNoticeMessage requires notice and trims message', () {
      const noNotice = ProfileFormState(noticeMessage: 'Perfil actualizado.');
      const withNotice = ProfileFormState(
        notice: ProfileFormNotice.success,
        noticeMessage: ' Perfil actualizado. ',
      );

      expect(ProfileFormLogic.resolveNoticeMessage(noNotice), isNull);
      expect(
        ProfileFormLogic.resolveNoticeMessage(withNotice),
        'Perfil actualizado.',
      );
    });
  });

  group('ProfileAvatarLogic', () {
    test('prefers memory image over avatar url', () {
      final provider = ProfileAvatarLogic.resolveImageProvider(
        avatarBytes: Uint8List.fromList(const [1, 2, 3]),
        avatarUrl: 'https://cdn.example.com/avatar.png',
      );

      expect(provider, isA<MemoryImage>());
    });

    test('returns network image for trimmed non-empty url', () {
      final provider = ProfileAvatarLogic.resolveImageProvider(
        avatarBytes: null,
        avatarUrl: ' https://cdn.example.com/avatar.png ',
      );

      expect(provider, isA<NetworkImage>());
      expect(
        (provider as NetworkImage).url,
        'https://cdn.example.com/avatar.png',
      );
    });

    test('returns null when no avatar bytes and no valid url', () {
      final provider = ProfileAvatarLogic.resolveImageProvider(
        avatarBytes: null,
        avatarUrl: '  ',
      );

      expect(provider, isNull);
    });
  });
}
