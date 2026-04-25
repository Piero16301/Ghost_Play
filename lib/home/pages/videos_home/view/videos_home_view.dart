import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:ghost_play/l10n/l10n.dart';
import 'package:hugeicons/hugeicons.dart';

class VideosHomeView extends StatelessWidget {
  const VideosHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final darkTheme = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state.videosStatus.isLoading) {
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

        if (state.videosStatus.isFailure) {
          return Center(
            child: Text(
              l10n.loadingVideosError,
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.welcomeVideosDescription,
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

        if (state.videos.isEmpty) {
          return Center(
            child: Text(
              l10n.noVideosFound,
              textAlign: TextAlign.center,
            ),
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
                        Text(l10n.weeksFilter(state.videoWeeksFilter)),
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
                        unawaited(
                          showDialog<void>(
                            context: context,
                            builder: (context) => MultimediaPreviewDialog(
                              item: item,
                              defaultAspectRatio: 1,
                            ),
                          ),
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
