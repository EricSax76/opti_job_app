import 'package:flutter/material.dart';

class OfferFormControllers {
  final TextEditingController title = TextEditingController();
  final TextEditingController description = TextEditingController();
  final TextEditingController location = TextEditingController();
  final TextEditingController salaryMin = TextEditingController();
  final TextEditingController salaryMax = TextEditingController();
  final TextEditingController education = TextEditingController();
  final TextEditingController jobType = TextEditingController();
  final TextEditingController keyIndicators = TextEditingController();

  void clear() {
    title.clear();
    description.clear();
    location.clear();
    salaryMin.clear();
    salaryMax.clear();
    education.clear();
    jobType.clear();
    keyIndicators.clear();
  }

  void dispose() {
    title.dispose();
    description.dispose();
    location.dispose();
    salaryMin.dispose();
    salaryMax.dispose();
    education.dispose();
    jobType.dispose();
    keyIndicators.dispose();
  }
}
