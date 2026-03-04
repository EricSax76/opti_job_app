import 'package:opti_job_app/features/ai/api/firebase_ai_client.dart';
import 'package:opti_job_app/features/ai/models/ai_match_result.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/skills/models/skill.dart';

class AiSkillsMatchingService {
  AiSkillsMatchingService(this._client);

  // ignore: unused_field
  final FirebaseAiClient _client;

  Future<SkillsOverlap> calculateSkillsOverlap({
    required List<Skill> candidateSkills,
    required List<JobOfferSkill> requiredSkills,
    required List<Skill> preferredSkills,
  }) async {
    // This could be a complex client-side logic or a call to a lightweight AI model
    // For now, we'll implement a logic-based comparison, but the plan mentions
    // matching by competencies, so we might need AI for semantic matching.

    final matched = <String>[];
    final missing = <String>[];

    final candidateSkillNames = candidateSkills
        .map((s) => s.name.toLowerCase())
        .toSet();

    for (final req in requiredSkills) {
      if (candidateSkillNames.contains(req.name.toLowerCase())) {
        matched.add(req.name);
      } else {
        missing.add(req.name);
      }
    }

    // In a real scenario, we'd use the AI client here to find 'adjacent' skills
    // or handle semantic similarities (e.g., 'React' matching 'React.js')

    return SkillsOverlap(
      matched: matched,
      missing: missing,
      adjacent: [], // TODO: semantic matching
    );
  }

  Future<List<Skill>> extractSkillsFromText(String text) async {
    // Implementation would use AI client with a specific prompt
    return [];
  }
}
