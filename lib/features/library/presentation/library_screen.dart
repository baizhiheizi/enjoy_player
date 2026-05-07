/// Media library grid/list with import entry point.
library;

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:enjoy_player/features/library/application/library_media_provider.dart';
import 'package:enjoy_player/features/library/application/library_repository_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(libraryMediaProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.libraryTitle),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: mediaAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.noMediaYet,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.tapImportToAdd,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final m = items[index];
              return ListTile(
                leading: Icon(
                  m.kind == 'video' ? Icons.movie : Icons.audiotrack,
                ),
                title: Text(m.title),
                subtitle: Text(
                  '${m.language} · ${_shortHash(m.fileHash)}',
                ),
                onTap: () => context.push('/player/${m.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.error}: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.importMedia,
        onPressed: () async {
          final pick = await FilePicker.platform.pickFiles(type: FileType.media);
          if (pick == null || pick.files.isEmpty) return;
          final path = pick.files.single.path;
          if (path == null) return;
          final id = await ref
              .read(mediaLibraryRepositoryProvider)
              .importMedia(XFile(path));
          if (context.mounted) {
            context.push('/player/$id');
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

String _shortHash(String h) => h.length <= 8 ? h : '${h.substring(0, 8)}…';
