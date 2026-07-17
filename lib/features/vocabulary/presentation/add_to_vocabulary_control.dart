/// Lookup-sheet control: add / add context / already in / remove vocabulary item.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/features/lookup/domain/lookup_request.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_cta_state.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_normalize.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

final _log = logNamed('Vocabulary');

class AddToVocabularyControl extends ConsumerStatefulWidget {
  const AddToVocabularyControl({required this.request, super.key});

  final LookupRequest request;

  @override
  ConsumerState<AddToVocabularyControl> createState() =>
      _AddToVocabularyControlState();
}

class _AddToVocabularyControlState
    extends ConsumerState<AddToVocabularyControl> {
  VocabularyCtaKind? _kind;
  String? _itemId;
  var _busy = false;
  var _unavailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshState());
    });
  }

  @override
  void didUpdateWidget(covariant AddToVocabularyControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request.selectedText != widget.request.selectedText ||
        oldWidget.request.sourceLanguage != widget.request.sourceLanguage ||
        oldWidget.request.targetLanguage != widget.request.targetLanguage ||
        oldWidget.request.mediaVocabularyContext?.locator !=
            widget.request.mediaVocabularyContext?.locator ||
        oldWidget.request.mediaVocabularyContext?.sourceId !=
            widget.request.mediaVocabularyContext?.sourceId) {
      unawaited(_refreshState());
    }
  }

  Future<void> _refreshState() async {
    final media = widget.request.mediaVocabularyContext;
    if (media == null || normalizeWord(widget.request.selectedText).isEmpty) {
      if (!mounted) return;
      setState(() {
        _unavailable = true;
        _kind = null;
        _itemId = null;
      });
      return;
    }
    try {
      final repo = ref.read(vocabularyRepositoryProvider);
      final resolved = await repo.resolveCtaState(
        word: widget.request.selectedText,
        language: widget.request.sourceLanguage,
        targetLanguage: widget.request.targetLanguage,
        sourceType: media.sourceType,
        sourceId: media.sourceId,
        mediaLocator: media.locator,
      );
      if (!mounted) return;
      setState(() {
        _unavailable = false;
        _kind = resolved.kind;
        _itemId = resolved.item?.id;
      });
    } catch (e, st) {
      _log.warning('resolve CTA state failed', e, st);
      if (!mounted) return;
      setState(() {
        _unavailable = true;
        _kind = null;
        _itemId = null;
      });
    }
  }

  Future<void> _onPrimary() async {
    final l10n = AppLocalizations.of(context)!;
    final media = widget.request.mediaVocabularyContext;
    final kind = _kind;
    if (media == null || kind == null || _busy) return;

    if (kind == VocabularyCtaKind.alreadyInVocabulary) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.vocabularyConfirmDeleteTitle),
          content: Text(l10n.vocabularyConfirmDeleteBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.vocabularyCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.vocabularyDelete),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => _busy = true);
      try {
        final id = _itemId;
        if (id != null) {
          await ref.read(vocabularyRepositoryProvider).deleteItem(id);
        }
        await _refreshState();
      } catch (e, st) {
        _log.warning('delete vocabulary item failed', e, st);
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(vocabularyRepositoryProvider)
          .addWithContext(
            word: widget.request.selectedText,
            language: widget.request.sourceLanguage,
            targetLanguage: widget.request.targetLanguage,
            text: media.text,
            sourceType: media.sourceType,
            sourceId: media.sourceId,
            mediaLocator: media.locator,
          );
      await _refreshState();
    } catch (e, st) {
      _log.warning('add vocabulary failed', e, st);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _label(AppLocalizations l10n) {
    if (_busy) {
      return _kind == VocabularyCtaKind.alreadyInVocabulary
          ? l10n.vocabularyRemoving
          : l10n.vocabularyAdding;
    }
    return switch (_kind) {
      VocabularyCtaKind.notInBook => l10n.vocabularyAddToVocabulary,
      VocabularyCtaKind.addContext => l10n.vocabularyAddContext,
      VocabularyCtaKind.alreadyInVocabulary =>
        l10n.vocabularyAlreadyInVocabulary,
      null => l10n.vocabularyAddToVocabulary,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_unavailable || _kind == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final label = _label(l10n);
    final onPressed = _busy ? null : _onPrimary;

    if (_kind == VocabularyCtaKind.alreadyInVocabulary) {
      return EnjoyButton.secondary(onPressed: onPressed, child: Text(label));
    }
    return EnjoyButton.primary(onPressed: onPressed, child: Text(label));
  }
}
