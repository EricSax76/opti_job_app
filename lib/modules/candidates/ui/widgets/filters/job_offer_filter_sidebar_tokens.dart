import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

class JobOfferFilterSidebarTokens {
  const JobOfferFilterSidebarTokens._();

  static const double sidebarWidth = 280;
  static const double minSalary = 0;
  static const double maxSalary = 100000;
  static const int salaryDivisions = 100;

  static const double headerIconSize = 24;
  static const double sectionIconSize = uiSpacing16 + 2;

  static const double panelPadding = uiSpacing20;
  static const double searchToNextSectionSpacing = uiSpacing24;
  static const double sectionSpacing = uiSpacing20;
  static const double clearButtonTopSpacing = uiSpacing24;

  static const double searchFieldBorderRadius = uiSpacing12;
  static const double regularFieldBorderRadius = uiSpacing8;
  static const double searchFontSize = uiSpacing16;
  static const double regularFontSize = uiSpacing12 + 2;
  static const double sectionTitleFontSize = uiSpacing16 - 1;
  static const double headerTitleFontSize = uiSpacing20;

  static const EdgeInsets searchFieldContentPadding = EdgeInsets.symmetric(
    horizontal: uiSpacing16,
    vertical: uiSpacing12,
  );
  static const EdgeInsets regularFieldContentPadding = EdgeInsets.symmetric(
    horizontal: uiSpacing12,
    vertical: uiSpacing12 - 2,
  );
}
