# karachords — UI/UX Design Document

> Дата: 2026-05-24
> Версия: 1.0
> Статус: Утверждено
> Язык: Русский

---

## 1. Design System

### 1.1 Философия дизайна

Приложение для музыкантов, которые играют в dimly-lit условиях: репетиционные базы, кухня с тусклым светом, сцена. Поэтому **тёмная тема — дефолт**, светлая — опциональная. Интерфейс минималистичный: ничего не отвлекает от текста и аккордов. Крупные сенсорные мишени, потому что во время игры палец может быть не очень точным.

**Ключевые принципы:**
- Читаемость в первую очередь.
- Минимум визуального шума.
- Большие тап-зоны.
- Мгновенная визуальная обратная связь.

---

### 1.2 Цветовая палитра

#### Тёмная тема (default)

| Роль | Значение | Описание |
|------|----------|----------|
| `background` | `#121212` | Основной фон, чёрный с лёгкой теплинкой |
| `surface` | `#1E1E1E` | Карточки, нижние панели, инпуты |
| `surfaceVariant` | `#2C2C2C` | Выделенные элементы, hover-фон |
| `primary` | `#BB86FC` | Основной акцент — фиолетовый, виден в темноте |
| `primaryContainer` | `#4A3868` | Фон кнопок и чипсов с primary |
| `onPrimary` | `#000000` | Текст на primary |
| `secondary` | `#03DAC6` | Вторичный акцент — бирюзовый, для метронома и активных элементов |
| `error` | `#CF6679` | Ошибки, удаление |
| `textPrimary` | `#FFFFFF` | Основной текст, высокая контрастность |
| `textSecondary` | `#B3B3B3` | Вторичный текст, подписи |
| `textDisabled` | `#666666` | Неактивный текст |
| `divider` | `#3A3A3A` | Разделители |
| `overlay` | `#000000` с `opacity: 0.7` | Модальные фоны, снэкбары |

#### Светлая тема (опциональная, через настройки)

| Роль | Значение |
|------|----------|
| `background` | `#FAFAFA` |
| `surface` | `#FFFFFF` |
| `surfaceVariant` | `#F0F0F0` |
| `primary` | `#6200EE` |
| `primaryContainer` | `#EADDFF` |
| `onPrimary` | `#FFFFFF` |
| `secondary` | `#03DAC6` |
| `error` | `#B00020` |
| `textPrimary` | `#1C1B1F` |
| `textSecondary` | `#49454F` |
| `textDisabled` | `#A1A1A1` |
| `divider` | `#E0E0E0` |

#### Цвета подсветки на экране Player (настраиваемые, дефолт)

| Состояние | Текст | Аккорд |
|-----------|-------|--------|
| **Active** (текущее) | `#FFFFFF` + `FontWeight.bold` | `#03DAC6` + `FontWeight.bold` |
| **Pending** (следующие) | `#B3B3B3` | `#4DB6AC` |
| **Inactive** (пройденные) | `#666666` | `#33695E` |

> Все цвета подсветки текста и аккордов — отдельные настройки в `SongSettings`. Пользователь может кастомизировать через color picker в `SettingsScreen`.

---

### 1.3 Типографика

**Шрифты:**

| Роль | Шрифт | Fallback |
|------|-------|----------|
| Текст песни | `Roboto` | `sans-serif` |
| Аккорды | `Roboto Mono` | `monospace` (равная ширина важна для позиционирования) |
| UI-элементы | `Roboto` | `sans-serif` |

**Размеры (sp — масштабируемые):**

| Элемент | Размер (sp) | Weight | Line Height |
|---------|-------------|--------|-------------|
| Заголовок экрана (AppBar) | 20 | w500 | 1.2 |
| Название песни в списке | 18 | w500 | 1.3 |
| Исполнитель в списке | 14 | w400 | 1.3 |
| **Текст песни (Player)** | **22-32** (настраиваемый) | w400 / w700 (active) | 1.5 |
| **Аккорды (Player)** | **18-28** (настраиваемый) | w500 / w700 (active) | 1.2 |
| Метка секции (Verse/Chorus) | 12 | w500 | 1.0 |
| Кнопка | 16 | w500 | 1.0 |
| Подпись / hint | 14 | w400 | 1.3 |
| Пустое состояние | 16 | w400 | 1.4 |

> Минимальный размер текста песни: 14sp. Максимальный: 48sp. Шаг: 2sp.

---

### 1.4 Система отступов

Базовая единица: `8dp`.

| Токен | Значение | Применение |
|-------|----------|------------|
| `spaceXs` | 4dp | Микро-отступы (иконка + текст) |
| `spaceSm` | 8dp | Внутренние отступы маленьких элементов |
| `spaceMd` | 16dp | Стандартный padding карточек, экранов |
| `spaceLg` | 24dp | Между секциями |
| `spaceXl` | 32dp | Крупные разрывы |
| `space2xl` | 48dp | Отступ от краёв экрана |

**Safe Area:** учитывать `MediaQuery.padding` — в нижней части экрана Player минимум 16dp от system gesture insets.

---

### 1.5 Библиотека компонентов

#### PrimaryButton

```dart
// Спецификация
- Background: primaryContainer (#4A3868)
- Foreground: onPrimary (#000000)
- Padding: 16dp vertical, 24dp horizontal
- BorderRadius: 12dp
- Font: 16sp, w500
- Minimum height: 48dp (Material touch target)
- Elevation: 0 (flat, современный Material 3)
```

#### SecondaryButton (Outlined)

```dart
- Border: 1dp solid primary
- Background: transparent
- Foreground: primary (#BB86FC)
- Padding: 16dp vertical, 24dp horizontal
- BorderRadius: 12dp
```

#### SongCard

```dart
- Background: surface (#1E1E1E)
- BorderRadius: 12dp
- Padding: 16dp
- Margin bottom: 8dp
- Title: 18sp, w500, textPrimary
- Artist: 14sp, w400, textSecondary
- Trailing: more_vert icon (24dp)
- Ripple: primary с opacity 0.08
```

#### TextInput (multiline для ввода песен)

```dart
- Background: surface
- BorderRadius: 12dp
- Border: 1dp solid divider (в покое), primary (в фокусе)
- Padding: 16dp
- Font: 16sp, w400
- Min height: 120dp (для песен)
- Max height: expandable
```

#### IconButton (Player controls)

```dart
- Size: 56dp (большой, для тапа пальцем)
- Icon size: 28dp
- Background: surfaceVariant (для Play/Stop)
- Ripple: secondary (#03DAC6) с opacity
```

#### Slider (BPM, font size)

```dart
- Active track: secondary (#03DAC6)
- Inactive track: surfaceVariant
- Thumb: secondary, size 20dp
- Track height: 4dp
```

#### ChordChip

```dart
- Background: surfaceVariant
- BorderRadius: 8dp
- Padding: 8dp horizontal, 4dp vertical
- Font: chordFont, 16sp, w500
- Active state: background secondary, color onPrimary
```

---

## 2. Screen Designs

### 2.1 Song List Screen

**Назначение:** Главный экран, точка входа. Список всех песен.

**Layout:**

```
┌─────────────────────────────────────┐
│  🎸 karachords              [⚙️]   │  AppBar, h=56dp
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐  │  SearchBar
│  │  🔍 Поиск по песням...       │  │  h=48dp, padding=16dp
│  └───────────────────────────────┘  │
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐  │  ListView
│  │ Песня о ветре                 │  │  SongCard
│  │ Виктор Цой                    │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ Кукушка                       │  │
│  │ Виктор Цой                    │  │
│  └───────────────────────────────┘  │
│              ...                    │
│                                     │
├─────────────────────────────────────┤
│         [  + Добавить песню  ]      │  FAB, 56dp circle
│                                     │  bottom: 24dp, right: 24dp
└─────────────────────────────────────┘
```

**Детали:**

- **AppBar:** `background = background`, `elevation = 0`, title: 20sp w500, trailing: иконка настроей (⚙️), 24dp.
- **SearchBar:** `TextField` с `prefixIcon: Icons.search`. Фон `surface`, `BorderRadius: 12dp`. Отступы `16dp` слева/справа, `8dp` сверху. Debounce поиска: 300ms. Поиск по `title` и `artist` case-insensitive.
- **SongCard:** тап → переход на `PlayerScreen`. Длинный тап — ripple без действия. `onDismissed` — удаление с `confirmDismiss` (диалог подтверждения для встроенных песен; для пользовательских — сразу удаление с undo SnackBar).
- **Swipe-to-delete:** `Dismissible` с `background` красным (`error`), иконка `Icons.delete`, white. Threshold: 0.4 ширины. Direction: `endToStart` (свайп слева направо — удаление).
- **Empty state:** Если нет песен (и поиск не дал результатов) — центрированная иллюстрация (🎸 emoji, 48sp) + текст "Нет песен. Добавьте первую!" + кнопка "Добавить".
- **FAB:** `backgroundColor: primary`, `foregroundColor: onPrimary`, `elevation: 4`. Иконка `Icons.add`, 24dp. `heroTag: 'fab_add_song'`.
- **Scroll:** `BouncingScrollPhysics` (iOS-style, плавно).

---

### 2.2 Player Screen

**Назначение:** Основной экран приложения. Аккорды сверху, текст снизу, подсветка по распознаванию.

**Layout:**

```
┌─────────────────────────────────────┐
│  [←] Песня о ветре    [♩]  [⚙️]   │  AppBar, h=56dp
├─────────────────────────────────────┤
│                                     │
│           Am        C               │  ChordDisplay
│         (active)  (pending)          │  h=~120dp (dynamic)
│                                     │
├─────────────────────────────────────┤
│                                     │
│   [Verse 1]                         │  SectionLabel
│                                     │
│   Как же мне рассказать             │  LyricsDisplay
│   █── ─── ─── ───                   │  (█ = active word)
│                                     │
│   О том, что я люблю                │
│   ─── ─── ─── ─── ───               │
│                                     │
│   [Chorus]                          │
│                                     │
│   Я люблю тебя, жизнь моя           │
│   ─── ─── ───  ───  ───             │
│                                     │
│              ...                    │
│                                     │
├─────────────────────────────────────┤
│                                     │
│   [🎤 Слушаю...]  или               │  Controls, h=80dp
│   [▶ Начать]                        │
│                                     │
└─────────────────────────────────────┘
```

**Детали:**

#### AppBar
- `background: background`, `elevation: 0`.
- Leading: back arrow (`Icons.arrow_back`), 24dp. Тап → `Navigator.pop()`.
- Title: название песни, 18sp w500. Если длинное — `overflow: TextOverflow.ellipsis`.
- Actions:
  - Metronome icon (♩): тап → `showModalBottomSheet` с `MetronomeControl` (не полный экран, компактная панель).
  - Settings icon (⚙️): тап → `Navigator.pushNamed('/settings')`.

#### ChordDisplay (верхний блок)
- **Высота:** `120dp` фиксированная. `SingleChildScrollView` horizontal.
- **Layout:** `Row` с `mainAxisAlignment: MainAxisAlignment.center` + `Wrap` на случай длинных последовательностей.
- **Аккорд-виджет:**
  - Размер шрифта: `chordFontSize` (default 22sp).
  - Размер: минимум `64dp` wide, `80dp` tall. Центрирование.
  - **Active:** цвет `chordActiveColor` (#03DAC6), `FontWeight.bold`, масштаб `1.15x` (анимация `scale` 200ms, `easeOutCubic`). Добавить мягкую тень: `BoxShadow(color: chordActiveColor.withOpacity(0.3), blurRadius: 8)`.
  - **Pending:** цвет `chordPendingColor` (#4DB6AC), `FontWeight.w500`, масштаб `1.0`.
  - **Inactive:** цвет `chordInactiveColor` (#33695E), `FontWeight.normal`, `opacity: 0.5`, масштаб `0.9`.
- **Поведение:** Показывать текущий аккорд + следующие 2-3 аккорда. Предыдущие аккорды уходят влево за пределы видимости.
- **Background:** `surface` с `BorderRadius.bottom: 16dp`.

#### LyricsDisplay (основной скроллируемый блок)
- **Widget:** `CustomScrollView` или `ListView.builder` с `shrinkWrap: true`.
- **Секция:** `SectionLabel` — маленький uppercase текст `[Verse 1]`, цвет `textSecondary`, 12sp w500. Padding: `24dp` top, `8dp` bottom.
- **Строка:** `Wrap` с `spacing: 4dp` (между словами). Каждое слово — отдельный `WordWidget`.
- **WordWidget:**
  - Размер шрифта: `textFontSize` (default 24sp).
  - **Active:** `textActiveColor` (#FFFFFF), `FontWeight.bold`, анимация `scale: 1.05` (200ms, `easeOutCubic`).
  - **Pending:** `textPendingColor` (#B3B3B3), `FontWeight.normal`.
  - **Inactive:** `textInactiveColor` (#666666), `FontWeight.normal`.
- **Автоскролл:** Когда `activeWord` переходит на следующую строку — плавный скролл (`animateTo`) так, чтобы активная строка была на `1/3` экрана от верха. Duration: `300ms`. Curve: `easeInOutCubic`.
- **Прокрутка:** Пользователь может скроллить вручную. Ручной скролл отключает автоскролл на 3 секунды (таймер), потом автоскролл возобновляется.
- **Padding bottom:** `80dp` (чтобы последние строки не прятались под controls).

#### Controls (нижняя панель)
- **Высота:** `80dp`.
- **Background:** `surface` с `BorderRadius.top: 16dp` + `BoxShadow` (subtle, поднятие над контентом).
- **Состояния:**
  - **Ожидание (не слушаем):** Кнопка "▶ Начать" (PrimaryButton, зелёный/secondary). Тап → запрос разрешения микрофона → старт Vosk.
  - **Слушаем:** Кнопка "■ Стоп" (IconButton, красный фон `error`, иконка `Icons.stop`). Рядом: пульсирующий индикатор — кружок `8dp` с анимацией `scale` (1.0 → 1.5 → 1.0), цвет `secondary`, `opacity` пульсации 0.5 → 1.0. Подпись: "Слушаю..." 14sp.
  - **Пауза (молчание > 5с):** Индикатор серый, кнопка "▶ Продолжить".
- **SafeArea:** панель должна быть выше system navigation bar (включаем `SafeArea`).

---

### 2.3 Add Song Screen

**Назначение:** Добавление новой песни вручную.

**Layout:**

```
┌─────────────────────────────────────┐
│  [✕] Добавить песню       [💾]    │  AppBar
├─────────────────────────────────────┤
│                                     │
│  Название                           │  Label
│  ┌───────────────────────────────┐  │  TextField
│  │ Введите название...          │  │
│  └───────────────────────────────┘  │
│                                     │
│  Исполнитель                        │
│  ┌───────────────────────────────┐  │
│  │ Введите исполнителя...       │  │
│  └───────────────────────────────┘  │
│                                     │
│  BPM (опционально)                  │
│  ┌──────┐ ┌──────┐                  │  Int input + metronome hint
│  │ 120  │ [♩]   │                  │
│  └──────┘ └──────┘                  │
│                                     │
│  Формат текста                      │  SegmentedButton
│  [  ChordPro  |  Plain Text  ]      │
│                                     │
│  Текст песни                        │  Label
│  ┌───────────────────────────────┐  │  Multiline TextField
│  │ [Am]Как же мне рассказать   │  │  minLines: 8, maxLines: null
│  │ [C]О том, что я люблю       │  │
│  │                             │  │
│  │ [G]Я люблю тебя, [F]жизнь   │  │
│  │                             │  │
│  └───────────────────────────────┘  │
│                                     │
│         [  + Добавить песню  ]      │  PrimaryButton
│                                     │  bottom: 24dp
└─────────────────────────────────────┘
```

**Детали:**

- **AppBar:** Leading — close icon (✕), тап → `Navigator.pop()` без сохранения (confirm dialog если были изменения). Trailing — save icon (💾), тап → валидация → сохранение → pop.
- **Название:** Обязательное. `TextInputType.text`, `textCapitalization: TextCapitalization.sentences`. Валидация: не пустое, не > 200 символов.
- **Исполнитель:** Опциональный. Те же настройки.
- **BPM:** `TextFormField` с `keyboardType: TextInputType.number`, `maxLength: 3`. Валидация: 40-208 или пусто. Рядом иконка метронома — тап показывает `MetronomeControl` для подбора темпа.
- **Формат текста:** `ToggleButtons` / `SegmentedButton` (Material 3). Default: ChordPro.
  - **ChordPro:** подсказка под полем: "Аккорды в квадратных скобках: `[Am]Слово`".
  - **Plain Text:** подсказка: "Аккорды сверху, текст снизу, выровненные пробелами".
- **Текст песни:** `TextField` `maxLines: null`, `keyboardType: TextInputType.multiline`. `minHeight: 200dp`.
  - Валидация: не пустое, минимум одна строка.
  - Авторасширение: `expands: true` или `minLines: 8` + `maxLines: null`.
- **Кнопка "Добавить":** Disabled если валидация не пройдена. При нажатии:
  1. Парсинг через соответствующий парсер.
  2. Если парсинг упал — `SnackBar` с ошибкой и подсветкой проблемной строки.
  3. Сохранение в Drift.
  4. `Navigator.pop()` с результатом.
- **Scroll:** Весь экран — `SingleChildScrollView`.

---

### 2.4 Settings Screen

**Назначение:** Настройки визуального отображения песни. Текст и аккорды настраиваются **отдельно**.

**Layout:**

```
┌─────────────────────────────────────┐
│  [←] Настройки визуала             │  AppBar
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐  │  Preview Card
│  │                               │  │  h=160dp, surface
│  │      Am        C              │  │
│  │    Как же мне рассказать      │  │
│  │                               │  │
│  └───────────────────────────────┘  │
│                                     │
│  ── Текст ─────────────────────     │  Section divider
│                                     │
│  Шрифт                              │
│  [ Roboto ▼ ]                       │  Dropdown
│                                     │
│  Размер шрифта                      │
│  A ───────────────●────── A         │  Slider (14sp - 48sp)
│           26sp                      │
│                                     │
│  Жирность                           │
│  [ Обычный  |  Полужирный  ]       │  SegmentedButton
│                                     │
│  Цвета текста                       │
│  Текущее    Следующее   Пройденное│
│  [█]        [█]          [█]       │  ColorPickers (3 штуки)
│  #FFFFFF    #B3B3B3     #666666   │
│                                     │
│  ── Аккорды ───────────────────     │
│                                     │
│  Шрифт                              │
│  [ Roboto Mono ▼ ]                  │
│                                     │
│  Размер шрифта                      │
│  A ─────●─────────────── A         │  Slider (14sp - 48sp)
│         20sp                        │
│                                     │
│  Жирность                           │
│  [ Обычный  |  Полужирный  ]       │
│                                     │
│  Цвета аккордов                     │
│  Текущий    Следующий   Пройденный│
│  [█]        [█]          [█]       │
│  #03DAC6    #4DB6AC     #33695E   │
│                                     │
│  ── Общее ────────────────────     │
│                                     │
│  Фон экрана                         │
│  [█] #121212                        │  ColorPicker
│                                     │
│  Межстрочный интервал               │
│  ─────●───────────────              │  Slider (1.0 - 3.0)
│       1.5x                         │
│                                     │
│  [  Сбросить настройки  ]           │  TextButton
│                                     │
└─────────────────────────────────────┘
```

**Детали:**

- **AppBar:** Title "Настройки визуала", leading back arrow.
- **Preview Card:** Статичный пример (2 слова, 2 аккорда) отображается с текущими настройками. Обновляется в реальном времени при изменении любого параметра. `Card` с `surface` фоном, `BorderRadius: 12dp`, `padding: 16dp`.
- **Шрифт:** `DropdownButtonFormField` со списком доступных шрифтов (Roboto, Roboto Mono, Open Sans, Montserrat). В будущем premium-шрифты.
- **Размер шрифта:** `Slider` с `divisions: 17` (шаг 2sp). Подпись текущего значения под слайдером.
- **Жирность:** `SegmentedButton` с двумя вариантами: `FontWeight.w400` / `FontWeight.w700`.
- **ColorPickers:** Каждый — `GestureDetector` на квадрате `40dp` с `BorderRadius: 8dp` + цвет. Тап — `showModalBottomSheet` с `flutter_colorpicker` (compact wheel). Выбранный цвет отображается как HEX под квадратом.
- **Фон экрана:** Аналогичный ColorPicker.
- **Межстрочный интервал:** `Slider` 1.0-3.0, шаг 0.1.
- **Сброс:** `TextButton` с `foregroundColor: error`. Подтверждение через `AlertDialog`.
- **Scroll:** `SingleChildScrollView`. Отступ снизу: `32dp`.
- **Сохранение:** Настройки сохраняются в `shared_preferences` / Drift при каждом изменении (debounce 500ms).

---

### 2.5 Metronome Screen (и Bottom Sheet)

**Назначение:** Отдельный экран или bottom sheet для настройки метронома. В Player используется компактный bottom sheet; полный экран доступен из меню (если решим добавить).

**Compact Bottom Sheet (в Player):**

```
┌─────────────────────────────────────┐
│  ⠿⠿⠿  Drag handle, 36dp height     │
├─────────────────────────────────────┤
│                                     │
│            ♩ = 120                  │  BPM display, 48sp
│                                     │
│  40 ─────────●─────────── 208        │  Slider
│                                     │
│     [  -  ]  [  ▶  ]  [  +  ]      │  Controls
│     10bpm     Play      10bpm       │
│                                     │
└─────────────────────────────────────┘
```

**Full Screen (если нужен):**

```
┌─────────────────────────────────────┐
│  [✕] Метроном                      │  AppBar
├─────────────────────────────────────┤
│                                     │
│           ♩ = 120                   │  Центральный BPM, 64sp
│                                     │
│   40 ─────────●─────────── 208      │  Slider, secondary color
│                                     │
│        ┌───────────┐                │
│        │     ▶     │                │  Play button, 72dp
│        └───────────┘                │
│                                     │
│   [  -10  ]        [  +10  ]        │  Secondary buttons
│                                     │
│   Громкость                         │
│   🔇 ─────────────●────── 🔊        │  Volume slider
│                                     │
│   [  Сохранить BPM в песню  ]       │  (только если открыто из Player)
│                                     │
└─────────────────────────────────────┘
```

**Детали:**

- **BPM Display:** Крупный текст, моноширинный шрифт (`Roboto Mono`). При изменении — анимация `scale` (1.1 → 1.0, 150ms) для тактильной отдачи.
- **Slider:** `min: 40`, `max: 208`, `divisions: 168` (шаг 1). Active track: `secondary`. При drag — haptic feedback (`HapticFeedback.selectionClick`).
- **Play Button:**
  - **Stopped:** Иконка `Icons.play_arrow`, background `secondary`, foreground `onPrimary`. Размер: `72dp` (круг), icon `36dp`.
  - **Playing:** Иконка `Icons.stop`, background `error`, foreground `onPrimary`.
  - Анимация: `AnimatedContainer` 200ms при смене состояния.
- **+10 / -10:** `OutlinedButton`, `BorderRadius: 8dp`, ширина `80dp`. Haptic feedback на тап.
- **Volume Slider:** `0.0 - 1.0`, шаг 0.05. Иконки `Icons.volume_mute` / `Icons.volume_up`.
- **Sound indicator:** При playing — пульсирующий круг `secondary` с `opacity` 0.3 → 0.8, `scale` 0.8 → 1.2, infinite loop, `duration: 60/BPM секунд`.
- **Save BPM:** Если открыто из `PlayerScreen` — кнопка "Сохранить BPM в песню" (PrimaryButton). Сохраняет в `Song.bpm` и Drift.
- **Drag handle:** `Container` `36dp` height, centered, с `RoundedRectangleBorder` (4dp wide, 4dp tall, `BorderRadius: 2dp`, color `textSecondary`).

---

## 3. User Flows

### 3.1 Первый запуск (Onboarding)

**Цель:** Объяснить, что делает приложение, и запросить необходимые разрешения.

**Flow:**

```
Splash Screen (1.5s) → Onboarding Page 1 → Onboarding Page 2 → Onboarding Page 3 → Разрешение микрофона → Главный экран
```

**Onboarding Page 1 — Что это:**
- Иллюстрация: гитара + микрофон + телефон (можно emoji 🎸🎤📱).
- Заголовок: "Играй и пой".
- Описание: "Открывай песню, приложение слушает твой голос и подсвечивает текущее слово и аккорд в реальном времени."
- Кнопка: "Далее".

**Onboarding Page 2 — Как работает:**
- Иллюстрация: текст с подсвеченным словом.
- Заголовок: "Следи за текстом".
- Описание: "Никаких таймеров. Просто пой — и текст сам подскажет, где ты."
- Кнопка: "Далее".

**Onboarding Page 3 — Офлайн:**
- Иллюстрация: галочка Wi-Fi перечёркнута.
- Заголовок: "Работает без интернета".
- Описание: "Распознавание речи работает локально. Загрузи модель один раз — и пользуйся где угодно."
- Кнопка: "Начать".

**Разрешение микрофона:**
- После onboarding — `showDialog` с объяснением: "Приложению нужен доступ к микрофону, чтобы слушать твой голос и синхронизировать текст."
- Кнопки: "Дать доступ" (запускает `Permission.microphone.request()`) / "Позже" (можно включить позже в настройках).

**Vosk Model Download:**
- Если модель не скачана — показать `LinearProgressIndicator` с текстом "Загрузка модели распознавания (~50 МБ)".
- Кнопка "Отмена" (можно пропустить и скачать позже).
- После загрузки — `SnackBar` "Готово к работе!" → `SongListScreen`.

---

### 3.2 Открытие и проигрывание песни

```
SongListScreen
  → Тап на песню
    → PlayerScreen (push)
      → Тап "▶ Начать"
        → Запрос разрешения микрофона (если не дано)
          → Инициализация Vosk (если не инициализирован)
            → Старт прослушивания
              → Vosk возвращает текст
                → FuzzyMatcher ищет позицию в песне
                  → Обновление currentPosition
                    → Подсветка слова и аккорда
                      → Автоскролл к активной строке
```

**Кейсы внутри flow:**

- **Разрешение отклонено:** См. раздел 5.2.
- **Модель не загружена:** См. раздел 5.3.
- **Пользователь сворачивает приложение:** `AppLifecycleState.paused` → остановка Vosk. При `resumed` — если раньше слушали, показать `SnackBar` "Нажмите ▶, чтобы продолжить".
- **Пользователь нажимает "Стоп":** Остановка Vosk, сброс `currentPosition` в начало (или оставить текущую позицию? Решение: оставить, чтобы можно было продолжить. Сброс по длинному тапу или через меню).

---

### 3.3 Добавление своей песни

```
SongListScreen
  → Тап FAB "+"
    → AddSongScreen
      → Ввод названия
      → Ввод исполнителя (опц.)
      → Выбор формата (ChordPro / Plain Text)
      → Ввод текста
      → Тап "Добавить"
        → Валидация
          → Парсинг
            → Сохранение в Drift
              → Pop → SongListScreen (с обновлённым списком)
                → SnackBar: "Песня добавлена"
```

**Кейсы:**
- **Невалидный ChordPro:** `SnackBar` "Ошибка в строке 5: незакрытая скобка `[]`". Курсор в `TextField` на позицию ошибки.
- **Plain Text — не совпадает количество строк:** `SnackBar` "Количество строк с аккордами и текстом должно совпадать".
- **Пустой текст:** `TextField` обводится `error` цветом, подпись "Введите текст песни".

---

### 3.4 Настройка визуала

```
PlayerScreen
  → Тап ⚙️ (Settings)
    → SettingsScreen
      → Изменение любого параметра
        → Preview обновляется в реальном времени
        → Debounce 500ms → сохранение в БД
      → Тап "Назад"
        → Pop → PlayerScreen
          → PlayerScreen перечитывает настройки через Riverpod
            → UI обновляется с новыми цветами/шрифтами
```

---

### 3.5 Использование метронома

```
PlayerScreen
  → Тап ♩ (Metronome)
    → BottomSheet (MetronomeControl)
      → Слайдер BPM / +10 / -10
      → Тап ▶
        → Метроном начинает щёлкать
        → Индикатор пульсирует в такт
        → Тап ■ (Stop)
          → Метроном останавливается
      → Свайп вниз / тап вне области
        → BottomSheet закрывается
        → Метроном продолжает играть (если был запущен)
```

---

## 4. Accessibility

### 4.1 Поддержка масштабирования шрифта

- Все текстовые размеры — в `sp` (через `MediaQuery.textScaleFactor`).
- **Исключение:** размеры аккордов и текста песни на `PlayerScreen` — пользовательские, но если `textScaleFactor > 1.5`, UI не должен ломаться.
- **Минимальные размеры касания:** все интерактивные элементы минимум `48dp` (Material standard).
- **Переполнение:** `LyricsDisplay` — `Wrap` + скролл. Если шрифт огромный — слова переносятся, скролл работает.

### 4.2 Контрастность

Все цвета подобраны под WCAG 2.1 AA:

| Комбинация | Контраст | Статус |
|------------|----------|--------|
| `textPrimary` (#FFFFFF) на `background` (#121212) | 16.1:1 | AAA |
| `textSecondary` (#B3B3B3) на `background` (#121212) | 8.6:1 | AAA |
| `primary` (#BB86FC) на `background` (#121212) | 7.2:1 | AAA |
| `secondary` (#03DAC6) на `background` (#121212) | 9.8:1 | AAA |
| `error` (#CF6679) на `background` (#121212) | 5.1:1 | AA |
| `textDisabled` (#666666) на `surface` (#1E1E1E) | 3.1:1 | AA (large text) |

> Если пользователь меняет цвета в настройках — не гарантируем WCAG, но показываем предупреждение при выборе цветов с низким контрастом (опционально, future).

### 4.3 Screen Reader (TalkBack / VoiceOver)

- **Semantics на PlayerScreen:**
  - `AppBar`: `header: true`, title — название песни.
  - `ChordDisplay`: `liveRegion: true`, при смене аккорда — `announce("Аккорд A minor")`.
  - `LyricsDisplay`: `liveRegion: true`, при смене слова — `announce("Как")`. Но: это может быть слишком шумно. **Решение:** настройка "VoiceOver для текста" (default: off). Если включено — анонсировать каждое новое слово.
  - `Controls`: кнопка "Начать прослушивание" с `button: true`, `onTapHint: "Дважды тапните, чтобы начать распознавание речи"`.
- **Semantics на SongListScreen:**
  - Каждая карточка: `Semantics.button`, label: "Песня о ветре, Виктор Цой. Дважды тапните, чтобы открыть. Свайп влево, чтобы удалить."
- **Semantics на AddSongScreen:**
  - Каждый `TextField` с `label` и `hint`.
  - Ошибки валидации — `Semantics.liveRegion: true`.

### 4.4 Доступность без звука / голоса

- Приложение не требует звука для работы (только для метронома, который визуален).
- Если пользователь немой / шепчет — Vosk может не распознать. **Решение:** ручной режим (future): тап по слову вручную продвигает подсветку.

---

## 5. Edge Cases & Error States

### 5.1 Нет песен (Empty State)

**Когда:** Первый запуск, удалены все песни, поиск не дал результатов.

**UI:**
- Центрированная колонка.
- Иконка: `Icons.music_off`, 64dp, color `textDisabled`.
- Заголовок: "Нет песен", 20sp, `textPrimary`.
- Описание: "Добавьте свою первую песню или импортируйте из библиотеки.", 16sp, `textSecondary`.
- Кнопка: "Добавить песню" (PrimaryButton).
- Для поиска: "По запросу 'foo' ничего не найдено" + кнопка "Сбросить поиск".

**Действие:** Тап на кнопку → `AddSongScreen`.

---

### 5.2 Разрешение на микрофон отклонено

**Когда:** Пользователь нажал "▶ Начать", но `Permission.microphone` == `denied`.

**UI:**
- `showDialog` с заголовком "Нужен доступ к микрофону".
- Описание: "Приложение слушает ваш голос, чтобы подсвечивать текст. Без разрешения это работать не будет."
- Кнопки:
  - "Открыть настройки" → `openAppSettings()` (если permanently denied).
  - "Попробовать снова" → `Permission.microphone.request()`.
  - "Отмена" → закрыть диалог.

**Если permanently denied:**
- Вместо диалога — `SnackBar`: "Разрешите доступ к микрофону в настройках телефона" + кнопка "Открыть настройки".
- На `PlayerScreen` — вместо кнопки "▶ Начать" показывать `IconButton` с иконкой `Icons.mic_off` и tooltip "Микрофон недоступен".

---

### 5.3 Модель Vosk не загружена

**Когда:** Пользователь нажал "▶ Начать", модель отсутствует в `getApplicationDocumentsDirectory()`.

**UI:**
- `showModalBottomSheet` с заголовком "Загрузка модели".
- `LinearProgressIndicator` (indeterminate если размер неизвестен, determinate если знаем).
- Текст: "Загрузка модели распознавания речи (~50 МБ)..."
- Кнопка "Отмена" (останавливает загрузку, закрывает bottom sheet).

**Если загрузка не удалась (нет сети, ошибка):**
- `SnackBar`: "Не удалось загрузить модель. Проверьте подключение к интернету."
- Кнопка "Повторить".
- На PlayerScreen — заменить кнопку "▶" на "⬇ Загрузить модель" (SecondaryButton).

**Если отменено пользователем:**
- `SnackBar`: "Модель можно загрузить позже через настройки" (если будет пункт).

---

### 5.4 Низкая уверенность распознавания

**Когда:** Vosk вернул результат, но `confidence < 0.6` (или частичный результат).

**UI:**
- **PlayerScreen:** Индикатор confidence в `Controls`:
  - `> 0.8`: пульсирующий круг `secondary`.
  - `0.5 - 0.8`: пульсирующий круг `primary` (жёлтый в Material, но у нас — `primary`).
  - `< 0.5`: круг `error`, медленная пульсация.
- **Подсветка:** Не прыгать. Если confidence низкий — удерживать текущую позицию. Не обновлять `currentPosition`.
- **Пользователю:** Ничего не показывать (чтобы не отвлекать). Только визуальный индикатор качества.
- **Если confidence низкий > 5 секунд:** Показать `SnackBar`: "Не слышно голоса. Проверьте, что микрофон не закрыт." (auto-hide 3s).

---

### 5.5 Пустой текст песни

**Когда:** Песня загружена, но `sections` пустой или все `lines` пустые.

**UI на PlayerScreen:**
- Вместо `LyricsDisplay` — `EmptyStateWidget`:
  - Иконка: `Icons.text_snippet`, 48dp, `textDisabled`.
  - Текст: "В этой песне нет текста."
- `ChordDisplay` — пустой (или "Нет аккордов").
- Кнопка "▶" — disabled (некуда подсвечивать).
- `SnackBar`: "Текст песни пуст. Отредактируйте песню." + кнопка "Редактировать".

**UI на AddSongScreen:**
- Валидация: не позволить сохранить пустой текст. `errorText: "Введите текст песни"`.

---

### 5.6 Дополнительные edge cases

| Сценарий | Поведение |
|----------|-----------|
| Пользователь удаляет песню, которая сейчас открыта в Player | Pop до SongListScreen, SnackBar "Песня удалена" |
| Поворот экрана (Landscape) | PlayerScreen: `ChordDisplay` слева (1/3 ширины), `LyricsDisplay` справа (2/3). Остальные экраны — portrait lock (опционально). |
| Системная тема меняется | Приложение использует свою тему, игнорирует системную (пользователь выбирает в настройках, default = dark). |
| Очень длинное название песни | `TextOverflow.ellipsis`, `maxLines: 1`. В полном имени — показать полностью в `AddSongScreen`. |
| Очень длинный текст песни (>1000 слов) | `ListView.builder` с lazy loading слов. FuzzyMatcher сканирует окно `±50` слов, а не всю песню. |
| Быстрое переключение песен | `SpeechRecognizer.stopListening()` перед `dispose()`. Сброс `currentPositionProvider` в `null`. |
| Батарея низкая | Не предупреждать (Vosk не жрёт много), но метроном + микрофон — drain. Можно future-фичу. |

---

## 6. Assets & Resources

### 6.1 Иконки (Material Icons)

| Иконка | Имя | Где используется |
|--------|-----|------------------|
| 🎸 | — | Branding (не иконка) |
| ➕ | `Icons.add` | FAB на SongListScreen |
| 🔍 | `Icons.search` | SearchBar |
| ⚙️ | `Icons.settings` | AppBar actions |
| ♩ | `Icons.music_note` | Metronome button |
| ▶ | `Icons.play_arrow` | Play button |
| ■ | `Icons.stop` | Stop button |
| ← | `Icons.arrow_back` | Back |
| ✕ | `Icons.close` | Close (AddSongScreen) |
| 💾 | `Icons.save` | Save (AddSongScreen) |
| 🗑️ | `Icons.delete` | Swipe-to-delete background |
| 🎤 | `Icons.mic` | Microphone status |
| 🚫 | `Icons.mic_off` | Mic denied |
| ⬇ | `Icons.download` | Download model |

### 6.2 Изображения

- **Splash screen:** Логотип "karachords" (текст, 32sp, `primary` цвет) на фоне `background`. Duration: 1.5s.
- **Onboarding:** Не используем картинки (сложно поддерживать), используем большие emoji/иконки (`Icons.music_note`, `Icons.mic`, `Icons.wifi_off`) в `primary` цвете, 96dp.

---

## 7. Адаптивность

### 7.1 Малые экраны (< 360dp ширины)

- `SongCard`: уменьшить padding до `12dp`.
- `ChordDisplay`: уменьшить размер шрифта аккордов на 2sp.
- `LyricsDisplay`: `textFontSize` default 20sp вместо 24sp.
- `Controls`: кнопки `48dp` вместо `56dp`.

### 7.2 Большие экраны (> 600dp, планшеты)

- `SongListScreen`: `GridView` с 2 колонками.
- `PlayerScreen`:
  - `ChordDisplay` — слева, фиксированная ширина `200dp`.
  - `LyricsDisplay` — справа, занимает оставшееся.
  - `Controls` — внизу, но шире.

### 7.3 Landscape

- `PlayerScreen`: split layout (аккорды слева, текст справа).
- Остальные экраны: оставить portrait ( force через `SystemChrome.setPreferredOrientations`).

---

## 8. Анимации & Motion

| Анимация | Duration | Curve | Детали |
|----------|----------|-------|--------|
| Screen transition (push) | 300ms | `easeInOutCubic` | Slide from right |
| Screen transition (pop) | 250ms | `easeInOutCubic` | Slide to right |
| FAB appearance | 200ms | `easeOutCubic` | Scale 0→1 |
| SongCard tap ripple | 300ms | — | Material ripple |
| Word highlight change | 200ms | `easeOutCubic` | Scale + color |
| Chord highlight change | 200ms | `easeOutCubic` | Scale + color + shadow |
| Auto-scroll to line | 300ms | `easeInOutCubic` | `animateTo` |
| BPM number change | 150ms | `easeOutBack` | Scale 1.1→1.0 |
| Metronome pulse | `60/BPM` s | `easeInOutSine` | Infinite, opacity + scale |
| BottomSheet open | 300ms | `easeOutCubic` | Slide up |
| BottomSheet close | 200ms | `easeInCubic` | Slide down |
| SnackBar | 250ms | `easeInOutCubic` | Slide up |
| Settings preview update | 150ms | `easeOutCubic` | Crossfade |
| Progress indicator | — | `linear` | Indeterminate for Vosk download |

---

## 9. Flutter Implementation Notes

### 9.1 Тема

```dart
// lib/presentation/theme/app_theme.dart
final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    primary: Color(0xFFBB86FC),
    onPrimary: Color(0xFF000000),
    secondary: Color(0xFF03DAC6),
    error: Color(0xFFCF6679),
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF121212),
    elevation: 0,
    centerTitle: false,
  ),
  cardTheme: CardTheme(
    color: const Color(0xFF1E1E1E),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  sliderTheme: SliderThemeData(
    activeTrackColor: const Color(0xFF03DAC6),
    thumbColor: const Color(0xFF03DAC6),
    overlayColor: const Color(0xFF03DAC6).withOpacity(0.12),
  ),
);
```

### 9.2 Ключевые виджеты для реализации

- `PlayerScreen`: `Column` → `ChordDisplay` (fixed height) + `Expanded` (`LyricsDisplay` in `CustomScrollView`) + `Controls` (fixed height).
- `LyricsDisplay`: `ListView.builder` с элементами `SectionHeader` и `LineWidget`. `LineWidget` — `Wrap` с `WordWidget`.
- `WordWidget`: `AnimatedDefaultTextStyle` + `AnimatedScale` для плавной смены состояния.
- `ChordDisplay`: `SingleChildScrollView` (horizontal) с `Row` из `ChordWidget`.
- `ChordWidget`: `AnimatedContainer` для фона + `AnimatedDefaultTextStyle` для текста.

### 9.3 State → UI Mapping

```dart
// PlayerScreen build
final song = ref.watch(currentSongProvider);
final position = ref.watch(currentPositionProvider);
final settings = ref.watch(songSettingsProvider);

return Scaffold(
  appBar: KarachordsAppBar(title: song.title),
  body: Column(
    children: [
      ChordDisplay(
        song: song,
        currentPosition: position,
        settings: settings,
      ),
      Expanded(
        child: LyricsDisplay(
          song: song,
          currentPosition: position,
          settings: settings,
        ),
      ),
      PlayerControls(
        isListening: ref.watch(speechRecognizerProvider).isListening,
        onToggle: () => ref.read(speechRecognizerProvider).toggle(),
      ),
    ],
  ),
);
```

### 9.4 Responsive helpers

```dart
// Полезные константы
const kSpaceXs = 4.0;
const kSpaceSm = 8.0;
const kSpaceMd = 16.0;
const kSpaceLg = 24.0;
const kSpaceXl = 32.0;
const kSpace2xl = 48.0;

const kBorderRadiusSm = 8.0;
const kBorderRadiusMd = 12.0;
const kBorderRadiusLg = 16.0;

const kMinTouchTarget = 48.0;
const kFabSize = 56.0;
const kAppBarHeight = 56.0;
const kPlayerControlsHeight = 80.0;
const kChordDisplayHeight = 120.0;
```

---

## 10. Changelog

| Версия | Дата | Изменения |
|--------|------|-----------|
| 1.0 | 2026-05-24 | Начальная версия. Тёмная тема, 5 экранов, accessibility, edge cases. |

---

## Приложение: Quick Reference — Цвета

```
Background:       #121212
Surface:          #1E1E1E
SurfaceVariant:   #2C2C2C
Primary:          #BB86FC
PrimaryContainer: #4A3868
OnPrimary:        #000000
Secondary:        #03DAC6
Error:            #CF6679
TextPrimary:      #FFFFFF
TextSecondary:    #B3B3B3
TextDisabled:     #666666
Divider:          #3A3A3A
```

## Приложение: Quick Reference — Размеры

```
AppBar:              56dp
FAB:                 56dp circle
IconButton (small):  48dp
IconButton (large):  56dp
SongCard padding:    16dp
TextField padding:   16dp
Player controls:     80dp
Chord display:       120dp
Border radius (card):12dp
Border radius (btn): 12dp
Min touch target:    48dp
```
