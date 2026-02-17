import 'package:equatable/equatable.dart';

class AuthFormScreenViewModel extends Equatable {
  const AuthFormScreenViewModel({required this.isLoading});

  final bool isLoading;

  @override
  List<Object> get props => [isLoading];
}
