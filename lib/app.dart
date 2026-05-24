import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'presentation/theme/app_theme.dart';
import 'presentation/screens/song_list_screen.dart';
import 'presentation/screens/player_screen.dart';
import 'presentation/screens/add_song_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/metronome_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SongListScreen(),
    ),
    GoRoute(
      path: '/player',
      builder: (context, state) => const PlayerScreen(),
    ),
    GoRoute(
      path: '/add',
      builder: (context, state) => const AddSongScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) {
        final songId = state.extra as String? ?? 'preview';
        return SettingsScreen(songId: songId);
      },
    ),
    GoRoute(
      path: '/metronome',
      builder: (context, state) => const MetronomeScreen(),
    ),
  ],
);

class KaraChordsApp extends StatelessWidget {
  const KaraChordsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'KaraChords',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: _router,
      ),
    );
  }
}
