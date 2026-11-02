import 'dart:async';
import 'dart:typed_data';

import 'package:expressive_kit/expressive_kit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:ghost_play/l10n/l10n.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

class VideosHomeView extends StatelessWidget {
  const VideosHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final darkTheme = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state.videosStatus.isLoading) {
          return const Center(
            child: SizedBox.square(
              dimension: 120,
              child: ExpressiveCircularProgressIndicator(),
            ),
          );
        }

        if (state.videosStatus.isFailure) {
          return Center(
            child: Text(l10n.loadingVideosError, textAlign: TextAlign.center),
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
                  l10n.welcomeVideosDescription,
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

        if (state.videos.isEmpty) {
          return Center(
            child: Text(l10n.noVideosFound, textAlign: TextAlign.center),
          );
        }

        return Column(
          spacing: 12,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  spacing: 4,
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedVideo01,
                      strokeWidth: 2,
                    ),
                    Text(l10n.videosFound(state.videos.length)),
                  ],
                ),
                InkWell(
                  onTap: () => _showWeeksMenu(context, state.videoWeeksFilter),
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
                          l10n.weeksFilter(state.videoWeeksFilter),
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
                onRefresh: context.read<HomeCubit>().loadVideos,
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: state.videos.length,
                  itemBuilder: (context, index) {
                    final item = state.videos[index];
                    return InkWell(
                      onTap: () {
                        getIt<AnalyticsService>().logEvent(
                          name: 'preview_video_action',
                          parameters: {'uri': item.uri},
                        );

                        showDialog<void>(
                          context: context,
                          builder: (context) =>
                              VideoNotePreviewDialog(item: item),
                        );
                      },
                      borderRadius: const BorderRadius.all(
                        Radius.circular(100),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(100),
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
                                    icon: HugeIcons.strokeRoundedVideoOff,
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                            ),
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
              ),
            ),
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
                          context.read<HomeCubit>().setVideosWeeks(value ?? 1),
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
