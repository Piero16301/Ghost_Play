import 'dart:async';

import 'package:expressive_kit/expressive_kit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghost_play/home/home.dart';
import 'package:ghost_play/l10n/l10n.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

class AudioTranscriptionCard extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.5;

    return BlocBuilder<AudiosHomeCubit, AudiosHomeState>(
      builder: (context, state) {
        if (!state.isVisible ||
            state.currentAudio == null ||
            !state.isTranscriptionVisible) {
          return const SizedBox.shrink();
        }

        final transcriptionText =
            (state.transcription?.trim().isNotEmpty ?? false)
            ? state.transcription!.trim()
            : l10n.transcriptionError;

        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: double.infinity,
            maxHeight: maxHeight,
          ),
          child: ExpressiveCard(
            margin: EdgeInsets.zero,
            backgroundColor: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            onTap: () {},
            child: state.isTranscribing
                ? Center(
                    heightFactor: 1.5,
                    child: ExpressiveCircularProgressIndicator(
                      size: 36,
                      strokeWidth: 4,
                      color: colorScheme.primary,
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.22,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 12,
                      children: [
                        Text(
                          transcriptionText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                        Align(
                          child: ExpressiveButton.tonal(
                            size: ExpressiveButtonSize.small,
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedRefresh,
                              size: 18,
                              strokeWidth: 2,
                            ),
                            label: l10n.regenerateTranscription,
                            onPressed: () => unawaited(
                              context.read<AudiosHomeCubit>().transcribeAudio(
                                forceRefresh: true,
                              ),
                            ),
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
}
