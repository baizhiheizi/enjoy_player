/// Scrollable transcript with tap-to-seek and echo-aware highlighting.
library;

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/data/subtitle/subtitle_markup_parser.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import '../../player/application/display_position_provider.dart';
import '../../player/application/player_controller.dart';
import '../../player/application/echo_mode_provider.dart';
import '../../player/application/player_interactions.dart';
import '../../player/application/player_state_providers.dart';
import '../../shadow_reading/presentation/shadow_reading_panel.dart';
import '../application/transcript_playback_highlight_provider.dart';
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
                final scheme = Theme.of(context).colorScheme;
                return LayoutBuilder(
                  builder: (context, viewport) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: t.space8,
                        vertical: t.space16,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: viewport.maxHeight),
                        child: Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest.withValues(
                                alpha: 0.55,
                              ),
                              borderRadius: BorderRadius.circular(t.radiusMd),
                              border: Border.all(
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(t.space24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.subtitles_outlined,
                                    size: 40,
                                    color: scheme.primary.withValues(alpha: 0.85),
                                  ),
                                  SizedBox(height: t.space16),
                                  Text(
                                    l10n.noTranscript,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(height: t.space8),
                                  Text(
                                    l10n.noTranscriptHint,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyMedium
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          height: 1.35,
                                        ),
                                  ),
                                  SizedBox(height: t.space24),
                                  FilledButton.icon(
                                    onPressed: () => _import(context, ref),
                                    icon: const Icon(Icons.upload_file_rounded),
                                    label: Text(l10n.importSubtitle),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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
  int _lastScrolledIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_TranscriptBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaId != widget.mediaId) {
      _lastScrolledIndex = -1;
    }
  }

  void _scheduleScrollActiveLineIntoView({bool force = false}) {
    final playingAsync = ref.read(playerIsPlayingProvider);
    final playing = switch (playingAsync) {
      AsyncData(:final value) => value,
      _ => false,
    };
    if (!playing) return;

    final activeForUi = ref.read(transcriptPlaybackHighlightProvider(widget.mediaId));
    if (activeForUi < 0) return;

    if (!force && activeForUi == _lastScrolledIndex) return;
    _lastScrolledIndex = activeForUi;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _activeLineKey.currentContext;
      if (ctx != null) {
        // Item is in the render tree — animate directly.
        final tok = EnjoyThemeTokens.of(context);
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.42,
          duration: tok.motionStandard,
          curve: Curves.easeOutCubic,
        );
        return;
      }

      // Item is outside the viewport and not yet rendered (lazy ListView).
      // Jump to an estimated offset so the item enters the render tree, then
      // ensureVisible in the following frame for precise placement.
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position;
      final estimated =
          (activeForUi / widget.lines.length) * pos.maxScrollExtent;
      _scrollController.jumpTo(estimated.clamp(0.0, pos.maxScrollExtent));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx2 = _activeLineKey.currentContext;
        if (ctx2 == null) return;
        final tok = EnjoyThemeTokens.of(context);
        Scrollable.ensureVisible(
          ctx2,
          alignment: 0.42,
          duration: tok.motionStandard,
          curve: Curves.easeOutCubic,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final echo = ref.watch(echoModeProvider);
    final activeForUi = ref.watch(
      transcriptPlaybackHighlightProvider(widget.mediaId).select((i) => i),
    );
    final tok = EnjoyThemeTokens.of(context);
    final secondaryAsync = ref.watch(
      secondaryTranscriptLinesForMediaProvider(widget.mediaId),
    );
    final secondaryLines = secondaryAsync.value ?? <TranscriptLine>[];

    ref.listen(transcriptPlaybackHighlightProvider(widget.mediaId), (
      prev,
      next,
    ) {
      if (prev == next) return;
      _scheduleScrollActiveLineIntoView(force: true);
    });
    ref.listen(playerIsPlayingProvider, (_, _) {
      _scheduleScrollActiveLineIntoView(force: true);
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
              activeCueIndex: activeForUi,
              secondaryLines: secondaryLines,
              activeLineKey: _activeLineKey,
            ),
          ),
        );
        i = echo.endLineIndex + 1;
        continue;
      }

      // Capture per-iteration values so the onTap closure does not bind
      // `i` by reference (the surrounding while loop's `var i` is shared
      // across iterations and otherwise leaks `lines.length` into taps).
      final lineIndex = i;
      final line = lines[lineIndex];
      final isActive = lineIndex == activeForUi;
      final inEcho =
          echo.active &&
          lineIndex >= echo.startLineIndex &&
          lineIndex <= echo.endLineIndex;
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
                .seekToLine(line, lineIndex),
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
    final chrome = ref.watch(playerControllerProvider.select(playbackChromeOf));
    final posAsync = ref.watch(displayPositionProvider);
    final currentTimeSec = switch (posAsync) {
      AsyncData(:final value) => value.inMilliseconds / 1000.0,
      _ => 0.0,
    };

    // Neutral surface — no colored background; left rail carries the echo accent.
    final shell = scheme.surfaceContainerLow;

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
            color: scheme.outlineVariant.withValues(alpha: 0.2),
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
        // Neutral card with 8px warm orange left rail
        ClipRRect(
          borderRadius: BorderRadius.circular(tok.radiusMd),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Orange rail
                Container(
                  width: 8,
                  decoration: BoxDecoration(
                    color: tok.echoActive,
                  ),
                ),
                // Content
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: shell,
                      border: Border(
                        top: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.18),
                        ),
                        right: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.18),
                        ),
                        bottom: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.18),
                        ),
                      ),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: lineWidgets,
                    ),
                  ),
                ),
              ],
            ),
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
            targetType: chrome?.dexieTargetType ?? 'Audio',
            language: chrome?.language ?? 'en',
            startSec: echo.startTimeSeconds,
            endSec: echo.endTimeSeconds,
            referenceText: echoReferencePlainText(lines, echo),
            echoActive: echo.active,
            currentTimeSec: currentTimeSec,
          ),
        ],
      ],
    );
  }
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
    final typography = TranscriptTypographyTokens.of(context);
    final baseBody = typography.bodyStyle;
    final defaultFg = scheme.onSurface;

    final echoCurrent = widget.isActive && widget.inEcho;

    // Editorial active-line: soft fill + left rail instead of heavy background.
    Color? bg;
    Color? railColor;
    if (widget.groupedInEcho) {
      if (echoCurrent) {
        bg = tok.echoActive.withValues(alpha: 0.06);
        // Parent [_EchoRegionMergedCard] already paints an 8px echo rail; do not add
        // a second inner rail or the active row reads as a wider orange stripe.
        railColor = null;
      } else if (widget.inEcho) {
        bg = Colors.transparent;
      }
    } else if (echoCurrent) {
      bg = tok.echoActive.withValues(alpha: 0.06);
      railColor = tok.echoActive;
    } else if (widget.isActive) {
      bg = scheme.primary.withValues(alpha: 0.08);
      railColor = scheme.primary;
    } else if (widget.inEcho) {
      bg = tok.echoActive.withValues(alpha: 0.04);
    } else if (_hover) {
      bg = scheme.onSurface.withValues(alpha: 0.04);
    }

    final timestampStyle = typography.timestampStyle;

    final textBody = Padding(
      padding: tok.transcriptLinePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatTranscriptTimestampMs(widget.line.startMs),
            style: timestampStyle,
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
                typography.secondaryStyle,
                defaultColor: scheme.onSurfaceVariant,
                emphasize: false,
              ),
            ),
          ],
        ],
      ),
    );

    // Left rail for active lines
    final content = railColor != null
        ? IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: tok.motionFast,
                  width: 3,
                  decoration: BoxDecoration(
                    color: railColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Expanded(child: textBody),
              ],
            ),
          )
        : textBody;

    if (widget.groupedInEcho) {
      return Material(
        color: bg ?? Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          highlightColor: scheme.onSurface.withValues(alpha: 0.04),
          splashColor: scheme.primary.withValues(alpha: 0.06),
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
          highlightColor: scheme.primary.withValues(alpha: 0.06),
          splashColor: scheme.primary.withValues(alpha: 0.10),
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
