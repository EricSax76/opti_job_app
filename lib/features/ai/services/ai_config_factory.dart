import 'package:firebase_ai/firebase_ai.dart';

class AiConfigFactory {
  static GenerationConfig jsonConfigForQuality(
    String quality, {
    required int proMaxOutputTokens,
    required int defaultMaxOutputTokens,
    required double temperature,
  }) {
    return _configForQuality(
      quality,
      proMaxOutputTokens: proMaxOutputTokens,
      defaultMaxOutputTokens: defaultMaxOutputTokens,
      temperature: temperature,
    );
  }

  static GenerationConfig textConfigForQuality(
    String quality, {
    required int proMaxOutputTokens,
    required int defaultMaxOutputTokens,
    required double temperature,
  }) {
    return _configForQuality(
      quality,
      proMaxOutputTokens: proMaxOutputTokens,
      defaultMaxOutputTokens: defaultMaxOutputTokens,
      temperature: temperature,
    );
  }

  static GenerationConfig _configForQuality(
    String quality, {
    required int proMaxOutputTokens,
    required int defaultMaxOutputTokens,
    required double temperature,
  }) {
    final maxOutputTokens = _maxOutputTokensForQuality(
      quality,
      proMaxOutputTokens: proMaxOutputTokens,
      defaultMaxOutputTokens: defaultMaxOutputTokens,
    );
    return GenerationConfig(
      maxOutputTokens: maxOutputTokens,
      temperature: temperature,
    );
  }

  static int _maxOutputTokensForQuality(
    String quality, {
    required int proMaxOutputTokens,
    required int defaultMaxOutputTokens,
  }) {
    return quality == 'pro' ? proMaxOutputTokens : defaultMaxOutputTokens;
  }
}
