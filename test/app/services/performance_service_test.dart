import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  group('PerformanceService', () {
    late PerformanceRepository repository;
    late PerformanceService service;

    setUpAll(registerFallbackValues);

    setUp(() {
      repository = MocktailPerformanceRepository();
      service = PerformanceService(performanceRepository: repository);
    });

    test('startTrace delegates to repository', () {
      final mockTrace = MockTrace();
      when(() => repository.startTrace(any())).thenReturn(mockTrace);

      final trace = service.startTrace('t');

      expect(trace, equals(mockTrace));
      verify(() => repository.startTrace('t')).called(1);
    });

    test('stopTrace delegates to repository', () {
      final mockTrace = MockTrace();
      when(() => repository.stopTrace(any())).thenReturn(null);

      service.stopTrace(mockTrace);

      verify(() => repository.stopTrace(mockTrace)).called(1);
    });
  });
}
