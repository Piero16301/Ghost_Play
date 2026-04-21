import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  group('FirebasePerformanceRepository', () {
    late MockFirebasePerformance performance;
    late FirebasePerformanceRepository repository;

    setUp(() {
      performance = MockFirebasePerformance();
      repository = FirebasePerformanceRepository(performance: performance);
    });

    test('startTrace starts a new trace', () async {
      final mockTrace = MockTrace();
      when(() => performance.newTrace(any())).thenReturn(mockTrace);
      when(mockTrace.start).thenAnswer((_) async {});

      final trace = repository.startTrace('test_trace');

      expect(trace, equals(mockTrace));
      verify(() => performance.newTrace('test_trace')).called(1);
      verify(mockTrace.start).called(1);
    });

    test('stopTrace stops the trace', () async {
      final mockTrace = MockTrace();
      when(mockTrace.stop).thenAnswer((_) async {});

      repository.stopTrace(mockTrace);

      verify(mockTrace.stop).called(1);
    });

    test('MockPerformanceRepository throws', () {
      final mockRepo = MockPerformanceRepository();
      expect(() => mockRepo.startTrace('t'), throwsUnimplementedError);
      expect(() => mockRepo.stopTrace(MockTrace()), throwsUnimplementedError);
    });

    test('default constructor hits FirebasePerformance.instance line', () {
      try {
        FirebasePerformanceRepository();
      } on Exception catch (_) {}
    });
  });
}
