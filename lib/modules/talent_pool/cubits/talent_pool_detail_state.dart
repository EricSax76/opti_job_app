part of 'talent_pool_detail_cubit.dart';

enum TalentPoolDetailStatus { initial, loading, success, failure }

class TalentPoolDetailState extends Equatable {
  const TalentPoolDetailState({
    this.status = TalentPoolDetailStatus.initial,
    this.members = const [],
  });

  final TalentPoolDetailStatus status;
  final List<PoolMember> members;

  @override
  List<Object?> get props => [status, members];

  TalentPoolDetailState copyWith({
    TalentPoolDetailStatus? status,
    List<PoolMember>? members,
  }) {
    return TalentPoolDetailState(
      status: status ?? this.status,
      members: members ?? this.members,
    );
  }
}
