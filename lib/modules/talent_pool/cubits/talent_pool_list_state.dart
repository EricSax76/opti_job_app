part of 'talent_pool_list_cubit.dart';

enum TalentPoolListStatus { initial, loading, success, failure }

class TalentPoolListState extends Equatable {
  const TalentPoolListState({
    this.status = TalentPoolListStatus.initial,
    this.pools = const [],
  });

  final TalentPoolListStatus status;
  final List<TalentPool> pools;

  @override
  List<Object?> get props => [status, pools];

  TalentPoolListState copyWith({
    TalentPoolListStatus? status,
    List<TalentPool>? pools,
  }) {
    return TalentPoolListState(
      status: status ?? this.status,
      pools: pools ?? this.pools,
    );
  }
}
