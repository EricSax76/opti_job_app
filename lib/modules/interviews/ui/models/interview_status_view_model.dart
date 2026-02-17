import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class InterviewStatusViewModel extends Equatable {
  const InterviewStatusViewModel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  List<Object> get props => [label, color];
}
