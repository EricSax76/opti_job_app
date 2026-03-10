import 'package:flutter/material.dart';

class JobOfferDetailLoadingDialog {
  const JobOfferDetailLoadingDialog._();

  static Future<T> run<T>({
    required BuildContext context,
    required String title,
    required String message,
    required Future<T> Function() action,
  }) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    var isLoadingDialogOpen = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: Row(
            children: [
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        );
      },
    ).whenComplete(() {
      isLoadingDialogOpen = false;
    });

    try {
      return await action();
    } finally {
      if (isLoadingDialogOpen && rootNavigator.mounted) {
        rootNavigator.pop();
      }
    }
  }
}
