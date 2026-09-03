import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghost_play/app/app.dart';
import 'package:material_ui/material_ui.dart';

class AppPage extends StatelessWidget {
  const AppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppCubit>(
          create: (_) => AppCubit()..initialize(),
        ),
      ],
      child: const AppView(),
    );
  }
}
