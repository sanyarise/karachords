import 'word.dart';

class Line {
  final List<Word> words;

  const Line({
    required this.words,
  });

  Line copyWith({
    List<Word>? words,
  }) {
    return Line(
      words: words ?? this.words,
    );
  }

  Map<String, dynamic> toJson() => {
        'words': words.map((w) => w.toJson()).toList(),
      };

  factory Line.fromJson(Map<String, dynamic> json) => Line(
        words: (json['words'] as List<dynamic>)
            .map((w) => Word.fromJson(w as Map<String, dynamic>))
            .toList(),
      );
}
