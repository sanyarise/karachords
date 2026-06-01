import 'package:flutter/material.dart';
import '../../domain/models/line.dart';
import '../../domain/models/section.dart';
import '../../domain/models/song_settings.dart';
import '../../domain/models/word.dart';
import '../theme/app_theme.dart';
import '../theme/constants.dart';
import 'chord_widget.dart';
import 'highlight_state.dart';
import 'word_widget.dart';

/// A scrollable lyrics view with section headers, line wrapping, and
/// auto-scroll to the active line.
///
/// The caller supplies [activeSectionIndex] and [activeLineIndex] to
/// drive highlighting and scrolling.
class LyricsDisplay extends StatefulWidget {
  final List<Section> sections;
  final SongSettings settings;
  final int activeSectionIndex;
  final int activeLineIndex;

  const LyricsDisplay({
    super.key,
    required this.sections,
    required this.settings,
    this.activeSectionIndex = 0,
    this.activeLineIndex = 0,
  });

  @override
  State<LyricsDisplay> createState() => _LyricsDisplayState();
}

class _LyricsDisplayState extends State<LyricsDisplay> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _lineKeys = {};

  String _lineKey(int sectionIndex, int lineIndex) => '$sectionIndex:$lineIndex';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LyricsDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeSectionIndex != widget.activeSectionIndex ||
        oldWidget.activeLineIndex != widget.activeLineIndex) {
      _scrollToActiveLine();
    }
  }

  void _scrollToActiveLine() {
    final key = _lineKey(widget.activeSectionIndex, widget.activeLineIndex);
    final lineContext = _lineKeys[key]?.currentContext;
    if (lineContext != null) {
      Scrollable.ensureVisible(
        lineContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        alignment: 0.33, // active line ~1/3 from top
      );
    }
  }

  HighlightState _lineState(int sectionIdx, int lineIdx) {
    if (sectionIdx < widget.activeSectionIndex) {
      return HighlightState.inactive;
    }
    if (sectionIdx > widget.activeSectionIndex) {
      return HighlightState.pending;
    }
    if (lineIdx < widget.activeLineIndex) {
      return HighlightState.inactive;
    }
    if (lineIdx > widget.activeLineIndex) {
      return HighlightState.pending;
    }
    return HighlightState.active;
  }

  int _totalItemCount() {
    int count = 0;
    for (final section in widget.sections) {
      count += 1 + section.lines.length; // header + lines
    }
    return count;
  }

  Widget _buildItem(BuildContext context, int index) {
    int current = 0;
    for (int sIdx = 0; sIdx < widget.sections.length; sIdx++) {
      final section = widget.sections[sIdx];

      // Section header
      if (index == current) {
        final sectionLabel = section.label ?? _defaultSectionLabel(section.type);
        return Padding(
          padding: const EdgeInsets.only(
            top: kSpaceLg,
            bottom: kSpaceSm,
          ),
          child: Text(
            '[$sectionLabel]',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurface,
            ),
          ),
        );
      }
      current++;

      // Lines
      for (int lIdx = 0; lIdx < section.lines.length; lIdx++) {
        if (index == current) {
          final line = section.lines[lIdx];
          final key = _lineKey(sIdx, lIdx);
          _lineKeys.putIfAbsent(key, GlobalKey.new);
          return _LineWidget(
            key: _lineKeys[key],
            line: line,
            settings: widget.settings,
            lineState: _lineState(sIdx, lIdx),
          );
        }
        current++;
      }
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: kSpaceMd)
          .copyWith(bottom: 80),
      itemCount: _totalItemCount(),
      itemBuilder: _buildItem,
    );
  }

  String _defaultSectionLabel(SectionType type) {
    switch (type) {
      case SectionType.verse:
        return 'Куплет';
      case SectionType.chorus:
        return 'Припев';
      case SectionType.bridge:
        return 'Бридж';
      case SectionType.intro:
        return 'Вступление';
      case SectionType.outro:
        return 'Концовка';
      case SectionType.preChorus:
        return 'Предприпев';
      case SectionType.other:
        return 'Другое';
    }
  }
}

/// A single line rendered as a [Wrap] of word+chord columns.
///
/// Each word is displayed as a mini-column: chord name on top, word text
/// below. If a word has no chord, a spacer of equal height is shown to
/// keep vertical alignment consistent across the line.
class _LineWidget extends StatelessWidget {
  final Line line;
  final SongSettings settings;
  final HighlightState lineState;

  const _LineWidget({
    super.key,
    required this.line,
    required this.settings,
    required this.lineState,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kSpaceSm),
      child: Wrap(
        spacing: kSpaceXs,
        runSpacing: kSpaceXs,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          for (final word in line.words) _WordWithChord(
            word: word,
            state: lineState,
            settings: settings,
          ),
        ],
      ),
    );
  }
}

/// A single word with its chord(s) rendered inline above it.
class _WordWithChord extends StatelessWidget {
  final Word word;
  final HighlightState state;
  final SongSettings settings;

  const _WordWithChord({
    required this.word,
    required this.state,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (word.chords.isNotEmpty)
          ChordWidget(
            chord: word.chords.first,
            state: state,
            settings: settings,
          )
        else
          SizedBox(height: settings.chordsFontSize * 1.4),
        WordWidget(
          text: word.text,
          state: state,
          settings: settings,
        ),
      ],
    );
  }
}
