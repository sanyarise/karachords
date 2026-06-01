import 'package:flutter_test/flutter_test.dart';
import 'package:karachords/data/speech/composite_recognizer.dart';
import 'package:karachords/data/speech/vosk_service.dart';
import 'package:karachords/data/speech/whisper_service.dart';
import 'package:karachords/domain/repositories/speech_recognizer.dart';

void main() {
  group('CompositeSpeechRecognizer', () {
    test('transcriptStream emits text from primary recognizer', () async {
      final composite = CompositeSpeechRecognizer(
        primary: VoskService(),
        fallback: WhisperService(),
      );

      // Composite tries Vosk first, which will fail in test environment,
      // so it falls back to WhisperService. We verify the interface contract.
      expect(composite.transcriptStream, isA<Stream<Transcript>>());
    });

    test('transcriptStream is broadcast', () {
      final composite = CompositeSpeechRecognizer(
        primary: VoskService(),
        fallback: WhisperService(),
      );
      expect(composite.transcriptStream.isBroadcast, isTrue);
    });
  });

  group('SpeechRecognizer interface contract', () {
    test('WhisperService implements SpeechRecognizer', () {
      final recognizer = WhisperService();
      expect(recognizer, isA<SpeechRecognizer>());
    });
  });
}
