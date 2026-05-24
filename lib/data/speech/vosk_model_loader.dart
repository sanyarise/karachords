import 'package:vosk_flutter/vosk_flutter.dart';

/// Loads and caches the Vosk speech recognition model from assets.
///
/// The model is bundled as a zip in `assets/models/` and extracted to the
/// application support directory on first use. Subsequent calls return the
/// cached path.
class VoskModelLoader {
  static const String _assetPath = 'assets/models/vosk-model-small-ru-0.22.zip';

  String? _cachedPath;

  Future<String> loadModel() async {
    if (_cachedPath != null) return _cachedPath!;
    _cachedPath = await ModelLoader().loadFromAssets(_assetPath);
    return _cachedPath!;
  }

  void clearCache() => _cachedPath = null;
}
