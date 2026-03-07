import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:opti_job_app/modules/ats/models/pipeline.dart';
import 'package:opti_job_app/modules/ats/repositories/pipeline_repository.dart';

class FirebasePipelineRepository implements PipelineRepository {
  FirebasePipelineRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('pipelines');

  @override
  Future<List<Pipeline>> getTemplatePipelines() async {
    final snapshots = <QuerySnapshot<Map<String, dynamic>>>[];
    final camelSnapshot = await _safeGet(
      _collection.where('isTemplate', isEqualTo: true),
    );
    if (camelSnapshot != null) {
      snapshots.add(camelSnapshot);
    }
    final snakeSnapshot = await _safeGet(
      _collection.where('is_template', isEqualTo: true),
    );
    if (snakeSnapshot != null) {
      snapshots.add(snakeSnapshot);
    }
    if (snapshots.isEmpty) {
      return const <Pipeline>[];
    }
    return _mergeAndSortPipelines(snapshots);
  }

  @override
  Future<List<Pipeline>> getCompanyPipelines(String companyId) async {
    final snapshots = <QuerySnapshot<Map<String, dynamic>>>[];
    final camelSnapshot = await _safeGet(
      _collection.where('companyId', isEqualTo: companyId),
    );
    if (camelSnapshot != null) {
      snapshots.add(camelSnapshot);
    }
    final snakeSnapshot = await _safeGet(
      _collection.where('company_id', isEqualTo: companyId),
    );
    if (snakeSnapshot != null) {
      snapshots.add(snakeSnapshot);
    }
    if (snapshots.isEmpty) {
      return const <Pipeline>[];
    }
    return _mergeAndSortPipelines(snapshots);
  }

  @override
  Future<Pipeline?> getPipeline(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Pipeline.fromFirestore(doc.data()!);
  }

  @override
  Future<void> createPipeline(Pipeline pipeline) async {
    final payload = pipeline.toFirestore();
    payload['createdAt'] = FieldValue.serverTimestamp();
    payload['updatedAt'] = FieldValue.serverTimestamp();
    await _collection.doc(pipeline.id).set(payload);
  }

  @override
  Future<void> updatePipeline(Pipeline pipeline) async {
    final payload = pipeline.toFirestore();
    payload['updatedAt'] = FieldValue.serverTimestamp();
    await _collection.doc(pipeline.id).update(payload);
  }

  @override
  Future<void> deletePipeline(String id) async {
    await _collection.doc(id).delete();
  }

  Future<QuerySnapshot<Map<String, dynamic>>?> _safeGet(
    Query<Map<String, dynamic>> query,
  ) async {
    try {
      return await query.get();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        return null;
      }
      rethrow;
    }
  }

  List<Pipeline> _mergeAndSortPipelines(
    List<QuerySnapshot<Map<String, dynamic>>> snapshots,
  ) {
    final byId = <String, Pipeline>{};
    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        final pipeline = Pipeline.fromFirestore(doc.data());
        final normalizedId = pipeline.id.trim().isNotEmpty
            ? pipeline.id
            : doc.id;
        byId[normalizedId] = Pipeline(
          id: normalizedId,
          companyId: pipeline.companyId,
          name: pipeline.name,
          stages: pipeline.stages,
          isTemplate: pipeline.isTemplate,
          createdBy: pipeline.createdBy,
          createdAt: pipeline.createdAt,
          updatedAt: pipeline.updatedAt,
        );
      }
    }

    final pipelines = byId.values.toList(growable: false);
    pipelines.sort((a, b) {
      final aMillis = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bMillis = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bMillis.compareTo(aMillis);
    });
    return pipelines;
  }
}
