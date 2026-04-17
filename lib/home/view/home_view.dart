import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final darkTheme = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Image.asset(
            darkTheme
                ? 'assets/images/logo-no-bg-dark.png'
                : 'assets/images/logo-no-bg-light.png',
            height: 35,
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
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Placeholder(),
          ),
        ),
      ),
    );
  }
}
