import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/l10n/l10n.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:video_player/video_player.dart';

class MultimediaPreviewDialog extends StatefulWidget {
  const MultimediaPreviewDialog({
    required this.item,
    required this.defaultAspectRatio,
    super.key,
  });

  final MultimediaMetadata item;
  final double defaultAspectRatio;

  @override
  State<MultimediaPreviewDialog> createState() =>
      _MultimediaPreviewDialogState();
}

class _MultimediaPreviewDialogState extends State<MultimediaPreviewDialog> {
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
      'multimedia_preview_cache_init',
    );
    try {
      getIt<CrashService>().log(
        'Start caching multimedia preview: ${widget.item.uri}',
      );
      final path = await getIt<StorageService>().cacheFile(
        uri: widget.item.uri,
        fileName: widget.item.name,
      );

      if (path == null) {
        throw Exception();
      }

      _cachedFilePath = path;

      if (widget.item.isVideo) {
        _videoPlayerController = VideoPlayerController.file(File(path));
        await _videoPlayerController!.initialize();
        await _videoPlayerController!.setLooping(false);
        await _videoPlayerController!.play();
      }

      getIt<CrashService>().log(
        'Successfully cached multimedia preview: ${widget.item.uri}',
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
        reason: 'Error caching and init multimedia preview',
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
      'multimedia_save_to_gallery',
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

      if (widget.item.isVideo) {
        await Gal.putVideo(_cachedFilePath!);
      } else {
        await Gal.putImage(_cachedFilePath!);
      }

      getIt<CrashService>().log(
        'Successfully saved multimedia to gallery: ${widget.item.uri}',
      );

      getIt<AnalyticsService>().logEvent(
        name: 'save_to_gallery_action',
        parameters: {
          'is_video': widget.item.isVideo.toString(),
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
        reason: 'Error saving multimedia to gallery',
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
      title: _buildTitle(l10n),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: _buildContent(l10n),
              ),
            ),
            if (widget.item.isVideo && _videoPlayerController != null)
              _buildVideoControls(),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceAround,
      actions: _buildActions(l10n),
    );
  }

  Widget? _buildTitle(AppLocalizations l10n) {
    if (_isLoading) {
      return null;
    }

    if (_error != null) {
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
      return const AspectRatio(
        aspectRatio: 3 / 4,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return AspectRatio(
        aspectRatio: 3 / 4,
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

    if (widget.item.isVideo && _videoPlayerController != null) {
      final value = _videoPlayerController!.value;
      var aspectRatio = value.aspectRatio;

      if (value.rotationCorrection == 90 || value.rotationCorrection == 270) {
        aspectRatio = 1 / aspectRatio;
      }

      if (aspectRatio == 1.0) {
        aspectRatio = widget.defaultAspectRatio;
      }

      return AspectRatio(
        aspectRatio: aspectRatio,
        child: VideoPlayer(_videoPlayerController!),
      );
    }

    return Image.file(
      File(_cachedFilePath!),
      fit: BoxFit.contain,
    );
  }

  Widget _buildVideoControls() {
    return ValueListenableBuilder(
      valueListenable: _videoPlayerController!,
      builder: (context, value, child) {
        final position = value.position;
        final duration = value.duration;

        return Row(
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
                  unawaited(_videoPlayerController!.pause());
                } else {
                  if (value.position >= value.duration) {
                    unawaited(_videoPlayerController!.seekTo(Duration.zero));
                  }
                  unawaited(_videoPlayerController!.play());
                }
              },
            ),
            Text(
              _formatDuration(position),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _VideoProgressBar(
                  controller: _videoPlayerController!,
                ),
              ),
            ),
            Text(
              _formatDuration(duration),
              style: Theme.of(context).textTheme.bodyMedium,
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
              onPressed: () => _videoPlayerController!.setVolume(
                value.volume == 0 ? 1 : 0,
              ),
            ),
          ],
        );
      },
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

class _VideoProgressBar extends StatefulWidget {
  const _VideoProgressBar({
    required this.controller,
  });

  final VideoPlayerController controller;

  @override
  State<_VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<_VideoProgressBar> {
  double? _dragValue;
  late VoidCallback listener;

  @override
  void initState() {
    super.initState();
    listener = () {
      if (mounted) {
        setState(() {});
      }
    };
    widget.controller.addListener(listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(listener);
    super.dispose();
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
        inactiveTrackColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest,
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
                unawaited(
                  widget.controller.seekTo(Duration(milliseconds: v.round())),
                );
                setState(() {
                  _dragValue = null;
                });
              }
            : null,
      ),
    );
  }
}
