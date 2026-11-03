import 'package:intl/intl.dart';

class AppVariables {
  static const String appName = 'Ghost Play';

  static const tabletMaxWidth = 500.0;
  static const tabletMaxHeight = 400.0;
  static const modalBottomSheetMaxHeightPct = 0.72;

  static const waVoiceNotesPath = 'Android/media/com.whatsapp/WhatsApp/Media';

  static final DateFormat formatDateTime = DateFormat('dd/MM/yyyy hh:mm a');
  static final List<int> weeksOptions = [1, 2, 3, 4, 5, 6, 7, 8];
  static const animationDuration = Duration(milliseconds: 400);
  static const snackBarDuration = Duration(seconds: 5);
  static const logoNoBgDark = 'assets/images/logo-no-bg-dark.png';
  static const logoNoBgLight = 'assets/images/logo-no-bg-light.png';
}

enum SnackBarType {
  success,
  error,
  warning,
  info;

  bool get isSuccess => this == SnackBarType.success;
  bool get isError => this == SnackBarType.error;
  bool get isWarning => this == SnackBarType.warning;
  bool get isInfo => this == SnackBarType.info;
}
