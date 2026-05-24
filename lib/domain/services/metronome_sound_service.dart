import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';

/// Generates and plays a short click sound for the metronome.
///
/// Uses [FlutterSoundPlayer] with an in-memory WAV buffer.
/// Falls back to system click sound on error.
class MetronomeSoundService {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _player.openPlayer();
    _initialized = true;
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    await _player.closePlayer();
    _initialized = false;
  }

  Future<void> playClick() async {
    if (!_initialized) {
      SystemSound.play(SystemSoundType.click);
      return;
    }
    try {
      final buffer = _generateClickWav();
      await _player.startPlayer(
        fromDataBuffer: buffer,
        codec: Codec.pcm16WAV,
      );
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  Uint8List _generateClickWav() {
    const sampleRate = 44100;
    const durationMs = 30;
    final sampleCount = (sampleRate * durationMs ~/ 1000);
    final samples = Int16List(sampleCount);
    for (int i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      final envelope = math.exp(-t * 150);
      samples[i] = (32000 * envelope * (i.isEven ? 1.0 : -0.8)).toInt();
    }
    return _encodeWav(samples, sampleRate);
  }

  Uint8List _encodeWav(Int16List samples, int sampleRate) {
    final byteData = ByteData(samples.length * 2 + 44);
    void writeString(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        byteData.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeString(0, 'RIFF');
    byteData.setUint32(4, 36 + samples.length * 2, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size
    byteData.setUint16(20, 1, Endian.little); // AudioFormat PCM
    byteData.setUint16(22, 1, Endian.little); // NumChannels
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    byteData.setUint16(32, 2, Endian.little); // BlockAlign
    byteData.setUint16(34, 16, Endian.little); // BitsPerSample
    writeString(36, 'data');
    byteData.setUint32(40, samples.length * 2, Endian.little);
    for (int i = 0; i < samples.length; i++) {
      byteData.setInt16(44 + i * 2, samples[i], Endian.little);
    }
    return byteData.buffer.asUint8List();
  }
}
