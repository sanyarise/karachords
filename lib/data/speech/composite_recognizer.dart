import 'dart:async';

import '../../core/logging/app_logger.dart';
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
  final SpeechRecognizer _primary;
  final SpeechRecognizer _fallback;
  final AppLogger _log = AppLogger();

  bool _usingFallback = false;

  final StreamController<Transcript> _transcriptController =
      StreamController<Transcript>.broadcast();

  StreamSubscription<Transcript>? _primarySub;
  StreamSubscription<Transcript>? _fallbackSub;

  bool _started = false;

  CompositeSpeechRecognizer({
    required this._primary,
    required this._fallback,
  });

  @override
  Stream<Transcript> get transcriptStream => _transcriptController.stream;

  @override
  Future<void> startListening() async {
    _log.i('[CompositeRecognizer] startListening called. started=$_started');
    if (_started) return;

    await _cancelSubscriptions();
    _started = true;
    _usingFallback = false;

    // Try Vosk first.
    try {
      _log.i('[CompositeRecognizer] Trying VoskService...');
      await _primary.startListening();
      _primarySub = _primary.transcriptStream.listen(
        (transcript) {
          _log.d('[CompositeRecognizer] Vosk transcript: "$transcript"');
          _transcriptController.add(transcript);
        },
        onError: (error) {
          _log.e('[CompositeRecognizer] Vosk stream error', error);
          _transcriptController.addError(error);
        },
      );
      _log.i('[CompositeRecognizer] Using Vosk (offline)');
      return;
    } catch (e, st) {
      _log.e('[CompositeRecognizer] Vosk failed, switching to fallback', e, st);
      _usingFallback = true;
    }

    // Fallback to WhisperService (speech_to_text).
    try {
      _log.i('[CompositeRecognizer] Trying WhisperService fallback...');
      await _fallback.startListening();
      _fallbackSub = _fallback.transcriptStream.listen(
        (transcript) {
          _log.d('[CompositeRecognizer] Whisper transcript: "$transcript"');
          _transcriptController.add(transcript);
        },
        onError: (error) {
          _log.e('[CompositeRecognizer] Whisper stream error', error);
          _transcriptController.addError(error);
        },
      );
      _log.i('[CompositeRecognizer] Using Whisper (online fallback)');
    } catch (e, st) {
      _log.e('[CompositeRecognizer] Fallback also failed', e, st);
      _transcriptController.addError(e);
      _started = false;
    }
  }

  Future<void> _cancelSubscriptions() async {
    await _primarySub?.cancel();
    _primarySub = null;
    await _fallbackSub?.cancel();
    _fallbackSub = null;
  }

  @override
  Future<void> stopListening() async {
    _log.i('[CompositeRecognizer] stopListening called');
    _started = false;
    await _cancelSubscriptions();

    try {
      await _primary.stopListening();
    } catch (e, st) {
      _log.e('[CompositeRecognizer] primary.stop error', e, st);
    }
    try {
      await _fallback.stopListening();
    } catch (e, st) {
      _log.e('[CompositeRecognizer] fallback.stop error', e, st);
    }
  }

  @override
  Future<void> dispose() async {
    _log.i('[CompositeRecognizer] dispose called');
    await stopListening();
    await _transcriptController.close();

    try {
      await _primary.dispose();
    } catch (e, st) {
      _log.e('[CompositeRecognizer] primary.dispose error', e, st);
    }
    try {
      await _fallback.dispose();
    } catch (e, st) {
      _log.e('[CompositeRecognizer] fallback.dispose error', e, st);
    }
    _log.i('[CompositeRecognizer] dispose complete');
  }

  /// Whether the online fallback is being used because Vosk failed.
  bool get isUsingFallback => _usingFallback;
}
