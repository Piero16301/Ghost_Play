import 'package:expressive_kit/expressive_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/service_locator.dart';

void main() {
  late HomeCubit homeCubit;
  late AudiosHomeCubit audiosHomeCubit;

  setUpAll(registerFallbackValues);

  setUp(() async {
    await setupServiceLocatorMocks();
    homeCubit = MockHomeCubit();
    audiosHomeCubit = MockAudiosHomeCubit();

    when(() => homeCubit.state).thenReturn(const HomeState());
    when(() => audiosHomeCubit.state).thenReturn(const AudiosHomeState());

    when(() => homeCubit.loadAudios()).thenAnswer((_) async {});
    when(() => homeCubit.requestPermission()).thenAnswer((_) async {});
    when(() => homeCubit.setAudiosWeeks(any<int>())).thenAnswer((_) async {});
    when(() => homeCubit.setVideosWeeks(any<int>())).thenAnswer((_) async {});
    when(() => audiosHomeCubit.playAudio(any<AudioMetadata>()))
        .thenAnswer((_) async {});
    when(
      () => audiosHomeCubit.transcribeAudio(
        forceRefresh: any<bool>(named: 'forceRefresh'),
      ),
    ).thenAnswer((_) async {});
    when(() => audiosHomeCubit.closePlayer()).thenAnswer((_) async {});
  });

  group('AudiosHomeView', () {
    testWidgets('renders CircularLoadingAnimation when loading', (
      tester,
    ) async {
      when(() => homeCubit.state)
          .thenReturn(const HomeState(audiosStatus: HomeStatus.loading));
      await tester.pumpApp(
        const AudiosHomeView(),
        homeCubit: homeCubit,
        audiosHomeCubit: audiosHomeCubit,
        locale: const Locale('en'),
      );
      expect(find.byType(ExpressiveCircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders failure message when status is failure', (
      tester,
    ) async {
      when(() => homeCubit.state)
          .thenReturn(const HomeState(audiosStatus: HomeStatus.failure));
      await tester.pumpApp(
        const AudiosHomeView(),
        homeCubit: homeCubit,
        audiosHomeCubit: audiosHomeCubit,
        locale: const Locale('en'),
      );
      expect(
        find.textContaining('An error occurred while loading the voice notes'),
        findsOneWidget,
      );
    });

    testWidgets('renders permission screen when no permission', (tester) async {
      when(() => homeCubit.state).thenReturn(const HomeState());
      await tester.pumpApp(
        const AudiosHomeView(),
        homeCubit: homeCubit,
        audiosHomeCubit: audiosHomeCubit,
        locale: const Locale('en'),
      );
      expect(find.text('Grant permission'), findsOneWidget);

      await tester.tap(find.text('Grant permission'));
      verify(() => homeCubit.requestPermission()).called(1);
    });

    testWidgets('renders no audios found message when list is empty', (
      tester,
    ) async {
      when(() => homeCubit.state).thenReturn(
        const HomeState(hasPermission: true, audiosStatus: HomeStatus.success),
      );
      await tester.pumpApp(
        const AudiosHomeView(),
        homeCubit: homeCubit,
        audiosHomeCubit: audiosHomeCubit,
        locale: const Locale('en'),
      );
      expect(find.text('No voice notes found yet'), findsOneWidget);
    });

    testWidgets('renders list of audios and calls playAudio on tap', (
      tester,
    ) async {
      final audio = AudioMetadata(
        uri: 'u',
        name: 'name.mp3',
        date: DateTime(2024),
        sizeBytes: 100,
        durationMs: 1000,
      );
      when(() => homeCubit.state).thenReturn(
        HomeState(
          hasPermission: true,
          audiosStatus: HomeStatus.success,
          audios: [audio],
        ),
      );

      await tester.pumpApp(
        const AudiosHomeView(),
        homeCubit: homeCubit,
        audiosHomeCubit: audiosHomeCubit,
        locale: const Locale('en'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('name'), findsOneWidget);

      await tester.tap(find.byType(ExpressiveListTile));
      verify(() => audiosHomeCubit.playAudio(audio)).called(1);
    });

    testWidgets('shows weeks menu and calls setAudiosWeeks', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final audio = AudioMetadata(
        uri: 'u',
        name: 'n.mp3',
        date: DateTime(2024),
        sizeBytes: 0,
        durationMs: 0,
      );
      when(() => homeCubit.state).thenReturn(
        HomeState(
          hasPermission: true,
          audiosStatus: HomeStatus.success,
          audios: [audio],
        ),
      );

      await tester.pumpApp(
        const AudiosHomeView(),
        homeCubit: homeCubit,
        audiosHomeCubit: audiosHomeCubit,
        locale: const Locale('en'),
      );

      await tester.tap(find.byType(Chip));
      await tester.pumpAndSettle();
      tester.takeException();

      await tester.tap(find.textContaining('2').last);
      await tester.pumpAndSettle();

      verify(() => homeCubit.setAudiosWeeks(2)).called(1);
    });

    testWidgets('shows loading indicator while transcribing', (tester) async {
      final audio = AudioMetadata(
        uri: 'u',
        name: 'voice.opus',
        date: DateTime(2024),
        sizeBytes: 100,
        durationMs: 1000,
      );
      when(() => homeCubit.state).thenReturn(
        HomeState(
          hasPermission: true,
          audiosStatus: HomeStatus.success,
          audios: [audio],
        ),
      );
      when(() => audiosHomeCubit.state).thenReturn(
        AudiosHomeState(
          isVisible: true,
          currentAudio: audio,
          isTranscriptionVisible: true,
          isTranscribing: true,
        ),
      );

      await tester.pumpApp(
        const AudiosHomeView(),
        homeCubit: homeCubit,
        audiosHomeCubit: audiosHomeCubit,
        locale: const Locale('en'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ExpressiveCard), findsOneWidget);
      expect(find.byType(ExpressiveCircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'shows transcription card, max half height, and regenerate button',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final audio = AudioMetadata(
          uri: 'u',
          name: 'voice.opus',
          date: DateTime(2024),
          sizeBytes: 100,
          durationMs: 1000,
        );
        final longText = List.filled(
          80,
          'Line of transcribed audio text.',
        ).join(' ');

        when(() => homeCubit.state).thenReturn(
          HomeState(
            hasPermission: true,
            audiosStatus: HomeStatus.success,
            audios: [audio],
          ),
        );
        when(() => audiosHomeCubit.state).thenReturn(
          AudiosHomeState(
            isVisible: true,
            currentAudio: audio,
            isTranscriptionVisible: true,
            transcription: longText,
          ),
        );

        await tester.pumpApp(
          const AudiosHomeView(),
          homeCubit: homeCubit,
          audiosHomeCubit: audiosHomeCubit,
          locale: const Locale('en'),
        );
        await tester.pumpAndSettle();

        final cardFinder = find.byType(ExpressiveCard);
        expect(cardFinder, findsOneWidget);
        expect(find.text(longText), findsOneWidget);
        expect(find.text('Regenerate'), findsOneWidget);
        expect(tester.getSize(cardFinder).height, lessThanOrEqualTo(400));

        await tester.ensureVisible(find.text('Regenerate'));
        await tester.tap(find.text('Regenerate'));
        verify(() => audiosHomeCubit.transcribeAudio(forceRefresh: true))
            .called(1);
      },
    );

    testWidgets('shows fallback error text when transcription is null', (
      tester,
    ) async {
      final audio = AudioMetadata(
        uri: 'u',
        name: 'voice.opus',
        date: DateTime(2024),
        sizeBytes: 100,
        durationMs: 1000,
      );
      when(() => homeCubit.state).thenReturn(
        HomeState(
          hasPermission: true,
          audiosStatus: HomeStatus.success,
          audios: [audio],
        ),
      );
      when(() => audiosHomeCubit.state).thenReturn(
        AudiosHomeState(
          isVisible: true,
          currentAudio: audio,
          isTranscriptionVisible: true,
        ),
      );

      await tester.pumpApp(
        const AudiosHomeView(),
        homeCubit: homeCubit,
        audiosHomeCubit: audiosHomeCubit,
        locale: const Locale('en'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not get transcription'), findsOneWidget);
      expect(find.text('Regenerate'), findsOneWidget);
    });

    testWidgets(
      'dismisses bottom sheet and closes player when tapping outside cards',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final audio = AudioMetadata(
          uri: 'u',
          name: 'voice.opus',
          date: DateTime(2024),
          sizeBytes: 100,
          durationMs: 1000,
        );
        when(() => homeCubit.state).thenReturn(
          HomeState(
            hasPermission: true,
            audiosStatus: HomeStatus.success,
            audios: [audio],
          ),
        );
        when(() => audiosHomeCubit.state).thenReturn(
          AudiosHomeState(
            isVisible: true,
            currentAudio: audio,
            isTranscriptionVisible: true,
            transcription: 'Short transcription',
          ),
        );

        await tester.pumpApp(
          const AudiosHomeView(),
          homeCubit: homeCubit,
          audiosHomeCubit: audiosHomeCubit,
          locale: const Locale('en'),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(find.byType(AudioTranscriptionCard), findsOneWidget);

        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();

        expect(find.byType(MiniPlayer), findsNothing);
        verify(() => audiosHomeCubit.closePlayer()).called(1);
      },
    );
  });
}
