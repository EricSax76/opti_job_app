import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:opti_job_app/modules/aplications/models/application_service.dart';
import 'package:opti_job_app/modules/aplications/models/candidate_application_entry.dart';
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
    final candidate = _candidateAuthCubit.state.candidate;
    final candidateUid = candidate?.uid;
    if (candidateUid == null) {
      emit(
        state.copyWith(
          status: ApplicationsStatus.error,
          errorMessage: 'Usuario no autenticado.',
        ),
      );
      return;
    }

    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (authUid == null || authUid != candidateUid) {
      emit(
        state.copyWith(
          status: ApplicationsStatus.error,
          errorMessage: 'Sesión inválida. Inicia sesión como candidato.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: ApplicationsStatus.loading));
    try {
      final applications = await _applicationService
          .getApplicationEntriesForCandidate(candidateUid);
      emit(
        state.copyWith(
          status: ApplicationsStatus.success,
          applications: applications,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MyApplicationsCubit.loadMyApplications error: $e');
      }
      emit(
        state.copyWith(
          status: ApplicationsStatus.error,
          errorMessage: 'Error al cargar las postulaciones.',
        ),
      );
    }
  }
}
