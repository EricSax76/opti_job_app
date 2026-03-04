import 'package:opti_job_app/features/ai/api/firebase_ai_client.dart';
import 'package:opti_job_app/features/ai/models/ai_match_result.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/skills/models/skill.dart';

class AiSkillsMatchingService {
  AiSkillsMatchingService([this._client]);

  final FirebaseAiClient? _client;

  Future<SkillsOverlap> calculateSkillsOverlap({
    required List<Skill> candidateSkills,
    required List<JobOfferSkill> requiredSkills,
    required List<Skill> preferredSkills,
  }) async {
    final semantic = await calculateSemanticMatch(
      candidateSkills: candidateSkills,
      requiredSkills: requiredSkills,
      preferredSkills: preferredSkills,
    );
    return semantic.overlap;
  }

  Future<SemanticSkillsMatch> calculateSemanticMatch({
    required List<Skill> candidateSkills,
    required List<JobOfferSkill> requiredSkills,
    required List<Skill> preferredSkills,
  }) async {
    final candidateIndex = _indexCandidateSkills(candidateSkills);
    final matched = <String>{};
    final missing = <String>{};
    final adjacent = <String>{};
    final evidence = <String>[];

    var totalWeight = 0.0;
    var earnedWeight = 0.0;

    for (final req in requiredSkills) {
      final requiredName = req.name.trim();
      if (requiredName.isEmpty) continue;
      totalWeight += _requiredWeight;

      final requiredCanonical = _canonicalize(requiredName);
      if (candidateIndex.containsKey(requiredCanonical)) {
        matched.add(requiredName);
        earnedWeight += _requiredWeight;
        evidence.add('Coincidencia exacta en requisito: $requiredName.');
        continue;
      }

      final adjacentSkill = _findAdjacentSkill(
        requiredCanonical,
        candidateIndex,
      );
      if (adjacentSkill != null) {
        adjacent.add('$requiredName ↔ ${adjacentSkill.original}');
        earnedWeight += _requiredAdjacentWeight;
        evidence.add(
          'Cobertura adyacente: $requiredName se aproxima con ${adjacentSkill.original}.',
        );
        continue;
      }

      missing.add(requiredName);
      evidence.add('Requisito sin cobertura: $requiredName.');
    }

    for (final pref in preferredSkills) {
      final preferredName = pref.name.trim();
      if (preferredName.isEmpty) continue;
      totalWeight += _preferredWeight;

      final preferredCanonical = _canonicalize(preferredName);
      if (candidateIndex.containsKey(preferredCanonical)) {
        matched.add(preferredName);
        earnedWeight += _preferredWeight;
        continue;
      }

      final adjacentSkill = _findAdjacentSkill(
        preferredCanonical,
        candidateIndex,
      );
      if (adjacentSkill != null) {
        adjacent.add('$preferredName ↔ ${adjacentSkill.original}');
        earnedWeight += _preferredAdjacentWeight;
      }
    }

    final score = totalWeight <= 0
        ? 0
        : ((earnedWeight / totalWeight) * 100).round().clamp(0, 100);
    final overlap = SkillsOverlap(
      matched: matched.toList(growable: false)..sort(),
      missing: missing.toList(growable: false)..sort(),
      adjacent: adjacent.toList(growable: false)..sort(),
    );

    return SemanticSkillsMatch(
      overlap: overlap,
      score: score,
      evidence: evidence,
    );
  }

  Future<List<Skill>> extractSkillsFromText(String text) async {
    if (_client == null || text.trim().isEmpty) {
      return [];
    }
    // Placeholder for model-based extraction. Semantic ranking is implemented
    // client-side to keep ranking deterministic and explainable.
    return [];
  }

  static const double _requiredWeight = 1.0;
  static const double _requiredAdjacentWeight = 0.72;
  static const double _preferredWeight = 0.45;
  static const double _preferredAdjacentWeight = 0.24;

  static final Map<String, String> _aliasToCanonical = _buildAliasMap();
  static final Map<String, Set<String>> _adjacencyGraph =
      _buildAdjacencyGraph();

  Map<String, List<_CandidateSkill>> _indexCandidateSkills(
    List<Skill> candidateSkills,
  ) {
    final index = <String, List<_CandidateSkill>>{};
    for (final skill in candidateSkills) {
      final original = skill.name.trim();
      if (original.isEmpty) continue;
      final canonical = _canonicalize(original);
      index
          .putIfAbsent(canonical, () => <_CandidateSkill>[])
          .add(_CandidateSkill(original: original));
    }
    return index;
  }

  _CandidateSkill? _findAdjacentSkill(
    String requiredCanonical,
    Map<String, List<_CandidateSkill>> candidateIndex,
  ) {
    final adjacentKeys = _adjacencyGraph[requiredCanonical];
    if (adjacentKeys == null || adjacentKeys.isEmpty) return null;
    for (final adjacentKey in adjacentKeys) {
      final matches = candidateIndex[adjacentKey];
      if (matches != null && matches.isNotEmpty) {
        return matches.first;
      }
    }
    return null;
  }

  String _canonicalize(String value) {
    final normalized = _normalizeToken(value);
    return _aliasToCanonical[normalized] ?? normalized;
  }

  static String _normalizeToken(String value) {
    final lowered = value.toLowerCase().trim();
    if (lowered.isEmpty) return '';
    final noAccents = lowered
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');
    return noAccents
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[^a-z0-9+#\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static Map<String, String> _buildAliasMap() {
    final aliases = <String, Set<String>>{
      'flutter': {'flutter', 'flutter framework'},
      'dart': {'dart', 'dartlang'},
      'react': {'react', 'react js', 'reactjs', 'react.js'},
      'react_native': {'react native', 'react-native'},
      'typescript': {'typescript', 'ts'},
      'javascript': {'javascript', 'js', 'ecmascript'},
      'nodejs': {'node', 'node js', 'nodejs', 'node.js'},
      'python': {'python', 'py'},
      'kotlin': {'kotlin'},
      'swift': {'swift'},
      'aws': {'aws', 'amazon web services'},
      'gcp': {'gcp', 'google cloud', 'google cloud platform'},
      'azure': {'azure', 'microsoft azure'},
      'docker': {'docker', 'containerization', 'containers'},
      'kubernetes': {'kubernetes', 'k8s'},
      'ci_cd': {
        'ci cd',
        'cicd',
        'continuous integration',
        'continuous delivery',
      },
      'postgresql': {'postgres', 'postgresql', 'psql'},
      'mysql': {'mysql'},
      'english': {'english', 'ingles', 'inglés'},
      'spanish': {'spanish', 'espanol', 'español'},
      'project_management': {
        'project management',
        'gestion de proyectos',
        'gestión de proyectos',
      },
      'scrum': {'scrum', 'agile scrum'},
      'communication': {'communication', 'comunicacion', 'comunicación'},
      'leadership': {'leadership', 'liderazgo'},
    };

    final map = <String, String>{};
    for (final entry in aliases.entries) {
      final canonical = entry.key;
      map[_normalizeToken(canonical)] = canonical;
      for (final alias in entry.value) {
        map[_normalizeToken(alias)] = canonical;
      }
    }
    return map;
  }

  static Map<String, Set<String>> _buildAdjacencyGraph() {
    final base = <String, Set<String>>{
      'flutter': {'dart', 'react_native'},
      'react': {'react_native', 'javascript', 'typescript'},
      'react_native': {'react', 'flutter'},
      'typescript': {'javascript'},
      'javascript': {'typescript', 'nodejs', 'react'},
      'nodejs': {'javascript', 'typescript'},
      'aws': {'gcp', 'azure'},
      'gcp': {'aws', 'azure'},
      'azure': {'aws', 'gcp'},
      'docker': {'kubernetes', 'ci_cd'},
      'kubernetes': {'docker', 'ci_cd'},
      'ci_cd': {'docker', 'kubernetes'},
      'postgresql': {'mysql'},
      'mysql': {'postgresql'},
      'project_management': {'scrum', 'leadership'},
      'scrum': {'project_management'},
      'communication': {'leadership'},
      'leadership': {'communication', 'project_management'},
      'english': {'spanish'},
      'spanish': {'english'},
    };

    final graph = <String, Set<String>>{};
    for (final entry in base.entries) {
      final canonical = entry.key;
      graph.putIfAbsent(canonical, () => <String>{});
      for (final adjacent in entry.value) {
        graph[canonical]!.add(adjacent);
        graph.putIfAbsent(adjacent, () => <String>{}).add(canonical);
      }
    }
    return graph;
  }
}

class SemanticSkillsMatch {
  const SemanticSkillsMatch({
    required this.overlap,
    required this.score,
    this.evidence = const [],
  });

  final SkillsOverlap overlap;
  final int score;
  final List<String> evidence;
}

class _CandidateSkill {
  const _CandidateSkill({required this.original});

  final String original;
}
