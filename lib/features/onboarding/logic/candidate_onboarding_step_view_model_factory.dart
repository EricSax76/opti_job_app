import 'package:flutter/material.dart';
import 'package:opti_job_app/features/onboarding/cubits/candidate_onboarding_cubit.dart';
import 'package:opti_job_app/features/onboarding/cubits/candidate_onboarding_state.dart';
import 'package:opti_job_app/features/onboarding/models/candidate_onboarding_step.dart';
import 'package:opti_job_app/features/onboarding/models/candidate_onboarding_step_view_model.dart';
import 'package:opti_job_app/features/onboarding/view/widgets/candidate_onboarding_steps/candidate_onboarding_intro_step.dart';
import 'package:opti_job_app/features/onboarding/view/widgets/candidate_onboarding_steps/candidate_onboarding_profile_basics_step.dart';
import 'package:opti_job_app/features/onboarding/view/widgets/candidate_onboarding_steps/candidate_onboarding_work_style_step.dart';

class CandidateOnboardingStepViewModelFactory {
  const CandidateOnboardingStepViewModelFactory();

  CandidateOnboardingStepViewModel build({
    required CandidateOnboardingState state,
    required CandidateOnboardingCubit cubit,
    required String candidateName,
  }) {
    final previousAction = state.canGoBack ? cubit.previousStep : null;
    final backLabel = state.canGoBack ? 'Atrás' : null;

    return switch (state.currentStep) {
      CandidateOnboardingStep.introWelcome => _buildIntroStep(
        title: 'Bienvenido, $candidateName',
        message:
            'Te mostramos la app en menos de 2 minutos y dejamos tu perfil listo para empezar con buen matching.',
        icon: Icons.auto_awesome_rounded,
        headline: 'Una búsqueda de empleo guiada por datos',
        description:
            'Tu panel se adapta a tus objetivos para priorizar vacantes relevantes desde el primer día.',
        highlights: const [
          'Ofertas priorizadas según tu perfil y actividad.',
          'Recomendaciones con señales reales de compatibilidad.',
          'Proceso corto, sin formularios largos al inicio.',
        ],
        primaryLabel: 'Siguiente',
        onPrimaryPressed: cubit.nextStep,
        backLabel: backLabel,
        onBackPressed: previousAction,
      ),
      CandidateOnboardingStep.introSmartMatches => _buildIntroStep(
        title: 'Matches más relevantes',
        message:
            'Cuanto mejor entendemos tus prioridades laborales, mejores serán las recomendaciones que recibes.',
        icon: Icons.insights_rounded,
        headline: 'Menos ruido, más oportunidades útiles',
        description:
            'OptiJob combina filtros, contexto de mercado y señales de experiencia para ordenar ofertas.',
        highlights: const [
          'Ajuste por modalidad, ubicación y nivel de experiencia.',
          'Ofertas similares agrupadas para decidir más rápido.',
          'Menos tiempo filtrando, más tiempo aplicando.',
        ],
        primaryLabel: 'Siguiente',
        onPrimaryPressed: cubit.nextStep,
        backLabel: backLabel,
        onBackPressed: previousAction,
      ),
      CandidateOnboardingStep.introControl => _buildIntroStep(
        title: 'Tú controlas tu ritmo',
        message:
            'Solo pedimos datos esenciales ahora. El resto lo puedes completar después desde tu perfil.',
        icon: Icons.verified_user_outlined,
        headline: 'Onboarding no invasivo',
        description:
            'Empezamos con lo mínimo útil para activar tu cuenta con calidad de matching.',
        highlights: const [
          'Preguntas de estilo de trabajo opcionales.',
          'Puedes saltar secciones y volver más tarde.',
          'Tus preferencias te ayudan a encontrar mejor encaje cultural.',
        ],
        primaryLabel: 'Continuar',
        onPrimaryPressed: cubit.nextStep,
        backLabel: backLabel,
        onBackPressed: previousAction,
      ),
      CandidateOnboardingStep.workStyle => _buildBaseStep(
        title: 'Estilo de trabajo (opcional)',
        message:
            'Estas preguntas son breves y no invasivas. Nos ayudan a recomendar equipos y dinámicas compatibles.',
        body: CandidateOnboardingWorkStyleStep(
          startOfDayPreference: state.startOfDayPreference,
          feedbackPreference: state.feedbackPreference,
          structurePreference: state.structurePreference,
          taskPacePreference: state.taskPacePreference,
          onStartOfDayChanged: cubit.updateStartOfDayPreference,
          onFeedbackChanged: cubit.updateFeedbackPreference,
          onStructureChanged: cubit.updateStructurePreference,
          onTaskPaceChanged: cubit.updateTaskPacePreference,
        ),
        primaryLabel: 'Continuar',
        primaryIcon: Icons.arrow_forward_rounded,
        onPrimaryPressed: cubit.nextStep,
        secondaryLabel: 'Saltar por ahora',
        onSecondaryPressed: cubit.skipCurrentStep,
        backLabel: backLabel,
        onBackPressed: previousAction,
      ),
      CandidateOnboardingStep.profileBasics => _buildBaseStep(
        title: 'Datos mínimos para arrancar',
        message:
            'Con esta información configuramos tus primeras sugerencias. Luego podrás afinar todo desde ajustes.',
        body: CandidateOnboardingProfileBasicsStep(
          targetRole: state.targetRole,
          preferredLocation: state.preferredLocation,
          preferredModality: state.preferredModality,
          preferredSeniority: state.preferredSeniority,
          validationMessage: state.validationMessage,
          onTargetRoleChanged: cubit.updateTargetRole,
          onPreferredLocationChanged: cubit.updatePreferredLocation,
          onPreferredModalityChanged: cubit.updatePreferredModality,
          onPreferredSeniorityChanged: cubit.updatePreferredSeniority,
        ),
        primaryLabel: 'Finalizar onboarding',
        primaryIcon: Icons.check_circle_outline_rounded,
        onPrimaryPressed: cubit.completeOnboarding,
        primaryEnabled: state.hasMinimumProfileData,
        backLabel: backLabel,
        onBackPressed: previousAction,
      ),
    };
  }

  CandidateOnboardingStepViewModel _buildIntroStep({
    required String title,
    required String message,
    required IconData icon,
    required String headline,
    required String description,
    required List<String> highlights,
    required String primaryLabel,
    required VoidCallback onPrimaryPressed,
    required String? backLabel,
    required VoidCallback? onBackPressed,
  }) {
    return _buildBaseStep(
      title: title,
      message: message,
      body: CandidateOnboardingIntroStep(
        icon: icon,
        headline: headline,
        description: description,
        highlights: highlights,
      ),
      primaryLabel: primaryLabel,
      primaryIcon: Icons.arrow_forward_rounded,
      onPrimaryPressed: onPrimaryPressed,
      backLabel: backLabel,
      onBackPressed: onBackPressed,
    );
  }

  CandidateOnboardingStepViewModel _buildBaseStep({
    required String title,
    required String message,
    required Widget body,
    required String primaryLabel,
    required IconData primaryIcon,
    required VoidCallback onPrimaryPressed,
    required String? backLabel,
    required VoidCallback? onBackPressed,
    String? secondaryLabel,
    VoidCallback? onSecondaryPressed,
    bool primaryEnabled = true,
  }) {
    return CandidateOnboardingStepViewModel(
      title: title,
      message: message,
      body: body,
      primaryLabel: primaryLabel,
      primaryIcon: primaryIcon,
      onPrimaryPressed: onPrimaryPressed,
      secondaryLabel: secondaryLabel,
      onSecondaryPressed: onSecondaryPressed,
      tertiaryLabel: backLabel,
      onTertiaryPressed: onBackPressed,
      primaryEnabled: primaryEnabled,
    );
  }
}
