import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';

import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../theme/constants.dart';
import '../widgets/settings_preview.dart';

class SettingsScreen extends ConsumerWidget {
  final String songId;

  const SettingsScreen({super.key, this.songId = 'preview'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(songSettingsProvider(songId));
    final notifier = ref.read(songSettingsProvider(songId).notifier);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Настройки визуала'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kSpaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsPreview(settings: settings),
            const SizedBox(height: kSpaceLg),
            _buildSectionTitle(context, 'Текст'),
            _FontDropdown(
              value: settings.textFontFamily,
              options: const ['Roboto', 'Open Sans', 'Montserrat'],
              onChanged: (v) => notifier.update(textFontFamily: v),
            ),
            const SizedBox(height: kSpaceMd),
            _SizeSlider(
              label: 'Размер шрифта',
              value: settings.textFontSize,
              min: 14,
              max: 48,
              divisions: 17,
              onChanged: (v) => notifier.update(textFontSize: v),
            ),
            const SizedBox(height: kSpaceMd),
            _WeightSegmentedButton(
              value: settings.textFontWeight,
              onChanged: (v) => notifier.update(textFontWeight: v),
            ),
            const SizedBox(height: kSpaceMd),
            _ColorPickersRow(
              labels: const ['Текущее', 'Следующее', 'Пройденное'],
              colors: [
                settings.textActiveColor,
                settings.textPendingColor,
                settings.textInactiveColor,
              ],
              onChanged: [
                (c) => notifier.update(textActiveColor: c),
                (c) => notifier.update(textPendingColor: c),
                (c) => notifier.update(textInactiveColor: c),
              ],
            ),
            const SizedBox(height: kSpaceLg),
            _buildSectionTitle(context, 'Аккорды'),
            _FontDropdown(
              value: settings.chordsFontFamily,
              options: const ['Roboto Mono', 'Fira Code', 'Source Code Pro'],
              onChanged: (v) => notifier.update(chordsFontFamily: v),
            ),
            const SizedBox(height: kSpaceMd),
            _SizeSlider(
              label: 'Размер шрифта',
              value: settings.chordsFontSize,
              min: 14,
              max: 48,
              divisions: 17,
              onChanged: (v) => notifier.update(chordsFontSize: v),
            ),
            const SizedBox(height: kSpaceMd),
            _WeightSegmentedButton(
              value: settings.chordsFontWeight,
              onChanged: (v) => notifier.update(chordsFontWeight: v),
            ),
            const SizedBox(height: kSpaceMd),
            _ColorPickersRow(
              labels: const ['Текущий', 'Следующий', 'Пройденный'],
              colors: [
                settings.chordsActiveColor,
                settings.chordsPendingColor,
                settings.chordsInactiveColor,
              ],
              onChanged: [
                (c) => notifier.update(chordsActiveColor: c),
                (c) => notifier.update(chordsPendingColor: c),
                (c) => notifier.update(chordsInactiveColor: c),
              ],
            ),
            const SizedBox(height: kSpaceLg),
            _buildSectionTitle(context, 'Общее'),
            _ColorPickerField(
              label: 'Фон экрана',
              color: settings.backgroundColor,
              onChanged: (c) => notifier.update(backgroundColor: c),
            ),
            const SizedBox(height: kSpaceMd),
            _SizeSlider(
              label: 'Межстрочный интервал',
              value: settings.lineSpacing,
              min: 1.0,
              max: 3.0,
              divisions: 20,
              onChanged: (v) => notifier.update(lineSpacing: v),
            ),
            const SizedBox(height: kSpaceLg),
            Center(
              child: TextButton(
                onPressed: () => context.push('/logs'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.onSurface.withValues(alpha: 0.7),
                ),
                child: const Text('Логи отладки'),
              ),
            ),
            const SizedBox(height: kSpaceMd),
            Center(
              child: TextButton(
                onPressed: () => _showResetDialog(context, notifier),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.error,
                ),
                child: const Text('Сбросить настройки'),
              ),
            ),
            const SizedBox(height: kSpaceXl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kSpaceMd),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: AppTheme.onSurface.withValues(alpha: 0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSpaceMd),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: AppTheme.onSurface.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showResetDialog(
    BuildContext context,
    SongSettingsNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить настройки?'),
        content: const Text(
          'Все изменения будут сброшены к значениям по умолчанию.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      notifier.reset();
    }
  }
}

// ── Shared sub-widgets ──────────────────────────────────────

class _FontDropdown extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _FontDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Шрифт',
          style: TextStyle(fontSize: 14, color: AppTheme.onSurface),
        ),
        const SizedBox(height: kSpaceSm),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(kBorderRadiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: kSpaceMd),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppTheme.surface,
              style: const TextStyle(color: AppTheme.onSurface),
              items: options
                  .map(
                    (f) => DropdownMenuItem(value: f, child: Text(f)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SizeSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SizeSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppTheme.onSurface),
        ),
        const SizedBox(height: kSpaceSm),
        Row(
          children: [
            Text(
              '${min.toInt()}',
              style: const TextStyle(fontSize: 12, color: AppTheme.onSurface),
            ),
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                activeColor: AppTheme.secondary,
                inactiveColor: AppTheme.surface,
                onChanged: onChanged,
              ),
            ),
            Text(
              '${max.toInt()}',
              style: const TextStyle(fontSize: 12, color: AppTheme.onSurface),
            ),
          ],
        ),
        Center(
          child: Text(
            '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}${label.contains('интервал') ? 'x' : 'sp'}',
            style: const TextStyle(fontSize: 12, color: AppTheme.onSurface),
          ),
        ),
      ],
    );
  }
}

class _WeightSegmentedButton extends StatelessWidget {
  final FontWeight value;
  final ValueChanged<FontWeight> onChanged;

  const _WeightSegmentedButton({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Жирность',
          style: TextStyle(fontSize: 14, color: AppTheme.onSurface),
        ),
        const SizedBox(height: kSpaceSm),
        SegmentedButton<FontWeight>(
          segments: const [
            ButtonSegment(
              value: FontWeight.w400,
              label: Text('Обычный'),
            ),
            ButtonSegment(
              value: FontWeight.w700,
              label: Text('Полужирный'),
            ),
          ],
          selected: {value},
          onSelectionChanged: (set) => onChanged(set.first),
          style: SegmentedButton.styleFrom(
            backgroundColor: AppTheme.surface,
            selectedBackgroundColor: AppTheme.primaryContainer,
            selectedForegroundColor: AppTheme.onPrimary,
          ),
        ),
      ],
    );
  }
}

class _ColorPickersRow extends StatelessWidget {
  final List<String> labels;
  final List<Color> colors;
  final List<ValueChanged<Color>> onChanged;

  const _ColorPickersRow({
    required this.labels,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Цвета',
          style: TextStyle(fontSize: 14, color: AppTheme.onSurface),
        ),
        const SizedBox(height: kSpaceSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < labels.length; i++)
              _ColorPickerField(
                label: labels[i],
                color: colors[i],
                onChanged: onChanged[i],
              ),
          ],
        ),
      ],
    );
  }
}

class _ColorPickerField extends StatelessWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;

  const _ColorPickerField({
    required this.label,
    required this.color,
    required this.onChanged,
  });

  String _hex(Color c) {
    return '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.onSurface),
        ),
        const SizedBox(height: kSpaceXs),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showColorPicker(context),
            borderRadius: BorderRadius.circular(kBorderRadiusSm),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(kBorderRadiusSm),
                border: Border.all(
                  color: AppTheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: kSpaceXs),
        Text(
          _hex(color),
          style: const TextStyle(fontSize: 10, color: AppTheme.onSurface),
        ),
      ],
    );
  }

  void _showColorPicker(BuildContext context) {
    Color pickerColor = color;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kBorderRadiusLg)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(kSpaceMd),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ColorPicker(
                  pickerColor: pickerColor,
                  onColorChanged: (c) => pickerColor = c,
                  enableAlpha: false,
                  displayThumbColor: true,
                  pickerAreaHeightPercent: 0.7,
                ),
                const SizedBox(height: kSpaceMd),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      onChanged(pickerColor);
                      Navigator.pop(context);
                    },
                    child: const Text('Готово'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
