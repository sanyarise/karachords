import 'dart:async';

import '../../domain/repositories/speech_recognizer.dart';

class VoskService implements SpeechRecognizer {
  final _controller = StreamController<String>.broadcast();

  @override
  Stream<String> get transcriptStream => _controller.stream;

  @override
  Future<void> startListening() async {
    // Stub
  }

  @override
  Future<void> stopListening() async {
    // Stub
  }

  @override
  Future<void> dispose() async {
    // Stub
  }
}
