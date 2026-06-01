import 'package:flutter/services.dart';

/// Platform service that keeps the screen awake while the player is active.
///
/// Uses a MethodChannel to call Android's `FLAG_KEEP_SCREEN_ON`.
class WakelockService {
  static const _channel = MethodChannel('com.karachords/wakelock');

  static Future<void> enable() async {
    try {
      await _channel.invokeMethod('enable');
    } catch (_) {
      // Ignore platform errors.
    }
  }

  static Future<void> disable() async {
    try {
      await _channel.invokeMethod('disable');
    } catch (_) {
      // Ignore platform errors.
    }
  }
}
