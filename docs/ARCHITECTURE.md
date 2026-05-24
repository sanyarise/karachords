# ARCHITECTURE — karachords

> Дата: 2026-05-24
> Версия: 1.0
> Режим: A (новый проект)

---

## 1. Архитектурный стиль

**Clean Architecture** (Layered) — три слоя с зависимостью только внутрь:

```
presentation → domain ← data
```

- `presentation` — знает о `domain`.
- `data` — знает о `domain`.
- `domain` — не знает ни о чём.

---

## 2. Структура проекта (Flutter)

```
karachords/
├── android/                    # Нативный Android (Vosk, аудио)
├── ios/                        # Нативный iOS (future)
├── lib/
│   ├── main.dart               # Точка входа
│   ├── app.dart                # MaterialApp + GoRouter
│   ├── domain/                 # Чистые модели, интерфейсы
│   │   ├── models/
│   │   │   ├── song.dart
│   │   │   ├── section.dart
│   │   │   ├── line.dart
│   │   │   ├── word.dart
│   │   │   ├── chord.dart
│   │   │   ├── song_settings.dart
│   │   │   └── metronome_settings.dart
│   │   └── repositories/
│   │       ├── song_repository.dart
│   │       ├── settings_repository.dart
│   │       └── speech_recognizer.dart
│   ├── data/
│   │   ├── local/
│   │   │   ├── drift_database.dart
│   │   │   ├── song_dao.dart
│   │   │   └── settings_dao.dart
│   │   ├── parsers/
│   │   │   ├── chordpro_parser.dart
│   │   │   └── plain_text_parser.dart
│   │   └── speech/
│   │       ├── vosk_service.dart
│   │       ├── whisper_service.dart
│   │       └── fuzzy_matcher.dart
│   └── presentation/
│       ├── providers/          # Riverpod providers
│       ├── screens/
│       │   ├── song_list_screen.dart
│       │   ├── player_screen.dart
│       │   ├── add_song_screen.dart
│       │   ├── settings_screen.dart
│       │   └── metronome_screen.dart
│       ├── widgets/
│       │   ├── chord_display.dart
│       │   ├── lyrics_display.dart
│       │   ├── word_widget.dart
│       │   ├── highlighted_text.dart
│       │   └── metronome_control.dart
│       └── theme/
│           └── app_theme.dart
├── assets/
│   ├── songs/                  # Встроенные песни (JSON)
│   └── models/                 # Vosk модель (загружается по запросу)
├── test/
│   ├── unit/                   # fuzzy matching, parsers
│   └── widget/                 # UI-компоненты
├── docs/
│   ├── ANALYSIS.md
│   ├── ARCHITECTURE.md
│   └── DESIGN.md
├── TASK.md
├── TEAM_KNOWLEDGE.md
├── pubspec.yaml
└── README.md
```

---

## 3. Domain Model

### 3.1 Song

```dart
class Song {
  final String id;           // UUID
  final String title;
  final String artist;
  final int? bpm;            // Опционально
  final List<Section> sections;
  final bool isBuiltIn;      // Встроенная или пользовательская
}
```

### 3.2 Section

```dart
class Section {
  final SectionType type;    // verse, chorus, bridge, intro, outro
  final List<Line> lines;
}

enum SectionType { verse, chorus, bridge, intro, outro, unknown }
```

### 3.3 Line

```dart
class Line {
  final List<Word> words;
  
  /// Все аккорды на этой строке (могут быть null у слова)
  List<Chord?> get chords => words.map((w) => w.chord).toList();
}
```

### 3.4 Word

```dart
class Word {
  final String text;
  final Chord? chord;        // Аккорд над этим словом (или null)
  
  /// Для будущих режимов (A, B) — тайминг не используется в варианте C
  final int? startMs;
}
```

### 3.5 Chord

```dart
class Chord {
  final String raw;          // "Am", "C#maj7", "Dsus4"
  
  /// Парсинг: корень + модификатор
  String get root;           // "A", "C#", "D"
  String get quality;        // "m", "maj7", "sus4"
}
```

### 3.6 SongSettings (настройки визуала)

```dart
class SongSettings {
  // Текст
  final String textFontFamily;
  final double textFontSize;
  final FontWeight textFontWeight;
  final Color textActiveColor;
  final Color textPendingColor;
  final Color textInactiveColor;
  
  // Аккорды
  final String chordFontFamily;
  final double chordFontSize;
  final FontWeight chordFontWeight;
  final Color chordActiveColor;
  final Color chordPendingColor;
  final Color chordInactiveColor;
  
  // Общее
  final Color backgroundColor;
  final double lineSpacing;
}
```

### 3.7 MetronomeSettings

```dart
class MetronomeSettings {
  final int bpm;             // 40-208
  final bool isPlaying;
  final double volume;       // 0.0-1.0
}
```

---

## 4. Repository Interfaces (Domain)

```dart
abstract class SongRepository {
  Future<List<Song>> getAllSongs();
  Future<Song?> getSongById(String id);
  Future<void> saveSong(Song song);
  Future<void> deleteSong(String id);
  Future<void> importBuiltInSongs();
}

abstract class SettingsRepository {
  Future<SongSettings> getSongSettings();
  Future<void> saveSongSettings(SongSettings settings);
  Future<MetronomeSettings> getMetronomeSettings();
  Future<void> saveMetronomeSettings(MetronomeSettings settings);
}

abstract class SpeechRecognizer {
  Stream<String> get transcriptStream;
  Future<void> startListening();
  Future<void> stopListening();
  bool get isListening;
}
```

---

## 5. Data Layer

### 5.1 Drift Database

Таблицы:
- `songs` — id, title, artist, bpm, json_content, is_built_in, created_at
- `settings` — key, json_value

### 5.2 Parsers

**ChordPro → internal JSON:**
```
{title: Песня}
{artist: Исполнитель}

[Am]Как же [C]мне рассказать
[G]О том, что [F]я люблю
```

→ Парсинг: регулярка `\[([^\]]+)\]` для аккордов, слова разбиваются по пробелам, аккорд привязывается к ближайшему слову.

**Plain Text → internal JSON:**
```
Am         C
Как же мне рассказать
G          F
О том, что я люблю
```

→ Парсинг: первая строка — аккорды (по позициям), вторая — текст. Позиционное сопоставление.

### 5.3 Speech Services

**VoskService (primary, Android streaming):**
- Model loading: `ModelLoader().loadFromAssets('assets/models/vosk-model-small-ru-0.22.zip')` extracts to app support dir on first run, caches for subsequent runs.
- Recognizer: `vosk.createRecognizer(modelPath, sampleRate: 16000)`.
- Streaming (Android): `vosk.initSpeechService(recognizer)` → `speechService.onPartial()` / `onResult()` streams emit transcript text.
- Batch (Linux/Windows): `recognizer.acceptWaveformBytes(pcm16Chunk)` + `getPartialResult()` for manual chunking.
- Lifecycle: `start()` → subscribe to streams → emit to `transcriptStream`. `stop()` → dispose speech service. `dispose()` → release recognizer + model.
- Error handling: any init or runtime error → switch to fallback, notify UI via SnackBar.

**WhisperService (fallback, online):**
- Uses `speech_to_text` package (Google Speech API).
- Activated automatically if `VoskService` fails to initialize or crashes.
- Same `SpeechRecognizer` interface, transparent to consumers.

**CompositeRecognizer (provider-level):**
- Tries `VoskService` first on app start.
- If Vosk init fails → instantiates `WhisperService`.
- Exposes unified `SpeechRecognizer` interface to UI.

**FuzzyMatcher:**
- Вход: `recognizedText` (от Vosk partials), `Song`, `currentPosition`.
- Выход: `int?` — новый индекс слова (null = no confident match).
- Алгоритм:
  1. Нормализация: lowercase, strip punctuation.
  2. Flatten song to word list.
  3. Search in sliding window `currentPosition ± 25` words.
  4. Levenshtein distance per word, allow up to 2 song skips.
  5. Confidence threshold `≥0.4`; drift beyond 10 words requires `≥3` matched words.
  6. No match → return null (keep current position, no drift).

---

## 6. Presentation Layer

### 6.1 Screens

| Экран | Описание |
|-------|----------|
| **SongListScreen** | Список песен (встроенные + пользовательские), поиск, удаление свайпом |
| **PlayerScreen** | Основной экран: аккорды сверху, текст снизу, подсветка |
| **AddSongScreen** | Форма: название, исполнитель, текст (multiline), выбор формата |
| **SettingsScreen** | Настройки визуала: шрифты, размеры, цвета (текст + аккорды отдельно) |
| **MetronomeScreen** | BPM слайдер, кнопки play/stop |

### 6.2 State Management (Riverpod)

```dart
// Провайдеры
final songListProvider = StateNotifierProvider<SongListNotifier, AsyncValue<List<Song>>>(...);
final currentSongProvider = StateProvider<Song?>(...);
final currentPositionProvider = StateProvider<int>(...); // Индекс текущего слова
final songSettingsProvider = StateNotifierProvider<SettingsNotifier, SongSettings>(...);
final metronomeProvider = StateNotifierProvider<MetronomeNotifier, MetronomeSettings>(...);
final speechRecognizerProvider = Provider<SpeechRecognizer>(...);
```

### 6.3 PlayerScreen Layout

```
┌─────────────────────────────┐
│  [Метроном]  [Настройки]   │  ← AppBar
├─────────────────────────────┤
│                             │
│        Am      C            │  ← ChordDisplay
│      (active) (pending)     │
│                             │
├─────────────────────────────┤
│                             │
│  Как же мне рассказать      │  ← LyricsDisplay
│  (active)(pend)(pend)(pend) │
│                             │
│  О том, что я люблю         │
│  (inact)(inact)(inact)...   │
│                             │
├─────────────────────────────┤
│  [Play] [Пауза]             │  ← Controls
└─────────────────────────────┘
```

### 6.4 Подсветка слов

Каждое слово — отдельный `WordWidget`:
- **Active** — `textActiveColor`, `FontWeight.bold`.
- **Pending** — `textPendingColor`, `FontWeight.normal`.
- **Inactive** — `textInactiveColor`, `FontWeight.normal`.

Аккорды — `ChordWidget` в `ChordDisplay`:
- **Active** — `chordActiveColor`, крупный шрифт.
- **Pending** — `chordPendingColor`, средний шрифт.
- **Inactive** — не отображается или `chordInactiveColor`.

---

## 7. Dependency Graph

```
Phase 0: Prototype (Vosk) ─────────────────────────────┐
                                                        │
Phase 1: Scaffold (Flutter project, Riverpod, GoRouter) │
                                                        ▼
Phase 2: Domain Layer (models, repository interfaces)     │
        || Data Layer (Drift, parsers)                 │
        || UI Widgets (chord_display, lyrics_display)   │
                                                        ▼
Phase 3: Integration (SpeechRecognizer + FuzzyMatcher)  │
        || PlayerScreen (with highlighting)             │
        || SettingsScreen                              │
        || MetronomeScreen                             │
                                                        ▼
Phase 4: Polish (edge cases, performance, tests)      │
        || User songs (AddSongScreen)                   │
                                                        ▼
Phase 5: Documentation (README, inline docs)           │
```

**Параллельные задачи:**
- Drift + парсеры || UI виджеты (независимы).
- Метроном || Настройки (независимы).

**Последовательные задачи:**
- Vosk-прототип → FuzzyMatcher → PlayerScreen (зависимость по аудио-ядру).

---

## 8. API / Интерфейсы

### 8.1 Vosk Flutter Plugin (Real API)

```dart
// Plugin instance
final vosk = VoskFlutterPlugin.instance();

// Model loading (extracts zip from assets to app support dir)
final modelPath = await ModelLoader().loadFromAssets('assets/models/vosk-model-small-ru-0.22.zip');

// Recognizer
final recognizer = await vosk.createRecognizer(model: modelPath, sampleRate: 16000);

// Android streaming speech service
final speechService = await vosk.initSpeechService(recognizer);
speechService.onPartial().forEach((partial) => print(partial));
speechService.onResult().forEach((result) => print(result));
await speechService.start();
// ... later ...
await speechService.stop();

// Batch mode (all platforms)
final chunk = Uint8List.fromList(pcm16Samples);
final resultReady = await recognizer.acceptWaveformBytes(chunk);
final partial = await recognizer.getPartialResult();
final result = await recognizer.getResult();
```

**Android Requirements:**
- `android.permission.RECORD_AUDIO` in `AndroidManifest.xml`
- ProGuard rule: `-keep class com.sun.jna.* { *; }`

**SDK Constraint Note:**
`vosk_flutter` declares `sdk: ">=2.15.1 <3.0.0"`. Our project uses `sdk: ^3.12.0`.
Resolution: use `dependency_override` in `pubspec.yaml` to force compatibility. Test on Dart 3.

### 8.2 Audio Session (метроном)

```dart
class MetronomeService {
  Future<void> start(int bpm);
  Future<void> stop();
  bool get isPlaying;
}
```

---

## 9. Граничные условия и ограничения

- **Android API 24+** (minSdkVersion).
- **Размер APK:** Vosk модель ~50MB — загружается по запросу, не включается в APK.
- **Разрешения:** `RECORD_AUDIO`, `INTERNET` (только для загрузки модели, не для распознавания).
- **Офлайн:** После загрузки модели — полностью офлайн.
- **Язык:** Русский (первый), английский (future).

---

## 10. Тестовая стратегия

| Тип | Что тестируем | Как |
|-----|--------------|-----|
| Unit | Парсеры (ChordPro, Plain Text) | Dart test, table-driven |
| Unit | FuzzyMatcher | Dart test, мок-распознанный текст |
| Unit | Chord parsing | Dart test, edge cases (C#, Dsus4) |
| Widget | WordWidget, ChordDisplay | Flutter widget tests |
| Integration | PlayerScreen + Vosk | Flutter integration tests (mock Vosk) |
| E2E | Полный флоу | Android emulator |

---

## 11. Гейты

| После | Проверка | Кто |
|-------|----------|-----|
| Phase 0 | Vosk распознаёт пение/читку, latency < 1с | Senior |
| Phase 2 | ARCHITECTURE.md утверждён | PM + User |
| Phase 3 | TASK.md утверждён | User |
| Phase 4 | `flutter build apk --release` проходит | PM |
| Phase 5 | `flutter test` проходит | Tester |
| Phase 6 | Security Review = PASS | Security Engineer |
| Phase 7 | README.md существует и актуален | Technical Writer |
