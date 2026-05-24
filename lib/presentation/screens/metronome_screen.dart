import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../providers/metronome_provider.dart';
import '../theme/app_theme.dart';
import '../theme/constants.dart';

class MetronomeScreen extends ConsumerWidget {
  const MetronomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(metronomeProvider);
    final notifier = ref.read(metronomeProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Метроном'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: kSpaceMd),
          child: Column(
            children: [
              const SizedBox(height: kSpaceXl),
              // Pulse indicator (visible only when playing)
              SizedBox(
                height: 40,
                child: settings.isPlaying
                    ? _PulseIndicator(bpm: settings.bpm)
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: kSpaceLg),
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
                        fontSize: 64,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: kSpaceLg),
              // BPM slider
              Row(
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
                      onChanged: (v) => notifier.setBpm(v.round()),
                    ),
                  ),
                  const Text(
                    '208',
                    style: TextStyle(fontSize: 12, color: AppTheme.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: kSpaceLg),
              // Play / Stop button
              SizedBox(
                width: 72,
                height: 72,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: settings.isPlaying ? AppTheme.error : AppTheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: notifier.togglePlay,
                    icon: Icon(
                      settings.isPlaying ? Icons.stop : Icons.play_arrow,
                      size: 36,
                      color: AppTheme.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: kSpaceMd),
              // +/- 10 buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    child: OutlinedButton(
                      onPressed: () => notifier.setBpm(settings.bpm - 10),
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
                  const SizedBox(width: kSpaceLg),
                  SizedBox(
                    width: 80,
                    child: OutlinedButton(
                      onPressed: () => notifier.setBpm(settings.bpm + 10),
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
              // Volume label
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Громкость',
                  style: TextStyle(fontSize: 14, color: AppTheme.onSurface),
                ),
              ),
              const SizedBox(height: kSpaceSm),
              // Volume slider
              Row(
                children: [
                  const Icon(Icons.volume_mute, color: AppTheme.onSurface),
                  Expanded(
                    child: Slider(
                      value: settings.volume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      activeColor: AppTheme.secondary,
                      inactiveColor: AppTheme.surface,
                      onChanged: (v) => notifier.setVolume(v),
                    ),
                  ),
                  const Icon(Icons.volume_up, color: AppTheme.onSurface),
                ],
              ),
              const SizedBox(height: kSpaceLg),
            ],
          ),
        ),
      ),
    );
  }
}

/// A pulsing circle that beats in sync with the metronome BPM.
class _PulseIndicator extends StatefulWidget {
  final int bpm;

  const _PulseIndicator({required this.bpm});

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  @override
  void didUpdateWidget(covariant _PulseIndicator oldWidget) {
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
        final scale = Tween<double>(begin: 0.8, end: 1.2)
            .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut))
            .value;
        final opacity = Tween<double>(begin: 0.3, end: 0.8)
            .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut))
            .value;
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 24,
              height: 24,
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
