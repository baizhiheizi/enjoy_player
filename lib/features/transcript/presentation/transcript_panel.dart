/// Scrollable transcript with tap-to-seek and echo-aware highlighting.
library;

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/subtitle/subtitle_markup_parser.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import '../../player/application/display_position_provider.dart';
import '../../player/application/player_controller.dart';
import '../../player/application/echo_mode_provider.dart';
import '../../player/application/player_interactions.dart';
import '../../player/application/player_state_providers.dart';
import '../../shadow_reading/presentation/shadow_reading_panel.dart';
import 'echo_region_controls_bar.dart';
import '../application/transcript_lines_provider.dart';
import '../application/transcript_repository_provider.dart';

class TranscriptPanel extends ConsumerWidget {
  const TranscriptPanel({required this.mediaId, super.key});

  final String mediaId;

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final pick = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['srt', 'vtt'],
    );
    if (pick == null || pick.files.isEmpty) return;
    final f = pick.files.single;
    final path = f.path;
    if (path == null) return;

    await ref
        .read(transcriptRepositoryProvider)
        .importSubtitle(mediaId: mediaId, file: XFile(path));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.importSubtitleSuccess),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final linesAsync = ref.watch(transcriptLinesForMediaProvider(mediaId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: linesAsync.when(
            data: (lines) {
              if (lines.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(t.space24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.noTranscript,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.noTranscriptHint,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: t.space16),
                        FilledButton.icon(
                          onPressed: () => _import(context, ref),
                          icon: const Icon(Icons.upload_file),
                          label: Text(l10n.importSubtitle),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return _TranscriptBody(mediaId: mediaId, lines: lines);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('${l10n.error}: $e')),
          ),
        ),
      ],
    );
  }
}

class _TranscriptBody extends ConsumerStatefulWidget {
  const _TranscriptBody({required this.mediaId, required this.lines});

  final String mediaId;
  final List<TranscriptLine> lines;

  @override
  ConsumerState<_TranscriptBody> createState() => _TranscriptBodyState();
}

class _TranscriptBodyState extends ConsumerState<_TranscriptBody> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _activeLineKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleScrollActiveLineIntoView() {
    final playingAsync = ref.read(playerIsPlayingProvider);
    final playing = switch (playingAsync) {
      AsyncData(:final value) => value,
      _ => false,
    };
    if (!playing) return;

    final posAsync = ref.read(displayPositionProvider);
    final timeSec = switch (posAsync) {
      AsyncData(:final value) => value.inMilliseconds / 1000.0,
      _ => 0.0,
    };
    final active = transcriptActiveIndex(widget.lines, timeSec);
    if (active < 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _activeLineKey.currentContext;
      if (ctx == null) return;
      final tok = EnjoyThemeTokens.of(context);
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.42,
        duration: tok.motionStandard,
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final echo = ref.watch(echoModeProvider);
    final posAsync = ref.watch(displayPositionProvider);
    final tok = EnjoyThemeTokens.of(context);
    final secondaryAsync = ref.watch(
      secondaryTranscriptLinesForMediaProvider(widget.mediaId),
    );
    final secondaryLines = secondaryAsync.value ?? <TranscriptLine>[];

    final timeSec = switch (posAsync) {
      AsyncData(:final value) => value.inMilliseconds / 1000.0,
      _ => 0.0,
    };
    final active = transcriptActiveIndex(widget.lines, timeSec);

    ref.listen(displayPositionProvider, (_, _) {
      _scheduleScrollActiveLineIntoView();
    });
    ref.listen(playerIsPlayingProvider, (_, _) {
      _scheduleScrollActiveLineIntoView();
    });

    final lines = widget.lines;
    final children = <Widget>[];

    var i = 0;
    while (i < lines.length) {
      if (echo.active && i == echo.startLineIndex) {
        children.add(
          Padding(
            padding: EdgeInsets.only(bottom: tok.space8),
            child: _EchoRegionMergedCard(
              mediaId: widget.mediaId,
              lines: lines,
              echo: echo,
              activeCueIndex: active,
              secondaryLines: secondaryLines,
              activeLineKey: _activeLineKey,
            ),
          ),
        );
        i = echo.endLineIndex + 1;
        continue;
      }

      final line = lines[i];
      final isActive = i == active;
      final inEcho =
          echo.active &&
          i >= echo.startLineIndex &&
          i <= echo.endLineIndex;
      final secondaryText = transcriptMatchSecondary(line, secondaryLines)?.text;

      Widget tile = _TranscriptLineTile(
        line: line,
        secondaryText: secondaryText,
        isActive: isActive,
        inEcho: inEcho,
        groupedInEcho: false,
        onTap:
            () => ref
                .read(playerInteractionsProvider.notifier)
                .seekToLine(line, i),
      );

      if (isActive) {
        tile = KeyedSubtree(key: _activeLineKey, child: tile);
      }

      children.add(
        Padding(
          padding: EdgeInsets.only(bottom: tok.space8),
          child: tile,
        ),
      );
      i++;
    }

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: tok.space12, vertical: tok.space8),
      children: children,
    );
  }
}

class _EchoRegionMergedCard extends ConsumerWidget {
  const _EchoRegionMergedCard({
    required this.mediaId,
    required this.lines,
    required this.echo,
    required this.activeCueIndex,
    required this.secondaryLines,
    required this.activeLineKey,
  });

  final String mediaId;
  final List<TranscriptLine> lines;
  final EchoState echo;
  final int activeCueIndex;
  final List<TranscriptLine> secondaryLines;
  final GlobalKey activeLineKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final tok = EnjoyThemeTokens.of(context);
    final session = ref.watch(playerControllerProvider);

    final shell = Color.lerp(
      tok.echoActive.withValues(alpha: 0.16),
      scheme.surfaceContainerHigh,
      0.55,
    )!;

    final showShadow =
        echo.startTimeSeconds >= 0 && echo.endTimeSeconds >= 0;

    final lineWidgets = <Widget>[];
    for (var i = echo.startLineIndex; i <= echo.endLineIndex; i++) {
      if (i > echo.startLineIndex) {
        lineWidgets.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: tok.space12,
            endIndent: tok.space12,
            color: scheme.outlineVariant.withValues(alpha: 0.28),
          ),
        );
      }

      final line = lines[i];
      final isActive = i == activeCueIndex;
      final secondaryText = transcriptMatchSecondary(line, secondaryLines)?.text;

      Widget tile = _TranscriptLineTile(
        line: line,
        secondaryText: secondaryText,
        isActive: isActive,
        inEcho: true,
        groupedInEcho: true,
        onTap:
            () => ref
                .read(playerInteractionsProvider.notifier)
                .seekToLine(line, i),
      );

      if (isActive) {
        tile = KeyedSubtree(key: activeLineKey, child: tile);
      }

      lineWidgets.add(tile);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        EchoRegionControlsBar(
          position: EchoRegionBarPosition.top,
          expandDisabled: echo.startLineIndex <= 0,
          shrinkDisabled: echo.startLineIndex >= echo.endLineIndex,
          dense: true,
          onExpand:
              () =>
                  ref.read(echoModeProvider.notifier).expandEchoBackward(lines),
          onShrink:
              () =>
                  ref.read(echoModeProvider.notifier).shrinkEchoBackward(lines),
        ),
        SizedBox(height: tok.space8),
        Material(
          color: shell,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tok.radiusMd),
            side: BorderSide(color: tok.echoActive.withValues(alpha: 0.40)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: lineWidgets,
          ),
        ),
        SizedBox(height: tok.space8),
        EchoRegionControlsBar(
          position: EchoRegionBarPosition.bottom,
          expandDisabled: echo.endLineIndex >= lines.length - 1,
          shrinkDisabled: echo.endLineIndex <= echo.startLineIndex,
          dense: true,
          onExpand:
              () =>
                  ref.read(echoModeProvider.notifier).expandEchoForward(lines),
          onShrink:
              () =>
                  ref.read(echoModeProvider.notifier).shrinkEchoForward(lines),
        ),
        if (showShadow) ...[
          SizedBox(height: tok.space16),
          ShadowReadingPanel(
            mediaId: mediaId,
            targetType: session?.dexieTargetType ?? 'Audio',
            language: session?.language ?? 'en',
            startSec: echo.startTimeSeconds,
            endSec: echo.endTimeSeconds,
            referenceText: echoReferencePlainText(lines, echo),
            echoActive: echo.active,
            currentTimeSec: session?.currentTimeSeconds,
          ),
        ],
      ],
    );
  }
}

/// Active cue index for [t] in seconds.
int transcriptActiveIndex(List<TranscriptLine> lines, double t) {
  for (var i = 0; i < lines.length; i++) {
    if (t >= lines[i].startSeconds && t < lines[i].endSeconds) return i;
  }
  for (var i = lines.length - 1; i >= 0; i--) {
    if (t >= lines[i].startSeconds) return i;
  }
  return -1;
}

/// Secondary line whose midpoint falls within [primary]'s range, else nearest.
TranscriptLine? transcriptMatchSecondary(
  TranscriptLine primary,
  List<TranscriptLine> secondary,
) {
  if (secondary.isEmpty) return null;
  final pStart = primary.startSeconds;
  final pEnd = primary.endSeconds;

  for (final s in secondary) {
    final mid = s.startSeconds + (s.endSeconds - s.startSeconds) / 2;
    if (mid >= pStart && mid < pEnd) return s;
  }

  TranscriptLine? best;
  for (final s in secondary) {
    if (s.startSeconds < pEnd) best = s;
  }
  return best;
}

String echoReferencePlainText(List<TranscriptLine> lines, EchoState echo) {
  if (!echo.active) return '';
  final start = echo.startLineIndex;
  final end = echo.endLineIndex;
  if (start < 0 || end < 0 || start > end) return '';
  final parts = <String>[];
  for (var i = start; i <= end && i < lines.length; i++) {
    final plain = lines[i].text.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    if (plain.isNotEmpty) parts.add(plain);
  }
  return parts.join(' ');
}

class _TranscriptLineTile extends StatefulWidget {
  const _TranscriptLineTile({
    required this.line,
    required this.secondaryText,
    required this.isActive,
    required this.inEcho,
    required this.onTap,
    this.groupedInEcho = false,
  });

  final TranscriptLine line;
  final String? secondaryText;
  final bool isActive;
  final bool inEcho;

  /// Echo cues rendered inside the echo-region transcript shell: flat rows.
  final bool groupedInEcho;
  final VoidCallback onTap;

  @override
  State<_TranscriptLineTile> createState() => _TranscriptLineTileState();
}

class _TranscriptLineTileState extends State<_TranscriptLineTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tok = EnjoyThemeTokens.of(context);
    final baseBody = Theme.of(context).textTheme.bodyLarge ?? const TextStyle();
    final defaultFg = scheme.onSurface;

    final echoCurrent = widget.isActive && widget.inEcho;

    Color? bg;
    if (widget.groupedInEcho) {
      if (echoCurrent) {
        bg = Color.lerp(
          tok.echoActive.withValues(alpha: 0.38),
          scheme.primary.withValues(alpha: 0.18),
          0.42,
        );
      } else if (widget.inEcho) {
        bg = Colors.transparent;
      }
    } else if (echoCurrent) {
      bg = Color.lerp(
        tok.echoActive.withValues(alpha: 0.42),
        scheme.primary.withValues(alpha: 0.22),
        0.4,
      );
    } else if (widget.isActive) {
      bg = scheme.primary.withValues(alpha: 0.18);
    } else if (widget.inEcho) {
      bg = tok.echoActive.withValues(alpha: 0.22);
    } else if (_hover) {
      bg = scheme.onSurface.withValues(alpha: 0.06);
    }

    final timestampStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final content = Padding(
      padding: tok.transcriptLinePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                formatTranscriptTimestampMs(widget.line.startMs),
                style: timestampStyle,
              ),
            ],
          ),
          SizedBox(height: tok.space4),
          Text.rich(
            transcriptMarkupToTextSpan(
              widget.line.text,
              baseBody,
              defaultColor: defaultFg,
              emphasize: widget.isActive,
            ),
          ),
          if (widget.secondaryText != null) ...[
            SizedBox(height: tok.space4),
            Text.rich(
              transcriptMarkupToTextSpan(
                widget.secondaryText!,
                (Theme.of(context).textTheme.bodySmall ??
                        const TextStyle())
                    .copyWith(fontStyle: FontStyle.italic),
                defaultColor: scheme.onSurfaceVariant,
                emphasize: false,
              ),
            ),
          ],
        ],
      ),
    );

    if (widget.groupedInEcho) {
      return Material(
        color: bg ?? Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          highlightColor:
              echoCurrent
                  ? tok.echoActive.withValues(alpha: 0.12)
                  : scheme.onSurface.withValues(alpha: 0.05),
          splashColor:
              echoCurrent
                  ? tok.echoActive.withValues(alpha: 0.16)
                  : scheme.primary.withValues(alpha: 0.08),
          child: content,
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: bg ?? Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tok.radiusSm),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(tok.radiusSm),
          onTap: widget.onTap,
          hoverColor: Colors.transparent,
          highlightColor:
              echoCurrent
                  ? tok.echoActive.withValues(alpha: 0.14)
                  : scheme.primary.withValues(alpha: 0.08),
          splashColor:
              echoCurrent
                  ? tok.echoActive.withValues(alpha: 0.18)
                  : scheme.primary.withValues(alpha: 0.12),
          child: content,
        ),
      ),
    );
  }
}

/// Formats [startMs] as `M:SS` or `H:MM:SS` when over one hour.
String formatTranscriptTimestampMs(int startMs) {
  final totalSec = (startMs / 1000).floor().clamp(0, 1 << 30);
  final h = totalSec ~/ 3600;
  final m = (totalSec % 3600) ~/ 60;
  final s = totalSec % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

/// Builds a [TextSpan] tree from SSA/HTML-like subtitle markup.
TextSpan transcriptMarkupToTextSpan(
  String raw,
  TextStyle baseStyle, {
  required Color defaultColor,
  bool emphasize = false,
}) {
  final segments = parseSubtitleMarkup(raw);
  if (segments.isEmpty) {
    final plain = raw.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    final text = plain.isEmpty ? raw : plain;
    return TextSpan(
      text: text,
      style: _cueStyle(
        baseStyle,
        defaultColor: defaultColor,
        emphasize: emphasize,
      ),
    );
  }

  return TextSpan(
    children:
        segments.map((seg) {
          final fg = seg.colorArgb != null ? Color(seg.colorArgb!) : defaultColor;
          return TextSpan(
            text: seg.text,
            style: _cueStyle(
              baseStyle,
              defaultColor: fg,
              emphasize: emphasize,
              bold: seg.bold,
              italic: seg.italic,
              underline: seg.underline,
            ),
          );
        }).toList(),
  );
}

TextStyle _cueStyle(
  TextStyle base, {
  required Color defaultColor,
  bool emphasize = false,
  bool bold = false,
  bool italic = false,
  bool underline = false,
}) {
  final weight =
      emphasize || bold ? FontWeight.w600 : base.fontWeight ?? FontWeight.normal;
  return base.copyWith(
    color: defaultColor,
    fontWeight: weight,
    fontStyle: italic ? FontStyle.italic : base.fontStyle,
    decoration:
        underline ? TextDecoration.underline : TextDecoration.none,
    decorationColor: defaultColor,
  );
}
