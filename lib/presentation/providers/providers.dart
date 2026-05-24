import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/drift_database.dart' hide Song;
import '../../data/local/song_dao.dart';
import '../../data/repositories/song_repository_impl.dart';
import '../../data/speech/composite_recognizer.dart';
import '../../domain/models/song.dart';
import '../../domain/repositories/song_repository.dart';
import '../../domain/repositories/speech_recognizer.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final songDaoProvider = Provider<SongDao>((ref) {
  return SongDao(ref.watch(appDatabaseProvider));
});

final songRepositoryProvider = Provider<SongRepository>((ref) {
  return SongRepositoryImpl(ref.watch(songDaoProvider));
});

final currentSongProvider = StateProvider<Song?>((ref) => null);

final speechRecognizerProvider = Provider<SpeechRecognizer>((ref) {
  return CompositeSpeechRecognizer();
});
