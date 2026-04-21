import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

void main() {
  late MockPlayerCubit playerCubit;

  setUpAll(registerFallbackValues);

  setUp(() {
    playerCubit = MockPlayerCubit();
    when(() => playerCubit.state).thenReturn(const PlayerState());
    when(() => playerCubit.changeSpeed()).thenAnswer((_) async {});
    when(() => playerCubit.pause()).thenAnswer((_) async {});
    when(() => playerCubit.resume()).thenAnswer((_) async {});
    when(() => playerCubit.closePlayer()).thenAnswer((_) async {});
    when(() => playerCubit.seek(any())).thenAnswer((_) async {});
  });

  group('MiniPlayer', () {
    final audio = AudioMetadata(
      name: 'test.opus',
      uri: 'uri',
      date: DateTime.now(),
      sizeBytes: 100,
      durationMs: 30000,
    );

    testWidgets('renders nothing when not visible', (tester) async {
      when(
        () => playerCubit.state,
      ).thenReturn(const PlayerState());
      await tester.pumpApp(const MiniPlayer(), playerCubit: playerCubit);
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('renders player content when visible', (tester) async {
      when(() => playerCubit.state).thenReturn(
        PlayerState(
          isVisible: true,
          currentAudio: audio,
          status: PlayerStatus.playing,
          position: const Duration(seconds: 10),
          duration: const Duration(seconds: 30),
        ),
      );

      await tester.pumpApp(const MiniPlayer(), playerCubit: playerCubit);
      expect(find.text('test'), findsOneWidget);
      expect(find.text('00:10 / 00:30'), findsOneWidget);
    });

    testWidgets('shows loading indicator when status is loading', (
      tester,
    ) async {
      when(() => playerCubit.state).thenReturn(
        PlayerState(
          isVisible: true,
          currentAudio: audio,
          status: PlayerStatus.loading,
        ),
      );

      await tester.pumpApp(const MiniPlayer(), playerCubit: playerCubit);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('taps pause button when playing', (tester) async {
      when(() => playerCubit.state).thenReturn(
        PlayerState(
          isVisible: true,
          status: PlayerStatus.playing,
          currentAudio: audio,
        ),
      );
      await tester.pumpApp(const MiniPlayer(), playerCubit: playerCubit);

      await tester.tap(find.byType(IconButton).at(0));
      verify(() => playerCubit.pause()).called(1);
    });

    testWidgets('taps resume button when paused', (tester) async {
      when(() => playerCubit.state).thenReturn(
        PlayerState(
          isVisible: true,
          status: PlayerStatus.paused,
          currentAudio: audio,
        ),
      );
      await tester.pumpApp(const MiniPlayer(), playerCubit: playerCubit);

      await tester.tap(find.byType(IconButton).at(0));
      verify(() => playerCubit.resume()).called(1);
    });

    testWidgets('changes speed when speed button pressed', (tester) async {
      when(() => playerCubit.state).thenReturn(
        PlayerState(
          isVisible: true,
          status: PlayerStatus.playing,
          currentAudio: audio,
          playbackSpeed: 1.5,
        ),
      );

      await tester.pumpApp(const MiniPlayer(), playerCubit: playerCubit);
      expect(find.text('x1.5'), findsOneWidget);

      await tester.tap(find.text('x1.5'));
      verify(() => playerCubit.changeSpeed()).called(1);
    });

    testWidgets('closes player when cancel button pressed', (tester) async {
      when(() => playerCubit.state).thenReturn(
        PlayerState(
          isVisible: true,
          currentAudio: audio,
        ),
      );

      await tester.pumpApp(const MiniPlayer(), playerCubit: playerCubit);
      await tester.tap(find.byType(IconButton).at(1));
      verify(() => playerCubit.closePlayer()).called(1);
    });

    testWidgets('updates UI during slider interaction and triggers seek', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => playerCubit.state).thenReturn(
        PlayerState(
          isVisible: true,
          currentAudio: audio,
          duration: const Duration(seconds: 100),
          position: const Duration(seconds: 10),
        ),
      );

      await tester.pumpApp(const MiniPlayer(), playerCubit: playerCubit);

      final sliderFinder = find.byType(Slider);
      expect(tester.widget<Slider>(sliderFinder).value, 10000.0);

      final gesture = await tester.startGesture(tester.getCenter(sliderFinder));
      await gesture.moveBy(const Offset(200, 0));
      await tester.pump();

      expect(tester.widget<Slider>(sliderFinder).value, isNot(10000.0));
      verifyNever(() => playerCubit.seek(any()));

      await gesture.up();
      await tester.pumpAndSettle();

      verify(() => playerCubit.seek(any())).called(1);
    });

    testWidgets('disables slider when duration is zero', (tester) async {
      when(() => playerCubit.state).thenReturn(
        PlayerState(
          isVisible: true,
          currentAudio: audio,
        ),
      );

      await tester.pumpApp(const MiniPlayer(), playerCubit: playerCubit);
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.onChanged, isNull);
      expect(slider.onChangeEnd, isNull);
    });
  });
}
