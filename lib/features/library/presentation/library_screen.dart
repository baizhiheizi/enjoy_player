/// Media library with premium list cards and import entry point.
library;

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:enjoy_player/features/library/application/library_media_provider.dart';
import 'package:enjoy_player/features/library/application/library_repository_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  Future<void> _importMedia(BuildContext context, WidgetRef ref) async {
    final pick = await FilePicker.pickFiles(type: FileType.media);
    if (pick == null || pick.files.isEmpty) return;
    final path = pick.files.single.path;
    if (path == null) return;
    final id = await ref
        .read(mediaLibraryRepositoryProvider)
        .importMedia(XFile(path));
    if (context.mounted) {
      context.push('/player/$id');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(libraryMediaProvider);
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.libraryTitle),
        actions: [
          IconButton(
            tooltip: l10n.importMedia,
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _importMedia(context, ref),
          ),
        ],
      ),
      body: mediaAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: t.contentMaxWidth),
                child: Padding(
                  padding: EdgeInsets.all(t.space24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.library_music_rounded,
                        size: 56,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                      ),
                      SizedBox(height: t.space16),
                      Text(
                        l10n.noMediaYet,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: t.space8),
                      Text(
                        l10n.tapImportToAdd,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      SizedBox(height: t.space24),
                      FilledButton.icon(
                        onPressed: () => _importMedia(context, ref),
                        icon: const Icon(Icons.upload_file_rounded),
                        label: Text(l10n.importMedia),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              t.space16,
              t.space8,
              t.space16,
              t.space24,
            ),
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(height: t.space8),
            itemBuilder: (context, index) {
              final m = items[index];
              final isVideo = m.kind == 'video';
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(t.radiusMd),
                  onTap: () => context.push('/player/${m.id}'),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: t.space16,
                      vertical: t.space12,
                    ),
                    child: Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(t.radiusSm),
                          ),
                          child: SizedBox(
                            width: 52,
                            height: 52,
                            child: Icon(
                              isVideo ? Icons.movie_outlined : Icons.audiotrack,
                              color: cs.primary,
                              size: 28,
                            ),
                          ),
                        ),
                        SizedBox(width: t.space16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: t.space4),
                              Text(
                                '${m.language} · ${_shortHash(m.fileHash)}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: cs.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(t.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
                SizedBox(height: t.space16),
                Text(
                  '${l10n.error}: $e',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: t.space16),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(libraryMediaProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _shortHash(String h) => h.length <= 8 ? h : '${h.substring(0, 8)}…';
