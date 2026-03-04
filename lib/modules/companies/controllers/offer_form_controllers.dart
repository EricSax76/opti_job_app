import 'package:flutter/material.dart';

class OfferFormControllers {
  final TextEditingController title = TextEditingController();
  final TextEditingController description = TextEditingController();
  final TextEditingController location = TextEditingController();
  final TextEditingController salaryMin = TextEditingController();
  final TextEditingController salaryMax = TextEditingController();
  final TextEditingController salaryCurrency = TextEditingController();
  final TextEditingController salaryPeriod = TextEditingController();
  final TextEditingController education = TextEditingController();
  final TextEditingController jobType = TextEditingController();
  final TextEditingController jobCategory = TextEditingController();
  final TextEditingController workSchedule = TextEditingController();
  final TextEditingController contractType = TextEditingController();
  final TextEditingController keyIndicators = TextEditingController();

  void clear() {
    title.clear();
    description.clear();
    location.clear();
    salaryMin.clear();
    salaryMax.clear();
    salaryCurrency.clear();
    salaryPeriod.clear();
    education.clear();
    jobType.clear();
    jobCategory.clear();
    workSchedule.clear();
    contractType.clear();
    keyIndicators.clear();
  }

  void dispose() {
    title.dispose();
    description.dispose();
    location.dispose();
    salaryMin.dispose();
    salaryMax.dispose();
    salaryCurrency.dispose();
    salaryPeriod.dispose();
    education.dispose();
    jobType.dispose();
    jobCategory.dispose();
    workSchedule.dispose();
    contractType.dispose();
    keyIndicators.dispose();
  }
}
