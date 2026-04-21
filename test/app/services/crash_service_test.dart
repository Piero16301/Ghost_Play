import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  group('CrashService', () {
    late CrashRepository repository;
    late CrashService service;

    setUpAll(registerFallbackValues);

    setUp(() {
      repository = MocktailCrashRepository();
      service = CrashService(crashRepository: repository);
    });

    test('log delegates to repository', () {
      when(() => repository.log(any())).thenReturn(null);
      service.log('msg');
      verify(() => repository.log('msg')).called(1);
    });

    test('recordError delegates to repository', () {
      final ex = Exception('e');
      final st = StackTrace.current;
      when(
        () => repository.recordError(
          any<dynamic>(),
          any<StackTrace?>(),
          reason: any<dynamic>(named: 'reason'),
          information: any<Iterable<Object>>(named: 'information'),
          fatal: any<bool>(named: 'fatal'),
        ),
      ).thenReturn(null);

      service.recordError(ex, st, reason: 'r');
      verify(
        () => repository.recordError(
          ex,
          st,
          reason: 'r',
          fatal: false,
        ),
      ).called(1);
    });

    test('setCustomKey delegates to repository', () {
      when(() => repository.setCustomKey(any(), any())).thenReturn(null);
      service.setCustomKey('k', 'v');
      verify(() => repository.setCustomKey('k', 'v')).called(1);
    });
  });
}
