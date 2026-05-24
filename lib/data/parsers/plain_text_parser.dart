import '../../domain/models/chord.dart';
import '../../domain/models/line.dart';
import '../../domain/models/section.dart';
import '../../domain/models/song.dart';
import '../../domain/models/word.dart';

/// Parses plain text with chord lines into a [Song].
///
/// Expected format: alternating lines where the first line contains
/// chords positioned above the words, and the second line contains lyrics.
///
/// Example:
/// ```
///      Am        C
/// Песен ещё не написанных
/// ```
class PlainTextParser {
  static final RegExp _chordToken = RegExp(r'\S+');

  Song parse(String input, {String id = 'parsed_song'}) {
    final allLines = input.split('\n');
    String title = 'Unknown';
    String artist = 'Unknown';
    int? bpm;

    // Try to extract title/artist from first comment-like lines.
    var startIndex = 0;
    for (var i = 0; i < allLines.length; i++) {
      final trimmed = allLines[i].trim();
      if (trimmed.startsWith('#')) {
        final content = trimmed.substring(1).trim();
        if (content.toLowerCase().startsWith('title:')) {
          title = content.substring(6).trim();
        } else if (content.toLowerCase().startsWith('artist:')) {
          artist = content.substring(7).trim();
        } else if (content.toLowerCase().startsWith('bpm:')) {
          bpm = int.tryParse(content.substring(4).trim());
        }
        startIndex = i + 1;
      }
    }

    final body = allLines.sublist(startIndex);
    final sections = _parseSections(body);

    return Song(
      id: id,
      title: title,
      artist: artist,
      bpm: bpm,
      sections: sections,
      isBuiltIn: false,
    );
  }

  List<Section> _parseSections(List<String> lines) {
    final rawBlocks = <List<String>>[];
    var current = <String>[];

    for (final raw in lines) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) {
        if (current.isNotEmpty) {
          rawBlocks.add(List<String>.from(current));
          current.clear();
        }
      } else {
        current.add(raw);
      }
    }
    if (current.isNotEmpty) {
      rawBlocks.add(current);
    }

    return rawBlocks.map((block) {
      final sectionType = _detectSectionType(block);
      final parsedLines = _parseBlock(block);
      return Section(
        type: sectionType,
        lines: parsedLines,
      );
    }).toList();
  }

  List<Line> _parseBlock(List<String> block) {
    // Pair lines: chord line + text line
    final lines = <Line>[];
    for (var i = 0; i < block.length; i += 2) {
      if (i + 1 < block.length) {
        lines.add(_parseChordLinePair(block[i], block[i + 1]));
      } else {
        // Odd line: treat as text-only line.
        lines.add(_parseTextOnlyLine(block[i]));
      }
    }
    return lines;
  }

  Line _parseChordLinePair(String chordLine, String textLine) {
    final words = <Word>[];
    final textWords = _splitWords(textLine);
    if (textWords.isEmpty) {
      return Line(words: words);
    }

    // Find chord positions.
    final chordMatches = _chordToken.allMatches(chordLine).toList();

    // Map each chord to the nearest word starting at or after its position.
    final wordChords = <int, List<Chord>>{};
    for (final match in chordMatches) {
      final chord = Chord(name: match.group(0)!, position: 0);
      final chordPos = match.start;

      // Find the word whose start position is closest to chordPos.
      int? targetWordIndex;
      var bestDist = double.maxFinite;
      for (var wi = 0; wi < textWords.length; wi++) {
        final dist = (textWords[wi].start - chordPos).abs().toDouble();
        if (dist < bestDist) {
          bestDist = dist;
          targetWordIndex = wi;
        }
      }

      if (targetWordIndex != null) {
        wordChords.putIfAbsent(targetWordIndex, () => []).add(chord);
      }
    }

    for (var wi = 0; wi < textWords.length; wi++) {
      words.add(
        Word(
          text: textWords[wi].text,
          chords: wordChords[wi] ?? [],
        ),
      );
    }

    return Line(words: words);
  }

  Line _parseTextOnlyLine(String line) {
    final textWords = _splitWords(line);
    return Line(
      words: textWords.map((tw) => Word(text: tw.text)).toList(),
    );
  }

  List<_WordPos> _splitWords(String line) {
    final result = <_WordPos>[];
    final pattern = RegExp(r'\S+');
    for (final match in pattern.allMatches(line)) {
      result.add(_WordPos(text: match.group(0)!, start: match.start));
    }
    return result;
  }

  SectionType _detectSectionType(List<String> block) {
    final text = block.join(' ').toLowerCase();
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

class _WordPos {
  final String text;
  final int start;

  _WordPos({required this.text, required this.start});
}
