import 'dart:typed_data';

import 'package:expressive_kit/expressive_kit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:ghost_play/l10n/l10n.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

class StatesHomeView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final darkTheme = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state.statesStatus.isLoading) {
          return const Center(
            child: SizedBox.square(
              dimension: 120,
              child: ExpressiveCircularProgressIndicator(),
            ),
          );
        }

        if (state.statesStatus.isFailure) {
          return Center(
            child: Text(l10n.loadingStatesError, textAlign: TextAlign.center),
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
                      ...(Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.fontVariations ??
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
                ExpressiveButton.filled(
                  onPressed: () =>
                      context.read<HomeCubit>().requestPermission(),
                  label: l10n.givePermissionButton,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedShield01,
                    size: 20,
                  ),
                ),
              ],
            ),
          );
        }

        if (state.states.isEmpty) {
          return Center(
            child: Text(l10n.noStatesFound, textAlign: TextAlign.center),
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

                  showDialog<void>(
                    context: context,
                    builder: (context) => MultimediaPreviewDialog(
                      item: item,
                      defaultAspectRatio: 3 / 4,
                    ),
                  );
                },
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
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
                              child: ExpressiveCircularProgressIndicator(
                                size: 32,
                                strokeWidth: 4,
                              ),
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
