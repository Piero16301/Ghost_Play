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

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(context.read<HomeCubit>().initStorage());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final hasPermission = context.read<HomeCubit>().state.hasPermission;
    if (state == AppLifecycleState.resumed && hasPermission) {
      unawaited(context.read<HomeCubit>().loadAudios());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(
            AppVariables.appName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            padding: EdgeInsets.zero,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedSettings02,
              strokeWidth: 2,
            ),
            onPressed: () => context.pushNamed(AppRoute.settings.name),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              if (state.status.isLoading) {
                return Center(
                  child: SizedBox.square(
                    dimension: 120,
                    child: CircularLoadingAnimation(
                      outerCircleColor: const Color(0xFF0DE4F9),
                      innerCircleColor: Colors.white,
                      backgroundColor: const Color(0xFF0F1B33),
                      centerWidget: Image.asset(
                        'assets/images/logo-no-bg.png',
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ),
                );
              }

              if (state.status.isFailure) {
                return Center(
                  child: Text(
                    l10n.loadingAudiosError,
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (!state.hasPermission) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F1B33),
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            'assets/images/logo-no-bg.png',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.welcomeTitle(AppVariables.appName),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.welcomeDescription,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      AppFilledButton(
                        onPressed: () =>
                            context.read<HomeCubit>().requestPermission(),
                        label: l10n.givePermissionButton,
                      ),
                    ],
                  ),
                );
              }

              if (state.audios.isEmpty) {
                return Center(
                  child: Text(
                    l10n.noAudiosFound,
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: context.read<HomeCubit>().loadAudios,
                child: ListView.builder(
                  itemCount: state.audios.length,
                  itemBuilder: (context, index) {
                    final audio = state.audios[index];
                    return ListTile(
                      leading: HugeIcon(
                        icon: HugeIcons.strokeRoundedAudioWave01,
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        audio.name,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        AppVariables.formatDateTime.format(audio.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Text(
                        audio.formattedDuration,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {},
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
