import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class CaptureRecordingView extends StatefulWidget {
  const CaptureRecordingView({
    super.key,
    required this.elapsed,
    required this.amplitudeBuffer,
    required this.amplitudeCount,
    required this.amplitudeWriteIndex,
    required this.l10n,
    required this.theme,
    required this.onStop,
    required this.onCancel,
  });

  final Duration elapsed;
  final Float32List amplitudeBuffer;
  final int amplitudeCount;
  final int amplitudeWriteIndex;
  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  @override
  State<CaptureRecordingView> createState() => _CaptureRecordingViewState();
}

class _CaptureRecordingViewState extends State<CaptureRecordingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    unawaited(_pulse.repeat(reverse: true));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final theme = widget.theme;
    final scheme = theme.colorScheme;
    final count = widget.amplitudeCount;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            formatDurationHms(widget.elapsed),
            style: enjoyMonoStyle(
              context,
              size: 34,
              weight: FontWeight.w600,
              color: t.youInk,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: t.space24),
          Center(
            child: SizedBox(
              width: _AmplitudeBarsPainter.trackWidthFor(
                widget.amplitudeBuffer.length,
              ),
              height: 56,
              child: CustomPaint(
                painter: _AmplitudeBarsPainter(
                  buffer: widget.amplitudeBuffer,
                  count: count,
                  writeIndex: widget.amplitudeWriteIndex,
                  color: t.brandInk,
                ),
              ),
            ),
          ),
          SizedBox(height: t.space40),
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final v = _pulse.value;
              return SizedBox(
                width: 96 + v * 8,
                height: 96 + v * 8,
                child: Center(
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      shape: const CircleBorder(),
                      color: t.you.withValues(alpha: 0.12 + v * 0.08),
                    ),
                    child: child,
                  ),
                ),
              );
            },
            child: EnjoyPressable(
              onTap: widget.onStop,
              borderRadius: BorderRadius.circular(40),
              pressedScale: 0.95,
              semanticsLabel: widget.l10n.craftCaptureStop,
              child: AnimatedContainer(
                duration: t.motionFast,
                width: 80,
                height: 80,
                decoration: ShapeDecoration(
                  color: t.you,
                  shape: const CircleBorder(),
                  shadows: t.shadowRecordButton,
                ),
                child: Icon(EnjoyIcons.stop, size: 40, color: t.onYou),
              ),
            ),
          ),
          SizedBox(height: t.space12),
          Text(
            widget.l10n.craftCaptureStop,
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: t.space8),
          EnjoyButton.ghost(
            onPressed: widget.onCancel,
            child: Text(widget.l10n.craftCaptureCancel),
          ),
        ],
      ),
    );
  }
}

class _AmplitudeBarsPainter extends CustomPainter {
  const _AmplitudeBarsPainter({
    required this.buffer,
    required this.count,
    required this.writeIndex,
    required this.color,
  });

  static const double _barWidth = 3.5;
  static const double _spacing = 3.0;

  /// Width of a fixed [barCount]-slot amplitude track.
  static double trackWidthFor(int barCount) =>
      barCount * _barWidth + (barCount - 1) * _spacing;

  final Float32List buffer;
  final int count;
  final int writeIndex;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    const minHeight = 6.0;
    final maxHeight = size.height;
    final radius = const Radius.circular(2);
    final trackWidth = trackWidthFor(buffer.length);
    final startX = (size.width - trackWidth) / 2;

    if (count == 0) {
      const placeholderCount = 12;
      final placeholderWidth = trackWidthFor(placeholderCount);
      final placeholderStart = startX + (trackWidth - placeholderWidth) / 2;
      for (var i = 0; i < placeholderCount; i++) {
        final h = 10 + (i % 3) * 6.0;
        final x = placeholderStart + i * (_barWidth + _spacing);
        paint.color = color.withValues(alpha: 0.25);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, (maxHeight - h) / 2, _barWidth, h),
            radius,
          ),
          paint,
        );
      }
      return;
    }

    for (var i = 0; i < count; i++) {
      final readIndex =
          (writeIndex - count + i + buffer.length) % buffer.length;
      final level = buffer[readIndex];
      final h = (level * maxHeight).clamp(minHeight, maxHeight);
      final x = startX + i * (_barWidth + _spacing);
      paint.color = Color.lerp(color.withValues(alpha: 0.45), color, level)!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, (maxHeight - h) / 2, _barWidth, h),
          radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmplitudeBarsPainter old) {
    return old.count != count ||
        old.writeIndex != writeIndex ||
        old.color != color;
  }
}
