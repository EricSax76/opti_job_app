import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DashboardScrollLogic {
  const DashboardScrollLogic._();

  /// Formats the scroll notification and returns the next header visibility state
  /// if it should change. Returns null if no state change is needed.
  static bool? handleOffersScrollNotification({
    required ScrollNotification notification,
    required bool enableHeaderAutoHide,
    required bool isMobileHeaderVisible,
  }) {
    if (!enableHeaderAutoHide) return null;
    if (notification.metrics.axis != Axis.vertical) return null;

    if (notification.metrics.pixels <= 8) {
      if (!isMobileHeaderVisible) {
        return true;
      }
      return null;
    }

    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse &&
          isMobileHeaderVisible) {
        return false;
      } else if (notification.direction == ScrollDirection.forward &&
          !isMobileHeaderVisible) {
        return true;
      }
    }
    return null;
  }
}
