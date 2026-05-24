# ANALYSIS — karachords

> Дата: 2026-05-24
> Аналитик: PM (self)

---

## 1. Общее описание проекта

**karachords** — мобильное приложение для гитаристов, реализующее "умное караоке" с динамической подсветкой текста и аккордов на основе локального распознавания речи.

Пользователь играет на гитаре и поёт. Приложение слушает микрофон, распознаёт речь локально (без интернета) и в реальном времени подсвечивает текущее слово текста песни и текущий аккорд.

---

## 2. Режим разработки (Mode)

**Mode A** — новый проект (greenfield).

Причины:
- Нет существующей кодовой базы.
- Нет legacy-ограничений.
- Старт с нуля.

---

## 3. Сложность и размер команды

| Параметр | Оценка |
|----------|--------|
| Сложность | **Complex** (аудио-ядро, fuzzy matching, UI-рендеринг в реальном времени, кроссплатформа) |
| Команда | **4 человека** (PM + 1 Senior + 1 Middle + 1 Junior) |
| Срок | **20-30 дней** активной разработки |

### Распределение ролей

| Роль | Грейд | Зона ответственности |
|------|-------|---------------------|
| **PM** | — | Координация, архитектура, принятие решений |
| **Senior (Audio Core)** | opus → kimi-k2.6:cloud | Vosk/Whisper интеграция, fuzzy matching, performance, прототипирование |
| **Middle (Flutter Dev)** | sonnet → glm-5.1:cloud | UI/UX, парсеры, БД (Drift), метроном, настройки, экраны |
| **Junior (Support)** | haiku → gemma3:27b | Заглушки, тестовые данные, мелкие виджеты, документирование |

### Специальные роли

| Роль | Нужен? | Причина |
|------|--------|---------|
| **Security Engineer** | Да | Локальное аудио — privacy-критично, разрешения |
| **Technical Writer** | Да | README, документация |
| **UI/UX Designer** | Да | Экраны для сторонних пользователей |
| **Financial Auditor** | Нет | Нет финансовых расчётов |

---

## 4. Технологический стек

| Слой | Технология |
|------|-----------|
| Framework | **Flutter** (Dart) — кроссплатформа |
| State Management | **Riverpod** |
| Navigation | **GoRouter** |
| Локальная БД | **Drift (SQLite)** |
| Распознавание речи | **Vosk** (primary), **Whisper tiny** (fallback через whisper.cpp) |
| Аудио | **flutter_sound** / custom platform channel |
| Ввод песен | **ChordPro** + **Plain Text** → internal JSON |
| Метроном | Нативный аудио-щелчок |

---

## 5. Основные риски

| Риск | Вероятность | Влияние | Митигация |
|------|-------------|---------|-----------|
| Vosk не распознаёт пение | Средняя | Критическое | Запасной план: Whisper tiny |
| Задержка распознавания > 500ms | Средняя | Высокое | Адаптивная подсветка, оптимизация модели |
| Performance на слабых Android | Средняя | Высокое | Оптимизация рендера (LazyList, ключи) |
| Точность fuzzy matching | Высокая | Среднее | Улучшенный алгоритм, ручная коррекция |
| Размер APK (Vosk ~50MB) | Высокая | Низкое | Загрузка модели по запросу, а не в APK |

---

## 6. Критический путь

```
Phase 0 (Preparation) → Phase 1 (Analysis) → Phase 2 (Architecture) →
Phase 3 (Planning) → Phase 4 (Implementation) →
Phase 5 (Testing) → Phase 6 (Review) → Phase 7 (Docs)
```

**Блокирующие зависимости:**
- Этап 0 (Vosk-прототип) **ДОЛЖЕН** пройти гейт перед Этапом 2.
- Если Vosk не работает — весь план пересматривается (переход на Whisper или ручной режим).

---

## 7. Acceptance Criteria (высокоуровневые)

- [ ] Пользователь открывает песню — видит аккорды и текст.
- [ ] Пользователь поёт в микрофон — текущее слово и аккорд подсвечиваются.
- [ ] Настройки визуала (шрифт, размер, жирность, цвет) работают для текста и аккордов отдельно.
- [ ] Метроном щёлкает с заданным BPM.
- [ ] Можно добавить свою песню (ChordPro / plain text).
- [ ] Release-сборка проходит.

---

## 8. Решения по архитектуре (предварительные)

- **Clean Architecture** — три слоя: domain / data / presentation.
- **Domain Model:** `Song` → `Section` → `Line` → `Word` + `Chord`.
- **Internal format:** JSON (нормализованный, позиционирование аккордов).
- **Input formats:** ChordPro и plain text (с квадратными скобками) — парсятся в internal JSON.
- **Режим синхронизации:** Вариант C (динамический, без таймингов).
- **Распознавание:** Локально, офлайн.

---

## 9. Рекомендации по запуску

1. **Сначала Этап 0 (прототип Vosk)** — 2-3 дня. Если гейт не проходит — меняем стек.
2. **Затем Этап 2 (архитектура)** — после подтверждения работы аудио.
3. **Middle может начинать UI-каркас параллельно** с Этапом 0, если Senior подтвердит API Vosk.
4. **Junior готовит тестовые данные** (5 песен в JSON) параллельно.

---

## 10. Vosk Integration Deep Dive (2026-05-24)

### Current Speech Stack
- `WhisperService` — uses `speech_to_text` package (online Google Speech, requires internet)
- `VoskService` — empty stub
- `SpeechRecognizer` interface: `transcriptStream`, `startListening`, `stopListening`, `dispose`

### Vosk Flutter Plugin
- Package: `vosk_flutter: ^0.3.48` (alphacep official)
- Platforms: Android ✔, Linux ✔, Windows ✔, iOS ✖, macOS ✖
- **Android streaming API:** `initSpeechService(recognizer)` → `onPartial()` / `onResult()` streams
- **Batch API (all platforms):** `acceptWaveformBytes()` + `getPartialResult()` / `getResult()`
- **Model loading:** `ModelLoader().loadFromAssets('assets/models/xxx.zip')` — extracts on first run, caches

### SDK Constraint Risk (BLOCKER)
`vosk_flutter` requires `sdk: ">=2.15.1 <3.0.0"`. Our project uses `sdk: ^3.12.0`.
Pub may reject this dependency. **Mitigation:** `dependency_override` to force resolution, then test if package works on Dart 3.

### Model Strategy
- Model: `vosk-model-small-ru-0.22.zip` (~50MB)
- Approach: Bundle in `assets/models/` (APK +50MB, instant on first run)
- Alternative: Download on first run (0MB APK, needs progress UI and network)
- Decision: **Bundle in assets** for simplicity

### Latency Estimate
| Component | Latency |
|-----------|---------|
| Audio capture | 100-300ms |
| Vosk partial processing | 200-500ms |
| FuzzyMatcher | 1-5ms |
| UI update | 16ms |
| **Total** | **300-800ms** |

Target <1s is achievable.

### Risks (Integration-specific)
| Risk | Prob | Impact | Mitigation |
|------|------|--------|------------|
| SDK constraint mismatch | Medium | Build fail | dependency_override, test Dart 3 compat |
| initSpeechService crash on some devices | Medium | High | Try-catch + fallback to speech_to_text |
| JNA/ProGuard in release | Low | High | Add ProGuard rules, test release APK |
| Model memory on low-end | Low | High | small model already chosen |

### Decision
**Vosk streaming (Android) wins over Whisper batch:**
- True streaming partial results (whisper_flutter_new is batch-only)
- Lower latency (~300-800ms vs 3-5s)
- Model already available
- Acceptable trade-off: Android-only streaming (Linux/Windows need manual chunking)
