import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/constants.dart';

/// Bottom control panel for the player screen.
///
/// Shows a large Play/Stop button and a pulsing listening indicator.
class PlayerControls extends StatelessWidget {
  final bool isListening;
  final bool isSilent;
  final bool isInitializing;
  final VoidCallback? onPlay;
  final VoidCallback? onStop;
  final VoidCallback? onResume;
  final VoidCallback? onForward;
  final VoidCallback? onBack;

  const PlayerControls({
    super.key,
    this.isListening = false,
    this.isSilent = false,
    this.isInitializing = false,
    this.onPlay,
    this.onStop,
    this.onResume,
    this.onForward,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: kPlayerControlsHeight,
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(kBorderRadiusLg),
            topRight: Radius.circular(kBorderRadiusLg),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.skip_previous, color: AppTheme.onSurface),
              iconSize: 28,
              tooltip: 'Назад',
            ),
            const SizedBox(width: kSpaceSm),
            if (isInitializing) ...[
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(AppTheme.secondary),
                ),
              ),
              const SizedBox(width: kSpaceMd),
              Text(
                'Загрузка модели...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ] else if (isListening && !isSilent) ...[
              const _PulseIndicator(),
              const SizedBox(width: kSpaceMd),
              Text(
                'Слушаю...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(width: kSpaceLg),
              Container(
                width: kFabSize,
                height: kFabSize,
                decoration: const BoxDecoration(
                  color: AppTheme.error,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: onStop,
                  icon: const Icon(
                    Icons.stop,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ] else if (isListening && isSilent) ...[
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.textDisabled,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: kSpaceMd),
              Text(
                'Пауза...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(width: kSpaceLg),
              ElevatedButton.icon(
                onPressed: onResume,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  foregroundColor: AppTheme.onSecondary,
                  minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kBorderRadiusMd),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: kSpaceLg,
                    vertical: kSpaceMd,
                  ),
                ),
                icon: const Icon(Icons.play_arrow, size: 28),
                label: const Text(
                  'Продолжить',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: onPlay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  foregroundColor: AppTheme.onSecondary,
                  minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kBorderRadiusMd),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: kSpaceLg,
                    vertical: kSpaceMd,
                  ),
                ),
                icon: const Icon(Icons.play_arrow, size: 28),
                label: const Text(
                  'Начать',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(width: kSpaceSm),
            IconButton(
              onPressed: onForward,
              icon: const Icon(Icons.skip_next, color: AppTheme.onSurface),
              iconSize: 28,
              tooltip: 'Вперёд',
            ),
          ],
        ),
      ),
    );
  }
}

/// A pulsing circle that indicates the app is actively listening.
class _PulseIndicator extends StatefulWidget {
  const _PulseIndicator();

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: 8,
              height: 8,
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
