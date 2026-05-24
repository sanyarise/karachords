import '../models/song_settings.dart';
import '../models/metronome_settings.dart';

abstract class SettingsRepository {
  Future<SongSettings> getSongSettings(String songId);
  Future<void> saveSongSettings(SongSettings settings);
  Future<MetronomeSettings> getMetronomeSettings();
  Future<void> saveMetronomeSettings(MetronomeSettings settings);
}
