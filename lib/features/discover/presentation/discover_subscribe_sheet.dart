/// Subscribe to a YouTube channel by URL or handle.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/theme/widgets/sheet_drag_handle.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/discover/data/youtube_channel_resolver.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

Future<void> showDiscoverSubscribeSheet(BuildContext context) {
  return showEnjoySheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _DiscoverSubscribeSheet(),
  );
}

class _DiscoverSubscribeSheet extends ConsumerStatefulWidget {
  const _DiscoverSubscribeSheet();

  @override
  ConsumerState<_DiscoverSubscribeSheet> createState() =>
      _DiscoverSubscribeSheetState();
}

class _DiscoverSubscribeSheetState
    extends ConsumerState<_DiscoverSubscribeSheet> {
  late final TextEditingController _controller;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l10n = AppLocalizations.of(context)!;
    final input = _controller.text;
    setState(() => _submitting = true);
    try {
      await ref.read(discoverRepositoryProvider).subscribeFromUserInput(input);
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      await ref
          .read(discoverRefreshStateProvider.notifier)
          .refresh(force: true);
      if (!mounted) return;
      Navigator.pop(context);
      AppNotice.success(context, l10n.discoverSubscribed);
    } on YoutubeChannelResolveException catch (e) {
      if (mounted) {
        AppNotice.error(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        AppNotice.error(context, l10n.discoverSubscribeFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PaddedSheetDragHandle(),
              Text(
                l10n.discoverSubscribeTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.discoverSubscribeHint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.discoverSubscribePlaceholder,
                  border: const OutlineInputBorder(),
                ),
                enabled: !_submitting,
                onSubmitted: _submitting ? null : (_) => unawaited(_submit()),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submitting ? null : () => unawaited(_submit()),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.discoverSubscribeAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
