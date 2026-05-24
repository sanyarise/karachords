import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/repositories/speech_recognizer.dart';
import 'vosk_service.dart';
import 'whisper_service.dart';

/// Tries [VoskService] first and falls back to [WhisperService]
/// (online Google Speech) if Vosk is unavailable.
///
/// Consumers see a single [SpeechRecognizer] interface; the fallback
/// is transparent. The first call to [startListening] determines which
/// backend is used for the lifetime of this instance.
class CompositeSpeechRecognizer implements SpeechRecognizer {
  SpeechRecognizer? _primary;
  SpeechRecognizer? _fallback;
  bool _usingFallback = false;

  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();

  StreamSubscription<String>? _primarySub;
  StreamSubscription<String>? _fallbackSub;

  bool _started = false;

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  Future<void> startListening() async {
    if (_started) return;
    _started = true;

    // Try Vosk first.
    try {
      final vosk = VoskService();
      await vosk.startListening();
      _primary = vosk;
      _primarySub = vosk.transcriptStream.listen(
        _transcriptController.add,
        onError: _transcriptController.addError,
      );
      if (kDebugMode) {
        debugPrint('CompositeSpeechRecognizer: using Vosk (offline)');
      }
      return;
    } catch (e, st) {
      debugPrint('Vosk failed, switching to fallback: $e\n$st');
      _usingFallback = true;
    }

    // Fallback to WhisperService (speech_to_text).
    try {
      final whisper = WhisperService();
      await whisper.startListening();
      _fallback = whisper;
      _fallbackSub = whisper.transcriptStream.listen(
        _transcriptController.add,
        onError: _transcriptController.addError,
      );
      if (kDebugMode) {
        debugPrint('CompositeSpeechRecognizer: using Whisper (online fallback)');
      }
    } catch (e, st) {
      debugPrint('Fallback also failed: $e\n$st');
      _transcriptController.addError(e);
    }
  }

  @override
  Future<void> stopListening() async {
    _started = false;
    await _primarySub?.cancel();
    _primarySub = null;
    await _fallbackSub?.cancel();
    _fallbackSub = null;

    try {
      await _primary?.stopListening();
    } catch (_) {}
    try {
      await _fallback?.stopListening();
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    await stopListening();
    await _transcriptController.close();

    try {
      await _primary?.dispose();
    } catch (_) {}
    try {
      await _fallback?.dispose();
    } catch (_) {}
  }

  /// Whether the online fallback is being used because Vosk failed.
  bool get isUsingFallback => _usingFallback;
}
