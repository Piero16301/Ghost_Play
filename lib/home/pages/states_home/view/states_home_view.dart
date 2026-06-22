import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:ghost_play/l10n/l10n.dart';
import 'package:hugeicons/hugeicons.dart';

class StatesHomeView extends StatelessWidget {
  const StatesHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final darkTheme = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state.statesStatus.isLoading) {
          return Center(
            child: SizedBox.square(
              dimension: 120,
              child: CircularLoadingAnimation(
                outerCircleColor: darkTheme
                    ? const Color(0xFF0DE4F9)
                    : const Color(0xFF0F1B33),
                innerCircleColor: darkTheme
                    ? Colors.white
                    : const Color(0xFF0DE4F9),
                centerWidget: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    darkTheme
                        ? AppVariables.logoNoBgDark
                        : AppVariables.logoNoBgLight,
                    width: 40,
                    height: 40,
                  ),
                ),
              ),
            ),
          );
        }

        if (state.statesStatus.isFailure) {
          return Center(
            child: Text(
              l10n.loadingStatesError,
              textAlign: TextAlign.center,
            ),
          );
        }

        if (!state.hasPermission) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  darkTheme
                      ? AppVariables.logoNoBgDark
                      : AppVariables.logoNoBgLight,
                  width: 150,
                  height: 150,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.welcomeTitle(AppVariables.appName),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontVariations: [
                      ...(Theme.of(
                                context,
                              ).textTheme.titleLarge?.fontVariations ??
                              const <FontVariation>[])
                          .where((v) => v.axis != 'wght'),
                      const FontVariation('wght', 700),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.welcomeStatesDescription,
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

        if (state.states.isEmpty) {
          return Center(
            child: Text(
              l10n.noStatesFound,
              textAlign: TextAlign.center,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: context.read<HomeCubit>().loadStates,
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3 / 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: state.states.length,
            itemBuilder: (context, index) {
              final item = state.states[index];
              return InkWell(
                onTap: () {
                  getIt<AnalyticsService>().logEvent(
                    name: 'preview_state_action',
                    parameters: {'uri': item.uri},
                  );
                  unawaited(
                    showDialog<void>(
                      context: context,
                      builder: (context) => MultimediaPreviewDialog(
                        item: item,
                        defaultAspectRatio: 3 / 4,
                      ),
                    ),
                  );
                },
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(12),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FutureBuilder<Uint8List?>(
                        future: getIt<StorageService>().getThumbnailBytes(
                          uri: item.uri,
                          isVideo: item.isVideo,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasData && snapshot.data != null) {
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            );
                          }
                          return const Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedImageDelete01,
                              strokeWidth: 2,
                            ),
                          );
                        },
                      ),
                      if (item.isVideo)
                        const Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedPlayCircle,
                            strokeWidth: 2,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
