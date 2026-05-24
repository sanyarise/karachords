import 'line.dart';

enum SectionType {
  verse,
  chorus,
  bridge,
  intro,
  outro,
  preChorus,
  other,
}

class Section {
  final SectionType type;
  final String? label;
  final List<Line> lines;

  const Section({
    required this.type,
    this.label,
    required this.lines,
  });

  Section copyWith({
    SectionType? type,
    String? label,
    List<Line>? lines,
  }) {
    return Section(
      type: type ?? this.type,
      label: label ?? this.label,
      lines: lines ?? this.lines,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'label': label,
        'lines': lines.map((l) => l.toJson()).toList(),
      };

  factory Section.fromJson(Map<String, dynamic> json) => Section(
        type: SectionType.values.byName(json['type'] as String),
        label: json['label'] as String?,
        lines: (json['lines'] as List<dynamic>)
            .map((l) => Line.fromJson(l as Map<String, dynamic>))
            .toList(),
      );
}
