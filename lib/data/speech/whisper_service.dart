import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/repositories/speech_recognizer.dart';

/// Online speech recognizer using the platform's speech-to-text API.
///
/// Requires an internet connection on most devices because the platform
/// recognizer (Google Speech) sends audio to the cloud.
///
/// Used as a fallback when Vosk is unavailable.
class WhisperService implements SpeechRecognizer {
  final SpeechToText _speech = SpeechToText();
  final AppLogger _log = AppLogger();
  final String localeId;

  final StreamController<Transcript> _transcriptController =
      StreamController<Transcript>.broadcast();

  bool _initialized = false;
  bool _isListening = false;

  WhisperService({this.localeId = 'ru_RU'});

  @override
  Stream<Transcript> get transcriptStream => _transcriptController.stream;

  /// Initializes the speech recognizer and requests microphone permission.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    _log.i('[WhisperService] Initializing speech_to_text...');
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      _log.e('[WhisperService] Microphone permission denied: $micStatus');
      throw Exception('Microphone permission denied');
    }
    _log.i('[WhisperService] Microphone permission granted');

    _initialized = await _speech.initialize(
      onError: (error) {
        _log.e('[WhisperService] Speech initialization error', error);
        _transcriptController.addError(error);
      },
      onStatus: (status) {
        _log.d('[WhisperService] Status: $status');
        if (status == 'notListening' && _isListening) {
          _isListening = false;
          _log.w('[WhisperService] Status changed to notListening while _isListening=true');
        }
      },
    );

    if (!_initialized) {
      _log.e('[WhisperService] Speech initialization failed');
      throw Exception('Speech recognition initialization failed');
    }
    _log.i('[WhisperService] Initialization complete');
  }

  @override
  Future<void> startListening() async {
    _log.i('[WhisperService] startListening called. isListening=$_isListening');
    if (_isListening) {
      _log.w('[WhisperService] Already listening, stopping first');
      await stopListening();
    }

    await _ensureInitialized();

    _isListening = true;

    _log.i('[WhisperService] Starting listen (localeId=ru_RU, partialResults=true)');
    await _speech.listen(
      onResult: _onResult,
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: localeId,
      ),
      onSoundLevelChange: (level) {
        _log.d('[WhisperService] Sound level: ${level.toStringAsFixed(2)}');
      },
    );
  }

  void _onResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords.trim();
    final confidence = result.confidence;
    final isFinal = result.finalResult;
    if (text.isNotEmpty) {
      _log.i('[WhisperService] Result (final=$isFinal, confidence=${confidence.toStringAsFixed(2)}): "$text"');
      _transcriptController.add(Transcript(text, isFinal: isFinal));
    }
  }

  @override
  Future<void> stopListening() async {
    _log.i('[WhisperService] stopListening called. isListening=$_isListening');
    _isListening = false;
    await _speech.stop();
    _log.i('[WhisperService] speech.stop() called');
  }

  @override
  Future<void> dispose() async {
    _log.i('[WhisperService] dispose called');
    _isListening = false;
    await _speech.cancel();
    await _transcriptController.close();
    _log.i('[WhisperService] Dispose complete');
  }
}
