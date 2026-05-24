import 'package:flutter/material.dart';

class SongSettings {
  final String songId;
  final String textFontFamily;
  final String chordsFontFamily;
  final double textFontSize;
  final double chordsFontSize;
  final FontWeight textFontWeight;
  final FontWeight chordsFontWeight;
  final Color textActiveColor;
  final Color textPendingColor;
  final Color textInactiveColor;
  final Color chordsActiveColor;
  final Color chordsPendingColor;
  final Color chordsInactiveColor;
  final Color backgroundColor;
  final double lineSpacing;

  const SongSettings({
    required this.songId,
    this.textFontFamily = 'Roboto',
    this.chordsFontFamily = 'Roboto Mono',
    this.textFontSize = 18.0,
    this.chordsFontSize = 16.0,
    this.textFontWeight = FontWeight.normal,
    this.chordsFontWeight = FontWeight.normal,
    this.textActiveColor = const Color(0xFFFFFFFF),
    this.textPendingColor = const Color(0xFFBBBBBB),
    this.textInactiveColor = const Color(0xFF666666),
    this.chordsActiveColor = const Color(0xFFBB86FC),
    this.chordsPendingColor = const Color(0xFF9B66DC),
    this.chordsInactiveColor = const Color(0xFF665686),
    this.backgroundColor = const Color(0xFF121212),
    this.lineSpacing = 1.4,
  });

  SongSettings copyWith({
    String? songId,
    String? textFontFamily,
    String? chordsFontFamily,
    double? textFontSize,
    double? chordsFontSize,
    FontWeight? textFontWeight,
    FontWeight? chordsFontWeight,
    Color? textActiveColor,
    Color? textPendingColor,
    Color? textInactiveColor,
    Color? chordsActiveColor,
    Color? chordsPendingColor,
    Color? chordsInactiveColor,
    Color? backgroundColor,
    double? lineSpacing,
  }) {
    return SongSettings(
      songId: songId ?? this.songId,
      textFontFamily: textFontFamily ?? this.textFontFamily,
      chordsFontFamily: chordsFontFamily ?? this.chordsFontFamily,
      textFontSize: textFontSize ?? this.textFontSize,
      chordsFontSize: chordsFontSize ?? this.chordsFontSize,
      textFontWeight: textFontWeight ?? this.textFontWeight,
      chordsFontWeight: chordsFontWeight ?? this.chordsFontWeight,
      textActiveColor: textActiveColor ?? this.textActiveColor,
      textPendingColor: textPendingColor ?? this.textPendingColor,
      textInactiveColor: textInactiveColor ?? this.textInactiveColor,
      chordsActiveColor: chordsActiveColor ?? this.chordsActiveColor,
      chordsPendingColor: chordsPendingColor ?? this.chordsPendingColor,
      chordsInactiveColor: chordsInactiveColor ?? this.chordsInactiveColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      lineSpacing: lineSpacing ?? this.lineSpacing,
    );
  }
}
