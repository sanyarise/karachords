import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/chord.dart';
import '../../domain/models/song_settings.dart';
import 'highlight_state.dart';

/// A single chord pill with animated highlighting.
///
/// The [state] drives color, weight, scale, and shadow transitions.
class ChordWidget extends StatelessWidget {
  final Chord chord;
  final HighlightState state;
  final SongSettings settings;

  const ChordWidget({
    super.key,
    required this.chord,
    required this.state,
    required this.settings,
  });

  Color get _color {
    switch (state) {
      case HighlightState.active:
        return settings.chordsActiveColor;
      case HighlightState.pending:
        return settings.chordsPendingColor;
      case HighlightState.inactive:
        return settings.chordsInactiveColor;
    }
  }

  FontWeight get _weight {
    switch (state) {
      case HighlightState.active:
        return FontWeight.bold;
      case HighlightState.pending:
        return FontWeight.w500;
      case HighlightState.inactive:
        return FontWeight.normal;
    }
  }

  double get _scale {
    switch (state) {
      case HighlightState.active:
        return 1.15;
      case HighlightState.pending:
        return 1.0;
      case HighlightState.inactive:
        return 0.9;
    }
  }

  double get _opacity {
    switch (state) {
      case HighlightState.active:
      case HighlightState.pending:
        return 1.0;
      case HighlightState.inactive:
        return 0.5;
    }
  }

  List<BoxShadow> get _shadow {
    if (state == HighlightState.active) {
      return [
        BoxShadow(
          color: settings.chordsActiveColor.withValues(alpha: 0.3),
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ];
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            boxShadow: _shadow,
          ),
          child: Text(
            chord.name,
            style: GoogleFonts.getFont(
              settings.chordsFontFamily,
              fontSize: settings.chordsFontSize,
              fontWeight: _weight,
              color: _color,
            ),
          ),
        ),
      ),
    );
  }
}
