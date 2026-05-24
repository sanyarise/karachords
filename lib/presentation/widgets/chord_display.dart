import 'package:flutter/material.dart';
import '../../domain/models/chord.dart';
import '../../domain/models/song_settings.dart';
import '../theme/app_theme.dart';
import '../theme/constants.dart';
import 'chord_widget.dart';
import 'highlight_state.dart';

/// Data class pairing a [Chord] with its current [HighlightState].
class ChordDisplayItem {
  final Chord chord;
  final HighlightState state;

  const ChordDisplayItem({
    required this.chord,
    required this.state,
  });
}

/// Horizontal chord strip shown at the top of the player screen.
///
/// Displays the current chord plus the next 2–3 chords with animated
/// highlighting. Previous chords scroll out of view to the left.
class ChordDisplay extends StatelessWidget {
  final List<ChordDisplayItem> items;
  final SongSettings settings;

  const ChordDisplay({
    super.key,
    required this.items,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kChordDisplayHeight,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(kBorderRadiusLg),
          bottomRight: Radius.circular(kBorderRadiusLg),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: kSpaceMd),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: items.map((item) {
            return Container(
              constraints: const BoxConstraints(
                minWidth: 64,
                minHeight: 80,
              ),
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(horizontal: kSpaceSm),
              child: ChordWidget(
                chord: item.chord,
                state: item.state,
                settings: settings,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
