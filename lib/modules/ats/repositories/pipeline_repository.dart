import 'package:opti_job_app/modules/ats/models/pipeline.dart';

abstract class PipelineRepository {
  Future<List<Pipeline>> getTemplatePipelines();
  Future<List<Pipeline>> getCompanyPipelines(String companyId);
  Future<Pipeline?> getPipeline(String id);
  Future<void> createPipeline(Pipeline pipeline);
  Future<void> updatePipeline(Pipeline pipeline);
  Future<void> deletePipeline(String id);
}
