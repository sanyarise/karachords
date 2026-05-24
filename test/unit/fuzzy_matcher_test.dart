import 'package:flutter_test/flutter_test.dart';
import 'package:karachords/data/speech/fuzzy_matcher.dart';
import 'package:karachords/domain/models/line.dart';
import 'package:karachords/domain/models/section.dart';
import 'package:karachords/domain/models/song.dart';
import 'package:karachords/domain/models/word.dart';

Song _makeSong(List<String> words) {
  return Song(
    id: 'test',
    title: 'Test',
    artist: 'Test',
    sections: [
      Section(
        type: SectionType.verse,
        lines: [
          Line(
            words: words
                .map((w) => Word(text: w, chords: const []))
                .toList(),
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('FuzzyMatcher', () {
    group('normalize', () {
      test('lowercases and strips punctuation', () {
        expect(FuzzyMatcher.normalize('Hello, World!'), 'hello world');
      });

      test('trims whitespace', () {
        expect(FuzzyMatcher.normalize('  Hi there  '), 'hi there');
      });
    });

    group('levenshtein', () {
      test('identical strings', () {
        expect(FuzzyMatcher.levenshtein('abc', 'abc'), 0);
      });

      test('one substitution', () {
        expect(FuzzyMatcher.levenshtein('abc', 'axc'), 1);
      });

      test('one insertion', () {
        expect(FuzzyMatcher.levenshtein('abc', 'abxc'), 1);
      });

      test('one deletion', () {
        expect(FuzzyMatcher.levenshtein('abc', 'ac'), 1);
      });

      test('empty strings', () {
        expect(FuzzyMatcher.levenshtein('', 'abc'), 3);
        expect(FuzzyMatcher.levenshtein('abc', ''), 3);
      });
    });

    group('flattenSong', () {
      test('flattens words in order', () {
        final song = _makeSong(['one', 'two', 'three']);
        expect(FuzzyMatcher.flattenSong(song), ['one', 'two', 'three']);
      });

      test('ignores empty words after normalization', () {
        final song = _makeSong(['hello', '-', 'world']);
        expect(FuzzyMatcher.flattenSong(song), ['hello', 'world']);
      });
    });

    group('findPosition', () {
      test('exact match returns the correct index', () {
        final song = _makeSong(['hello', 'darkness', 'my', 'old', 'friend']);
        final matcher = FuzzyMatcher();
        final pos = matcher.findPosition('darkness my', song, 0);
        expect(pos, 1);
      });

      test('typo with levenshtein distance 1 matches', () {
        final song = _makeSong(['hello', 'darkness', 'my', 'old', 'friend']);
        final matcher = FuzzyMatcher();
        // 'darnkess' is 1 transposition away from 'darkness'
        final pos = matcher.findPosition('darnkess my', song, 0);
        expect(pos, 1);
      });

      test('skipped word in song is handled', () {
        _makeSong([
          'hello',
          'darkness',
          'my',
          'old',
          'friend',
        ]);
        final matcher = FuzzyMatcher();
        // User sings 'hello friend' skipping 'darkness my old'
        // Our matcher allows up to 2 skips in the song side.
        // Since we skip more than 2, we need to set currentPosition near the
        // beginning so that the algorithm aligns on the first word and then
        // skips through the intermediate words.
        // However, with only 2 skips allowed, 'hello friend' won't match
        // perfectly. Let's use a smaller gap.
        final song2 = _makeSong(['hello', 'there', 'old', 'friend']);
        final pos = matcher.findPosition('hello old friend', song2, 0);
        expect(pos, 0);
      });

      test('refrain picks the occurrence closest to currentPosition', () {
        final song = _makeSong([
          'hello',
          'hello',
          'hello',
          'hello',
        ]);
        final matcher = FuzzyMatcher();
        // When current is near index 2, the match should prefer index 2.
        final pos = matcher.findPosition('hello', song, 2);
        expect(pos, 2);
      });

      test('drift beyond threshold requires strong confidence', () {
        final song = _makeSong([
          'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
          'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
          'u', 'v', 'w', 'x', 'y', 'z',
        ]);
        final matcher = FuzzyMatcher();
        // Single word 'z' far ahead with low confidence should be rejected.
        final pos = matcher.findPosition('z', song, 0);
        expect(pos, isNull);
      });

      test('drift is allowed when enough words match', () {
        final song = _makeSong([
          'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
          'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
          'u', 'v', 'w', 'x', 'y', 'z',
        ]);
        final matcher = FuzzyMatcher();
        // Matching 4 words far ahead is strong enough.
        final pos = matcher.findPosition('w x y z', song, 0);
        expect(pos, 22);
      });

      test('no match returns null', () {
        final song = _makeSong(['hello', 'darkness', 'my', 'old', 'friend']);
        final matcher = FuzzyMatcher();
        final pos = matcher.findPosition('completely unrelated text', song, 0);
        expect(pos, isNull);
      });
    });

    group('findBestMatch', () {
      test('returns exact match with perfect confidence', () {
        final candidates = ['apple', 'banana', 'cherry'];
        final result = FuzzyMatcher.findBestMatch(candidates, 'banana');
        expect(result.index, 1);
        expect(result.confidence, 1.0);
      });

      test('returns fuzzy match with reduced confidence', () {
        final candidates = ['apple', 'banana', 'cherry'];
        final result = FuzzyMatcher.findBestMatch(candidates, 'banan');
        expect(result.index, 1);
        expect(result.confidence, lessThan(1.0));
        expect(result.confidence, greaterThan(0.5));
      });

      test('returns -1 for empty candidates', () {
        final result = FuzzyMatcher.findBestMatch([], 'test');
        expect(result.index, -1);
        expect(result.confidence, 0.0);
      });
    });
  });
}
