/// A recognized speech transcript with a flag indicating whether it is a
/// final (confirmed) result or an intermediate partial result.
class Transcript {
  final String text;
  final bool isFinal;

  Transcript(this.text, {this.isFinal = false});

  @override
  String toString() => 'Transcript("$text", isFinal=$isFinal)';
}

abstract class SpeechRecognizer {
  Stream<Transcript> get transcriptStream;
  Future<void> startListening();
  Future<void> stopListening();
  Future<void> dispose();
}
