import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

class MockPageRoute extends Mock implements PageRoute<dynamic> {}

void main() {
  late MockAnalyticsService analyticsService;
  late AppRouteObserver observer;

  setUp(() {
    analyticsService = MockAnalyticsService();
    observer = AppRouteObserver(analyticsService: analyticsService);

    when(
      () => analyticsService.setCurrentScreen(
        screenName: any(named: 'screenName'),
      ),
    ).thenReturn(null);
  });

  group('AppRouteObserver', () {
    test('didPush sends screen view when route is PageRoute', () {
      final route = MockPageRoute();
      when(
        () => route.settings,
      ).thenReturn(const RouteSettings(name: 'test_screen'));

      observer.didPush(route, null);

      verify(
        () => analyticsService.setCurrentScreen(screenName: 'test_screen'),
      ).called(1);
    });

    test('didPush does nothing when route name is null', () {
      final route = MockPageRoute();
      when(() => route.settings).thenReturn(const RouteSettings());

      observer.didPush(route, null);

      verifyNever(
        () => analyticsService.setCurrentScreen(
          screenName: any(named: 'screenName'),
        ),
      );
    });

    test(
      'didPop sends screen view of previous route if both are PageRoute',
      () {
        final route = MockPageRoute();
        final prevRoute = MockPageRoute();
        when(
          () => prevRoute.settings,
        ).thenReturn(const RouteSettings(name: 'prev_screen'));

        observer.didPop(route, prevRoute);

        verify(
          () => analyticsService.setCurrentScreen(screenName: 'prev_screen'),
        ).called(1);
      },
    );

    test('didRemove sends screen view of previous route', () {
      final prevRoute = MockPageRoute();
      when(
        () => prevRoute.settings,
      ).thenReturn(const RouteSettings(name: 'removed_to_screen'));

      observer.didRemove(MockPageRoute(), prevRoute);

      verify(
        () =>
            analyticsService.setCurrentScreen(screenName: 'removed_to_screen'),
      ).called(1);
    });

    test('didReplace sends screen view of new route', () {
      final newRoute = MockPageRoute();
      when(
        () => newRoute.settings,
      ).thenReturn(const RouteSettings(name: 'new_screen'));

      observer.didReplace(newRoute: newRoute, oldRoute: MockPageRoute());

      verify(
        () => analyticsService.setCurrentScreen(screenName: 'new_screen'),
      ).called(1);
    });

    test('didChangeTop sends screen view of top route', () {
      final topRoute = MockPageRoute();
      when(
        () => topRoute.settings,
      ).thenReturn(const RouteSettings(name: 'top_screen'));

      observer.didChangeTop(topRoute, null);

      verify(
        () => analyticsService.setCurrentScreen(screenName: 'top_screen'),
      ).called(1);
    });

    test('does nothing if route is not PageRoute', () {
      observer.didPush(MockRoute(), null);
      verifyNever(
        () => analyticsService.setCurrentScreen(
          screenName: any(named: 'screenName'),
        ),
      );
    });
  });
}

class MockRoute extends Mock implements Route<dynamic> {}
