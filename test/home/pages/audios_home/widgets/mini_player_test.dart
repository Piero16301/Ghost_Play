import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:ghost_play/home/pages/audios_home/audios_home.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  late AudiosHomeCubit audiosHomeCubit;

  setUpAll(registerFallbackValues);

  setUp(() {
    audiosHomeCubit = MockAudiosHomeCubit();
    when(() => audiosHomeCubit.state).thenReturn(const AudiosHomeState());
    when(() => audiosHomeCubit.pause()).thenAnswer((_) async {});
    when(() => audiosHomeCubit.resume()).thenAnswer((_) async {});
    when(() => audiosHomeCubit.changeSpeed()).thenAnswer((_) async {});
    when(() => audiosHomeCubit.closePlayer()).thenAnswer((_) async {});
    when(() => audiosHomeCubit.seek(any())).thenAnswer((_) async {});
  });

  group('MiniPlayer', () {
    testWidgets('renders nothing when isVisible is false', (tester) async {
      when(
        () => audiosHomeCubit.state,
      ).thenReturn(const AudiosHomeState());
      await tester.pumpApp(
        const MiniPlayer(),
        audiosHomeCubit: audiosHomeCubit,
      );
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('renders player info when visible', (tester) async {
      final audio = AudioMetadata(
        uri: 'u',
        name: 'audio.mp3',
        date: DateTime(2024),
        sizeBytes: 100,
        durationMs: 1000,
      );
      when(() => audiosHomeCubit.state).thenReturn(
        AudiosHomeState(
          isVisible: true,
          currentAudio: audio,
          status: AudiosHomeStatus.playing,
        ),
      );

      await tester.pumpApp(
        const MiniPlayer(),
        audiosHomeCubit: audiosHomeCubit,
      );

      expect(find.text('audio'), findsOneWidget);
      expect(find.text('x1'), findsOneWidget);
    });

    testWidgets('taps pause when playing', (tester) async {
      final audio = AudioMetadata(
        uri: 'u',
        name: 'a.mp3',
        date: DateTime(2024),
        sizeBytes: 0,
        durationMs: 0,
      );
      when(() => audiosHomeCubit.state).thenReturn(
        AudiosHomeState(
          isVisible: true,
          currentAudio: audio,
          status: AudiosHomeStatus.playing,
        ),
      );

      await tester.pumpApp(
        const MiniPlayer(),
        audiosHomeCubit: audiosHomeCubit,
      );

      await tester.tap(find.byType(HugeIcon).at(0));
      verify(() => audiosHomeCubit.pause()).called(1);
    });

    testWidgets('taps resume when paused', (tester) async {
      final audio = AudioMetadata(
        uri: 'u',
        name: 'a.mp3',
        date: DateTime(2024),
        sizeBytes: 0,
        durationMs: 0,
      );
      when(() => audiosHomeCubit.state).thenReturn(
        AudiosHomeState(
          isVisible: true,
          currentAudio: audio,
          status: AudiosHomeStatus.paused,
        ),
      );

      await tester.pumpApp(
        const MiniPlayer(),
        audiosHomeCubit: audiosHomeCubit,
      );

      await tester.tap(find.byType(HugeIcon).at(0));
      verify(() => audiosHomeCubit.resume()).called(1);
    });

    testWidgets('renders loading indicator when status is loading', (
      tester,
    ) async {
      final audio = AudioMetadata(
        uri: 'u',
        name: 'a.mp3',
        date: DateTime(2024),
        sizeBytes: 0,
        durationMs: 0,
      );
      when(() => audiosHomeCubit.state).thenReturn(
        AudiosHomeState(
          isVisible: true,
          currentAudio: audio,
          status: AudiosHomeStatus.loading,
        ),
      );

      await tester.pumpApp(
        const MiniPlayer(),
        audiosHomeCubit: audiosHomeCubit,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('taps changeSpeed', (tester) async {
      final audio = AudioMetadata(
        uri: 'u',
        name: 'a.mp3',
        date: DateTime(2024),
        sizeBytes: 0,
        durationMs: 0,
      );
      when(() => audiosHomeCubit.state).thenReturn(
        AudiosHomeState(
          isVisible: true,
          currentAudio: audio,
          playbackSpeed: 1.5,
        ),
      );

      await tester.pumpApp(
        const MiniPlayer(),
        audiosHomeCubit: audiosHomeCubit,
      );

      await tester.tap(find.text('x1.5'));
      verify(() => audiosHomeCubit.changeSpeed()).called(1);
    });

    testWidgets('taps closePlayer', (tester) async {
      final audio = AudioMetadata(
        uri: 'u',
        name: 'a.mp3',
        date: DateTime(2024),
        sizeBytes: 0,
        durationMs: 0,
      );
      when(() => audiosHomeCubit.state).thenReturn(
        AudiosHomeState(isVisible: true, currentAudio: audio),
      );

      await tester.pumpApp(
        const MiniPlayer(),
        audiosHomeCubit: audiosHomeCubit,
      );

      await tester.tap(find.byType(HugeIcon).at(1));
      verify(() => audiosHomeCubit.closePlayer()).called(1);
    });

    testWidgets('seeks when slider changes', (tester) async {
      final audio = AudioMetadata(
        uri: 'u',
        name: 'a.mp3',
        date: DateTime(2024),
        sizeBytes: 0,
        durationMs: 10000,
      );
      when(() => audiosHomeCubit.state).thenReturn(
        AudiosHomeState(
          isVisible: true,
          currentAudio: audio,
          duration: const Duration(seconds: 10),
        ),
      );

      await tester.pumpApp(
        const MiniPlayer(),
        audiosHomeCubit: audiosHomeCubit,
      );

      final slider = find.byType(Slider);
      await tester.drag(slider, const Offset(100, 0));
      await tester.pumpAndSettle();

      verify(() => audiosHomeCubit.seek(any())).called(1);
    });
  });
}
