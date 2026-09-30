import 'dart:async';
import 'dart:io';

import 'package:enjoy_player/features/library/application/library_media_provider.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/library/presentation/widgets/local_library_tab_view.dart';
import 'package:enjoy_player/features/player/application/local_thumbnail_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _ts = DateTime.utc(2024, 1, 1);

final _audioSample = Media(
  id: 'audio-1',
  kind: MediaKind.audio,
  title: 'Track',
  sourceUri: 'file:///track.mp3',
  durationMs: 60_000,
  language: 'en',
  contentHash: 'h',
  fileSize: 1024,
  createdAt: _ts,
  updatedAt: _ts,
);

final _videoSample = Media(
  id: 'video-1',
  kind: MediaKind.video,
  title: 'Clip',
  sourceUri: 'file:///clip.mp4',
  durationMs: 120_000,
  language: 'ja',
  contentHash: 'h',
  fileSize: 2048,
  createdAt: _ts,
  updatedAt: _ts,
);

bool _hasFileImageProvider(Image image) {
  final provider = image.image;
  return provider is FileImage ||
      provider is ResizeImage && provider.imageProvider is FileImage;
}

bool _isFileImage(Image image, File file) {
  final provider = image.image;
  if (provider is FileImage) return provider.file.path == file.path;
  if (provider is ResizeImage) {
    final inner = provider.imageProvider;
    return inner is FileImage && inner.file.path == file.path;
  }
  return false;
}

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(body: child),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

Widget _wrapWithThumbnailOverride(Widget child, Future<File?> thumb) {
  return ProviderScope(
    overrides: [localThumbnailFileProvider.overrideWith((ref, path) => thumb)],
    child: MaterialApp(
      home: Scaffold(body: child),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalAudioLibraryBody', () {
    testWidgets('empty items show the empty-audio placeholder', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LocalAudioLibraryBody(
            items: <Media>[],
            searchQuery: '',
            totalInLibraryOfKind: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(LocalAudioLibraryBody));
      final loc = AppLocalizations.of(ctx)!;
      expect(find.text(loc.libraryEmptyAudioTitle), findsOneWidget);
      expect(find.text(loc.libraryEmptyAudioHint), findsOneWidget);
    });

    testWidgets(
      'empty items + active search + library has audio → search empty CTA',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const LocalAudioLibraryBody(
              items: <Media>[],
              searchQuery: 'hello',
              totalInLibraryOfKind: 3,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final ctx = tester.element(find.byType(LocalAudioLibraryBody));
        final loc = AppLocalizations.of(ctx)!;
        expect(find.text(loc.librarySearchNoMatchesTitle), findsOneWidget);
        expect(find.text(loc.librarySearchNoMatchesHint), findsOneWidget);
        expect(find.text(loc.librarySearchClear), findsOneWidget);
      },
    );

    testWidgets('non-empty items render a listview of MediaCardRow rows', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          LocalAudioLibraryBody(
            items: [_audioSample],
            searchQuery: '',
            totalInLibraryOfKind: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Track'), findsOneWidget);
    });
  });

  group('LocalVideoLibraryBody', () {
    testWidgets('empty items show the empty-video placeholder', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LocalVideoLibraryBody(
            items: <Media>[],
            searchQuery: '',
            totalInLibraryOfKind: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(LocalVideoLibraryBody));
      final loc = AppLocalizations.of(ctx)!;
      expect(find.text(loc.libraryEmptyVideoTitle), findsOneWidget);
      expect(find.text(loc.libraryEmptyVideoHint), findsOneWidget);
    });

    testWidgets(
      'empty items + active search + library has video → search empty CTA',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const LocalVideoLibraryBody(
              items: <Media>[],
              searchQuery: 'xyz',
              totalInLibraryOfKind: 7,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final ctx = tester.element(find.byType(LocalVideoLibraryBody));
        final loc = AppLocalizations.of(ctx)!;
        expect(find.text(loc.librarySearchNoMatchesTitle), findsOneWidget);
        expect(find.text(loc.librarySearchClear), findsOneWidget);
      },
    );

    testWidgets('non-empty items render a gridview of MediaCardTile tiles', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          LocalVideoLibraryBody(
            items: [_videoSample],
            searchQuery: '',
            totalInLibraryOfKind: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clip'), findsOneWidget);
    });

    testWidgets(
      'video tile artwork resolves through the async thumbnail provider',
      (tester) async {
        final overrideFile = File('/provider-resolved-artwork.jpg');
        await tester.pumpWidget(
          _wrapWithThumbnailOverride(
            LocalVideoLibraryBody(
              items: [
                Media(
                  id: 'video-thumb',
                  kind: MediaKind.video,
                  title: 'Clipped',
                  sourceUri: 'file:///clip.mp4',
                  thumbnailPath: '/nonexistent/on-disk.jpg',
                  durationMs: 120_000,
                  language: 'ja',
                  contentHash: 'h',
                  fileSize: 2048,
                  createdAt: _ts,
                  updatedAt: _ts,
                ),
              ],
              searchQuery: '',
              totalInLibraryOfKind: 1,
            ),
            Future.value(overrideFile),
          ),
        );
        await tester.pumpAndSettle();

        final image = tester.widgetList<Image>(
          find.byWidgetPredicate(
            (w) => w is Image && _isFileImage(w, overrideFile),
          ),
        );
        expect(image, hasLength(1));
      },
    );

    testWidgets(
      'video tile shows the fallback while the async resolve is pending',
      (tester) async {
        final pending = Completer<File?>();
        await tester.pumpWidget(
          _wrapWithThumbnailOverride(
            LocalVideoLibraryBody(
              items: [
                Media(
                  id: 'video-thumb',
                  kind: MediaKind.video,
                  title: 'Clipped',
                  sourceUri: 'file:///clip.mp4',
                  thumbnailPath: '/nonexistent/on-disk.jpg',
                  durationMs: 120_000,
                  language: 'ja',
                  contentHash: 'h',
                  fileSize: 2048,
                  createdAt: _ts,
                  updatedAt: _ts,
                ),
              ],
              searchQuery: '',
              totalInLibraryOfKind: 1,
            ),
            pending.future,
          ),
        );
        await tester.pump();

        expect(
          find.byWidgetPredicate((w) => w is Image && _hasFileImageProvider(w)),
          findsNothing,
        );
      },
    );
  });

  group('LocalLibraryTabView totals', () {
    testWidgets(
      'count-preserving library changes do not rebuild the tab bodies',
      (tester) async {
        final media = StreamController<List<Media>>();
        final tabController = TabController(length: 2, vsync: tester);
        addTearDown(() async {
          tabController.dispose();
          await media.close();
        });

        Media videoWith({String? syncStatus}) => Media(
          id: 'video-1',
          kind: MediaKind.video,
          title: 'Clip',
          sourceUri: 'file:///clip.mp4',
          durationMs: 120_000,
          language: 'ja',
          contentHash: 'h',
          fileSize: 2048,
          syncStatus: syncStatus,
          createdAt: _ts,
          updatedAt: _ts,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              libraryMediaProvider.overrideWith((ref) => media.stream),
              libraryFilteredListsProvider.overrideWith(
                (ref) => Stream.value((audio: <Media>[], video: [videoWith()])),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: LocalLibraryTabView(tabController: tabController),
              ),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );
        media.add([videoWith()]);
        await tester.pumpAndSettle();

        final before = tester.widget<LocalVideoLibraryBody>(
          find.byType(LocalVideoLibraryBody),
        );

        media.add([videoWith(syncStatus: 'pending')]);
        await tester.pumpAndSettle();

        final after = tester.widget<LocalVideoLibraryBody>(
          find.byType(LocalVideoLibraryBody),
        );
        expect(
          identical(before, after),
          isTrue,
          reason:
              'a syncStatus flip keeps both counts; the tab bodies must '
              'not rebuild',
        );

        media.add([videoWith(), videoWith().rebuildWithId('video-2')]);
        await tester.pumpAndSettle();

        final grown = tester.widget<LocalVideoLibraryBody>(
          find.byType(LocalVideoLibraryBody),
        );
        expect(identical(before, grown), isFalse);
        expect(grown.totalInLibraryOfKind, 2);
      },
    );
  });
}

extension on Media {
  Media rebuildWithId(String id) => Media(
    id: id,
    kind: kind,
    title: title,
    sourceUri: sourceUri,
    thumbnailPath: thumbnailPath,
    durationMs: durationMs,
    language: language,
    contentHash: contentHash,
    fileSize: fileSize,
    mediaUrl: mediaUrl,
    source: source,
    provider: provider,
    syncStatus: syncStatus,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
