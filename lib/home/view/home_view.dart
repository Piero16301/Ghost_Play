import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:ghost_play/l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialIndex = context.read<HomeCubit>().state.selectedIndex;
    _pageController = PageController(
      initialPage: (initialIndex >= 0 && initialIndex < 3) ? initialIndex : 0,
    );
    unawaited(context.read<HomeCubit>().initStorage());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkTheme = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<HomeCubit, HomeState>(
      listenWhen: (previous, current) =>
          previous.selectedIndex != current.selectedIndex,
      listener: (context, state) {
        if (_pageController.hasClients &&
            state.selectedIndex >= 0 &&
            state.selectedIndex < 3 &&
            _pageController.page?.round() != state.selectedIndex) {
          _pageController.animateToPage(
            state.selectedIndex,
            duration: AppVariables.animationDuration,
            curve: Curves.easeInOutCubic,
          );
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Image.asset(
            darkTheme ? AppVariables.logoNoBgDark : AppVariables.logoNoBgLight,
            width: 40,
            height: 40,
          ),
          notificationPredicate: (_) => false,
          actions: [
            IconButton(
              padding: EdgeInsets.zero,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedSettings02,
                strokeWidth: 2,
              ),
              onPressed: () {
                getIt<AnalyticsService>().logEvent(
                  name: 'open_settings_action',
                );
                unawaited(context.pushNamed(AppRoute.settings.name));
              },
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: _getSelectedBody(state.selectedIndex),
        ),
        bottomNavigationBar: const BottomNavigationBarHome(),
      ),
    );
  }

  Widget _getSelectedBody(int selectedIndex) {
    if (selectedIndex < 0 || selectedIndex >= 3) {
      return const SizedBox.shrink();
    }

    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _KeepAliveTab(child: AudiosHomePage()),
        _KeepAliveTab(child: StatesHomePage()),
        _KeepAliveTab(child: VideosHomePage()),
      ],
    );
  }
}

class _KeepAliveTab extends StatefulWidget {
  const _KeepAliveTab({required this.child});

  final Widget child;

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
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
