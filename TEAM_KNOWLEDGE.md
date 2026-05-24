# TEAM_KNOWLEDGE — karachords

> Команда: PM + Senior + Middle + Junior (Flutter)
> Проект: кроссплатформенное мобильное приложение (Flutter) для гитаристов — умное караоке с распознаванием речи.

---

## Стандарты

- **Framework:** Flutter (Dart)
- **State Management:** Riverpod
- **Navigation:** GoRouter
- **БД:** Drift (SQLite)
- **Архитектура:** Clean Architecture (domain → data → presentation)
- **Локальное распознавание:** Vosk (запасной — Whisper tiny через whisper.cpp)
- **Аудио:** flutter_sound / custom platform channel для метронома
- **Формат песен:** ChordPro + Plain Text → internal JSON

---

## Грейды

| Роль | Модель |
|------|--------|
| Senior | kimi-k2.6:cloud |
| Middle | glm-5.1:cloud |
| Junior | gemma3:27b |

---

## Правила

1. **Гейт Phase 0:** Vosk на пении — обязательная проверка перед архитектурой.
2. **Гейт Phase 4:** `flutter build apk --release` должен проходить.
3. **Гейт Phase 5:** Интеграционный тест: поём песню — подсветка работает.
4. **Edge case:** если Vosk не справляется с пением → переход на Whisper tiny.
5. **Риск:** fuzzy matching может дрейфовать — нужен механизм resync.

---

## Решения

*(заполняется по ходу работы)*
