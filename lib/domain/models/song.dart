import 'line.dart';
import 'section.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final int? bpm;
  final List<Section> sections;
  final bool isBuiltIn;

  List<String>? _flattenedWords;
  List<({int sectionIndex, int lineIndex, Line line})>? _flattenedLines;

  /// Lazily computed list of normalized words for fuzzy matching.
  List<String> get flattenedWords {
    if (_flattenedWords != null) return _flattenedWords!;
    final words = <String>[];
    for (final section in sections) {
      for (final line in section.lines) {
        for (final word in line.words) {
          final normalized = word.text
              .toLowerCase()
              .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '')
              .trim();
          if (normalized.isNotEmpty) words.add(normalized);
        }
      }
    }
    _flattenedWords = words;
    return words;
  }

  /// Lazily computed flat list of all lines with their section/line indices.
  List<({int sectionIndex, int lineIndex, Line line})> get flattenedLines {
    if (_flattenedLines != null) return _flattenedLines!;
    final lines = <({int sectionIndex, int lineIndex, Line line})>[];
    for (int s = 0; s < sections.length; s++) {
      for (int l = 0; l < sections[s].lines.length; l++) {
        lines.add((sectionIndex: s, lineIndex: l, line: sections[s].lines[l]));
      }
    }
    _flattenedLines = lines;
    return lines;
  }

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.bpm,
    required this.sections,
    this.isBuiltIn = false,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    int? bpm,
    List<Section>? sections,
    bool? isBuiltIn,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      bpm: bpm ?? this.bpm,
      sections: sections ?? this.sections,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'bpm': bpm,
        'sections': sections.map((s) => s.toJson()).toList(),
        'isBuiltIn': isBuiltIn,
      };

  factory Song.fromJson(Map<String, dynamic> json) => Song(
        id: json['id'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String,
        bpm: json['bpm'] as int?,
        sections: (json['sections'] as List<dynamic>)
            .map((s) => Section.fromJson(s as Map<String, dynamic>))
            .toList(),
        isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      );
}
