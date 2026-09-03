import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghost_play/home/pages/audios_home/audios_home.dart';
import 'package:material_ui/material_ui.dart';

class AudiosHomePage extends StatelessWidget {
  const AudiosHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AudiosHomeCubit(),
      child: const AudiosHomeView(),
    );
  }
}
