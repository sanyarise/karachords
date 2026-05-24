class Chord {
  final String name;
  final int position;

  const Chord({
    required this.name,
    required this.position,
  });

  Chord copyWith({
    String? name,
    int? position,
  }) {
    return Chord(
      name: name ?? this.name,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'position': position,
      };

  factory Chord.fromJson(Map<String, dynamic> json) => Chord(
        name: json['name'] as String,
        position: json['position'] as int,
      );
}
