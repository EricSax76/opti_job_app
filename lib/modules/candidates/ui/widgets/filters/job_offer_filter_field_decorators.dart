import 'package:flutter/material.dart';

import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_models.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_tokens.dart';

class JobOfferFilterInputStyle {
  const JobOfferFilterInputStyle({
    this.hintFontSize = JobOfferFilterSidebarTokens.regularFontSize,
    this.borderRadius = JobOfferFilterSidebarTokens.regularFieldBorderRadius,
    this.contentPadding =
        JobOfferFilterSidebarTokens.regularFieldContentPadding,
  });

  final double hintFontSize;
  final double borderRadius;
  final EdgeInsetsGeometry contentPadding;
}

class JobOfferFilterFieldDecorators {
  const JobOfferFilterFieldDecorators._();

  static InputDecoration inputDecoration({
    required JobOfferFilterPalette palette,
    required String hintText,
    JobOfferFilterInputStyle style = const JobOfferFilterInputStyle(),
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: palette.muted, fontSize: style.hintFontSize),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: _inputBorder(palette, style.borderRadius),
      enabledBorder: _inputBorder(palette, style.borderRadius),
      focusedBorder: _inputBorder(
        palette,
        style.borderRadius,
        color: palette.accent,
        width: 2,
      ),
      fillColor: palette.inputFill,
      filled: true,
      contentPadding: style.contentPadding,
    );
  }

  static OutlineInputBorder _inputBorder(
    JobOfferFilterPalette palette,
    double borderRadius, {
    Color? color,
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: color ?? palette.border, width: width),
    );
  }
}
