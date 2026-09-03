import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

class AppVariables {
  static const String appName = 'Ghost Play';
  static const Color defaultBaseColor = Colors.green;
  static const String defaultFontFamily = 'GoogleSansFlex';

  static const tabletMaxWidth = 500.0;
  static const tabletMaxHeight = 400.0;

  static const waVoiceNotesPath = 'Android/media/com.whatsapp/WhatsApp/Media';

  static final DateFormat formatDateTime = DateFormat('dd/MM/yyyy hh:mm a');
  static final List<int> weeksOptions = [1, 2, 3, 4, 5, 6, 7, 8];
  static const animationDuration = Duration(milliseconds: 400);
  static const snackBarDuration = Duration(seconds: 5);
  static const logoNoBgDark = 'assets/images/logo-no-bg-dark.png';
  static const logoNoBgLight = 'assets/images/logo-no-bg-light.png';

  static Map<String, String> availableFonts = getAvailableFonts();

  static Map<String, String> getAvailableFonts() {
    return {
      'Google Sans Flex': 'GoogleSansFlex',
      'Merriweather': 'Merriweather',
      'Montserrat': 'Montserrat',
      'Nunito': 'Nunito',
      'Open Sans': 'OpenSans',
      'Orbitron': 'Orbitron',
      'Playfair Display': 'PlayfairDisplay',
      'Roboto': 'Roboto',
      'Source Code Pro': 'SourceCodePro',
    };
  }

  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('es', 'ES'),
    Locale('it', 'IT'),
    Locale('fr', 'FR'),
    Locale('de', 'DE'),
    Locale('pt', 'PT'),
  ];
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
