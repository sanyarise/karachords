# karachords — План разработки

> Статус: Утверждение (Phase 3)
> Дата: 2026-05-24
> Версия: 2.0

---

## 1. Общее описание

**karachords** — мобильное приложение для гитаристов: "умное караоке" с динамической подсветкой текста и аккордов на основе локального распознавания речи.

- **Платформа:** Android (API 24+), iOS — в перспективе.
- **Кроссплатформа:** Flutter (Dart).
- **Режим разработки:** A (greenfield, с нуля).
- **Команда:** PM + Senior + Middle + Junior.
- **Срок:** 20-30 дней активной разработки.

---

## 2. Роли и модели

| Роль | Модель | Зона ответственности |
|------|--------|---------------------|
| **PM** | — | Координация, архитектура, принятие решений |
| **Senior (Audio Core)** | kimi-k2.6:cloud | Vosk/Whisper, fuzzy matching, performance, прототипирование |
| **Middle (Flutter Dev)** | glm-5.1:cloud | UI/UX, парсеры, Drift, метроном, настройки, экраны |
| **Junior (Support)** | gemma3:27b | Заглушки, тестовые данные, мелкие виджеты, документирование |

### Специальные роли

| Роль | Нужен? | Примечание |
|------|--------|-----------|
| Security Engineer | Да | Privacy аудио, разрешения |
| Technical Writer | Да | README, документация |
| UI/UX Designer | Да | Дизайн-документ готов (DESIGN.md) |
| Financial Auditor | Нет | Нет финансовых расчётов |

---

## 3. Стек технологий

| Слой | Технология |
|------|-----------|
| Framework | **Flutter** (Dart) |
| State Management | **Riverpod** |
| Navigation | **GoRouter** |
| Локальная БД | **Drift (SQLite)** |
| Распознавание речи | **Vosk** (primary), **Whisper tiny** (fallback) |
| Аудио | **flutter_sound** / custom platform channel |
| Ввод песен | **ChordPro** + **Plain Text** → internal JSON |

---

## 4. Архитектура

**Clean Architecture** — три слоя: `domain` → `data` → `presentation`.

### Domain Model

- `Song` → `Section` (verse, chorus, bridge...) → `Line` → `Word` + `Chord`
- `SongSettings` — шрифт, размер, жирность, цвет (текст и аккорды отдельно)
- `MetronomeSettings` — BPM, isPlaying, volume

### Repository Interfaces

- `SongRepository` — CRUD + import built-in
- `SettingsRepository` — song settings + metronome settings
- `SpeechRecognizer` — start/stop + transcript stream

### Data Layer

- **Drift:** таблицы `songs`, `settings`
- **Parsers:** ChordPro → JSON, Plain Text → JSON
- **Speech:** VoskService / WhisperService + FuzzyMatcher

### Presentation Layer

| Экран | Описание |
|-------|----------|
| **SongListScreen** | Список песен, поиск, FAB добавления, swipe-to-delete |
| **PlayerScreen** | Аккорды сверху, текст снизу, подсветка, метроном, настройки |
| **AddSongScreen** | Форма: название, исполнитель, BPM, формат, текст |
| **SettingsScreen** | Настройки визуала: preview, шрифты, размеры, цвета, межстрочный интервал |
| **MetronomeScreen** | BPM слайдер, play/stop, volume (compact bottom sheet + full screen) |

---

## 5. Design System

- **Тема:** Тёмная по умолчанию (`#121212`), светлая опционально.
- **Цвета:** Primary `#BB86FC`, Secondary `#03DAC6`, Error `#CF6679`.
- **Шрифты:** Roboto (текст), Roboto Mono (аккорды — моноширинный).
- **Размеры текста песни:** 14-48sp, шаг 2sp.
- **Размеры аккордов:** 14-48sp, шаг 2sp.
- **Отступы:** база 8dp.
- **Анимации:** 150-300ms, easeOutCubic / easeInOutCubic.

Полный дизайн — в `docs/DESIGN.md`.

---

## 6. Пошаговый план (Dependency Graph)

```
Phase 0: Prototype ─────────────────────────────────────┐
  (Vosk на пении, latency < 1с)                           │
                                                          │
Phase 1: Scaffold ────────────────────────────────────────┤
  (Flutter проект, Riverpod, GoRouter, тема)              │
                                                          ▼
Phase 2: Domain + Data ───────────────────────────────────┤
  (Модели, Drift, парсеры)  ||  (UI виджеты, тема)       │
                                                          ▼
Phase 3: Speech Core ───────────────────────────────────┤
  (Vosk интеграция, FuzzyMatcher)                          │
                                                          ▼
Phase 4: PlayerScreen ────────────────────────────────────┤
  (Подсветка, автоскролл, ChordDisplay, LyricsDisplay)    │
                                                          ▼
Phase 5: Метроном + Settings ─────────────────────────────┤
  (Bottom sheet, настройки визуала, preview)              │
                                                          ▼
Phase 6: User Songs ──────────────────────────────────────┤
  (AddSongScreen, SongListScreen, валидация)              │
                                                          ▼
Phase 7: Polish ──────────────────────────────────────────┤
  (Edge cases, performance, тесты, onboarding)              │
                                                          ▼
Phase 8: Docs + Release ───────────────────────────────────┘
  (README, Google Play assets, release build)
```

### Параллельные задачи (независимые)

- Drift + парсеры || UI виджеты (ChordDisplay, LyricsDisplay)
- Метроном || SettingsScreen
- Onboarding || Performance optimization

---

## 7. Детализация фаз

### Phase 0: Prototype (2-3 дня) — Senior
**Цель:** Проверить, работает ли Vosk с пением.

- Минимальный Flutter-проект.
- Интеграция Vosk, загрузка русской модели.
- Тест: распознаёт ли пение/читку под гитару?
- Измерить latency (задержка от произнесения до результата).
- Простой fuzzy-matching: строка от Vosk → поиск в тексте → вывод позиции.

**Гейт:** Если Vosk не справляется → переход на Whisper tiny (или ручной режим).

---

### Phase 1: Scaffold (2-3 дня) — Middle + Junior
**Цель:** Рабочий каркас приложения.

- `flutter create karachords`.
- Добавить зависимости: `flutter_riverpod`, `go_router`, `drift`, `drift_flutter`, `flutter_sound`, `permission_handler`.
- Настроить тему (dark/light), Material 3.
- GoRouter: маршруты `/`, `/player`, `/add`, `/settings`, `/metronome`.
- Заглушки всех экранов.
- 5 встроенных песен в `assets/songs/` (JSON).

---

### Phase 2: Domain + Data (3-4 дня) — Middle
**Цель:** Модели, БД, парсеры.

- **Domain:** `Song`, `Section`, `Line`, `Word`, `Chord`, `SongSettings`, `MetronomeSettings`.
- **Data:** Drift DAO (`songs`, `settings`), миграции.
- **Parsers:** `ChordProParser`, `PlainTextParser` → internal JSON.
- **Unit-тесты:** парсеры, модели.

**Параллельно (Junior):** UI-виджеты (SongCard, WordWidget, ChordWidget) по DESIGN.md.

---

### Phase 3: Speech Core (4-5 дней) — Senior
**Цель:** Распознавание речи + сопоставление с текстом.

- **Vosk интеграция:** MethodChannel или готовый плагин.
  - `startListening()` → `Stream<String>`.
  - Буферизация частичных результатов.
- **FuzzyMatcher:**
  - Нормализация (lowercase, убрать пунктуацию).
  - Поиск в окне `currentPosition ± windowSize`.
  - Levenshtein distance или `String.contains`.
  - Обработка пропусков, повторов, защита от дрейфа.
- **Unit-тесты:** FuzzyMatcher с мок-распознанным текстом.

---

### Phase 4: PlayerScreen (4-5 дней) — Middle + Senior
**Цель:** Основной экран с подсветкой.

- **ChordDisplay:** горизонтальный скролл, анимация scale + shadow для active.
- **LyricsDisplay:** `ListView.builder` / `Wrap`, каждое слово — `WordWidget`.
  - Состояния: active, pending, inactive.
  - Анимация: `AnimatedDefaultTextStyle` + `AnimatedScale`.
- **Автоскролл:** плавный скролл к активной строке (300ms, easeInOutCubic).
- **Controls:** кнопка Play/Stop, пульсирующий индикатор, статус микрофона.
- **Интеграция:** `SpeechRecognizer` → `FuzzyMatcher` → `currentPositionProvider` → UI.

---

### Phase 5: Метроном + Settings (2-3 дня) — Middle
**Цель:** Метроном и настройки визуала.

- **Metronome:**
  - Bottom sheet в PlayerScreen: BPM слайдер, +/-10, play/stop.
  - Нативный щелчок (flutter_sound или platform channel).
  - Пульсирующий индикатор в такт.
- **SettingsScreen:**
  - Preview card (реальное время).
  - Шрифт, размер, жирность (текст + аккорды отдельно).
  - 3 цвета каждого (active, pending, inactive) — color picker.
  - Фон экрана, межстрочный интервал.
  - Сброс к дефолту.

---

### Phase 6: User Songs (2-3 дня) — Middle
**Цель:** Добавление и управление песнями.

- **SongListScreen:**
  - Отображение встроенных + пользовательских.
  - Поиск (debounce 300ms).
  - Swipe-to-delete с `confirmDismiss`.
- **AddSongScreen:**
  - Поля: название (обязательно), исполнитель, BPM.
  - Toggle: ChordPro / Plain Text.
  - Multiline TextField для текста (min 8 строк).
  - Валидация + парсинг + сохранение в Drift.
  - Ошибки парсинга → SnackBar + подсветка строки.

---

### Phase 7: Polish (3-4 дня) — Middle + Senior + Junior
**Цель:** Стабильность и edge cases.

- **Edge cases:**
  - Пользователь молчит > 5с → пауза подсветки.
  - Перепрыгнул куплет → быстрый resync.
  - Напел не те слова → не уходим в конец.
  - Быстрое переключение песен → корректный dispose.
- **Performance:**
  - `ListView.builder` для слов (не перестраивать весь список).
  - FuzzyMatcher сканирует окно, не всю песню.
  - Профилирование через Flutter DevTools.
- **Onboarding:**
  - 3 экрана: "Что это", "Как работает", "Офлайн".
  - Запрос разрешения микрофона.
  - Загрузка модели Vosk (~50MB, progress indicator).
- **Accessibility:** TalkBack, Semantics, масштабирование шрифта.
- **Landscape:** split layout (аккорды слева, текст справа).

---

### Phase 8: Docs + Release (2-3 дня) — Middle + Junior
**Цель:** Подготовка к публикации.

- **README.md:** описание, скриншоты, установка.
- **Google Play:** иконка (1024x1024), скриншоты (5 штук), описание.
- **Release build:** `flutter build apk --release`, подписание.
- **In-app purchases:** заглушка (premium-шрифты, неограниченные песни).
- **CI/CD:** `.github/workflows/ci.yml` (lint + test).

---

## 8. Acceptance Criteria

- [ ] Пользователь открывает песню — видит аккорды и текст.
- [ ] Пользователь поёт в микрофон — текущее слово и аккорд подсвечиваются в реальном времени.
- [ ] Настройки визуала (шрифт, размер, жирность, цвет) работают для текста и аккордов отдельно. Preview обновляется в реальном времени.
- [ ] Метроном щёлкает с заданным BPM (40-208).
- [ ] Можно добавить свою песню (ChordPro / Plain Text), она появляется в списке.
- [ ] Release-сборка (`flutter build apk --release`) проходит без ошибок.
- [ ] `flutter test` проходит (unit + widget tests).

---

## 9. Гейты

| После | Проверка | Кто |
|-------|----------|-----|
| Phase 0 | Vosk распознаёт пение, latency < 1с | Senior |
| Phase 2 | `flutter build` проходит, парсеры протестированы | Middle |
| Phase 3 | FuzzyMatcher: точность > 80% на тестовых данных | Senior |
| Phase 4 | PlayerScreen: подсветка работает на демо-песне | PM |
| Phase 5 | Метроном щёлкает стабильно, настройки сохраняются | Middle |
| Phase 6 | Можно добавить песню, она отображается корректно | PM |
| Phase 7 | Нет фризов, edge cases обработаны | Senior |
| Phase 8 | Release APK собран, README готов | PM |

---

## 10. Риски и митигация

| Риск | Вероятность | Влияние | Митигация |
|------|-------------|---------|-----------|
| Vosk не распознаёт пение | Средняя | Критическое | Whisper tiny fallback |
| Задержка > 500ms | Средняя | Высокое | Адаптивная подсветка, оптимизация модели |
| Performance на слабых устройствах | Средняя | Высокое | Lazy loading, оптимизация рендера |
| Точность fuzzy matching | Высокая | Среднее | Улучшенный алгоритм, ручная коррекция (future) |
| Размер APK (Vosk модель ~50MB) | Высокая | Низкое | Загрузка модели по запросу, не в APK |

---

## 11. Согласование

**Этот план утверждается пользователем перед началом Phase 4 (Implementation).**

Если есть правки — вносим в TASK.md и пересогласовываем.
