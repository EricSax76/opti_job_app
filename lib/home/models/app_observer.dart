import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Simple [BlocObserver] to log transitions and errors during development.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    assert(() {
      debugPrint('[${bloc.runtimeType}] $change');
      return true;
    }());
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    assert(() {
      debugPrint('[${bloc.runtimeType}] $transition');
      return true;
    }());
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    assert(() {
      debugPrint('[${bloc.runtimeType}] Error: $error\n$stackTrace');
      return true;
    }());
  }
}
