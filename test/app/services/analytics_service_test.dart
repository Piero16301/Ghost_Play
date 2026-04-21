import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  group('AnalyticsService', () {
    late AnalyticsRepository repository;
    late AnalyticsService service;

    setUpAll(registerFallbackValues);

    setUp(() {
      repository = MocktailAnalyticsRepository();
      service = AnalyticsService(analyticsRepository: repository);
    });

    test('logEvent delegates to repository', () {
      when(
        () => repository.logEvent(
          name: any(named: 'name', that: equals('test_event')),
          parameters: any(named: 'parameters'),
        ),
      ).thenReturn(null);

      service.logEvent(name: 'test_event', parameters: {'p': 'v'});

      verify(
        () => repository.logEvent(
          name: 'test_event',
          parameters: {'p': 'v'},
        ),
      ).called(1);
    });

    test('setCurrentScreen delegates to repository', () {
      when(
        () => repository.setCurrentScreen(
          screenName: any(named: 'screenName', that: equals('test_screen')),
        ),
      ).thenReturn(null);

      service.setCurrentScreen(screenName: 'test_screen');

      verify(
        () => repository.setCurrentScreen(screenName: 'test_screen'),
      ).called(1);
    });
  });
}
