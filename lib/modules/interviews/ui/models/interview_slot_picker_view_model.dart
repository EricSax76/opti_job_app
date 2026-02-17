import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class InterviewSlotPickerViewModel extends Equatable {
  const InterviewSlotPickerViewModel({
    required this.firstDate,
    required this.lastDate,
    required this.initialDate,
    required this.initialTime,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime initialDate;
  final TimeOfDay initialTime;

  @override
  List<Object> get props => [firstDate, lastDate, initialDate, initialTime];
}
