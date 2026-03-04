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
    final snapshot =
        await _collection
            .where('isTemplate', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();
    return snapshot.docs.map((doc) => Pipeline.fromFirestore(doc.data())).toList();
  }

  @override
  Future<List<Pipeline>> getCompanyPipelines(String companyId) async {
    final snapshot =
        await _collection
            .where('companyId', isEqualTo: companyId)
            .orderBy('createdAt', descending: true)
            .get();
    return snapshot.docs.map((doc) => Pipeline.fromFirestore(doc.data())).toList();
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
}
