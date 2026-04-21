import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/l10n/l10n.dart';
import '../helpers/pump_app.dart';

void main() {
  group('AppLocalizationsX', () {
    testWidgets('provides l10n from BuildContext', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpApp(
        Builder(
          builder: (context) {
            l10n = context.l10n;
            return const Placeholder();
          },
        ),
      );
      expect(l10n, isA<AppLocalizations>());
    });
  });
}
