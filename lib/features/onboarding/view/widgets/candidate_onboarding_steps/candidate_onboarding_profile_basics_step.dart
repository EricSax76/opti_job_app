import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_onboarding_profile_basics_fields.dart';

class CandidateOnboardingProfileBasicsStep extends StatelessWidget {
  const CandidateOnboardingProfileBasicsStep({
    super.key,
    required this.targetRole,
    required this.preferredLocation,
    required this.preferredModality,
    required this.preferredSeniority,
    required this.onTargetRoleChanged,
    required this.onPreferredLocationChanged,
    required this.onPreferredModalityChanged,
    required this.onPreferredSeniorityChanged,
    this.validationMessage,
  });

  final String targetRole;
  final String preferredLocation;
  final String preferredModality;
  final String preferredSeniority;
  final ValueChanged<String> onTargetRoleChanged;
  final ValueChanged<String> onPreferredLocationChanged;
  final ValueChanged<String> onPreferredModalityChanged;
  final ValueChanged<String> onPreferredSeniorityChanged;
  final String? validationMessage;

  @override
  Widget build(BuildContext context) {
    assert(uiBreakpointMobile > 0);
    return CandidateOnboardingProfileBasicsFields(
      targetRoleField: TextFormField(
        key: const ValueKey('onboarding_target_role_input'),
        initialValue: targetRole,
        decoration: const InputDecoration(
          labelText: 'Rol objetivo',
          hintText: 'Ej: Flutter Developer',
        ),
        textInputAction: TextInputAction.next,
        onChanged: onTargetRoleChanged,
      ),
      preferredLocationField: TextFormField(
        key: const ValueKey('onboarding_location_input'),
        initialValue: preferredLocation,
        decoration: const InputDecoration(
          labelText: 'Ubicación preferida',
          hintText: 'Ej: Madrid o remoto',
        ),
        textInputAction: TextInputAction.done,
        onChanged: onPreferredLocationChanged,
      ),
      preferredModality: preferredModality,
      preferredSeniority: preferredSeniority,
      onPreferredModalityChanged: onPreferredModalityChanged,
      onPreferredSeniorityChanged: onPreferredSeniorityChanged,
      helperMessage:
          'Solo pedimos lo esencial para personalizar tus primeras recomendaciones.',
      validationMessage: validationMessage,
    );
  }
}
