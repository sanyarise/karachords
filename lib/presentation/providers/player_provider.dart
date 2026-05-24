import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index of the currently active (highlighted) word in the flattened song.
final currentPositionProvider = StateProvider<int>((ref) => 0);

/// Whether the speech recognizer is actively listening.
final isListeningProvider = StateProvider<bool>((ref) => false);
