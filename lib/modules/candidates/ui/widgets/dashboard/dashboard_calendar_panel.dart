import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/features/calendar/cubits/calendar_cubit.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/calendar_panel.dart';

class DashboardCalendarPanel extends StatelessWidget {
  const DashboardCalendarPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) => CalendarPanel(state: state),
    );
  }
}
