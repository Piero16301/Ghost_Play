import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppVariables {
  static const String appName = 'Ghost Play';
  static const Color defaultBaseColor = Colors.green;
  static const String defaultFontFamily = 'Poppins';

  static const tabletMaxWidth = 500.0;
  static const tabletMaxHeight = 400.0;

  static const waVoiceNotesPath =
      'Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Voice Notes';

  static final DateFormat formatDateTime = DateFormat('dd/MM/yyyy hh:mm a');

  static final List<int> weeksOptions = [1, 2, 3, 4, 5, 6, 7, 8];

  static Map<String, String> availableFonts = getAvailableFonts();

  static Map<String, String> getAvailableFonts() {
    return {
      'Merriweather': 'Merriweather',
      'Montserrat': 'Montserrat',
      'Nunito': 'Nunito',
      'Open Sans': 'Open Sans',
      'Orbitron': 'Orbitron',
      'Pacifico': 'Pacifico',
      'Playfair Display': 'Playfair Display',
      'Poppins': 'Poppins',
      'Roboto': 'Roboto',
      'Source Code Pro': 'Source Code Pro',
    };
  }

  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('es', 'ES'),
    Locale('it', 'IT'),
  ];
}
