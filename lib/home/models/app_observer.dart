import 'package:flutter_bloc/flutter_bloc.dart';

/// Simple [BlocObserver] to log transitions and errors during development.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    assert(() {
      // ignore: avoid_print
      print('[${bloc.runtimeType}] $transition');
      return true;
    }());
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    assert(() {
      // ignore: avoid_print
      print('[${bloc.runtimeType}] Error: $error\n$stackTrace');
      return true;
    }());
  }
}
