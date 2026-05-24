class MetronomeSettings {
  final int bpm;
  final bool isPlaying;
  final double volume;

  const MetronomeSettings({
    this.bpm = 120,
    this.isPlaying = false,
    this.volume = 0.8,
  });

  MetronomeSettings copyWith({
    int? bpm,
    bool? isPlaying,
    double? volume,
  }) {
    return MetronomeSettings(
      bpm: bpm ?? this.bpm,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
    );
  }
}
