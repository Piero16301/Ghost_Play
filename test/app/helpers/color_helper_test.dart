import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('ColorHelper', () {
    test('getColorByName returns correct color', () {
      expect(ColorHelper.getColorByName('red'), Colors.red);
      expect(ColorHelper.getColorByName('BLUE'), Colors.blue);
      expect(ColorHelper.getColorByName('indigo'), Colors.indigo);
    });

    test('getColorByName returns default color for unknown name', () {
      expect(ColorHelper.getColorByName('unknown'), Colors.green);
    });

    test('getColorName returns correct name', () {
      expect(ColorHelper.getColorName(Colors.red), 'RED');
      expect(ColorHelper.getColorName(Colors.blue), 'BLUE');
      expect(ColorHelper.getColorName(Colors.green), 'GREEN');
    });

    test('colorMap contains all expected colors', () {
      expect(ColorHelper.colorMap.length, 19);
      expect(ColorHelper.colorMap['ORANGE'], Colors.orange);
    });
  });
}
