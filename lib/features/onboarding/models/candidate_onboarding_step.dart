enum CandidateOnboardingStep {
  introWelcome,
  introSmartMatches,
  introControl,
  workStyle,
  profileBasics,
}

extension CandidateOnboardingStepX on CandidateOnboardingStep {
  static const List<CandidateOnboardingStep> orderedValues =
      CandidateOnboardingStep.values;

  int get position => orderedValues.indexOf(this) + 1;

  bool get isOptional => this == CandidateOnboardingStep.workStyle;

  CandidateOnboardingStep? get next {
    final index = orderedValues.indexOf(this);
    if (index < 0 || index >= orderedValues.length - 1) return null;
    return orderedValues[index + 1];
  }

  CandidateOnboardingStep? get previous {
    final index = orderedValues.indexOf(this);
    if (index <= 0) return null;
    return orderedValues[index - 1];
  }
}
