import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/metronome_provider.dart';
import '../theme/app_theme.dart';
import '../theme/constants.dart';

/// Compact metronome bottom sheet for the player screen.
///
/// Shows a large BPM display, a slider, and +/- 10 buttons.
class MetronomeControl extends ConsumerWidget {
  const MetronomeControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(metronomeProvider);
    final notifier = ref.read(metronomeProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(kBorderRadiusLg),
          topRight: Radius.circular(kBorderRadiusLg),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              height: 36,
              alignment: Alignment.center,
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.onSurface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: kSpaceMd),

            // Pulse indicator when playing
            SizedBox(
              height: 24,
              child: settings.isPlaying
                  ? _CompactPulseIndicator(bpm: settings.bpm)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: kSpaceMd),

            // BPM display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '♩ = ',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.onSurface,
                  ),
                ),
                AnimatedScale(
                  scale: 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Text(
                    '${settings.bpm}',
                    style: GoogleFonts.robotoMono(
                      fontSize: 48,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: kSpaceMd),

            // Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpaceMd),
              child: Row(
                children: [
                  const Text(
                    '40',
                    style: TextStyle(fontSize: 12, color: AppTheme.onSurface),
                  ),
                  Expanded(
                    child: Slider(
                      value: settings.bpm.toDouble(),
                      min: 40,
                      max: 208,
                      divisions: 168,
                      activeColor: AppTheme.secondary,
                      inactiveColor: AppTheme.surface,
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        notifier.setBpm(value.round());
                      },
                    ),
                  ),
                  const Text(
                    '208',
                    style: TextStyle(fontSize: 12, color: AppTheme.onSurface),
                  ),
                ],
              ),
            ),
            const SizedBox(height: kSpaceMd),

            // Controls: -10, Play/Stop, +10
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80,
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      notifier.setBpm(settings.bpm - 10);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.onSurface,
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kBorderRadiusSm),
                      ),
                      minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
                    ),
                    child: const Text(
                      '-10',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: kSpaceMd),
                SizedBox(
                  width: 72,
                  height: 72,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: settings.isPlaying
                          ? AppTheme.error
                          : AppTheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: notifier.togglePlay,
                      icon: Icon(
                        settings.isPlaying
                            ? Icons.stop
                            : Icons.play_arrow,
                        size: 36,
                        color: AppTheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: kSpaceMd),
                SizedBox(
                  width: 80,
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      notifier.setBpm(settings.bpm + 10);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.onSurface,
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kBorderRadiusSm),
                      ),
                      minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
                    ),
                    child: const Text(
                      '+10',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: kSpaceLg),
          ],
        ),
      ),
    );
  }
}

class _CompactPulseIndicator extends StatefulWidget {
  final int bpm;

  const _CompactPulseIndicator({required this.bpm});

  @override
  State<_CompactPulseIndicator> createState() => _CompactPulseIndicatorState();
}

class _CompactPulseIndicatorState extends State<_CompactPulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  @override
  void didUpdateWidget(covariant _CompactPulseIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bpm != widget.bpm) {
      _controller.dispose();
      _initAnimation();
    }
  }

  void _initAnimation() {
    final duration = Duration(
      milliseconds: (60000 / widget.bpm).round(),
    );
    _controller = AnimationController(
      vsync: this,
      duration: duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = Tween<double>(begin: 0.8, end: 1.2).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ).value;
        final opacity = Tween<double>(begin: 0.3, end: 0.8).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ).value;
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppTheme.secondary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
