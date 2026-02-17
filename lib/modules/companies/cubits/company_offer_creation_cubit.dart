import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/features/ai/models/ai_exceptions.dart';
import 'package:opti_job_app/features/ai/models/ai_job_offer_draft.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/companies/cubits/company_offer_creation_state.dart';

class CompanyOfferCreationCubit extends Cubit<CompanyOfferCreationState> {
  CompanyOfferCreationCubit({
    required this.aiRepository,
  }) : super(const CompanyOfferCreationState());

  final AiRepository aiRepository;

  Future<AiJobOfferDraft?> generateJobOffer({
    required Map<String, dynamic> criteria,
  }) async {
    if (state.isGeneratingOffer) return null;

    emit(state.copyWith(isGeneratingOffer: true));

    try {
      final draft = await aiRepository.generateJobOffer(criteria: criteria);
      return draft;
    } on AiConfigurationException catch (_) {
      rethrow;
    } on AiRequestException catch (_) {
      rethrow;
    } catch (_) {
      rethrow;
    } finally {
      emit(state.copyWith(isGeneratingOffer: false));
    }
  }
}
