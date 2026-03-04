part of 'data_requests_cubit.dart';

enum DataRequestsStatus { initial, loading, success, failure }

class DataRequestsState extends Equatable {
  const DataRequestsState({
    this.status = DataRequestsStatus.initial,
    this.requests = const [],
    this.errorMessage,
  });

  final DataRequestsStatus status;
  final List<DataRequest> requests;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, requests, errorMessage];

  DataRequestsState copyWith({
    DataRequestsStatus? status,
    List<DataRequest>? requests,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DataRequestsState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
