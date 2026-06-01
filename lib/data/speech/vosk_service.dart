import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:vosk_flutter/vosk_flutter.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/repositories/speech_recognizer.dart';
import 'vosk_model_loader.dart';

/// Offline streaming speech recognizer using Vosk.
///
/// On Android it uses [VoskFlutterPlugin.initSpeechService] for true
/// streaming with partial results. On other platforms (Linux/Windows) it
/// falls back gracefully because the streaming service is not available.
///
/// The recognizer emits both partial and final transcripts on
/// [transcriptStream]. Partial results provide near-real-time feedback
/// (latency ~300-800ms), final results confirm the phrase.
class VoskService implements SpeechRecognizer {
  final VoskModelLoader _modelLoader;
  final AppLogger _log;

  VoskFlutterPlugin? _vosk;
  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;

  StreamSubscription<String>? _partialSub;
  StreamSubscription<String>? _resultSub;

  final StreamController<Transcript> _transcriptController =
      StreamController<Transcript>.broadcast();

  bool _initialized = false;
  bool _isListening = false;

  VoskService({VoskModelLoader? modelLoader, AppLogger? log})
      : _modelLoader = modelLoader ?? VoskModelLoader(),
        _log = log ?? AppLogger();

  @override
  Stream<Transcript> get transcriptStream => _transcriptController.stream;

  @override
  Future<void> startListening() async {
    _log.i('[VoskService] startListening called. isListening=$_isListening');
    if (_isListening) {
      _log.w('[VoskService] Already listening, ignoring startListening');
      return;
    }

    try {
      await _ensureInitialized();
      if (!_initialized) {
        _log.e('[VoskService] Initialization failed, cannot start listening');
        return;
      }

      _isListening = true;
      _log.i('[VoskService] Platform=${Platform.operatingSystem}');

      if (Platform.isAndroid) {
        _log.i('[VoskService] Starting Android streaming via initSpeechService');
        await _startStreaming();
      } else {
        _log.w('[VoskService] Streaming not supported on ${Platform.operatingSystem}');
        _transcriptController.addError(
          Exception('Vosk streaming is only supported on Android.'),
        );
        _isListening = false;
        return;
      }
    } catch (e, st) {
      _log.e('[VoskService] startListening error', e, st);
      _isListening = false;
      _transcriptController.addError(e);
      rethrow;
    }
  }

  @override
  Future<void> stopListening() async {
    _log.i('[VoskService] stopListening called. isListening=$_isListening');
    if (!_isListening) return;
    _isListening = false;

    await _partialSub?.cancel();
    _partialSub = null;
    await _resultSub?.cancel();
    _resultSub = null;

    try {
      await _speechService?.stop();
      _log.i('[VoskService] SpeechService stopped');
    } catch (e, st) {
      _log.e('[VoskService] speechService.stop error', e, st);
    }
  }

  @override
  Future<void> dispose() async {
    _log.i('[VoskService] dispose called');
    await stopListening();
    await _transcriptController.close();

    try {
      await _recognizer?.dispose();
      _log.i('[VoskService] Recognizer disposed');
    } catch (e, st) {
      _log.e('[VoskService] recognizer.dispose error', e, st);
    }
    try {
      _model?.dispose();
      _log.i('[VoskService] Model disposed');
    } catch (e, st) {
      _log.e('[VoskService] model.dispose error', e, st);
    }
    _recognizer = null;
    _model = null;
    _speechService = null;
    _vosk = null;
    _log.i('[VoskService] Dispose complete');
  }

  /// Whether the service is currently listening.
  bool get isListening => _isListening;

  /// Whether Vosk initialized successfully.
  bool get isAvailable => _initialized;

  // ── Internal ───────────────────────────────────────────────

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _log.i('[VoskService] Ensuring initialization...');

    try {
      _vosk = VoskFlutterPlugin.instance();
      _log.i('[VoskService] Got VoskFlutterPlugin instance');

      var modelPath = await _modelLoader.loadModel();
      _log.i('[VoskService] Model loaded from: $modelPath');

      try {
        _model = await _vosk!.createModel(modelPath);
      } on FormatException catch (e) {
        _log.e('[VoskService] Model corrupted (zip?), clearing cache and retrying...', e);
        _modelLoader.clearCache();
        modelPath = await _modelLoader.loadModel();
        _log.i('[VoskService] Retried model loaded from: $modelPath');
        _model = await _vosk!.createModel(modelPath);
      }
      _log.i('[VoskService] Model created');

      _recognizer = await _vosk!.createRecognizer(
        model: _model!,
        sampleRate: 16000,
      );
      _log.i('[VoskService] Recognizer created (sampleRate=16000)');

      _initialized = true;
      _log.i('[VoskService] Initialization complete');
    } catch (e, st) {
      _log.e('[VoskService] Initialization failed', e, st);
      _initialized = false;
      rethrow;
    }
  }

  Future<void> _startStreaming() async {
    if (_vosk == null || _recognizer == null) {
      _log.e('[VoskService] Cannot start streaming: vosk=$_vosk, recognizer=$_recognizer');
      throw StateError('Vosk not initialized: vosk=$_vosk, recognizer=$_recognizer');
    }

    if (_speechService != null) {
      _log.i('[VoskService] Reusing existing SpeechService');
    } else {
      _speechService = await _vosk!.initSpeechService(_recognizer!);
      _log.i('[VoskService] SpeechService initialized');
    }

    _partialSub = _speechService!.onPartial().listen(
      _onPartial,
      onError: _onStreamError,
    );
    _log.i('[VoskService] Subscribed to onPartial stream');

    _resultSub = _speechService!.onResult().listen(
      _onResult,
      onError: _onStreamError,
    );
    _log.i('[VoskService] Subscribed to onResult stream');

    await _speechService!.start();
    _log.i('[VoskService] SpeechService.start() called');
  }

  void _onPartial(String text) {
    final extracted = _extractText(text);
    if (extracted.isNotEmpty) {
      _log.d('[VoskService] Partial: "$extracted"');
      _transcriptController.add(Transcript(extracted, isFinal: false));
    }
  }

  void _onResult(String text) {
    final extracted = _extractText(text);
    if (extracted.isNotEmpty) {
      _log.i('[VoskService] Result: "$extracted"');
      _transcriptController.add(Transcript(extracted, isFinal: true));
    }
  }

  static String _extractText(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    try {
      final json = jsonDecode(trimmed);
      if (json is Map<String, dynamic>) {
        if (json.containsKey('text')) {
          return (json['text'] as String).trim();
        }
        if (json.containsKey('partial')) {
          return (json['partial'] as String).trim();
        }
      }
    } catch (_) {
      // Not JSON, return raw text.
    }
    return trimmed;
  }

  void _onStreamError(Object error) {
    _log.e('[VoskService] Stream error', error);
    _transcriptController.addError(error);
  }
}
