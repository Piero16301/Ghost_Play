import 'dart:async';

import 'package:expressive_kit/expressive_kit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:ghost_play/l10n/l10n.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

class AudiosHomeView extends StatelessWidget {
  const AudiosHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final darkTheme = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state.audiosStatus.isLoading) {
          return const Center(
            child: SizedBox.square(
              dimension: 120,
              child: ExpressiveCircularProgressIndicator(),
            ),
          );
        }

        if (state.audiosStatus.isFailure) {
          return Center(
            child: Text(l10n.loadingAudiosError, textAlign: TextAlign.center),
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
                  l10n.welcomeAudiosDescription,
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

        if (state.audios.isEmpty) {
          return Center(
            child: Text(l10n.noAudiosFound, textAlign: TextAlign.center),
          );
        }

        return Stack(
          alignment: AlignmentGeometry.bottomCenter,
          children: [
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      spacing: 4,
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedAudioWave02,
                          strokeWidth: 2,
                        ),
                        Text(l10n.audiosFound(state.audios.length)),
                      ],
                    ),
                    InkWell(
                      onTap: () =>
                          _showWeeksMenu(context, state.audioWeeksFilter),
                      borderRadius: BorderRadius.circular(100),
                      child: Chip(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                        side: BorderSide.none,
                        label: Row(
                          spacing: 4,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedCalendar02,
                              size: 18,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                            ),
                            Text(
                              l10n.weeksFilter(state.audioWeeksFilter),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: context.read<HomeCubit>().loadAudios,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: state.audios.length,
                      itemBuilder: (context, index) {
                        final audio = state.audios[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: ExpressiveListTile(
                            leading: ExpressiveBadge(
                              icon: HugeIcon(
                                icon: HugeIcons.strokeRoundedAudioWave01,
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              audio.name.split('.').first,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              AppVariables.formatDateTime.format(audio.date),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: Text(
                              audio.formattedDuration,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            onTap: () => context
                                .read<AudiosHomeCubit>()
                                .playAudio(audio),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const MiniPlayer(),
          ],
        );
      },
    );
  }

  void _showWeeksMenu(BuildContext context, int currentWeeks) {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (dragContext, scrollController) => Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).buttonTheme.colorScheme!.primary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.weeksFilterTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: RadioGroup<int?>(
                      groupValue: currentWeeks,
                      onChanged: (value) {
                        unawaited(
                          context.read<HomeCubit>().setAudiosWeeks(value ?? 1),
                        );
                        Navigator.pop(context);
                      },
                      child: Column(
                        children: AppVariables.weeksOptions.map((weeks) {
                          return RadioListTile<int?>(
                            title: Text(l10n.weeksFilter(weeks)),
                            value: weeks,
                            contentPadding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
