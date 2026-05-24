abstract class SpeechRecognizer {
  Stream<String> get transcriptStream;
  Future<void> startListening();
  Future<void> stopListening();
  Future<void> dispose();
}
