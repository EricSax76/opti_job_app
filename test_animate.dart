import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

void main() {
  Container()
      .animate()
      .fadeIn(duration: 450.ms, curve: Curves.easeOut)
      .slideY(begin: 0.05, duration: 600.ms, curve: Curves.easeOutExpo)
      .scaleXY(begin: 0.98, end: 1.0, duration: 600.ms, curve: Curves.easeOutExpo);
}
