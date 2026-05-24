import '../../domain/models/chord.dart';
import '../../domain/models/line.dart';
import '../../domain/models/section.dart';
import '../../domain/models/song.dart';
import '../../domain/models/word.dart';

/// Parses ChordPro formatted text into a [Song].
///
/// Supported directives:
/// - `{title: ...}` / `{t: ...}`
/// - `{artist: ...}` / `{a: ...}`
/// - `{start_of_verse}`, `{start_of_chorus}`, `{start_of_bridge}`
/// - `{end_of_verse}`, `{end_of_chorus}`, `{end_of_bridge}`
///
/// Inline chords are written as `[ChordName]`, e.g. `[Am]Слово`.
class ChordProParser {
  static final RegExp _directivePattern = RegExp(r'\{(\w+)(?::\s*(.*?))?\}');
  static final RegExp _chordPattern = RegExp(r'\[([^\]]+)\]');

  Song parse(String input, {String id = 'parsed_song'}) {
    final lines = input.split('\n');
    String title = 'Unknown';
    String artist = 'Unknown';
    int? bpm;

    final rawSections = <_RawSection>[];
    _RawSection? currentSection;
    final pendingLines = <String>[];

    bool inDirectiveBlock = false;

    for (var rawLine in lines) {
      final line = rawLine.trimRight();
      final trimmed = line.trim();

      // Directives
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        final match = _directivePattern.firstMatch(trimmed);
        if (match != null) {
          final directive = match.group(1)!.toLowerCase();
          final value = match.group(2) ?? '';

          switch (directive) {
            case 'title':
            case 't':
              title = value.trim();
              continue;
            case 'artist':
            case 'a':
            case 'composer':
              artist = value.trim();
              continue;
            case 'bpm':
              bpm = int.tryParse(value.trim());
              continue;
            case 'start_of_verse':
              _flushPending(pendingLines, currentSection, rawSections);
              pendingLines.clear();
              currentSection = _RawSection(
                type: SectionType.verse,
                label: value.trim().isEmpty ? null : value.trim(),
              );
              inDirectiveBlock = true;
              continue;
            case 'start_of_chorus':
              _flushPending(pendingLines, currentSection, rawSections);
              pendingLines.clear();
              currentSection = _RawSection(
                type: SectionType.chorus,
                label: value.trim().isEmpty ? null : value.trim(),
              );
              inDirectiveBlock = true;
              continue;
            case 'start_of_bridge':
              _flushPending(pendingLines, currentSection, rawSections);
              pendingLines.clear();
              currentSection = _RawSection(
                type: SectionType.bridge,
                label: value.trim().isEmpty ? null : value.trim(),
              );
              inDirectiveBlock = true;
              continue;
            case 'end_of_verse':
            case 'end_of_chorus':
            case 'end_of_bridge':
            case 'end_of_sot':
              _flushPending(pendingLines, currentSection, rawSections);
              pendingLines.clear();
              currentSection = null;
              inDirectiveBlock = false;
              continue;
          }
        }
      }

      if (trimmed.isEmpty) {
        if (!inDirectiveBlock) {
          _flushPending(pendingLines, currentSection, rawSections);
          pendingLines.clear();
          currentSection = null;
        }
        continue;
      }

      pendingLines.add(line);
    }

    _flushPending(pendingLines, currentSection, rawSections);

    // If no sections were created, treat all pending lines as a single verse.
    if (rawSections.isEmpty && pendingLines.isNotEmpty) {
      rawSections.add(
        _RawSection(
          type: SectionType.verse,
          lines: pendingLines.map(_parseLine).toList(),
        ),
      );
    }

    // Detect section types for sections without explicit directives.
    for (var i = 0; i < rawSections.length; i++) {
      final rs = rawSections[i];
      if (rs.type == SectionType.other && rs.lines.isNotEmpty) {
        rawSections[i] = rs.copyWith(
          type: _detectSectionTypeFromLines(rs.lines),
        );
      }
    }

    final sections = rawSections
        .map(
          (rs) => Section(
            type: rs.type,
            label: rs.label,
            lines: rs.lines,
          ),
        )
        .toList();

    return Song(
      id: id,
      title: title,
      artist: artist,
      bpm: bpm,
      sections: sections,
      isBuiltIn: false,
    );
  }

  void _flushPending(
    List<String> pending,
    _RawSection? current,
    List<_RawSection> sections,
  ) {
    if (pending.isEmpty) return;
    final parsed = pending.map(_parseLine).toList();
    if (current != null) {
      current.lines.addAll(parsed);
    } else {
      final type = _detectSectionTypeFromContent(pending);
      sections.add(
        _RawSection(type: type, lines: parsed),
      );
    }
    pending.clear();
  }

  Line _parseLine(String line) {
    final chordMatches = _chordPattern.allMatches(line).toList();
    return Line(words: _rebuildWords(line, chordMatches));
  }

  List<Word> _rebuildWords(String line, List<RegExpMatch> chordMatches) {
    final words = <Word>[];
    var lastEnd = 0;

    for (var i = 0; i < chordMatches.length; i++) {
      final match = chordMatches[i];
      final chord = Chord(name: match.group(1)!, position: 0);
      final chordStart = match.start;
      final chordEnd = match.end;

      // Text between previous chord and this chord
      if (chordStart > lastEnd) {
        final text = line.substring(lastEnd, chordStart);
        for (final w in text.split(RegExp(r'\s+'))) {
          if (w.isNotEmpty) words.add(Word(text: w));
        }
      }

      // Text after this chord until next chord or end of line
      final nextStart =
          i + 1 < chordMatches.length ? chordMatches[i + 1].start : line.length;
      final textAfter = line.substring(chordEnd, nextStart);
      final firstWord = textAfter.split(RegExp(r'\s+')).firstWhere(
            (s) => s.isNotEmpty,
            orElse: () => '',
          );

      if (firstWord.isNotEmpty) {
        words.add(Word(text: firstWord, chords: [chord]));
        final remainder = textAfter.substring(textAfter.indexOf(firstWord) + firstWord.length);
        for (final w in remainder.split(RegExp(r'\s+'))) {
          if (w.isNotEmpty) words.add(Word(text: w));
        }
        lastEnd = nextStart;
      } else {
        words.add(Word(text: '', chords: [chord]));
        lastEnd = chordEnd;
      }
    }

    if (lastEnd < line.length) {
      final text = line.substring(lastEnd);
      for (final w in text.split(RegExp(r'\s+'))) {
        if (w.isNotEmpty) words.add(Word(text: w));
      }
    }

    return words;
  }

  SectionType _detectSectionTypeFromContent(List<String> lines) {
    final text = lines.join(' ').toLowerCase();
    return _detectSectionType(text);
  }

  SectionType _detectSectionTypeFromLines(List<Line> lines) {
    final text = lines
        .expand((l) => l.words)
        .map((w) => w.text)
        .join(' ')
        .toLowerCase();
    return _detectSectionType(text);
  }

  SectionType _detectSectionType(String text) {
    if (text.contains('припев') ||
        text.contains('chorus') ||
        text.contains('refren')) {
      return SectionType.chorus;
    }
    if (text.contains('бридж') || text.contains('bridge')) {
      return SectionType.bridge;
    }
    if (text.contains('куплет') ||
        text.contains('verse') ||
        text.contains('strofa')) {
      return SectionType.verse;
    }
    return SectionType.other;
  }
}

class _RawSection {
  SectionType type;
  String? label;
  final List<Line> lines;

  _RawSection({required this.type, this.label, List<Line>? lines})
      : lines = lines ?? [];

  _RawSection copyWith({SectionType? type, String? label, List<Line>? lines}) {
    return _RawSection(
      type: type ?? this.type,
      label: label ?? this.label,
      lines: lines ?? this.lines,
    );
  }
}
