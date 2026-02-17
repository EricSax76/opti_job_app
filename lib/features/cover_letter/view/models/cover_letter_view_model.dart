import 'package:equatable/equatable.dart';

class CoverLetterViewModel extends Equatable {
  const CoverLetterViewModel({
    required this.isLoading,
    required this.isImproving,
  });

  final bool isLoading;
  final bool isImproving;

  @override
  List<Object> get props => [isLoading, isImproving];
}
