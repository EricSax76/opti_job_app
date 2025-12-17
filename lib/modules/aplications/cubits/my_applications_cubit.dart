import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/aplications/models/application_service.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';

part 'my_applications_state.dart';

class MyApplicationsCubit extends Cubit<MyApplicationsState> {
  MyApplicationsCubit({
    required ApplicationService applicationService,
    required CandidateAuthCubit candidateAuthCubit,
  }) : _applicationService = applicationService,
       _candidateAuthCubit = candidateAuthCubit,
       super(const MyApplicationsState());

  final ApplicationService _applicationService;
  final CandidateAuthCubit _candidateAuthCubit;

  Future<void> loadMyApplications() async {
    final candidateId = _candidateAuthCubit.state.candidate?.id;
    if (candidateId == null) {
      emit(
        state.copyWith(
          status: ApplicationsStatus.error,
          errorMessage: 'Usuario no autenticado.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: ApplicationsStatus.loading));
    try {
      final applications = await _applicationService
          .getApplicationsForCandidate(candidateId);
      emit(
        state.copyWith(
          status: ApplicationsStatus.success,
          applications: applications,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ApplicationsStatus.error,
          errorMessage: 'Error al cargar las postulaciones.',
        ),
      );
    }
  }
}
