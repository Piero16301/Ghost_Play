import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:expressive_kit/expressive_kit.dart';
import 'package:gal/gal.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/widgets/transcription_markdown.dart';
import 'package:ghost_play/home/widgets/video_progress_bar.dart';
import 'package:ghost_play/l10n/l10n.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

class VideoNotePreviewDialog extends StatefulWidget {
  const new({required this.item, super.key});

  final MultimediaMetadata item;

  @override
  State<VideoNotePreviewDialog> createState() => _VideoNotePreviewDialogState();
}

class _VideoNotePreviewDialogState extends State<VideoNotePreviewDialog> {
  String? _cachedFilePath;
  bool _isLoading = true;
  String? _error;
  VideoPlayerController? _videoPlayerController;
  bool _isTranscriptionVisible = false;
  bool _isTranscribing = false;
  String? _transcription;

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
      if (!mounted) {
        _deleteCachedFile();
        return;
      }

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
    _deleteCachedFile();
    super.dispose();
  }

  void _deleteCachedFile() {
    final path = _cachedFilePath;
    if (path == null) return;
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } on Object catch (_) {}
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
      final hasPermission = await Gal.hasPermission();
      if (!hasPermission) {
        final granted = await Gal.requestPermission();
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
    } on Exception catch (e, stackTrace) {
      getIt<CrashService>().recordError(
        e,
        stackTrace,
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

  Future<void> _transcribeVideo({bool forceRefresh = false}) async {
    if (_isTranscribing) return;

    getIt<AnalyticsService>().logEvent(
      name: 'transcribe_video_note_action',
      parameters: {'force_refresh': forceRefresh.toString()},
    );
    setState(() {
      _isTranscriptionVisible = true;
      _isTranscribing = true;
      _transcription = null;
    });

    try {
      final result = await getIt<AiService>().extractVideoTranscription(
        video: widget.item,
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _isTranscribing = false;
          _transcription = result;
        });
      }
    } on Object catch (e, stackTrace) {
      getIt<CrashService>().recordError(
        e,
        stackTrace,
        reason: 'Error transcribing video note: ${widget.item.uri}',
      );
      if (mounted) {
        setState(() {
          _isTranscribing = false;
          _transcription = null;
        });
      }
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
            if (_isTranscriptionVisible)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.42,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _buildContent(l10n),
                ),
              )
            else
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _buildContent(l10n),
                ),
              ),
            if (_videoPlayerController != null && !_isLoading && _error == null)
              _buildBottomControls(),
            if (_isTranscriptionVisible) ...[
              const SizedBox(height: 12),
              Flexible(child: _buildTranscriptionSection(l10n)),
            ],
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
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
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
      const playerSize = 330.0;

      return SizedBox.square(
        dimension: playerSize,
        child: _CircularVideoPlayer(
          controller: _videoPlayerController!,
          size: playerSize,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: VideoControlsBar(
        controller: _videoPlayerController!,
        onTranscribe: _isTranscriptionVisible
            ? null
            : () => unawaited(_transcribeVideo()),
      ),
    );
  }

  Widget _buildTranscriptionSection(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final transcriptionText = (_transcription?.trim().isNotEmpty ?? false)
        ? _transcription!.trim()
        : l10n.transcriptionError;

    return SizedBox(
      width: double.infinity,
      child: ExpressiveCard(
        margin: EdgeInsets.zero,
        backgroundColor: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        child: _isTranscribing
            ? SingleChildScrollView(
                child: Center(
                  heightFactor: 1.5,
                  child: ExpressiveCircularProgressIndicator(
                    size: 36,
                    strokeWidth: 4,
                    color: colorScheme.primary,
                    backgroundColor: colorScheme.primary.withValues(
                      alpha: 0.22,
                    ),
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    TranscriptionMarkdown(data: transcriptionText),
                    Align(
                      child: ExpressiveButton.tonal(
                        size: ExpressiveButtonSize.small,
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedRefresh,
                          size: 18,
                          strokeWidth: 2,
                        ),
                        label: l10n.regenerateTranscription,
                        onPressed: () =>
                            unawaited(_transcribeVideo(forceRefresh: true)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
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
  const new({required this.controller, required this.size});

  final VideoPlayerController controller;
  final double size;

  @override
  State<_CircularVideoPlayer> createState() => _CircularVideoPlayerState();
}

class _CircularVideoPlayerState extends State<_CircularVideoPlayer> {
  static const double _strokeWidth = 6;
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

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    final duration = value.duration;
    final currentPosition = value.position;

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

    return SizedBox.square(
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
                  if (!value.isPlaying)
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
              isDragging: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularTimePainter extends CustomPainter {
  new({
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
