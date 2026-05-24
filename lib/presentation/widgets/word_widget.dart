import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/song_settings.dart';
import 'highlight_state.dart';

/// A single word from a song line with animated highlighting.
///
/// The [state] drives color, weight, and scale transitions.
class WordWidget extends StatelessWidget {
  final String text;
  final HighlightState state;
  final SongSettings settings;

  const WordWidget({
    super.key,
    required this.text,
    required this.state,
    required this.settings,
  });

  Color get _color {
    switch (state) {
      case HighlightState.active:
        return settings.textActiveColor;
      case HighlightState.pending:
        return settings.textPendingColor;
      case HighlightState.inactive:
        return settings.textInactiveColor;
    }
  }

  FontWeight get _weight {
    switch (state) {
      case HighlightState.active:
        return FontWeight.bold;
      case HighlightState.pending:
      case HighlightState.inactive:
        return FontWeight.normal;
    }
  }

  double get _scale {
    switch (state) {
      case HighlightState.active:
        return 1.05;
      case HighlightState.pending:
      case HighlightState.inactive:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        style: GoogleFonts.getFont(
          settings.textFontFamily,
          fontSize: settings.textFontSize,
          fontWeight: _weight,
          color: _color,
          height: settings.lineSpacing,
        ),
        child: Text(text),
      ),
    );
  }
}
