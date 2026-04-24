import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:ghost_play/app/app.dart';
import 'package:saf/saf.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    StorageService? storageService,
  }) : _storageService = storageService ?? getIt<StorageService>(),
       super(const HomeState());

  final StorageService _storageService;
  final AnalyticsService _analyticsService = getIt<AnalyticsService>();
  final CrashService _crashService = getIt<CrashService>();
  final PerformanceService _performanceService = getIt<PerformanceService>();

  void toggleSelectedIndex(int index) {
    _analyticsService.logEvent(
      name: 'toggle_selected_index_action',
      parameters: {'index': index},
    );
    emit(state.copyWith(selectedIndex: index));
  }

  Future<void> initStorage() async {
    final trace = _performanceService.startTrace('storage_setup_latency');
    try {
      final persistedDirs = await _storageService
          .getPersistedPermissionDirectories();

      if (persistedDirs != null && persistedDirs.isNotEmpty) {
        _crashService
          ..log(
            'Persisted directories found, loading audios and states.',
          )
          ..setCustomKey('permission_granted', true);
        final saf = Saf(persistedDirs.first);
        emit(
          state.copyWith(
            saf: saf,
            hasPermission: true,
            savedDirectoryUri: persistedDirs.first,
          ),
        );

        await Future.wait([
          loadAudios(),
          loadStates(),
        ]);
      } else {
        _crashService
          ..log('No persisted directories, need permission.')
          ..setCustomKey('permission_granted', false);
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
      emit(state.copyWith(hasPermission: false));
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

    emit(state.copyWith(audiosStatus: HomeStatus.loading));

    final trace = _performanceService.startTrace('audio_list_load_latency');
    try {
      final result = await _storageService.getRecentAudios(
        uri: state.savedDirectoryUri,
        weeks: state.audioWeeksFilter,
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
            audiosStatus: HomeStatus.success,
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
      emit(state.copyWith(audiosStatus: HomeStatus.failure));
    } on Exception catch (e, stackTrace) {
      _crashService.recordError(
        e,
        stackTrace,
        reason: 'Exception loading audios',
      );
      emit(state.copyWith(audiosStatus: HomeStatus.failure));
    } finally {
      _performanceService.stopTrace(trace);
    }
  }

  Future<void> requestPermission() async {
    _analyticsService.logEvent(name: 'request_permission_action');
    final isGranted = await _storageService.getDirectoryPermission(
      AppVariables.waVoiceNotesPath,
    );

    _crashService.setCustomKey('permission_granted', isGranted ?? false);

    if (isGranted == true) {
      final persistedDirs = await _storageService
          .getPersistedPermissionDirectories();
      if (persistedDirs != null && persistedDirs.isNotEmpty) {
        final saf = Saf(persistedDirs.first);
        _crashService.log('Permission granted by user.');
        emit(
          state.copyWith(
            saf: saf,
            hasPermission: true,
            savedDirectoryUri: persistedDirs.first,
          ),
        );

        await Future.wait([
          loadAudios(),
          loadStates(),
        ]);
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
    if (weeks == state.audioWeeksFilter) return;
    _crashService.setCustomKey('filter_weeks', weeks);
    emit(state.copyWith(audioWeeksFilter: weeks));
    await loadAudios();
  }

  Future<void> loadStates() async {
    if (state.saf == null) {
      return;
    }

    if (state.savedDirectoryUri.isEmpty) {
      return;
    }

    emit(state.copyWith(statesStatus: HomeStatus.loading));

    final trace = _performanceService.startTrace('states_list_load_latency');
    try {
      final result = await _storageService.getRecentStates(
        uri: state.savedDirectoryUri,
      );

      if (result != null) {
        final loadedStates = result
            .map(
              (data) =>
                  StateMetadata.fromMap(Map<String, dynamic>.from(data as Map)),
            )
            .toList();

        _crashService.log('Successfully loaded ${loadedStates.length} states.');
        emit(
          state.copyWith(
            statesStatus: HomeStatus.success,
            states: loadedStates,
          ),
        );
      }
    } on PlatformException catch (e, stackTrace) {
      _crashService.recordError(
        e,
        stackTrace,
        reason: 'PlatformException loading states',
      );
      emit(state.copyWith(statesStatus: HomeStatus.failure));
    } on Exception catch (e, stackTrace) {
      _crashService.recordError(
        e,
        stackTrace,
        reason: 'Exception loading states',
      );
      emit(state.copyWith(statesStatus: HomeStatus.failure));
    } finally {
      _performanceService.stopTrace(trace);
    }
  }
}
