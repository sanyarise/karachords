# TASK: KaraChords Critical Fixes — COMPLETED

## Результат
Все critical/high/medium баги по код-ревью исправлены и закоммичены.

## Что сделано

### Phase 1: CRITICAL
- [x] 1.1 `CompositeSpeechRecognizer` → DI через конструктор (primary/fallback). Убрано создание VoskService/WhisperService внутри startListening() — модель теперь загружается один раз. Добавлена отмена старых подписок перед новым стартом.
- [x] 1.2 `AppDatabase` → единый singleton provider (`appDatabaseProvider` в `providers.dart`), убраны дубли из `settings_provider.dart` и `metronome_provider.dart`.
- [x] 1.3 `AppLogger._writeToFile` → async batched writes через `Future.delayed(Duration.zero, _flush)`. Убран `flush: true` и `writeAsStringSync`.

### Phase 2: HIGH
- [x] 2.1 `LogsScreen` — `_logLines: List<String>` кэшируется в state, `ListView.builder` работает за O(1).
- [x] 2.2 `PlayerScreen` — добавлен `if (!mounted) return;` после `await recognizer.startListening()`.
- [x] 2.3 `FuzzyMatcher` — использует `song.flattenedWords` (lazy getter) вместо `flattenSong(song)`.
- [x] 2.4 `Song` — добавлен `flattenedWords` getter, вычисляется лениво и кэшируется.

### Phase 3: MEDIUM
- [x] 3.1 `AppLogger` — log rotation: max 5 файлов по 1MB (`_rotateIfNeeded`).
- [x] 3.2 `WhisperService` — `localeId` вынесен в параметр конструктора (default `'ru_RU'`).
- [x] 3.3 `_FileOutput` — убран `flush: true`, batch writing.

### Phase 4: Validation
- [x] 4.1 `flutter analyze lib/ test/` — 0 issues
- [x] 4.2 `flutter test` — 23/23 passed
- [x] 4.3 Коммит `6d528bf`

## Коммит
`6d528bf refactor: critical/high/medium fixes from code review`
