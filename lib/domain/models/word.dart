import 'chord.dart';

class Word {
  final String text;
  final List<Chord> chords;

  const Word({
    required this.text,
    this.chords = const [],
  });

  Word copyWith({
    String? text,
    List<Chord>? chords,
  }) {
    return Word(
      text: text ?? this.text,
      chords: chords ?? this.chords,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'chords': chords.map((c) => c.toJson()).toList(),
      };

  factory Word.fromJson(Map<String, dynamic> json) => Word(
        text: json['text'] as String,
        chords: (json['chords'] as List<dynamic>?)
                ?.map((c) => Chord.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
