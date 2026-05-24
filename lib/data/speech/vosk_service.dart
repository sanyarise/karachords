import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

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

  VoskFlutterPlugin? _vosk;
  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;

  StreamSubscription<String>? _partialSub;
  StreamSubscription<String>? _resultSub;

  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();

  bool _initialized = false;
  bool _isListening = false;

  VoskService({VoskModelLoader? modelLoader})
      : _modelLoader = modelLoader ?? VoskModelLoader();

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  Future<void> startListening() async {
    if (_isListening) return;

    try {
      await _ensureInitialized();
      if (!_initialized) return;

      _isListening = true;

      if (Platform.isAndroid) {
        await _startStreaming();
      } else {
        // Non-Android platforms: streaming service unavailable.
        // Emit a warning and rely on the caller to fall back.
        _transcriptController.addError(
          Exception('Vosk streaming is only supported on Android.'),
        );
        _isListening = false;
        return;
      }
    } catch (e, st) {
      debugPrint('VoskService.startListening error: $e\n$st');
      _isListening = false;
      _transcriptController.addError(e);
    }
  }

  @override
  Future<void> stopListening() async {
    if (!_isListening) return;
    _isListening = false;

    await _partialSub?.cancel();
    _partialSub = null;
    await _resultSub?.cancel();
    _resultSub = null;

    try {
      await _speechService?.stop();
    } catch (e) {
      debugPrint('VoskService speechService.stop error: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await stopListening();

    await _transcriptController.close();

    try {
      await _recognizer?.dispose();
    } catch (e) {
      debugPrint('VoskService recognizer.dispose error: $e');
    }
    try {
      _model?.dispose();
    } catch (e) {
      debugPrint('VoskService model.dispose error: $e');
    }
    _recognizer = null;
    _model = null;
    _speechService = null;
    _vosk = null;
  }

  /// Whether the service is currently listening.
  bool get isListening => _isListening;

  /// Whether Vosk initialized successfully.
  bool get isAvailable => _initialized;

  // ── Internal ───────────────────────────────────────────────

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    try {
      _vosk = VoskFlutterPlugin.instance();

      final modelPath = await _modelLoader.loadModel();
      if (kDebugMode) {
        debugPrint('Vosk model loaded: $modelPath');
      }

      _model = await _vosk!.createModel(modelPath);
      _recognizer = await _vosk!.createRecognizer(
        model: _model!,
        sampleRate: 16000,
      );

      _initialized = true;
    } catch (e, st) {
      debugPrint('VoskService initialization failed: $e\n$st');
      _initialized = false;
      rethrow;
    }
  }

  Future<void> _startStreaming() async {
    if (_vosk == null || _recognizer == null) return;

    _speechService = await _vosk!.initSpeechService(_recognizer!);

    _partialSub = _speechService!.onPartial().listen(
      _onPartial,
      onError: _onStreamError,
    );

    _resultSub = _speechService!.onResult().listen(
      _onResult,
      onError: _onStreamError,
    );

    await _speechService!.start();
  }

  void _onPartial(String text) {
    final trimmed = text.trim();
    if (trimmed.isNotEmpty) {
      _transcriptController.add(trimmed);
    }
  }

  void _onResult(String text) {
    final trimmed = text.trim();
    if (trimmed.isNotEmpty) {
      _transcriptController.add(trimmed);
    }
  }

  void _onStreamError(Object error) {
    debugPrint('VoskService stream error: $error');
    _transcriptController.addError(error);
  }
}
