import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/parsers/chordpro_parser.dart';
import '../../data/parsers/plain_text_parser.dart';
import '../../domain/models/song.dart';
import '../providers/providers.dart';
import '../providers/song_list_provider.dart';
import '../theme/app_theme.dart';
import '../theme/constants.dart';

enum _SongFormat { chordPro, plainText }

class AddSongScreen extends ConsumerStatefulWidget {
  final Song? initialSong;

  const AddSongScreen({super.key, this.initialSong});

  @override
  ConsumerState<AddSongScreen> createState() => _AddSongScreenState();
}

class _AddSongScreenState extends ConsumerState<AddSongScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _bpmController = TextEditingController();
  final _textController = TextEditingController();
  final _textFocusNode = FocusNode();

  _SongFormat _format = _SongFormat.chordPro;
  bool _isDirty = false;
  Timer? _draftSaveTimer;

  static const String _draftKey = 'add_song_draft';
  static const String _draftFormatKey = 'add_song_draft_format';

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_markDirty);
    _artistController.addListener(_markDirty);
    _bpmController.addListener(_markDirty);
    _textController.addListener(_markDirty);

    final song = widget.initialSong;
    if (song != null) {
      _titleController.text = song.title;
      _artistController.text = song.artist;
      _bpmController.text = song.bpm?.toString() ?? '';
      _textController.text = _reconstructText(song);
    } else {
      _loadDraft();
    }
  }

  /// Reconstructs raw text from a parsed song for editing.
  String _reconstructText(Song song) {
    final buffer = StringBuffer();
    for (final section in song.sections) {
      for (final line in section.lines) {
        for (final word in line.words) {
          for (final chord in word.chords) {
            buffer.write('[${chord.name}]');
          }
          buffer.write(word.text);
          buffer.write(' ');
        }
        buffer.write('\n');
      }
      buffer.write('\n');
    }
    return buffer.toString().trim();
  }

  @override
  void dispose() {
    _titleController.removeListener(_markDirty);
    _artistController.removeListener(_markDirty);
    _bpmController.removeListener(_markDirty);
    _textController.removeListener(_markDirty);
    _titleController.dispose();
    _artistController.dispose();
    _bpmController.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    _draftSaveTimer?.cancel();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
    _scheduleDraftSave();
  }

  void _scheduleDraftSave() {
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(seconds: 5), _saveDraft);
  }

  Future<void> _saveDraft() async {
    if (!_isDirty) return;
    final prefs = await SharedPreferences.getInstance();
    final draft = {
      'title': _titleController.text,
      'artist': _artistController.text,
      'bpm': _bpmController.text,
      'text': _textController.text,
      'format': _format.name,
    };
    await prefs.setString(_draftKey, draft.toString());
    await prefs.setString(_draftFormatKey, _format.name);
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftJson = prefs.getString(_draftKey);
    if (draftJson == null || draftJson.isEmpty) return;

    final formatName = prefs.getString(_draftFormatKey);
    final restoredFormat = formatName == _SongFormat.plainText.name
        ? _SongFormat.plainText
        : _SongFormat.chordPro;

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Восстановить черновик?',
          style: TextStyle(color: AppTheme.onSurface),
        ),
        content: const Text(
          'Найден несохранённый черновик. Восстановить?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            child: const Text('Восстановить'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Simple parsing from toString() — stored as {key: value, ...}
      final map = _parseDraft(draftJson);
      setState(() {
        _titleController.text = map['title'] ?? '';
        _artistController.text = map['artist'] ?? '';
        _bpmController.text = map['bpm'] ?? '';
        _textController.text = map['text'] ?? '';
        _format = restoredFormat;
      });
    }
  }

  Map<String, String> _parseDraft(String draftJson) {
    final map = <String, String>{};
    final regex = RegExp(r"'(\w+)':\s*'([^']*)'");
    for (final match in regex.allMatches(draftJson)) {
      map[match.group(1)!] = match.group(2)!;
    }
    return map;
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
    await prefs.remove(_draftFormatKey);
  }

  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите название';
    }
    if (value.trim().length > 200) {
      return 'Слишком длинное название';
    }
    return null;
  }

  String? _validateBpm(String? value) {
    if (value == null || value.isEmpty) return null;
    final bpm = int.tryParse(value.trim());
    if (bpm == null || bpm < 40 || bpm > 208) {
      return 'BPM: 40–208';
    }
    return null;
  }

  String? _validateText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите текст песни';
    }
    return null;
  }

  String get _formatHint {
    switch (_format) {
      case _SongFormat.chordPro:
        return 'Аккорды в квадратных скобках: [Am]Слово';
      case _SongFormat.plainText:
        return 'Аккорды сверху, текст снизу, выровненные пробелами';
    }
  }

  int? _findErrorLine(String text) {
    if (_format != _SongFormat.chordPro) return null;
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final openCount = '['.allMatches(line).length;
      final closeCount = ']'.allMatches(line).length;
      if (openCount != closeCount) return i;
    }
    return null;
  }

  void _focusErrorLine(int lineIndex) {
    final lines = _textController.text.split('\n');
    var offset = 0;
    for (var i = 0; i < lineIndex && i < lines.length; i++) {
      offset += lines[i].length + 1;
    }
    if (lineIndex < lines.length) {
      final lineLength = lines[lineIndex].length;
      _textController.selection = TextSelection(
        baseOffset: offset,
        extentOffset: offset + lineLength,
      );
      FocusScope.of(context).requestFocus(_textFocusNode);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final rawText = _textController.text;
    final title = _titleController.text.trim();
    final artist = _artistController.text.trim();
    final bpmText = _bpmController.text.trim();
    final bpm = bpmText.isEmpty ? null : int.tryParse(bpmText);
    final isEditing = widget.initialSong != null;
    final id = isEditing
        ? widget.initialSong!.id
        : DateTime.now().millisecondsSinceEpoch.toString();

    try {
      final parsed = _format == _SongFormat.chordPro
          ? ChordProParser().parse(rawText, id: id)
          : PlainTextParser().parse(rawText, id: id);

      final song = parsed.copyWith(
        title: title,
        artist: artist.isEmpty ? 'Unknown' : artist,
        bpm: bpm,
      );

      await ref.read(songRepositoryProvider).saveSong(song);
      ref.invalidate(songListProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? 'Песня обновлена' : 'Песня добавлена')),
      );

      setState(() => _isDirty = false);
      if (!isEditing) await _clearDraft();
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;

      final errorLine = _findErrorLine(rawText);
      if (errorLine != null) {
        _focusErrorLine(errorLine);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка парсинга: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Отменить изменения?',
          style: TextStyle(color: AppTheme.onSurface),
        ),
        content: const Text(
          'Все введённые данные будут потеряны.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Остаться'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() => _isDirty = false);
      context.pop();
    }
  }

  void _showMetronomeBottomSheet() {
    var tempBpm = int.tryParse(_bpmController.text.trim()) ?? 120;
    if (tempBpm < 40) tempBpm = 40;
    if (tempBpm > 208) tempBpm = 208;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kBorderRadiusLg)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(kSpaceMd),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '♩ = $tempBpm',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: kSpaceMd),
                    Slider(
                      value: tempBpm.toDouble(),
                      min: 40,
                      max: 208,
                      divisions: 168,
                      activeColor: AppTheme.secondary,
                      inactiveColor: AppTheme.surface,
                      onChanged: (value) {
                        setModalState(() {
                          tempBpm = value.round();
                        });
                      },
                    ),
                    const SizedBox(height: kSpaceMd),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              tempBpm = (tempBpm - 10).clamp(40, 208);
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.onSurface,
                            side: const BorderSide(color: AppTheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(kBorderRadiusSm),
                            ),
                            minimumSize: const Size(80, kMinTouchTarget),
                          ),
                          child: const Text('-10'),
                        ),
                        const SizedBox(width: kSpaceMd),
                        OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              tempBpm = (tempBpm + 10).clamp(40, 208);
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.onSurface,
                            side: const BorderSide(color: AppTheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(kBorderRadiusSm),
                            ),
                            minimumSize: const Size(80, kMinTouchTarget),
                          ),
                          child: const Text('+10'),
                        ),
                      ],
                    ),
                    const SizedBox(height: kSpaceLg),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _bpmController.text = tempBpm.toString();
      _markDirty();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showDiscardDialog();
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppTheme.onSurface),
            tooltip: 'Закрыть',
            onPressed: () {
              if (_isDirty) {
                _showDiscardDialog();
              } else {
                context.pop();
              }
            },
          ),
          title: Text(
            widget.initialSong != null ? 'Редактировать песню' : 'Добавить песню',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurface,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save, color: AppTheme.onSurface),
              tooltip: 'Сохранить',
              onPressed: _save,
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(kSpaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  controller: _titleController,
                  label: 'Название',
                  hint: 'Введите название...',
                  validator: _validateTitle,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: kSpaceLg),
                _buildTextField(
                  controller: _artistController,
                  label: 'Исполнитель',
                  hint: 'Введите исполнителя...',
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: kSpaceLg),
                _buildBpmField(),
                const SizedBox(height: kSpaceLg),
                _buildFormatToggle(),
                const SizedBox(height: kSpaceLg),
                _buildTextArea(),
                const SizedBox(height: kSpaceLg),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: kSpaceLg,
                      vertical: kSpaceMd,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kBorderRadiusMd),
                    ),
                  ),
                  child: Text(widget.initialSong != null ? 'Сохранить изменения' : 'Добавить песню'),
                ),
                const SizedBox(height: kSpace2xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: kSpaceSm),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          style: const TextStyle(color: AppTheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textDisabled),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kBorderRadiusMd),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kBorderRadiusMd),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kBorderRadiusMd),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kBorderRadiusMd),
              borderSide: const BorderSide(color: AppTheme.error),
            ),
            contentPadding: const EdgeInsets.all(kSpaceMd),
          ),
        ),
      ],
    );
  }

  Widget _buildBpmField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BPM (опционально)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: kSpaceSm),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _bpmController,
                validator: _validateBpm,
                keyboardType: TextInputType.number,
                maxLength: 3,
                style: const TextStyle(color: AppTheme.onSurface),
                decoration: InputDecoration(
                  hintText: '120',
                  hintStyle: const TextStyle(color: AppTheme.textDisabled),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kBorderRadiusMd),
                    borderSide: const BorderSide(color: AppTheme.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kBorderRadiusMd),
                    borderSide: const BorderSide(color: AppTheme.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kBorderRadiusMd),
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kBorderRadiusMd),
                    borderSide: const BorderSide(color: AppTheme.error),
                  ),
                  contentPadding: const EdgeInsets.all(kSpaceMd),
                ),
              ),
            ),
            const SizedBox(width: kSpaceSm),
            IconButton(
              icon: const Icon(Icons.music_note, color: AppTheme.primary),
              tooltip: 'Метроном',
              onPressed: _showMetronomeBottomSheet,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormatToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Формат текста',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: kSpaceSm),
        SegmentedButton<_SongFormat>(
          segments: const [
            ButtonSegment(
              value: _SongFormat.chordPro,
              label: Text('ChordPro'),
            ),
            ButtonSegment(
              value: _SongFormat.plainText,
              label: Text('Plain Text'),
            ),
          ],
          selected: <_SongFormat>{_format},
          onSelectionChanged: (Set<_SongFormat> newSelection) {
            setState(() {
              _format = newSelection.first;
              _isDirty = true;
            });
          },
          style: SegmentedButton.styleFrom(
            backgroundColor: AppTheme.surface,
            foregroundColor: AppTheme.onSurface,
            selectedBackgroundColor: AppTheme.primary,
            selectedForegroundColor: AppTheme.onPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Текст песни',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: kSpaceSm),
        TextFormField(
          controller: _textController,
          focusNode: _textFocusNode,
          validator: _validateText,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          minLines: 8,
          maxLines: null,
          style: const TextStyle(color: AppTheme.onSurface),
          decoration: InputDecoration(
            hintText: _format == _SongFormat.chordPro
                ? '[Am]Как же мне рассказать\n[C]О том, что я люблю'
                : '     Am        C\nПесен ещё не написанных',
            hintStyle: const TextStyle(color: AppTheme.textDisabled),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kBorderRadiusMd),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kBorderRadiusMd),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kBorderRadiusMd),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kBorderRadiusMd),
              borderSide: const BorderSide(color: AppTheme.error),
            ),
            contentPadding: const EdgeInsets.all(kSpaceMd),
          ),
        ),
        const SizedBox(height: kSpaceSm),
        Text(
          _formatHint,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textDisabled,
          ),
        ),
      ],
    );
  }
}
