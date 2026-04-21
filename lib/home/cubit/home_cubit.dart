import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:ghost_play/app/app.dart';
import 'package:saf/saf.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState());

  Future<void> initStorage() async {
    try {
      final persistedDirs = await Saf.getPersistedPermissionDirectories();

      if (persistedDirs != null && persistedDirs.isNotEmpty) {
        final saf = Saf(persistedDirs.first);
        emit(
          state.copyWith(
            status: HomeStatus.success,
            saf: saf,
            hasPermission: true,
            savedDirectoryUri: persistedDirs.first,
          ),
        );

        await loadAudios();
      } else {
        emit(
          state.copyWith(
            hasPermission: false,
          ),
        );
      }
    } on Exception catch (_) {
      emit(state.copyWith(status: HomeStatus.failure));
    }
  }

  Future<void> loadAudios() async {
    if (state.saf == null) {
      return;
    }

    if (state.savedDirectoryUri.isEmpty) {
      return;
    }

    emit(state.copyWith(status: HomeStatus.loading));

    try {
      const platform = MethodChannel('ghostplay/storage');

      final result = await platform.invokeMethod<List<dynamic>>(
        'getRecentAudios',
        {
          'uri': state.savedDirectoryUri,
          'weeks': state.weeks,
        },
      );

      if (result != null) {
        final loadedAudios = result
            .map(
              (data) =>
                  AudioMetadata.fromMap(Map<String, dynamic>.from(data as Map)),
            )
            .toList();

        emit(
          state.copyWith(
            status: HomeStatus.success,
            audios: loadedAudios,
          ),
        );
      }
    } on PlatformException catch (_) {
      emit(state.copyWith(status: HomeStatus.failure));
    } on Exception catch (_) {
      emit(state.copyWith(status: HomeStatus.failure));
    }
  }

  Future<void> requestPermission() async {
    final tempSaf = Saf(AppVariables.waVoiceNotesPath);
    final isGranted = await tempSaf.getDirectoryPermission(
      grantWritePermission: false,
    );

    if (isGranted == true) {
      final persistedDirs = await Saf.getPersistedPermissionDirectories();
      if (persistedDirs != null && persistedDirs.isNotEmpty) {
        final saf = Saf(persistedDirs.first);
        emit(
          state.copyWith(
            status: HomeStatus.success,
            saf: saf,
            hasPermission: true,
            savedDirectoryUri: persistedDirs.first,
          ),
        );

        await loadAudios();
      }
    }
  }

  Future<void> setWeeks(int weeks) async {
    if (weeks == state.weeks) return;
    emit(state.copyWith(weeks: weeks));
    await loadAudios();
  }
}
