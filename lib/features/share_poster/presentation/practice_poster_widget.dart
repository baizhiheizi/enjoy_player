/// Fixed 9:16 branded practice poster layout for export and preview.
library;

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:enjoy_player/core/theme/colors.dart';
import 'package:enjoy_player/core/theme/generative_media_cover.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_logo.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/features/share_poster/domain/practice_poster_data.dart';

/// User-visible poster strings (from l10n).
class PracticePosterLabels {
  const PracticePosterLabels({
    required this.tagline,
    required this.takesLabel,
    required this.sentencesLabel,
    required this.spokenLabel,
    required this.qrHint,
  });

  final String tagline;
  final String takesLabel;
  final String sentencesLabel;
  final String spokenLabel;
  final String qrHint;
}

class PracticePosterWidget extends StatelessWidget {
  const PracticePosterWidget({
    super.key,
    required this.data,
    required this.labels,
    this.onCoverReady,
  });

  final PracticePosterData data;
  final PracticePosterLabels labels;
  final VoidCallback? onCoverReady;

  @override
  Widget build(BuildContext context) {
    final accent = generativeAccentForSeed(data.coverSeed);
    final hasQuote = data.quote != null && !data.quote!.isEmpty;

    return SizedBox(
      width: practicePosterLogicalWidth,
      height: practicePosterLogicalHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gradientStartDark,
              AppColors.gradientEndDark,
              accent.withValues(alpha: 0.08),
            ],
            stops: const [0.0, 0.72, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const EnjoyLogo(size: 28),
                  const Spacer(),
                  Text(
                    labels.tagline,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandOnDark.withValues(alpha: 0.85),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.32),
                          blurRadius: 22,
                          spreadRadius: -6,
                        ),
                      ],
                    ),
                    child: PracticePosterCover(
                      data: data,
                      onCoverReady: onCoverReady,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                data.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.28,
                  color: Colors.white,
                ),
              ),
              if (hasQuote) ...[
                const Spacer(),
                _PracticePosterQuoteBlock(quote: data.quote!, accent: accent),
                const Spacer(),
              ] else
                const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      value: '${data.takes}',
                      label: labels.takesLabel,
                      accent: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      value: '${data.sentencesPracticed}',
                      label: labels.sentencesLabel,
                      accent: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      value: formatPracticeDurationMs(data.spokenDurationMs),
                      label: labels.spokenLabel,
                      accent: accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(
                height: 24,
                thickness: 1,
                color: accent.withValues(alpha: 0.18),
              ),
              _PracticePosterFooter(labels: labels, accent: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _PracticePosterQuoteBlock extends StatelessWidget {
  const _PracticePosterQuoteBlock({required this.quote, required this.accent});

  final PracticePosterQuote quote;
  final Color accent;

  static TextStyle _quoteMarkStyle(Color accent, {required double fontSize}) {
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      height: 1.0,
      fontWeight: FontWeight.w700,
      color: accent.withValues(alpha: 0.52),
    );
  }

  static TextStyle _quoteTextStyle({
    required double opacity,
    required double fontSize,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      height: 1.35,
      fontWeight: fontWeight,
      fontStyle: FontStyle.italic,
      color: Colors.white.withValues(alpha: opacity),
      letterSpacing: 0.18,
    );
  }

  static TextSpan _shadowingQuoteSpan({
    required String text,
    required TextStyle baseStyle,
    required int highlightWords,
  }) {
    final (lead, tail) = _splitShadowingHighlight(
      text,
      wordCount: highlightWords,
    );
    if (lead.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }
    return TextSpan(
      children: [
        TextSpan(
          text: lead,
          style: baseStyle.copyWith(
            color: AppColors.echoActive,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (tail.isNotEmpty) TextSpan(text: tail, style: baseStyle),
      ],
    );
  }

  /// First [wordCount] words (or ~4 CJK chars) — karaoke / shadowing lead-in.
  static (String lead, String tail) _splitShadowingHighlight(
    String text, {
    int wordCount = 3,
    int cjkCharCount = 4,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return ('', '');

    if (!RegExp(r'\s').hasMatch(trimmed)) {
      if (trimmed.length <= cjkCharCount) return (trimmed, '');
      return (
        trimmed.substring(0, cjkCharCount),
        trimmed.substring(cjkCharCount),
      );
    }

    final matches = RegExp(r'\S+').allMatches(trimmed).toList();
    if (matches.isEmpty) return (trimmed, '');
    if (matches.length <= wordCount) return (trimmed, '');

    final leadEnd = matches[wordCount - 1].end;
    return (trimmed.substring(0, leadEnd), trimmed.substring(leadEnd));
  }

  @override
  Widget build(BuildContext context) {
    const maxQuoteLines = 2;
    const fontSize = 18.0;
    const markSize = 32.0;
    final quoteText = quote.line.displayText;
    final primaryStyle = _quoteTextStyle(opacity: 0.97, fontSize: fontSize);
    final markStyle = _quoteMarkStyle(accent, fontSize: markSize);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text('“', style: markStyle),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text.rich(
            _shadowingQuoteSpan(
              text: quoteText,
              baseStyle: primaryStyle,
              highlightWords: 4,
            ),
            maxLines: maxQuoteLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PracticePosterFooter extends StatelessWidget {
  const _PracticePosterFooter({required this.labels, required this.accent});

  final PracticePosterLabels labels;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: QrImageView(
              data: practicePosterDownloadUrl,
              size: 68,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            labels.qrHint,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ),
      ],
    );
  }
}

class PracticePosterCover extends StatefulWidget {
  const PracticePosterCover({super.key, required this.data, this.onCoverReady});

  final PracticePosterData data;
  final VoidCallback? onCoverReady;

  @override
  State<PracticePosterCover> createState() => _PracticePosterCoverState();
}

class _PracticePosterCoverState extends State<PracticePosterCover> {
  var _readyNotified = false;

  void _notifyReadyOnce() {
    if (_readyNotified) return;
    _readyNotified = true;
    widget.onCoverReady?.call();
  }

  @override
  Widget build(BuildContext context) {
    final echoBytes = widget.data.echoCoverBytes;
    if (echoBytes != null && echoBytes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyReadyOnce();
      });
      return Image.memory(echoBytes, fit: BoxFit.cover);
    }

    final localPath = widget.data.localThumbnailPath;
    if (localPath != null && localPath.isNotEmpty) {
      final file = File(localPath);
      if (file.existsSync()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _notifyReadyOnce();
        });
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    final url = widget.data.networkThumbnailUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, _) => GenerativeMediaCover(
          seed: widget.data.coverSeed,
          isVideo: widget.data.isVideo,
        ),
        errorWidget: (_, _, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _notifyReadyOnce();
          });
          return GenerativeMediaCover(
            seed: widget.data.coverSeed,
            isVideo: widget.data.isVideo,
          );
        },
        imageBuilder: (context, imageProvider) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _notifyReadyOnce();
          });
          return DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            ),
          );
        },
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyReadyOnce();
    });
    return GenerativeMediaCover(
      seed: widget.data.coverSeed,
      isVideo: widget.data.isVideo,
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.accent,
  });

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: Colors.white,
                letterSpacing: 0.15,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                height: 1.2,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
