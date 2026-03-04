import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/talent_pool/models/talent_pool.dart';
import 'package:opti_job_app/modules/talent_pool/repositories/talent_pool_repository.dart';

part 'talent_pool_list_state.dart';

class TalentPoolListCubit extends Cubit<TalentPoolListState> {
  TalentPoolListCubit({required TalentPoolRepository repository})
    : _repository = repository,
      super(const TalentPoolListState());

  final TalentPoolRepository _repository;

  Future<void> loadPools(String companyId) async {
    emit(state.copyWith(status: TalentPoolListStatus.loading));
    try {
      final pools = await _repository.getTalentPools(companyId);
      emit(state.copyWith(status: TalentPoolListStatus.success, pools: pools));
    } catch (e) {
      emit(state.copyWith(status: TalentPoolListStatus.failure));
    }
  }

  Future<void> createPool(TalentPool pool) async {
    try {
      final newPool = await _repository.createTalentPool(pool);
      emit(state.copyWith(pools: [newPool, ...state.pools]));
    } catch (e) {
      // Handle error
    }
  }
}
