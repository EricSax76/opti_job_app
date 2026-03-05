import 'package:opti_job_app/modules/profiles/cubits/profile_form_state.dart';
import 'package:opti_job_app/modules/profiles/ui/models/profile_form_view_model.dart';

class ProfileFormLogic {
  const ProfileFormLogic._();

  static const String requiredNameMessage = 'El nombre es obligatorio';
  static const String requiredLastNameMessage =
      'Los apellidos son obligatorios';
  static const String defaultCandidateLabel = 'Candidato';

  static bool shouldHandleNotice({
    required ProfileFormState previous,
    required ProfileFormState current,
  }) {
    return previous.notice != current.notice ||
        previous.noticeMessage != current.noticeMessage;
  }

  static String? resolveNoticeMessage(ProfileFormState state) {
    if (state.notice == null) return null;
    return _normalizeText(state.noticeMessage);
  }

  static ProfileFormViewModel buildViewModel(ProfileFormState state) {
    final candidateName =
        _normalizeText(state.candidateName) ?? defaultCandidateLabel;

    return ProfileFormViewModel(
      avatarBytes: state.avatarBytes,
      avatarUrl: _normalizeText(state.avatarUrl),
      canSubmit: state.canSubmit,
      isSaving: state.isSaving,
      sessionLabel: 'Sesión activa como $candidateName',
    );
  }

  static bool canSubmit(ProfileFormState state) {
    return state.canSubmit;
  }

  static String? validateFirstName(String? value) {
    if (_normalizeText(value) == null) return requiredNameMessage;
    return null;
  }

  static String? validateLastName(String? value) {
    // Last name is optional; many existing accounts only have a single name.
    // Keeping this optional prevents blocking avatar/profile saves.
    return null;
  }

  static String? _normalizeText(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}
