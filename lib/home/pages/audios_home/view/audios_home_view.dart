import 'dart:async';

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

        if (state.audiosStatus.isFailure) {
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
                      borderRadius: BorderRadius.circular(8),
                      child: Chip(
                        padding: const EdgeInsets.all(4),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                        ),
                        label: Row(
                          spacing: 4,
                          children: [
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedCalendar02,
                            ),
                            Text(l10n.weeksFilter(state.audioWeeksFilter)),
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
                        return ListTile(
                          leading: HugeIcon(
                            icon: HugeIcons.strokeRoundedAudioWave01,
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            audio.name.split('.').first,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          subtitle: Text(
                            AppVariables.formatDateTime.format(
                              audio.date,
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontVariations: [
                                    ...(Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.fontVariations ??
                                            const <FontVariation>[])
                                        .where((v) => v.axis != 'wght'),
                                    const FontVariation('wght', 700),
                                  ],
                                ),
                          ),
                          trailing: Text(
                            audio.formattedDuration,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontVariations: [
                                    ...(Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.fontVariations ??
                                            const <FontVariation>[])
                                        .where((v) => v.axis != 'wght'),
                                    const FontVariation('wght', 700),
                                  ],
                                ),
                          ),
                          onTap: () =>
                              context.read<AudiosHomeCubit>().playAudio(audio),
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

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (modalContext) => DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (dragContext, scrollController) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).buttonTheme.colorScheme!.primary,
                      borderRadius: const BorderRadius.all(Radius.circular(2)),
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
