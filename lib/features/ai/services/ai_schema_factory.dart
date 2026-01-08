import 'package:firebase_ai/firebase_ai.dart';

class AiSchemaFactory {
  static Schema matchSchema() {
    return Schema.object(
      properties: {
        'score': Schema.integer(minimum: 0, maximum: 100),
        'reasons': Schema.array(
          items: Schema.string(),
          minItems: 3,
          maxItems: 7,
        ),
        'recommendations': Schema.array(
          items: Schema.string(),
          minItems: 3,
          maxItems: 6,
        ),
        'summary': Schema.string(nullable: true),
      },
      optionalProperties: ['summary'],
      propertyOrdering: ['score', 'reasons', 'recommendations', 'summary'],
    );
  }

  static Schema jobOfferSchema() {
    return Schema.object(
      properties: {
        'title': Schema.string(),
        'description': Schema.string(),
        'location': Schema.string(),
        'job_type': Schema.string(nullable: true),
        'salary_min': Schema.string(nullable: true),
        'salary_max': Schema.string(nullable: true),
        'education': Schema.string(nullable: true),
        'key_indicators': Schema.string(nullable: true),
      },
      optionalProperties: [
        'job_type',
        'salary_min',
        'salary_max',
        'education',
        'key_indicators',
      ],
      propertyOrdering: [
        'title',
        'description',
        'location',
        'job_type',
        'salary_min',
        'salary_max',
        'education',
        'key_indicators',
      ],
    );
  }
}
