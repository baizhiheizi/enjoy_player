/// Scrollable transcript with tap-to-seek and echo-aware highlighting.
library;

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/subtitle/subtitle_markup_parser.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import '../../../l10n/app_localizations.dart';
import '../../player/application/display_position_provider.dart';
import '../../player/application/echo_mode_provider.dart';
import '../../player/application/player_interactions.dart';
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

class _TranscriptBody extends ConsumerWidget {
  const _TranscriptBody({required this.mediaId, required this.lines});

  final String mediaId;
  final List<TranscriptLine> lines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final echo = ref.watch(echoModeProvider);
    final posAsync = ref.watch(displayPositionProvider);
    final tok = EnjoyThemeTokens.of(context);
    final secondaryAsync = ref.watch(
      secondaryTranscriptLinesForMediaProvider(mediaId),
    );
    final secondaryLines = secondaryAsync.value ?? <TranscriptLine>[];

    final timeSec = switch (posAsync) {
      AsyncData(:final value) => value.inMilliseconds / 1000.0,
      _ => 0.0,
    };
    final active = _activeIndex(lines, timeSec);

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: tok.space12, vertical: tok.space8),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index];
        final isActive = index == active;
        final inEcho =
            echo.active &&
            index >= echo.startLineIndex &&
            index <= echo.endLineIndex;
        final secondaryText = _matchSecondary(line, secondaryLines)?.text;

        return Padding(
          padding: EdgeInsets.only(bottom: tok.space8),
          child: _TranscriptLineTile(
            line: line,
            secondaryText: secondaryText,
            isActive: isActive,
            inEcho: inEcho,
            onTap:
                () => ref
                    .read(playerInteractionsProvider.notifier)
                    .seekToLine(line, index),
          ),
        );
      },
    );
  }

  int _activeIndex(List<TranscriptLine> lines, double t) {
    for (var i = 0; i < lines.length; i++) {
      if (t >= lines[i].startSeconds && t < lines[i].endSeconds) return i;
    }
    for (var i = lines.length - 1; i >= 0; i--) {
      if (t >= lines[i].startSeconds) return i;
    }
    return -1;
  }

  /// Returns the secondary line whose midpoint falls within [primary]'s range,
  /// or the nearest secondary line if none overlaps.
  TranscriptLine? _matchSecondary(
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
}

class _TranscriptLineTile extends StatefulWidget {
  const _TranscriptLineTile({
    required this.line,
    required this.secondaryText,
    required this.isActive,
    required this.inEcho,
    required this.onTap,
  });

  final TranscriptLine line;
  final String? secondaryText;
  final bool isActive;
  final bool inEcho;
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
    if (echoCurrent) {
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
          child: Padding(
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
          ),
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
