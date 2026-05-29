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

Future<void> showDiscoverSubscribeSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final controller = TextEditingController();
  final l10n = AppLocalizations.of(context)!;

  await showEnjoySheet<void>(
    context: context,
    builder: (ctx) {
      var submitting = false;
      return StatefulBuilder(
        builder: (context, setState) {
          return SafeArea(
            child: Padding(
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
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: l10n.discoverSubscribePlaceholder,
                      border: const OutlineInputBorder(),
                    ),
                    enabled: !submitting,
                    onSubmitted: submitting
                        ? null
                        : (_) => unawaited(
                            _submit(
                              ctx,
                              ref,
                              controller.text,
                              setState,
                              () {
                                submitting = true;
                              },
                              () {
                                submitting = false;
                              },
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: submitting
                        ? null
                        : () => unawaited(
                            _submit(
                              ctx,
                              ref,
                              controller.text,
                              setState,
                              () {
                                submitting = true;
                                setState(() {});
                              },
                              () {
                                submitting = false;
                                setState(() {});
                              },
                            ),
                          ),
                    child: submitting
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
          );
        },
      );
    },
  );

  controller.dispose();
}

Future<void> _submit(
  BuildContext context,
  WidgetRef ref,
  String input,
  StateSetter setState,
  VoidCallback onStart,
  VoidCallback onEnd,
) async {
  final l10n = AppLocalizations.of(context)!;
  onStart();
  setState(() {});
  try {
    await ref.read(discoverRepositoryProvider).subscribeFromUserInput(input);
    await ref.read(discoverRefreshStateProvider.notifier).refresh(force: true);
    if (!context.mounted) return;
    Navigator.pop(context);
    AppNotice.success(context, l10n.discoverSubscribed);
  } on YoutubeChannelResolveException catch (e) {
    if (context.mounted) {
      AppNotice.error(context, e.message);
    }
  } catch (_) {
    if (context.mounted) {
      AppNotice.error(context, l10n.discoverSubscribeFailed);
    }
  } finally {
    onEnd();
    setState(() {});
  }
}
