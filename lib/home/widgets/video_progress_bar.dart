import 'dart:async';

import 'package:expressive_kit/expressive_kit.dart';
import 'package:ghost_play/app/app.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

class VideoControlsBar extends StatelessWidget {
  const new({required this.controller, this.onTranscribe, super.key});

  final VideoPlayerController controller;
  final VoidCallback? onTranscribe;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final position = value.position;
        final duration = value.duration;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: VideoProgressBar(controller: controller),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  padding: const EdgeInsets.all(5),
                  icon: HugeIcon(
                    icon: value.isPlaying
                        ? HugeIcons.strokeRoundedPause
                        : HugeIcons.strokeRoundedPlay,
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () {
                    if (value.isPlaying) {
                      getIt<AnalyticsService>().logEvent(name: 'pause_video');
                      unawaited(controller.pause());
                    } else {
                      getIt<AnalyticsService>().logEvent(name: 'play_video');
                      if (value.position >= value.duration) {
                        unawaited(controller.seekTo(Duration.zero));
                      }
                      unawaited(controller.play());
                    }
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${_formatDuration(position)} / '
                        '${_formatDuration(duration)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontVariations: [const FontVariation('wght', 600)],
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onTranscribe != null)
                      ExpressiveIconButton.circle(
                        size: ExpressiveIconButtonSize.small,
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedAiTranscribeAudio,
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: onTranscribe,
                      ),
                    IconButton(
                      padding: const EdgeInsets.all(5),
                      icon: HugeIcon(
                        icon: value.volume == 0
                            ? HugeIcons.strokeRoundedVolumeMute02
                            : HugeIcons.strokeRoundedVolumeHigh,
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () {
                        final nextVolume = value.volume == 0 ? 1.0 : 0.0;
                        getIt<AnalyticsService>().logEvent(
                          name: 'toggle_video_mute',
                          parameters: {'muted': (nextVolume == 0).toString()},
                        );
                        unawaited(controller.setVolume(nextVolume));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class VideoProgressBar extends StatefulWidget {
  const new({required this.controller, super.key});

  final VideoPlayerController controller;

  @override
  State<VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<VideoProgressBar> {
  double? _dragValue;
  bool _wasPlayingBeforeDrag = false;
  bool _isSeeking = false;
  Duration? _pendingSeek;
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = () {
      if (mounted) {
        setState(() {});
      }
    };
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  void _enqueueSeek(Duration target) {
    if (_isSeeking) {
      _pendingSeek = target;
      return;
    }
    unawaited(_performSeek(target));
  }

  Future<void> _performSeek(Duration target) async {
    _isSeeking = true;
    try {
      await widget.controller.seekTo(target);
    } finally {
      _isSeeking = false;
    }

    final next = _pendingSeek;
    if (next != null) {
      _pendingSeek = null;
      await _performSeek(next);
    }
  }

  Future<void> _finishSeek(Duration target) async {
    _pendingSeek = null;
    await _performSeek(target);
    getIt<AnalyticsService>().logEvent(
      name: 'seek_video',
      parameters: {'position_seconds': target.inSeconds},
    );
    if (!mounted) return;
    if (_wasPlayingBeforeDrag && !widget.controller.value.isPlaying) {
      unawaited(widget.controller.play());
    }
    setState(() {
      _dragValue = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.controller.value.duration;
    final position = widget.controller.value.position;

    final max = duration.inMilliseconds.toDouble();
    final value = _dragValue ?? position.inMilliseconds.toDouble();
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
        inactiveTrackColor: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        thumbColor: Theme.of(context).colorScheme.primary,
      ),
      child: Slider(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        max: max > 0 ? max : 1.0,
        value: clampedValue,
        onChangeStart: max > 0
            ? (_) {
                _wasPlayingBeforeDrag = widget.controller.value.isPlaying;
              }
            : null,
        onChanged: max > 0
            ? (v) {
                setState(() {
                  _dragValue = v;
                });
                _enqueueSeek(Duration(milliseconds: v.round()));
              }
            : null,
        onChangeEnd: max > 0
            ? (v) {
                unawaited(_finishSeek(Duration(milliseconds: v.round())));
              }
            : null,
      ),
    );
  }
}
