import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/home/cubits/candidate_onboarding_cubit.dart';
import 'package:opti_job_app/home/cubits/candidate_onboarding_state.dart';
import 'package:opti_job_app/home/models/candidate_onboarding_step.dart';

void main() {
  group('CandidateOnboardingCubit', () {
    late CandidateOnboardingCubit cubit;

    setUp(() {
      cubit = CandidateOnboardingCubit();
    });

    tearDown(() async {
      await cubit.close();
    });

    test('starts at first intro step', () {
      expect(cubit.state.currentStep, CandidateOnboardingStep.introWelcome);
      expect(cubit.state.currentStepIndex, 1);
      expect(cubit.state.totalSteps, 5);
      expect(cubit.state.canGoBack, isFalse);
      expect(cubit.state.canSkipCurrentStep, isFalse);
    });

    test('navigates intro steps in order with nextStep', () {
      cubit.nextStep();
      expect(
        cubit.state.currentStep,
        CandidateOnboardingStep.introSmartMatches,
      );

      cubit.nextStep();
      expect(cubit.state.currentStep, CandidateOnboardingStep.introControl);

      cubit.nextStep();
      expect(cubit.state.currentStep, CandidateOnboardingStep.workStyle);
      expect(cubit.state.canSkipCurrentStep, isTrue);
    });

    test('skipCurrentStep only applies to optional step', () {
      cubit.skipCurrentStep();
      expect(cubit.state.currentStep, CandidateOnboardingStep.introWelcome);
      expect(cubit.state.workStyleSkipped, isFalse);

      cubit.nextStep();
      cubit.nextStep();
      cubit.nextStep();
      expect(cubit.state.currentStep, CandidateOnboardingStep.workStyle);

      cubit.skipCurrentStep();
      expect(cubit.state.currentStep, CandidateOnboardingStep.profileBasics);
      expect(cubit.state.workStyleSkipped, isTrue);
    });

    test('cannot complete profile step without minimum fields', () {
      _goToProfileBasics(cubit);
      expect(cubit.state.currentStep, CandidateOnboardingStep.profileBasics);

      cubit.completeOnboarding();

      expect(
        cubit.state.submissionStatus,
        CandidateOnboardingSubmissionStatus.idle,
      );
      expect(cubit.state.validationMessage, isNotNull);
      expect(cubit.state.currentStep, CandidateOnboardingStep.profileBasics);
    });

    test('completes onboarding when minimum fields are provided', () {
      _goToProfileBasics(cubit);

      cubit
        ..updateTargetRole('Flutter Developer')
        ..updatePreferredLocation('Madrid')
        ..updatePreferredModality('Híbrido')
        ..updatePreferredSeniority('Mid');

      cubit.completeOnboarding();

      expect(
        cubit.state.submissionStatus,
        CandidateOnboardingSubmissionStatus.completed,
      );
      expect(cubit.state.validationMessage, isNull);
    });

    test('previousStep goes back one step when possible', () {
      _goToProfileBasics(cubit);
      expect(cubit.state.currentStep, CandidateOnboardingStep.profileBasics);

      cubit.previousStep();
      expect(cubit.state.currentStep, CandidateOnboardingStep.workStyle);
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
