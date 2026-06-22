import 'package:flutter/material.dart';
import 'package:ghost_play/app/app.dart';
import 'package:hugeicons/hugeicons.dart';

class AppFunctions {
  static void showSnackBar(
    BuildContext context, {
    String? message,
    SnackBarType type = SnackBarType.info,
  }) {
    List<List<dynamic>> icon;
    switch (type) {
      case SnackBarType.success:
        icon = HugeIcons.strokeRoundedCheckmarkCircle02;
      case SnackBarType.error:
        icon = HugeIcons.strokeRoundedAlertCircle;
      case SnackBarType.warning:
        icon = HugeIcons.strokeRoundedAlert02;
      case SnackBarType.info:
        icon = HugeIcons.strokeRoundedInformationCircle;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          spacing: 12,
          children: [
            HugeIcon(
              icon: icon,
              strokeWidth: 2,
              color: Colors.white,
            ),
            Expanded(
              child: Text(
                message ?? '',
                style: TextStyle(
                  fontVariations: [
                    ...(Theme.of(
                              context,
                            ).textTheme.titleMedium?.fontVariations ??
                            const <FontVariation>[])
                        .where((v) => v.axis != 'wght'),
                    const FontVariation('wght', 700),
                  ],
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        closeIconColor: Colors.white,
        backgroundColor: type.isSuccess
            ? Colors.green
            : type.isError
            ? Colors.red
            : type.isWarning
            ? Colors.orange
            : Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: AppVariables.snackBarDuration,
      ),
    );
  }

  static String formatFileName(
    String fileName, {
    int startCount = 10,
    int endCount = 10,
  }) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1) return fileName;

    final name = fileName.substring(0, dotIndex);
    final extension = fileName.substring(dotIndex);

    if (name.length <= startCount + endCount) return fileName;

    final start = name.substring(0, startCount);
    final end = name.substring(name.length - endCount);

    return '$start...$end$extension';
  }
}
