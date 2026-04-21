import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:saf/saf.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    StorageService? storageService,
  }) : _storageService = storageService ?? MethodChannelStorageService(),
       super(const HomeState());

  final StorageService _storageService;
  final AnalyticsService _analyticsService = getIt<AnalyticsService>();
  final CrashService _crashService = getIt<CrashService>();
  final PerformanceService _performanceService = getIt<PerformanceService>();

  Future<void> initStorage() async {
    final trace = _performanceService.startTrace('home_cubit_init_storage');
    try {
      final persistedDirs = await _storageService
          .getPersistedPermissionDirectories();

      if (persistedDirs != null && persistedDirs.isNotEmpty) {
        _crashService.log('Persisted directories found, loading audios.');
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
        _crashService.log('No persisted directories, need permission.');
        emit(
          state.copyWith(
            hasPermission: false,
          ),
        );
      }
    } on Exception catch (e, stackTrace) {
      _crashService.recordError(
        e,
        stackTrace,
        reason: 'Failed to init storage',
      );
      emit(state.copyWith(status: HomeStatus.failure));
    } finally {
      _performanceService.stopTrace(trace);
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

    final trace = _performanceService.startTrace('home_cubit_load_audios');
    try {
      final result = await _storageService.getRecentAudios(
        uri: state.savedDirectoryUri,
        weeks: state.weeks,
      );

      if (result != null) {
        final loadedAudios = result
            .map(
              (data) =>
                  AudioMetadata.fromMap(Map<String, dynamic>.from(data as Map)),
            )
            .toList();

        _crashService.log('Successfully loaded ${loadedAudios.length} audios.');
        emit(
          state.copyWith(
            status: HomeStatus.success,
            audios: loadedAudios,
          ),
        );
      }
    } on PlatformException catch (e, stackTrace) {
      _crashService.recordError(
        e,
        stackTrace,
        reason: 'PlatformException loading audios',
      );
      emit(state.copyWith(status: HomeStatus.failure));
    } on Exception catch (e, stackTrace) {
      _crashService.recordError(
        e,
        stackTrace,
        reason: 'Exception loading audios',
      );
      emit(state.copyWith(status: HomeStatus.failure));
    } finally {
      _performanceService.stopTrace(trace);
    }
  }

  Future<void> requestPermission() async {
    _analyticsService.logEvent(name: 'request_permission_action');
    final isGranted = await _storageService.getDirectoryPermission(
      AppVariables.waVoiceNotesPath,
    );

    if (isGranted == true) {
      final persistedDirs = await _storageService
          .getPersistedPermissionDirectories();
      if (persistedDirs != null && persistedDirs.isNotEmpty) {
        final saf = Saf(persistedDirs.first);
        _crashService.log('Permission granted by user.');
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
    } else {
      _crashService.log('Permission explicitly denied by user.');
    }
  }

  Future<void> setWeeks(int weeks) async {
    _analyticsService.logEvent(
      name: 'change_weeks_filter_action',
      parameters: {'weeks': weeks},
    );
    if (weeks == state.weeks) return;
    _crashService.setCustomKey('filter_weeks', weeks);
    emit(state.copyWith(weeks: weeks));
    await loadAudios();
  }
}
