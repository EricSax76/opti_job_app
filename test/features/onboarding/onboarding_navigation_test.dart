import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/features/onboarding/cubits/candidate_onboarding_cubit.dart';
import 'package:opti_job_app/features/onboarding/cubits/candidate_onboarding_state.dart';
import 'package:opti_job_app/features/onboarding/models/candidate_onboarding_step.dart';

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

    test('skipCurrentStep clears any captured work style preferences', () {
      _goToWorkStyle(cubit);

      cubit
        ..updateStartOfDayPreference('Foco individual')
        ..updateFeedbackPreference('Feedback continuo')
        ..updateStructurePreference('Autonomía amplia')
        ..updateTaskPacePreference('Tareas variadas y cambios');

      cubit.skipCurrentStep();

      expect(cubit.state.currentStep, CandidateOnboardingStep.profileBasics);
      expect(cubit.state.workStyleSkipped, isTrue);
      expect(cubit.state.startOfDayPreference, isEmpty);
      expect(cubit.state.feedbackPreference, isEmpty);
      expect(cubit.state.structurePreference, isEmpty);
      expect(cubit.state.taskPacePreference, isEmpty);
    });

    test('answering work style after skip clears skipped flag', () {
      _goToWorkStyle(cubit);
      cubit.skipCurrentStep();
      expect(cubit.state.workStyleSkipped, isTrue);

      cubit.previousStep();
      expect(cubit.state.currentStep, CandidateOnboardingStep.workStyle);

      cubit.updateStartOfDayPreference('Foco individual');

      expect(cubit.state.workStyleSkipped, isFalse);
      expect(cubit.state.startOfDayPreference, 'Foco individual');
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

void _goToWorkStyle(CandidateOnboardingCubit cubit) {
  cubit
    ..nextStep()
    ..nextStep()
    ..nextStep();
}
