import 'package:flutter/material.dart';
import '../../domain/models/line.dart';
import '../../domain/models/section.dart';
import '../../domain/models/song_settings.dart';
import '../theme/app_theme.dart';
import '../theme/constants.dart';
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

  HighlightState _wordState(int sectionIdx, int lineIdx, int wordIdx) {
    if (sectionIdx < widget.activeSectionIndex) {
      return HighlightState.inactive;
    }
    if (sectionIdx > widget.activeSectionIndex) {
      return HighlightState.pending;
    }
    // Same section
    if (lineIdx < widget.activeLineIndex) {
      return HighlightState.inactive;
    }
    if (lineIdx > widget.activeLineIndex) {
      return HighlightState.pending;
    }
    // Same line — for now all words on active line are active.
    // In a real implementation this would be driven by word-level index.
    return HighlightState.active;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];

    for (int sIdx = 0; sIdx < widget.sections.length; sIdx++) {
      final section = widget.sections[sIdx];

      // Section header
      final sectionLabel = section.label ?? _defaultSectionLabel(section.type);
      children.add(
        Padding(
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
        ),
      );

      // Lines
      for (int lIdx = 0; lIdx < section.lines.length; lIdx++) {
        final line = section.lines[lIdx];
        final key = _lineKey(sIdx, lIdx);
        _lineKeys.putIfAbsent(key, GlobalKey.new);

        children.add(
          _LineWidget(
            key: _lineKeys[key],
            line: line,
            settings: widget.settings,
            wordStateBuilder: (wIdx) => _wordState(sIdx, lIdx, wIdx),
          ),
        );
      }
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: kSpaceMd)
          .copyWith(bottom: 80),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }

  String _defaultSectionLabel(SectionType type) {
    switch (type) {
      case SectionType.verse:
        return 'Verse';
      case SectionType.chorus:
        return 'Chorus';
      case SectionType.bridge:
        return 'Bridge';
      case SectionType.intro:
        return 'Intro';
      case SectionType.outro:
        return 'Outro';
      case SectionType.preChorus:
        return 'Pre-Chorus';
      case SectionType.other:
        return 'Other';
    }
  }
}

/// A single line rendered as a [Wrap] of [WordWidget]s.
class _LineWidget extends StatelessWidget {
  final Line line;
  final SongSettings settings;
  final HighlightState Function(int wordIndex) wordStateBuilder;

  const _LineWidget({
    super.key,
    required this.line,
    required this.settings,
    required this.wordStateBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kSpaceSm),
      child: Wrap(
        spacing: kSpaceXs,
        runSpacing: kSpaceXs,
        children: [
          for (int i = 0; i < line.words.length; i++)
            WordWidget(
              text: line.words[i].text,
              state: wordStateBuilder(i),
              settings: settings,
            ),
        ],
      ),
    );
  }
}
