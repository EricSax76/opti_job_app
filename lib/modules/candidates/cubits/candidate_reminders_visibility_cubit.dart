import 'package:flutter_bloc/flutter_bloc.dart';

class CandidateRemindersVisibilityCubit extends Cubit<bool> {
  CandidateRemindersVisibilityCubit() : super(true);

  void hideReminders() => emit(false);
  void showReminders() => emit(true);
  void toggleReminders() => emit(!state);
}
