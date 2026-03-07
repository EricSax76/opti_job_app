import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/talent_pool/models/pool_member.dart';
import 'package:opti_job_app/modules/talent_pool/repositories/talent_pool_repository.dart';

part 'talent_pool_detail_state.dart';

class TalentPoolDetailCubit extends Cubit<TalentPoolDetailState> {
  TalentPoolDetailCubit({required TalentPoolRepository repository})
    : _repository = repository,
      super(const TalentPoolDetailState());

  final TalentPoolRepository _repository;
  StreamSubscription? _subscription;

  void subscribeToMembers(String poolId) {
    emit(state.copyWith(status: TalentPoolDetailStatus.loading));
    _subscription?.cancel();
    _subscription = _repository
        .getPoolMembers(poolId)
        .listen(
          (members) {
            emit(
              state.copyWith(
                status: TalentPoolDetailStatus.success,
                members: members,
              ),
            );
          },
          onError: (_) {
            emit(state.copyWith(status: TalentPoolDetailStatus.failure));
          },
        );
  }

  Future<void> addMember({
    required String poolId,
    required String candidateUid,
    required String addedBy,
    List<String> tags = const [],
    String source = 'manual',
    String? sourceApplicationId,
  }) async {
    await _repository.addMemberToPool(
      poolId,
      PoolMember(
        candidateUid: candidateUid,
        addedBy: addedBy,
        addedAt: DateTime.now(),
        tags: tags,
        source: source,
        sourceApplicationId: sourceApplicationId,
      ),
    );
  }

  Future<void> removeMember(String poolId, String candidateUid) async {
    await _repository.removeMemberFromPool(poolId, candidateUid);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
