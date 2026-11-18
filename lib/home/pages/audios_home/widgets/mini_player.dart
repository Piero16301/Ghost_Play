import 'dart:async';

import 'package:expressive_kit/expressive_kit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghost_play/home/home.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

class MiniPlayer extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<AudiosHomeCubit, AudiosHomeState>(
      builder: (context, state) {
        if (!state.isVisible || state.currentAudio == null) {
          return const SizedBox.shrink();
        }

        final audio = state.currentAudio!;
        final isPlaying = state.status.isPlaying || state.status.isLoading;
        final isLoading = state.status.isLoading;
        final speedString = state.playbackSpeed.toString();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => unawaited(
                          context.read<AudiosHomeCubit>().changeSpeed(),
                        ),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'x${speedString.replaceAll(RegExp(r'\.0$'), '')}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              audio.name.split('.').first,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontVariations: [
                                  ...(theme
                                              .textTheme
                                              .bodyLarge
                                              ?.fontVariations ??
                                          const <FontVariation>[])
                                      .where((v) => v.axis != 'wght'),
                                  const FontVariation('wght', 700),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatDuration(state.position)} / '
                              '${audio.formattedDuration}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!state.isTranscriptionVisible)
                        ExpressiveIconButton.circle(
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedAiTranscribeAudio,
                            color: colorScheme.onSurface,
                            strokeWidth: 2,
                          ),
                          onPressed: () => unawaited(
                            context.read<AudiosHomeCubit>().transcribeAudio(),
                          ),
                        ),
                      if (isLoading)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: colorScheme.primary,
                            ),
                          ),
                        )
                      else
                        IconButton(
                          icon: HugeIcon(
                            icon: isPlaying
                                ? HugeIcons.strokeRoundedPause
                                : HugeIcons.strokeRoundedPlay,
                            color: colorScheme.onSurface,
                            strokeWidth: 2,
                          ),
                          onPressed: () {
                            if (isPlaying) {
                              unawaited(
                                context.read<AudiosHomeCubit>().pause(),
                              );
                            } else {
                              unawaited(
                                context.read<AudiosHomeCubit>().resume(),
                              );
                            }
                          },
                        ),
                      IconButton(
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          color: colorScheme.onSurfaceVariant,
                          strokeWidth: 2,
                        ),
                        onPressed: () =>
                            context.read<AudiosHomeCubit>().closePlayer(),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 16,
                    child: _PlayerProgressBar(
                      position: state.position,
                      duration: state.duration,
                      onSeek: (position) {
                        unawaited(
                          context.read<AudiosHomeCubit>().seek(position),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _PlayerProgressBar extends StatefulWidget {
  const new({
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  @override
  State<_PlayerProgressBar> createState() => _PlayerProgressBarState();
}

class _PlayerProgressBarState extends State<_PlayerProgressBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final max = widget.duration.inMilliseconds.toDouble();
    final value = _dragValue ?? widget.position.inMilliseconds.toDouble();
    final clampedValue = value.clamp(0.0, max > 0 ? max : 1.0);

    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 5,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 6,
          elevation: 0,
          pressedElevation: 4,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.22),
        thumbColor: colorScheme.primary,
      ),
      child: Slider(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        max: max > 0 ? max : 1.0,
        value: clampedValue,
        onChanged: max > 0
            ? (v) {
                setState(() {
                  _dragValue = v;
                });
              }
            : null,
        onChangeEnd: max > 0
            ? (v) {
                widget.onSeek(Duration(milliseconds: v.round()));
                setState(() {
                  _dragValue = null;
                });
              }
            : null,
      ),
    );
  }
}
