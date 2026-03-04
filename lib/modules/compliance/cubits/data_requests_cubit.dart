import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/compliance/models/data_request.dart';
import 'package:opti_job_app/modules/compliance/repositories/compliance_repository.dart';

part 'data_requests_state.dart';

class DataRequestsCubit extends Cubit<DataRequestsState> {
  DataRequestsCubit({required DataRequestRepository repository})
      : _repository = repository,
        super(const DataRequestsState());

  final DataRequestRepository _repository;
  StreamSubscription? _subscription;

  void subscribeToRequests(String candidateUid) {
    emit(state.copyWith(status: DataRequestsStatus.loading));
    _subscription?.cancel();
    _subscription = _repository.getRequests(candidateUid).listen(
      (requests) {
        emit(state.copyWith(
          status: DataRequestsStatus.success,
          requests: requests,
        ));
      },
      onError: (_) {
        emit(state.copyWith(status: DataRequestsStatus.failure));
      },
    );
  }

  Future<void> submitRequest(DataRequest request) async {
    try {
      await _repository.submitRequest(request);
    } catch (e) {
      // Handle error
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
