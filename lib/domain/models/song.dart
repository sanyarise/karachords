import 'section.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final int? bpm;
  final List<Section> sections;
  final bool isBuiltIn;

  const Song({
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
