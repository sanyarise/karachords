import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/speech/composite_recognizer.dart';
import '../../data/speech/fuzzy_matcher.dart';
import '../../domain/models/song.dart';
import '../providers/player_provider.dart';
import '../providers/providers.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/chord_display.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/highlight_state.dart';
import '../widgets/lyrics_display.dart';
import '../widgets/metronome_control.dart';
import '../widgets/player_controls.dart';

/// Main player screen with chord display, lyrics highlighting, and speech
/// recognition integration.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _transcriptSub;
  Timer? _silenceTimer;
  bool _isSilent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Reset position when entering the player for a new song.
    ref.read(currentPositionProvider.notifier).state = 0;
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _transcriptSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    // Stop recognizer but do not dispose the singleton.
    ref.read(speechRecognizerProvider).stopListening().catchError((_) {});
    ref.read(isListeningProvider.notifier).state = false;

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopListening();
    }
  }

  Future<void> _startListening() async {
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        _showPermissionDialog(result);
        return;
      }
    }

    await _stopListening();

    ref.read(isListeningProvider.notifier).state = true;
    if (mounted) {
      setState(() => _isSilent = false);
    }

    final recognizer = ref.read(speechRecognizerProvider);
    await recognizer.startListening();

    if (recognizer is CompositeSpeechRecognizer && recognizer.isUsingFallback && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Распознавание офлайн недоступно. Используется онлайн-режим (требуется интернет).'),
          duration: Duration(seconds: 4),
        ),
      );
    }

    _transcriptSub?.cancel();
    _transcriptSub = recognizer.transcriptStream.listen(
      _onTranscript,
      onError: _onSpeechError,
    );

    _resetSilenceTimer();
  }

  Future<void> _stopListening() async {
    _silenceTimer?.cancel();
    _transcriptSub?.cancel();
    _transcriptSub = null;
    if (mounted) {
      setState(() => _isSilent = false);
    }
    ref.read(isListeningProvider.notifier).state = false;
    await ref.read(speechRecognizerProvider).stopListening();
  }

  void _onTranscript(String text) {
    _resetSilenceTimer();
    final song = ref.read(currentSongProvider);
    if (song == null) return;

    final currentPos = ref.read(currentPositionProvider);
    final newPos = FuzzyMatcher().findPosition(text, song, currentPos);
    if (newPos != null) {
      ref.read(currentPositionProvider.notifier).state = newPos;
    }
  }

  void _onSpeechError(Object error) {
    // Transient errors are ignored; the UI remains in its current state.
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    if (mounted && _isSilent) {
      setState(() => _isSilent = false);
    }
    _silenceTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _isSilent = true);
      }
    });
  }

  void _showPermissionDialog(PermissionStatus currentStatus) {
    if (!mounted) return;
    final isPermanentlyDenied = currentStatus.isPermanentlyDenied;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Нужен доступ к микрофону',
          style: TextStyle(color: AppTheme.onSurface),
        ),
        content: const Text(
          'Приложение слушает ваш голос, чтобы подсвечивать текст. '
          'Без разрешения это работать не будет.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          if (isPermanentlyDenied)
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
              child: const Text('Открыть настройки'),
            )
          else
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startListening();
              },
              child: const Text('Попробовать снова'),
            ),
        ],
      ),
    );
  }

  void _showMetronomeSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const MetronomeControl(),
    );
  }

  void _openSettings(Song song) {
    context.push('/settings', extra: song.id);
  }

  bool _isSongEmpty(Song song) {
    if (song.sections.isEmpty) return true;
    return song.sections.every(
      (section) =>
          section.lines.isEmpty ||
          section.lines.every((line) => line.words.isEmpty),
    );
  }

  /// Converts a flat word index into section/line/word coordinates.
  ({int sectionIndex, int lineIndex, int wordIndex}) _resolvePosition(
    Song song,
    int position,
  ) {
    int count = 0;
    for (int s = 0; s < song.sections.length; s++) {
      final section = song.sections[s];
      for (int l = 0; l < section.lines.length; l++) {
        final line = section.lines[l];
        for (int w = 0; w < line.words.length; w++) {
          if (count == position) {
            return (
              sectionIndex: s,
              lineIndex: l,
              wordIndex: w,
            );
          }
          count++;
        }
      }
    }
    if (count > 0) {
      return _resolvePosition(song, count - 1);
    }
    return (sectionIndex: 0, lineIndex: 0, wordIndex: 0);
  }

  /// Builds up to 4 chord items starting from the current line.
  List<ChordDisplayItem> _buildChordItems(
    Song song,
    int sectionIndex,
    int lineIndex,
  ) {
    final items = <ChordDisplayItem>[];
    var foundActive = false;
    for (int s = sectionIndex;
        s < song.sections.length && items.length < 4;
        s++) {
      final section = song.sections[s];
      for (int l = (s == sectionIndex ? lineIndex : 0);
          l < section.lines.length && items.length < 4;
          l++) {
        final line = section.lines[l];
        for (final word in line.words) {
          for (final chord in word.chords) {
            final state =
                !foundActive ? HighlightState.active : HighlightState.pending;
            if (state == HighlightState.active) foundActive = true;
            items.add(
              ChordDisplayItem(chord: chord, state: state),
            );
            if (items.length >= 4) break;
          }
          if (items.length >= 4) break;
        }
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final song = ref.watch(currentSongProvider);

    if (song == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.onSurface),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Плеер',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurface,
            ),
          ),
        ),
        body: const EmptyStateWidget(
          icon: Icons.music_note,
          title: 'Песня не выбрана',
          subtitle: 'Вернитесь к списку и выберите песню.',
        ),
      );
    }

    final settings = ref.watch(songSettingsProvider(song.id));
    final currentPosition = ref.watch(currentPositionProvider);
    final isListening = ref.watch(isListeningProvider);

    final resolved = _resolvePosition(song, currentPosition);
    final chordItems =
        _buildChordItems(song, resolved.sectionIndex, resolved.lineIndex);
    final isEmpty = _isSongEmpty(song);

    return Scaffold(
      backgroundColor: settings.backgroundColor,
      appBar: AppBar(
        backgroundColor: settings.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          song.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.music_note, color: AppTheme.onSurface),
            tooltip: 'Метроном',
            onPressed: _showMetronomeSheet,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppTheme.onSurface),
            tooltip: 'Настройки',
            onPressed: () => _openSettings(song),
          ),
        ],
      ),
      body: Column(
        children: [
          ChordDisplay(
            items: chordItems,
            settings: settings,
          ),
          Expanded(
            child: isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.text_snippet,
                    title: 'В этой песне нет текста',
                    subtitle:
                        'Отредактируйте песню, чтобы добавить текст и аккорды.',
                  )
                : LyricsDisplay(
                    sections: song.sections,
                    settings: settings,
                    activeSectionIndex: resolved.sectionIndex,
                    activeLineIndex: resolved.lineIndex,
                  ),
          ),
          PlayerControls(
            isListening: isListening,
            isSilent: _isSilent,
            onPlay: _startListening,
            onStop: _stopListening,
            onResume: _startListening,
          ),
        ],
      ),
    );
  }
}
