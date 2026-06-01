import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/settings_dao.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/models/metronome_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/services/metronome_sound_service.dart';
import 'providers.dart';

final metronomeDaoProvider = Provider<SettingsDao>((ref) {
  return SettingsDao(ref.watch(appDatabaseProvider));
});

final metronomeRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(ref.watch(metronomeDaoProvider));
});

final metronomeSoundServiceProvider = Provider<MetronomeSoundService>((ref) {
  final service = MetronomeSoundService();
  service.init();
  ref.onDispose(service.dispose);
  return service;
});

/// Notifier for metronome settings and playback scheduling.
class MetronomeSettingsNotifier extends StateNotifier<MetronomeSettings> {
  final SettingsRepository _repository;
  final MetronomeSoundService _soundService;

  Timer? _timer;

  MetronomeSettingsNotifier(this._repository, this._soundService)
      : super(const MetronomeSettings());

  Future<void> load() async {
    state = await _repository.getMetronomeSettings();
  }

  void setBpm(int bpm) {
    final next = state.copyWith(bpm: bpm.clamp(40, 208));
    state = next;
    _repository.saveMetronomeSettings(next);
    if (next.isPlaying) {
      _restartTimer();
    }
  }

  void togglePlay() {
    final next = state.copyWith(isPlaying: !state.isPlaying);
    state = next;
    _repository.saveMetronomeSettings(next);
    if (next.isPlaying) {
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  void setVolume(double volume) {
    final next = state.copyWith(volume: volume.clamp(0.0, 1.0));
    state = next;
    _repository.saveMetronomeSettings(next);
  }

  void _startTimer() {
    _stopTimer();
    final interval = Duration(milliseconds: (60000 / state.bpm).round());
    _timer = Timer.periodic(interval, (_) async {
      await _soundService.playClick();
    });
  }

  void _restartTimer() {
    if (state.isPlaying) {
      _startTimer();
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

final metronomeProvider =
    StateNotifierProvider<MetronomeSettingsNotifier, MetronomeSettings>((ref) {
  final repo = ref.watch(metronomeRepositoryProvider);
  final sound = ref.watch(metronomeSoundServiceProvider);
  final notifier = MetronomeSettingsNotifier(repo, sound);
  notifier.load();
  return notifier;
});
