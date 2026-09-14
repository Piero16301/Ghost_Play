import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:gal/gal.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/l10n/l10n.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

class VideoNotePreviewDialog extends StatefulWidget {
  const VideoNotePreviewDialog({required this.item, super.key});

  final MultimediaMetadata item;

  @override
  State<VideoNotePreviewDialog> createState() => _VideoNotePreviewDialogState();
}

class _VideoNotePreviewDialogState extends State<VideoNotePreviewDialog> {
  String? _cachedFilePath;
  bool _isLoading = true;
  String? _error;
  VideoPlayerController? _videoPlayerController;

  @override
  void initState() {
    super.initState();
    unawaited(_cacheAndInit());
  }

  Future<void> _cacheAndInit() async {
    final trace = getIt<PerformanceService>().startTrace(
      'video_note_preview_cache_init',
    );
    try {
      getIt<CrashService>().log(
        'Start caching video note preview: ${widget.item.uri}',
      );
      final path = await getIt<StorageService>().cacheFile(
        uri: widget.item.uri,
        fileName: widget.item.name,
      );

      if (path == null) {
        throw Exception();
      }

      _cachedFilePath = path;

      _videoPlayerController = VideoPlayerController.file(File(path));
      await _videoPlayerController!.initialize();
      await _videoPlayerController!.setLooping(false);
      await _videoPlayerController!.play();

      getIt<CrashService>().log(
        'Successfully cached video note preview: ${widget.item.uri}',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } on Exception catch (e, stackTrace) {
      getIt<CrashService>().recordError(
        e,
        stackTrace,
        reason: 'Error caching and init video note preview',
      );
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    } finally {
      getIt<PerformanceService>().stopTrace(trace);
    }
  }

  @override
  void dispose() {
    unawaited(_videoPlayerController?.dispose());
    super.dispose();
  }

  Future<void> _saveToGallery(AppLocalizations l10n) async {
    if (_cachedFilePath == null) return;

    final trace = getIt<PerformanceService>().startTrace(
      'video_note_save_to_gallery',
    );
    try {
      getIt<CrashService>().log(
        'Requesting gallery access for: ${widget.item.uri}',
      );
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          if (mounted) {
            AppFunctions.showSnackBar(
              context,
              message: l10n.permissionDenied,
              type: SnackBarType.error,
            );
          }
          return;
        }
      }

      await Gal.putVideo(_cachedFilePath!);

      getIt<CrashService>().log(
        'Successfully saved video note to gallery: ${widget.item.uri}',
      );

      getIt<AnalyticsService>().logEvent(
        name: 'save_to_gallery_action',
        parameters: {
          'is_video': 'true',
          'is_video_note': 'true',
          'uri': widget.item.uri,
        },
      );

      if (mounted) {
        AppFunctions.showSnackBar(
          context,
          message: l10n.savedToGallery,
          type: SnackBarType.success,
        );
        Navigator.of(context).pop();
      }
    } on Exception catch (e) {
      getIt<CrashService>().recordError(
        e,
        StackTrace.current,
        reason: 'Error saving video note to gallery',
      );
      if (mounted) {
        AppFunctions.showSnackBar(
          context,
          message: l10n.errorSaving,
          type: SnackBarType.error,
        );
      }
    } finally {
      getIt<PerformanceService>().stopTrace(trace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      contentPadding: const EdgeInsets.all(16),
      insetPadding: const EdgeInsets.all(16),
      title: _buildTitle(),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: _buildContent(l10n)),
            if (_videoPlayerController != null && !_isLoading && _error == null)
              _buildBottomControls(),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceAround,
      actions: _buildActions(l10n),
    );
  }

  Widget? _buildTitle() {
    if (_isLoading || _error != null) {
      return null;
    }

    return Column(
      spacing: 8,
      children: [
        Text(
          AppFunctions.formatFileName(
            widget.item.name,
            startCount: 5,
            endCount: 5,
          ),
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HugeIcon(icon: HugeIcons.strokeRoundedCalendar01, size: 16),
            const SizedBox(width: 4),
            Text(
              AppVariables.formatDateTime.format(widget.item.date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 16),
            const HugeIcon(icon: HugeIcons.strokeRoundedSave, size: 16),
            const SizedBox(width: 4),
            Text(
              widget.item.formattedSize,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    if (_isLoading) {
      return const SizedBox.square(
        dimension: 285,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox.square(
        dimension: 285,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedImageDelete02,
                strokeWidth: 2,
                size: 64,
                color: Colors.red,
              ),
              Text(
                l10n.errorLoadingPreview,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_videoPlayerController != null) {
      const playerSize = 285.0;

      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox.square(
              dimension: playerSize,
              child: _CircularVideoPlayer(
                controller: _videoPlayerController!,
                size: playerSize,
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: _videoPlayerController!,
        builder: (context, value, child) {
          final position = value.position;
          final duration = value.duration;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                padding: const EdgeInsets.all(6),
                icon: HugeIcon(
                  icon: value.isPlaying
                      ? HugeIcons.strokeRoundedPause
                      : HugeIcons.strokeRoundedPlay,
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () {
                  if (value.isPlaying) {
                    unawaited(_videoPlayerController!.pause());
                  } else {
                    if (value.position >= value.duration) {
                      unawaited(_videoPlayerController!.seekTo(Duration.zero));
                    }
                    unawaited(_videoPlayerController!.play());
                  }
                },
              ),
              const SizedBox(width: 8),
              Text(
                '${_formatDuration(position)} / ${_formatDuration(duration)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontVariations: [const FontVariation('wght', 600)],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: const EdgeInsets.all(6),
                icon: HugeIcon(
                  icon: value.volume == 0
                      ? HugeIcons.strokeRoundedVolumeMute02
                      : HugeIcons.strokeRoundedVolumeHigh,
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => _videoPlayerController!.setVolume(
                  value.volume == 0 ? 1 : 0,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  List<Widget>? _buildActions(AppLocalizations l10n) {
    if (_isLoading) {
      return null;
    }

    if (_error != null) {
      return [
        Row(
          children: [
            Expanded(
              child: AppOutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: HugeIcons.strokeRoundedCancel01,
                label: l10n.cancel,
              ),
            ),
          ],
        ),
      ];
    }

    return [
      Row(
        spacing: 10,
        children: [
          Expanded(
            child: AppOutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: HugeIcons.strokeRoundedCancel01,
              label: l10n.cancel,
            ),
          ),
          Expanded(
            child: AppFilledButton(
              onPressed: _isLoading || _error != null
                  ? null
                  : () => _saveToGallery(l10n),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedSave,
                strokeWidth: 2,
              ),
              label: l10n.save,
            ),
          ),
        ],
      ),
    ];
  }
}

class _CircularVideoPlayer extends StatefulWidget {
  const _CircularVideoPlayer({required this.controller, required this.size});

  final VideoPlayerController controller;
  final double size;

  @override
  State<_CircularVideoPlayer> createState() => _CircularVideoPlayerState();
}

class _CircularVideoPlayerState extends State<_CircularVideoPlayer> {
  static const double _strokeWidth = 6;
  Duration? _dragPosition;
  bool _isDragging = false;
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = () {
      if (mounted && !_isDragging) {
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

  void _handleSeek(Offset localPosition, {required bool isFinal}) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    // Angle starting at top (12 o'clock, -pi/2) going clockwise
    var angle = math.atan2(dy, dx) + (math.pi / 2);
    if (angle < 0) {
      angle += 2 * math.pi;
    }

    final fraction = (angle / (2 * math.pi)).clamp(0.0, 1.0);
    final duration = widget.controller.value.duration;
    if (duration <= Duration.zero) return;

    final targetMs = (duration.inMilliseconds * fraction).round();
    final targetPosition = Duration(milliseconds: targetMs);

    if (isFinal) {
      unawaited(widget.controller.seekTo(targetPosition));
      setState(() {
        _dragPosition = null;
        _isDragging = false;
      });
    } else {
      setState(() {
        _dragPosition = targetPosition;
        _isDragging = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    final duration = value.duration;
    final currentPosition = _dragPosition ?? value.position;

    final progress = duration.inMilliseconds > 0
        ? (currentPosition.inMilliseconds / duration.inMilliseconds).clamp(
            0.0,
            1.0,
          )
        : 0.0;

    final primaryColor = Theme.of(context).colorScheme.primary;
    final trackColor = primaryColor.withValues(alpha: 0.25);

    // Inner video radius taking stroke into account to avoid cutoffs
    final videoDimension = widget.size - (_strokeWidth * 1.5);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) =>
          _handleSeek(details.localPosition, isFinal: false),
      onPanUpdate: (details) =>
          _handleSeek(details.localPosition, isFinal: false),
      onPanEnd: (details) {
        if (_dragPosition != null) {
          unawaited(widget.controller.seekTo(_dragPosition!));
        }
        setState(() {
          _dragPosition = null;
          _isDragging = false;
        });
      },
      onPanCancel: () {
        setState(() {
          _dragPosition = null;
          _isDragging = false;
        });
      },
      onTapUp: (details) {
        final center = Offset(widget.size / 2, widget.size / 2);
        final dx = details.localPosition.dx - center.dx;
        final dy = details.localPosition.dy - center.dy;
        final distance = math.sqrt(dx * dx + dy * dy);

        // If tap is inside the inner video area, toggle play/pause
        if (distance < (widget.size / 2) - (_strokeWidth * 2)) {
          if (value.isPlaying) {
            unawaited(widget.controller.pause());
          } else {
            if (value.position >= value.duration) {
              unawaited(widget.controller.seekTo(Duration.zero));
            }
            unawaited(widget.controller.play());
          }
        } else {
          // If tap is on or near the perimeter, seek to that position
          _handleSeek(details.localPosition, isFinal: true);
        }
      },
      child: SizedBox.square(
        dimension: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular Video
            ClipOval(
              child: SizedBox.square(
                dimension: videoDimension,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Slight scale so that WhatsApp PTV rectangular edge
                    // artifacts are hidden.
                    Transform.scale(
                      scale: 1.06,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: value.size.width > 0 ? value.size.width : 1,
                          height: value.size.height > 0 ? value.size.height : 1,
                          child: VideoPlayer(widget.controller),
                        ),
                      ),
                    ),
                    // Centered play icon when paused
                    if (!value.isPlaying && !_isDragging)
                      ColoredBox(
                        color: Colors.black26,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: const HugeIcon(
                              icon: HugeIcons.strokeRoundedPlay,
                              size: 40,
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Circular Progress Bar Track and Arc
            CustomPaint(
              size: Size.square(widget.size),
              painter: _CircularTimePainter(
                progress: progress,
                strokeWidth: _strokeWidth,
                trackColor: trackColor,
                progressColor: primaryColor,
                isDragging: _isDragging,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularTimePainter extends CustomPainter {
  _CircularTimePainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
    required this.isDragging,
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;
  final bool isDragging;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track background
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc starting from 12 o'clock (-pi/2)
    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress;
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );

      // Scrubber head indicator when dragging or playing
      if (isDragging) {
        final currentAngle = -math.pi / 2 + sweepAngle;
        final thumbX = center.dx + radius * math.cos(currentAngle);
        final thumbY = center.dy + radius * math.sin(currentAngle);

        final thumbGlowPaint = Paint()
          ..color = progressColor.withValues(alpha: 0.35)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(thumbX, thumbY),
          strokeWidth + 3,
          thumbGlowPaint,
        );

        final thumbPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(thumbX, thumbY), strokeWidth, thumbPaint);

        final thumbBorderPaint = Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(
          Offset(thumbX, thumbY),
          strokeWidth,
          thumbBorderPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CircularTimePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.isDragging != isDragging;
  }
}
