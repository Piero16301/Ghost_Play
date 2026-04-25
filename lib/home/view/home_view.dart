import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:ghost_play/l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<HomeCubit>().initStorage());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(
            AppVariables.appName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          notificationPredicate: (_) => false,
          leading: IconButton(
            padding: EdgeInsets.zero,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedSettings02,
              strokeWidth: 2,
            ),
            onPressed: () {
              getIt<AnalyticsService>().logEvent(name: 'open_settings_action');
              unawaited(context.pushNamed(AppRoute.settings.name));
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedSwitcher(
            duration: AppVariables.animationDuration,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: _getSelectedBody(
              state.selectedIndex,
            ),
          ),
        ),
        bottomNavigationBar: const BottomNavigationBarHome(),
      ),
    );
  }

  Widget _getSelectedBody(
    int selectedIndex,
  ) {
    switch (selectedIndex) {
      case 0:
        return const AudiosHomePage();
      case 1:
        return const StatesHomePage();
      case 2:
        return const VideosHomePage();
      default:
        return const SizedBox.shrink();
    }
  }
}

class BottomNavigationBarHome extends StatelessWidget {
  const BottomNavigationBarHome({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) => NavigationBar(
        selectedIndex: state.selectedIndex,
        onDestinationSelected: (index) =>
            context.read<HomeCubit>().toggleSelectedIndex(index),
        destinations: [
          NavigationDestination(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedAudioWave02,
              strokeWidth: 2,
            ),
            label: l10n.homeAudiosTitle,
          ),
          NavigationDestination(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedVideo02,
              strokeWidth: 2,
            ),
            label: l10n.homeStatesTitle,
          ),
          NavigationDestination(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedVideo01,
              strokeWidth: 2,
            ),
            label: l10n.homeVideosTitle,
          ),
        ],
      ),
    );
  }
}
