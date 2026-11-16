import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

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
