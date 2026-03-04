import 'package:equatable/equatable.dart';

class KpiMetric extends Equatable {
  const KpiMetric({
    required this.label,
    required this.value,
    this.previousValue,
    this.unit = '',
    this.isPositiveGood = true,
  });

  final String label;
  final double value;
  final double? previousValue;
  final String unit;
  final bool isPositiveGood;

  double? get change {
    if (previousValue == null || previousValue == 0) return null;
    return (value - previousValue!) / previousValue! * 100;
  }

  @override
  List<Object?> get props => [label, value, previousValue, unit, isPositiveGood];
}
