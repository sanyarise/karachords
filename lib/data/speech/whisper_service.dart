import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/repositories/speech_recognizer.dart';

/// Streaming speech recognizer implementation.
///
/// Currently uses [speech_to_text] as the active backend for real-time
/// streaming with low latency. This requires an internet connection on
/// most devices because the platform recognizer (Google Speech) is used.
///
/// TODO: Migrate to whisper.cpp offline once a streaming whisper Flutter
/// package is available or when we implement chunked audio transcription
/// via [whisper_flutter_new].
class WhisperService implements SpeechRecognizer {
  final SpeechToText _speech = SpeechToText();

  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();

  bool _initialized = false;
  bool _isListening = false;

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  /// Initializes the speech recognizer and requests microphone permission.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      throw Exception('Microphone permission denied');
    }

    _initialized = await _speech.initialize(
      onError: (error) {
        _transcriptController.addError(error);
      },
      onStatus: (status) {
        if (status == 'notListening' && _isListening) {
          _isListening = false;
        }
      },
    );

    if (!_initialized) {
      throw Exception('Speech recognition initialization failed');
    }
  }

  @override
  Future<void> startListening() async {
    await _ensureInitialized();

    if (_isListening) {
      await stopListening();
    }

    _isListening = true;

    await _speech.listen(
      onResult: _onResult,
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'ru_RU',
      ),
      onSoundLevelChange: (_) {},
    );
  }

  void _onResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords.trim();
    if (text.isNotEmpty) {
      _transcriptController.add(text);
    }
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
    await _speech.stop();
  }

  @override
  Future<void> dispose() async {
    _isListening = false;
    await _speech.cancel();
    await _transcriptController.close();
  }
}
