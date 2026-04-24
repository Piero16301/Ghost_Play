import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghost_play/home/pages/states_home/states_home.dart';

class StatesHomePage extends StatelessWidget {
  const StatesHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StatesHomeCubit(),
      child: const StatesHomeView(),
    );
  }
}
