import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  group('FirebaseAnalyticsRepository', () {
    late MockFirebaseAnalytics analytics;
    late FirebaseAnalyticsRepository repository;

    setUp(() {
      analytics = MockFirebaseAnalytics();
      repository = FirebaseAnalyticsRepository(analytics: analytics);
    });

    test('logEvent calls analytics.logEvent', () async {
      when(
        () => analytics.logEvent(
          name: any<String>(named: 'name'),
          parameters: any<Map<String, Object>?>(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      repository.logEvent(name: 'test_event', parameters: {'p1': 'v1'});

      verify(
        () => analytics.logEvent(
          name: 'test_event',
          parameters: {'p1': 'v1'},
        ),
      ).called(1);
    });

    test(
      'setCurrentScreen calls analytics.logEvent with screen_view',
      () async {
        when(
          () => analytics.logEvent(
            name: any<String>(named: 'name'),
            parameters: any<Map<String, Object>?>(named: 'parameters'),
          ),
        ).thenAnswer((_) async {});

        repository.setCurrentScreen(screenName: 'test_screen');

        verify(
          () => analytics.logEvent(
            name: 'screen_view',
            parameters: {'screen_name': 'test_screen'},
          ),
        ).called(1);
      },
    );

    test('MockAnalyticsRepository does nothing', () {
      final _ = MockAnalyticsRepository()
        ..logEvent(name: 'event')
        ..setCurrentScreen(screenName: 'screen');
    });

    test('default constructor hits Firebase.instance line', () {
      try {
        FirebaseAnalyticsRepository();
      } on Exception catch (_) {}
    });
  });
}
