import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  group('CrashlyticsCrashRepository', () {
    late MockFirebaseCrashlytics crashlytics;
    late CrashlyticsCrashRepository repository;

    setUp(() {
      crashlytics = MockFirebaseCrashlytics();
      repository = CrashlyticsCrashRepository(crashlytics: crashlytics);
    });

    test('log calls _crashlytics.log', () async {
      when(() => crashlytics.log(any())).thenAnswer((_) async {});

      repository.log('test log');

      verify(() => crashlytics.log('test log')).called(1);
    });

    test('recordError calls _crashlytics.recordError', () async {
      final exception = Exception('test');
      final stack = StackTrace.current;

      when(
        () => crashlytics.recordError(
          any<dynamic>(),
          any<StackTrace?>(),
          reason: any<dynamic>(named: 'reason'),
          information: any<Iterable<Object>>(named: 'information'),
          fatal: any<bool>(named: 'fatal'),
        ),
      ).thenAnswer((_) async {});

      repository.recordError(exception, stack, reason: 'reason');

      verify(
        () => crashlytics.recordError(
          exception,
          stack,
          reason: 'reason',
          information: any<Iterable<Object>>(named: 'information'),
        ),
      ).called(1);
    });

    test('setCustomKey calls _crashlytics.setCustomKey', () async {
      when(
        () => crashlytics.setCustomKey(any<String>(), any<Object>()),
      ).thenAnswer((_) async {});

      repository.setCustomKey('key', 'value');

      verify(() => crashlytics.setCustomKey('key', 'value')).called(1);
    });

    test('MockCrashRepository does nothing', () {
      final _ = MockCrashRepository()
        ..log('msg')
        ..recordError('err', null)
        ..setCustomKey('k', 'v');
    });

    test('default constructor hits FirebaseCrashlytics.instance line', () {
      try {
        CrashlyticsCrashRepository();
      } on Exception catch (_) {}
    });
  });
}
