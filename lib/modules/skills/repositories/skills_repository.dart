import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:opti_job_app/modules/skills/models/skill_taxonomy.dart';

abstract class SkillsRepository {
  Future<List<SkillTaxonomy>> searchSkills(String query);
  Future<List<SkillTaxonomy>> getSkillsByCategory(SkillCategory category);
  Future<List<SkillTaxonomy>> getPopularSkills({int limit = 10});
}

class FirebaseSkillsRepository implements SkillsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<SkillTaxonomy>> searchSkills(String query) async {
    if (query.isEmpty) return [];
    
    // Simple prefix search using startAt/endAt
    final snapshot = await _firestore
        .collection('skillsTaxonomy')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();

    return snapshot.docs
        .map((doc) => SkillTaxonomy.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<List<SkillTaxonomy>> getSkillsByCategory(SkillCategory category) async {
    final snapshot = await _firestore
        .collection('skillsTaxonomy')
        .where('category', isEqualTo: category.name)
        .get();

    return snapshot.docs
        .map((doc) => SkillTaxonomy.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<List<SkillTaxonomy>> getPopularSkills({int limit = 10}) async {
    final snapshot = await _firestore
        .collection('skillsTaxonomy')
        .orderBy('popularity', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => SkillTaxonomy.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }
}
