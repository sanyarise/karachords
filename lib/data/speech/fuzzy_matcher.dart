import '../../domain/models/song.dart';

/// Matches recognized speech text against song lyrics.
///
/// The matcher works on a flattened list of words extracted from a [Song]
/// and searches within a sliding window around the [currentPosition].
class FuzzyMatcher {
  static const int _defaultWindowSize = 25;
  static const int _defaultMaxDistance = 2;
  static const double _defaultMinConfidence = 0.4;
  static const int _driftThreshold = 10;
  static const int _driftMinMatchedWords = 3;
  static const int _maxSongSkip = 2;

  /// Finds the best word position in [song] for the given [recognizedText].
  ///
  /// Returns the index of the first matched word in the flattened song, or
  /// `null` when no confident match is found.
  int? findPosition(
    String recognizedText,
    Song song,
    int currentPosition, {
    int windowSize = _defaultWindowSize,
    int maxDistance = _defaultMaxDistance,
    double minConfidence = _defaultMinConfidence,
  }) {
    final queryWords = _wordsFromText(recognizedText);
    if (queryWords.isEmpty) return null;

    final allWords = flattenSong(song);
    if (allWords.isEmpty) return null;

    final clampedCurrent = currentPosition.clamp(0, allWords.length - 1);
    final windowStart = (clampedCurrent - windowSize).clamp(0, allWords.length);
    final windowEnd = (clampedCurrent + windowSize).clamp(0, allWords.length);

    if (windowStart >= windowEnd) return null;

    final matches = <_Match>{};

    for (int i = windowStart; i < windowEnd; i++) {
      final result = _matchAtPosition(
        queryWords,
        allWords,
        startIndex: i,
        maxDistance: maxDistance,
      );
      if (result.matchedWords > 0) {
        matches.add(result);
      }
    }

    if (matches.isEmpty) return null;

    // Sort by confidence descending, then by distance to currentPosition ascending.
    final sorted = matches.toList()
      ..sort((a, b) {
        final confidenceDiff = b.confidence.compareTo(a.confidence);
        if (confidenceDiff != 0) return confidenceDiff;
        final distA = (a.startIndex - clampedCurrent).abs();
        final distB = (b.startIndex - clampedCurrent).abs();
        return distA.compareTo(distB);
      });

    final best = sorted.first;

    // If the match is far ahead, require stronger evidence.
    if (best.startIndex > clampedCurrent + _driftThreshold) {
      if (best.matchedWords < _driftMinMatchedWords) {
        return null;
      }
    }

    if (best.confidence < minConfidence) {
      return null;
    }

    return best.startIndex;
  }

  /// Normalizes text by lowercasing and removing punctuation.
  static String normalize(String text) {
    return text.toLowerCase().replaceAll(RegExp(r"[^\w\s]"), '').trim();
  }

  /// Flattens a [Song] into a list of normalized words.
  static List<String> flattenSong(Song song) {
    final words = <String>[];
    for (final section in song.sections) {
      for (final line in section.lines) {
        for (final word in line.words) {
          final normalized = normalize(word.text);
          if (normalized.isNotEmpty) {
            words.add(normalized);
          }
        }
      }
    }
    return words;
  }

  /// Computes the Levenshtein distance between [a] and [b].
  static int levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final previous = List<int>.generate(b.length + 1, (i) => i);
    final current = List<int>.filled(b.length + 1, 0);

    for (int i = 0; i < a.length; i++) {
      current[0] = i + 1;
      for (int j = 0; j < b.length; j++) {
        final cost = (a[i] == b[j]) ? 0 : 1;
        current[j + 1] = _min3(
          current[j] + 1,       // deletion
          previous[j + 1] + 1,  // insertion
          previous[j] + cost,   // substitution
        );
      }
      for (int j = 0; j <= b.length; j++) {
        previous[j] = current[j];
      }
    }

    return current[b.length];
  }

  /// Finds the best matching word index in [candidates] for [target].
  ///
  /// Returns a record `(index, confidence)` where [index] is the position
  /// of the best candidate and [confidence] is `1 - distance / maxLength`.
  static ({int index, double confidence}) findBestMatch(
    List<String> candidates,
    String target, {
    int maxDistance = _defaultMaxDistance,
  }) {
    if (candidates.isEmpty) {
      return (index: -1, confidence: 0.0);
    }

    int bestIndex = 0;
    int bestDistance = levenshtein(target, candidates[0]);

    for (int i = 1; i < candidates.length; i++) {
      final distance = levenshtein(target, candidates[i]);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }

    final maxLen = target.length > candidates[bestIndex].length
        ? target.length
        : candidates[bestIndex].length;
    final confidence = maxLen == 0 ? 1.0 : 1.0 - (bestDistance / maxLen);

    return (index: bestIndex, confidence: confidence);
  }

  static List<String> _wordsFromText(String text) {
    final normalized = normalize(text);
    if (normalized.isEmpty) return const [];
    return normalized.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  }

  static _Match _matchAtPosition(
    List<String> queryWords,
    List<String> allWords, {
    required int startIndex,
    required int maxDistance,
  }) {
    int matchedWords = 0;
    int queryIdx = 0;
    int songIdx = startIndex;
    int songSkips = 0;

    while (queryIdx < queryWords.length &&
           songIdx < allWords.length &&
           songSkips <= _maxSongSkip) {
      final distance = levenshtein(queryWords[queryIdx], allWords[songIdx]);
      final maxLen = queryWords[queryIdx].length > allWords[songIdx].length
          ? queryWords[queryIdx].length
          : allWords[songIdx].length;
      // Cap distance by half the word length to avoid false positives on
      // very short words (e.g. single-character words matching each other).
      final allowedDistance =
          maxDistance < (maxLen ~/ 2) ? maxDistance : (maxLen ~/ 2);
      if (distance <= allowedDistance) {
        matchedWords++;
        queryIdx++;
        songIdx++;
      } else {
        // Allow skipping a word in the song text.
        songIdx++;
        songSkips++;
      }
    }

    final confidence = queryWords.isEmpty
        ? 0.0
        : matchedWords / (queryWords.length + songSkips);

    return _Match(
      startIndex: startIndex,
      matchedWords: matchedWords,
      confidence: confidence,
    );
  }

  static int _min3(int a, int b, int c) {
    int min = a;
    if (b < min) min = b;
    if (c < min) min = c;
    return min;
  }
}

class _Match {
  final int startIndex;
  final int matchedWords;
  final double confidence;

  _Match({
    required this.startIndex,
    required this.matchedWords,
    required this.confidence,
  });

  @override
  bool operator ==(Object other) =>
      other is _Match &&
      other.startIndex == startIndex &&
      other.matchedWords == matchedWords &&
      other.confidence == confidence;

  @override
  int get hashCode => Object.hash(startIndex, matchedWords, confidence);
}
