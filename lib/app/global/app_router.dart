import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:ghost_play/settings/settings.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static GoRouter getRouter() {
    return GoRouter(
      observers: [
        AppRouteObserver(analyticsService: getIt<AnalyticsService>()),
      ],
      routes: [
        GoRoute(
          name: AppRoute.home.name,
          path: AppRoute.home.path,
          builder: (context, state) => const HomePage(),
          routes: [
            GoRoute(
              name: AppRoute.settings.name,
              path: AppRoute.settings.path,
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
      debugLogDiagnostics: true,
    );
  }
}

enum AppRoute {
  home('/', 'home'),
  settings('/settings', 'settings'),
  ;

  const AppRoute(this.path, this.name);
  final String path;
  final String name;
}
