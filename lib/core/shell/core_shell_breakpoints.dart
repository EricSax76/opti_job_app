import 'package:flutter/widgets.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

/// Shared responsive breakpoints for app-level shell decisions.
const double coreShellCompactBreakpoint = uiBreakpointMobile;
const double coreShellNavigationBreakpoint = uiBreakpointTablet;
const double coreShellWideBreakpoint = uiBreakpointDesktop;

bool coreShellIsExpandedNavigation(double width) {
  return width >= coreShellNavigationBreakpoint;
}

bool coreShellIsWide(double width) {
  return width >= coreShellWideBreakpoint;
}

extension CoreShellBreakpointContext on BuildContext {
  double get coreShellWidth => MediaQuery.sizeOf(this).width;

  bool get hasExpandedShellNavigation {
    return coreShellIsExpandedNavigation(coreShellWidth);
  }

  bool get hasWideShellLayout {
    return coreShellIsWide(coreShellWidth);
  }
}
