import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/platform/wakelock_service.dart';
import '../../core/version.dart';

import '../../core/logging/app_logger.dart';
import '../../data/speech/composite_recognizer.dart';
import '../../data/speech/fuzzy_matcher.dart';
import '../../domain/models/song.dart';
import '../../domain/repositories/speech_recognizer.dart';
import '../providers/player_provider.dart';
import '../providers/providers.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_widget.dart';
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
  StreamSubscription<Transcript>? _transcriptSub;
  Timer? _silenceTimer;
  bool _isSilent = false;
  bool _isInitializing = false;
  int _lastPartialWordCount = 0;
  final AppLogger _log = AppLogger();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _log.i('[PlayerScreen] initState version=$kAppVersion');
    // Reset position after first frame to avoid modifying a provider
    // while the widget tree is building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentPositionProvider.notifier).state = 0;
    });
  }

  @override
  void dispose() {
    _log.i('[PlayerScreen] dispose');
    _silenceTimer?.cancel();
    _transcriptSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    WakelockService.disable();

    // Flush logs before stopping recognizer.
    _log.flush();

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
    _log.i('[PlayerScreen] _startListening called');
    if (mounted) {
      setState(() => _isInitializing = true);
    }

    final status = await Permission.microphone.status;
    _log.i('[PlayerScreen] Microphone permission: $status');
    if (!status.isGranted) {
      final result = await Permission.microphone.request();
      _log.i('[PlayerScreen] Permission request result: $result');
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

    await WakelockService.enable();

    final recognizer = ref.read(speechRecognizerProvider);

    // Subscribe BEFORE starting so we don't miss early partial results.
    _transcriptSub?.cancel();
    _transcriptSub = recognizer.transcriptStream.listen(
      _onTranscript,
      onError: _onSpeechError,
    );

    await recognizer.startListening();
    if (mounted) {
      setState(() => _isInitializing = false);
    }
    if (!mounted) return;

    if (recognizer is CompositeSpeechRecognizer && recognizer.isUsingFallback) {
      _log.w('[PlayerScreen] Using online fallback');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Распознавание офлайн недоступно. Используется онлайн-режим (требуется интернет).'),
          duration: Duration(seconds: 4),
        ),
      );
    }

    _resetSilenceTimer();
  }

  Future<void> _stopListening() async {
    _log.i('[PlayerScreen] _stopListening called');
    _silenceTimer?.cancel();
    _transcriptSub?.cancel();
    _transcriptSub = null;
    _lastPartialWordCount = 0;
    if (mounted) {
      setState(() => _isSilent = false);
    }
    ref.read(isListeningProvider.notifier).state = false;
    await WakelockService.disable();
    await ref.read(speechRecognizerProvider).stopListening();
  }

  void _onTranscript(Transcript transcript) {
    final text = transcript.text;
    _log.i('[PlayerScreen] _onTranscript: "${text.substring(0, text.length < 40 ? text.length : 40)}" isFinal=${transcript.isFinal}');
    _resetSilenceTimer();

    final song = ref.read(currentSongProvider);
    if (song == null) {
      _log.w('[PlayerScreen] _onTranscript: no current song');
      return;
    }

    final flatLines = song.flattenedLines;
    final currentLinePos = ref.read(currentPositionProvider);
    _log.i('[PlayerScreen] _onTranscript: currentLinePos=$currentLinePos, totalLines=${flatLines.length}');

    if (text.trim().isEmpty) {
      _log.w('[PlayerScreen] _onTranscript: empty text');
      return;
    }

    if (flatLines.isEmpty) return;

    // For partial results: advance by 1 line when new words arrive.
    const int maxLineAdvance = 2;
    final normalizedText = FuzzyMatcher.normalize(text);
    final recognizedWords = normalizedText
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;

    if (!transcript.isFinal) {
      final advance = (recognizedWords - _lastPartialWordCount).clamp(0, maxLineAdvance);
      _lastPartialWordCount = recognizedWords;
      if (advance > 0) {
        final nextLine = (currentLinePos + 1).clamp(0, flatLines.length - 1);
        if (nextLine != currentLinePos) {
          HapticFeedback.lightImpact();
          ref.read(currentPositionProvider.notifier).state = nextLine;
          _log.i('[PlayerScreen] _onTranscript: advance to line $nextLine (partial delta: +$advance, totalWords=$recognizedWords)');
          return;
        }
      }
      _log.w('[PlayerScreen] _onTranscript: no line change (partial)');
      return;
    }

    // Final results: reset partial accumulator and try line-level fuzzy matching.
    _lastPartialWordCount = 0;
    final newLine = FuzzyMatcher(log: _log).findLinePosition(text, song, currentLinePos);
    _log.i('[PlayerScreen] _onTranscript: fuzzy line=$newLine');

    if (newLine != null && newLine != currentLinePos) {
      HapticFeedback.lightImpact();
      ref.read(currentPositionProvider.notifier).state = newLine;
      _log.i('[PlayerScreen] _onTranscript: updated line to $newLine (fuzzy final)');
      return;
    }

    // Final fallback: advance by 1 line.
    final nextLine = (currentLinePos + 1).clamp(0, flatLines.length - 1);
    if (nextLine != currentLinePos) {
      HapticFeedback.lightImpact();
      ref.read(currentPositionProvider.notifier).state = nextLine;
      _log.i('[PlayerScreen] _onTranscript: advance to line $nextLine (fallback final)');
      return;
    }

    _log.w('[PlayerScreen] _onTranscript: no position change');
  }

  void _onSpeechError(Object error) {
    _log.e('[PlayerScreen] Speech error', error);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка распознавания: $error'),
          duration: const Duration(seconds: 3),
          backgroundColor: AppTheme.error,
        ),
      );
    }
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

  /// Converts a flat line index into section/line coordinates.
  ({int sectionIndex, int lineIndex}) _resolvePosition(
    Song song,
    int position,
  ) {
    final flatLines = song.flattenedLines;
    if (flatLines.isEmpty) {
      return (sectionIndex: 0, lineIndex: 0);
    }
    final clamped = position.clamp(0, flatLines.length - 1);
    final entry = flatLines[clamped];
    return (sectionIndex: entry.sectionIndex, lineIndex: entry.lineIndex);
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
    final isEmpty = _isSongEmpty(song);
    final flatLines = song.flattenedLines;

    void advanceLine(int delta) {
      if (flatLines.isEmpty) return;
      final newPos = (currentPosition + delta).clamp(0, flatLines.length - 1);
      if (newPos != currentPosition) {
        HapticFeedback.lightImpact();
        ref.read(currentPositionProvider.notifier).state = newPos;
      }
    }

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
          Expanded(
            child: isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.text_snippet,
                    title: 'В этой песне нет текста',
                    subtitle:
                        'Отредактируйте песню, чтобы добавить текст и аккорды.',
                  )
                : GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity == null) return;
                      if (details.primaryVelocity! < -300) {
                        advanceLine(-1);
                      } else if (details.primaryVelocity! > 300) {
                        advanceLine(1);
                      }
                    },
                    child: LyricsDisplay(
                      sections: song.sections,
                      settings: settings,
                      activeSectionIndex: resolved.sectionIndex,
                      activeLineIndex: resolved.lineIndex,
                    ),
                  ),
          ),
          PlayerControls(
            isListening: isListening,
            isSilent: _isSilent,
            isInitializing: _isInitializing,
            onPlay: _startListening,
            onStop: _stopListening,
            onResume: _startListening,
            onForward: () => advanceLine(1),
            onBack: () => advanceLine(-1),
          ),
        ],
      ),
    );
  }
}
