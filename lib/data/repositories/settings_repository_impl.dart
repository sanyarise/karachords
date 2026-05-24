import '../../domain/models/metronome_settings.dart';
import '../../domain/models/song_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../local/settings_dao.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsDao _dao;

  SettingsRepositoryImpl(this._dao);

  @override
  Future<SongSettings> getSongSettings(String songId) => _dao.getSongSettings(songId);

  @override
  Future<void> saveSongSettings(SongSettings settings) => _dao.saveSongSettings(settings);

  @override
  Future<MetronomeSettings> getMetronomeSettings() => _dao.getMetronomeSettings();

  @override
  Future<void> saveMetronomeSettings(MetronomeSettings settings) => _dao.saveMetronomeSettings(settings);
}
