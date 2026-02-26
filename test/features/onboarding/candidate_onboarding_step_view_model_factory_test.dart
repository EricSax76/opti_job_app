import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/features/onboarding/cubits/candidate_onboarding_cubit.dart';
import 'package:opti_job_app/features/onboarding/cubits/candidate_onboarding_state.dart';
import 'package:opti_job_app/features/onboarding/logic/candidate_onboarding_step_view_model_factory.dart';
import 'package:opti_job_app/features/onboarding/models/candidate_onboarding_step.dart';
import 'package:opti_job_app/features/onboarding/view/widgets/candidate_onboarding_steps/candidate_onboarding_intro_step.dart';
import 'package:opti_job_app/features/onboarding/view/widgets/candidate_onboarding_steps/candidate_onboarding_profile_basics_step.dart';
import 'package:opti_job_app/features/onboarding/view/widgets/candidate_onboarding_steps/candidate_onboarding_work_style_step.dart';
import 'package:opti_job_app/l10n/app_localizations_es.dart';

void main() {
  const factory = CandidateOnboardingStepViewModelFactory();
  final l10n = AppLocalizationsEs();

  group('CandidateOnboardingStepViewModelFactory', () {
    late CandidateOnboardingCubit cubit;

    setUp(() {
      cubit = CandidateOnboardingCubit();
    });

    tearDown(() async {
      await cubit.close();
    });

    test('builds welcome step with intro body and next action', () {
      final viewModel = factory.build(
        state: cubit.state,
        cubit: cubit,
        candidateName: 'Ana',
        l10n: l10n,
      );

      expect(viewModel.title, 'Bienvenido, Ana');
      expect(viewModel.body, isA<CandidateOnboardingIntroStep>());
      expect(viewModel.primaryLabel, 'Siguiente');
      expect(viewModel.tertiaryLabel, isNull);

      viewModel.onPrimaryPressed();
      expect(
        cubit.state.currentStep,
        CandidateOnboardingStep.introSmartMatches,
      );
    });

    test('builds optional work style step with skip and back actions', () {
      cubit
        ..nextStep()
        ..nextStep()
        ..nextStep();

      final viewModel = factory.build(
        state: cubit.state,
        cubit: cubit,
        candidateName: 'Ana',
        l10n: l10n,
      );

      expect(cubit.state.currentStep, CandidateOnboardingStep.workStyle);
      expect(viewModel.body, isA<CandidateOnboardingWorkStyleStep>());
      expect(viewModel.secondaryLabel, 'Saltar por ahora');
      expect(viewModel.tertiaryLabel, 'Atrás');
      expect(viewModel.onSecondaryPressed, isNotNull);
      expect(viewModel.onTertiaryPressed, isNotNull);

      viewModel.onSecondaryPressed!.call();
      expect(cubit.state.currentStep, CandidateOnboardingStep.profileBasics);
      expect(cubit.state.workStyleSkipped, isTrue);
    });

    test('builds profile basics step with gated primary action', () {
      _goToProfileBasics(cubit);

      final viewModelBlocked = factory.build(
        state: cubit.state,
        cubit: cubit,
        candidateName: 'Ana',
        l10n: l10n,
      );

      expect(
        viewModelBlocked.body,
        isA<CandidateOnboardingProfileBasicsStep>(),
      );
      expect(viewModelBlocked.primaryLabel, 'Finalizar onboarding');
      expect(viewModelBlocked.primaryEnabled, isFalse);
      expect(viewModelBlocked.tertiaryLabel, 'Atrás');

      cubit
        ..updateTargetRole('Flutter Developer')
        ..updatePreferredLocation('Madrid')
        ..updatePreferredModality('Remoto')
        ..updatePreferredSeniority('Mid');

      final viewModelEnabled = factory.build(
        state: cubit.state,
        cubit: cubit,
        candidateName: 'Ana',
        l10n: l10n,
      );
      expect(viewModelEnabled.primaryEnabled, isTrue);

      viewModelEnabled.onPrimaryPressed();
      expect(
        cubit.state.submissionStatus,
        CandidateOnboardingSubmissionStatus.completed,
      );
    });
  });
}

void _goToProfileBasics(CandidateOnboardingCubit cubit) {
  cubit
    ..nextStep()
    ..nextStep()
    ..nextStep()
    ..nextStep();
}
