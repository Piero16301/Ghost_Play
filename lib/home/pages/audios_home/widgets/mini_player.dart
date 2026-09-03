import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghost_play/home/home.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudiosHomeCubit, AudiosHomeState>(
      builder: (context, state) {
        if (!state.isVisible || state.currentAudio == null) {
          return const SizedBox.shrink();
        }

        final audio = state.currentAudio!;
        final isPlaying = state.status.isPlaying || state.status.isLoading;
        final isLoading = state.status.isLoading;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
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
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'x${state.playbackSpeed.toString().replaceAll(
                            RegExp(r'\.0$'),
                            '',
                          )}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
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
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontVariations: [
                                  ...(Theme.of(context)
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
                          '${_formatDuration(state.position)} / ${audio.formattedDuration}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: HugeIcon(
                        icon: isPlaying
                            ? HugeIcons.strokeRoundedPause
                            : HugeIcons.strokeRoundedPlay,
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer,
                        strokeWidth: 2,
                      ),
                      onPressed: () {
                        if (isPlaying) {
                          unawaited(context.read<AudiosHomeCubit>().pause());
                        } else {
                          unawaited(context.read<AudiosHomeCubit>().resume());
                        }
                      },
                    ),
                  IconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer,
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
  const _PlayerProgressBar({
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
        activeTrackColor: Theme.of(context).colorScheme.primary,
        inactiveTrackColor: Theme.of(context).colorScheme.onPrimary,
        thumbColor: Theme.of(context).colorScheme.primary,
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
