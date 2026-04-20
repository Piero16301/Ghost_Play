import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(context.read<HomeCubit>().initStorage());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final hasPermission = context.read<HomeCubit>().state.hasPermission;
    if (state == AppLifecycleState.resumed && hasPermission) {
      unawaited(context.read<HomeCubit>().loadAudios());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(
            AppVariables.appName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          notificationPredicate: (notification) => false,
          leading: IconButton(
            padding: EdgeInsets.zero,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedSettings02,
              strokeWidth: 2,
            ),
            onPressed: () => context.pushNamed(AppRoute.settings.name),
          ),
        ),
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state.status.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state.status.isFailure) {
              return const Center(
                child: Text('Error'),
              );
            }

            if (!state.hasPermission) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.folder_shared,
                        size: 80,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '¡Bienvenido a GhostPlay!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Para escuchar tus notas de voz sin ser visto, '
                        'necesitamos acceso a la carpeta de audios de WhatsApp',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<HomeCubit>().requestPermission(),
                        child: const Text('Dar Permiso a Carpeta'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state.audios.isEmpty) {
              return const Center(child: Text('No se encontraron audios aún.'));
            }

            return RefreshIndicator(
              onRefresh: context.read<HomeCubit>().loadAudios,
              child: ListView.builder(
                itemCount: state.audios.length,
                itemBuilder: (context, index) {
                  final audio = state.audios[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.play_circle_fill,
                      color: Colors.cyan,
                    ),
                    title: Text(audio.name),
                    subtitle: Text('Recibido: ${audio.date}'),
                    trailing: Text(audio.formattedDuration),
                    onTap: () {},
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
