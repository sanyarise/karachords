import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/song.dart';
import '../providers/providers.dart';
import '../providers/song_list_provider.dart';
import '../theme/app_theme.dart';
import '../theme/constants.dart';
import '../widgets/song_card.dart';

class SongListScreen extends ConsumerStatefulWidget {
  const SongListScreen({super.key});

  @override
  ConsumerState<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends ConsumerState<SongListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(songListProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(songListProvider.notifier).search(query);
    });
  }

  void _onTapSong(Song song) {
    ref.read(currentSongProvider.notifier).state = song;
    context.push('/player');
  }

  Future<bool> _confirmDismiss(Song song) async {
    if (song.isBuiltIn) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text(
            'Удалить встроенную песню?',
            style: TextStyle(color: AppTheme.onSurface),
          ),
          content: Text(
            'Вы уверены, что хотите удалить «${song.title}»?',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              child: const Text('Удалить'),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
  }

  void _onDismissed(Song song) {
    final notifier = ref.read(songListProvider.notifier);
    notifier.deleteSong(song);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Песня «${song.title}» удалена'),
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () => notifier.undoDelete(song),
        ),
      ),
    );
  }

  void _onAddSong() {
    context.push('/add');
  }

  void _onEditSong(Song song) {
    context.push('/add', extra: song);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(songListProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'karachords',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppTheme.onSurface),
            tooltip: 'Настройки',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSpaceMd),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: AppTheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Поиск по песням...',
                hintStyle: const TextStyle(color: AppTheme.textDisabled),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textDisabled),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(kBorderRadiusMd),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: kSpaceMd,
                  vertical: kSpaceSm,
                ),
              ),
            ),
          ),
          const SizedBox(height: kSpaceSm),
          Expanded(
            child: _buildBody(state),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_song',
        onPressed: _onAddSong,
        icon: const Icon(Icons.add),
        label: const Text('Добавить песню'),
      ),
    );
  }

  Widget _buildBody(SongListState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (state.error != null && state.allSongs.isEmpty) {
      return _buildEmptyState(
        icon: Icons.error_outline,
        title: 'Ошибка загрузки',
        description: state.error!,
        buttonText: 'Повторить',
        onButtonPressed: () => ref.read(songListProvider.notifier).load(),
      );
    }

    if (state.filteredSongs.isEmpty) {
      if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
        return _buildEmptyState(
          icon: Icons.search_off,
          title: 'Ничего не найдено',
          description: 'По запросу «${state.searchQuery}» ничего не найдено.',
          buttonText: 'Сбросить поиск',
          onButtonPressed: () {
            _searchController.clear();
            ref.read(songListProvider.notifier).search('');
          },
        );
      }

      return _buildEmptyState(
        icon: Icons.music_off,
        title: 'Нет песен',
        description:
            'Добавьте свою первую песню или импортируйте из библиотеки.',
        buttonText: 'Добавить песню',
        onButtonPressed: _onAddSong,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: kSpaceMd),
      physics: const BouncingScrollPhysics(),
      itemCount: state.filteredSongs.length,
      itemBuilder: (context, index) {
        final song = state.filteredSongs[index];
        return SongCard(
          song: song,
          onTap: () => _onTapSong(song),
          onEdit: () => _onEditSong(song),
          confirmDismiss: (_) => _confirmDismiss(song),
          onDismissed: (_) => _onDismissed(song),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onButtonPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kSpace2xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppTheme.textDisabled),
            const SizedBox(height: kSpaceLg),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kSpaceSm),
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kSpaceLg),
            ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: kSpaceLg,
                  vertical: kSpaceMd,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kBorderRadiusMd),
                ),
              ),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
