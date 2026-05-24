import 'package:flutter/material.dart';

import '../../domain/models/chord.dart';
import '../../domain/models/song_settings.dart';
import 'chord_widget.dart';
import 'highlight_state.dart';
import 'word_widget.dart';

/// Live preview card for the settings screen.
///
/// Displays two chords (active / pending) and a short lyric line
/// (active / pending / inactive words) using the current [SongSettings].
class SettingsPreview extends StatelessWidget {
  final SongSettings settings;

  const SettingsPreview({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: settings.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChordWidget(
                chord: const Chord(name: 'Am', position: 0),
                state: HighlightState.active,
                settings: settings,
              ),
              const SizedBox(width: 24),
              ChordWidget(
                chord: const Chord(name: 'C', position: 0),
                state: HighlightState.pending,
                settings: settings,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              WordWidget(
                text: 'Как',
                state: HighlightState.active,
                settings: settings,
              ),
              WordWidget(
                text: 'же',
                state: HighlightState.pending,
                settings: settings,
              ),
              WordWidget(
                text: 'мне',
                state: HighlightState.inactive,
                settings: settings,
              ),
              WordWidget(
                text: 'рассказать',
                state: HighlightState.inactive,
                settings: settings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
