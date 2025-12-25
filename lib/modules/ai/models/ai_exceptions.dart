class AiConfigurationException implements Exception {
  const AiConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'AiConfigurationException: $message';
}

class AiRequestException implements Exception {
  const AiRequestException(this.message);

  final String message;

  @override
  String toString() => 'AiRequestException: $message';
}

