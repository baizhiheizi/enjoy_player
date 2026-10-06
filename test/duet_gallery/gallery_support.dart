import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../support/test_path_provider.dart';

/// Directory (relative to the repo root) the board PNGs are written to;
/// `tool/duet_compare.sh` pairs them with `docs/design/duet/renders/`.
const kGalleryOutDir = 'build/duet_gallery';

/// Board frame presets from `docs/design/duet/README.md`:
/// desktop 1440 × 900 at 1×, compact 880 × 560 at 1×, phone 390 × 844 at 2×.
enum GalleryFrame {
  desktop(1440, 900, 1),
  compact(880, 560, 1),
  phone(390, 844, 2);

  const GalleryFrame(this.width, this.height, this.devicePixelRatio);

  final double width;
  final double height;
  final double devicePixelRatio;

  Size get size => Size(width, height);
}

final _boundaryKey = GlobalKey();

/// Offline harness bootstrap: Phosphor from the asset manifest, google_fonts
/// from the bundled assets (`allowRuntimeFetching = false`), both themes built.
Future<void> setUpGallery() async {
  final scratch = Directory.systemTemp.createTempSync('enjoy-gallery');
  addTearDown(() => scratch.deleteSync(recursive: true));
  PathProviderPlatform.instance = TestPathProvider(scratch.path);
  GoogleFonts.config.allowRuntimeFetching = false;
  await _loadManifestFonts();
  buildAppTheme(Brightness.dark);
  buildAppTheme(Brightness.light);
  for (final weight in [FontWeight.w400, FontWeight.w500, FontWeight.w600]) {
    GoogleFonts.geist(fontWeight: weight);
    GoogleFonts.sourceSerif4(fontWeight: weight);
  }
  for (final weight in [FontWeight.w500, FontWeight.w600]) {
    GoogleFonts.geistMono(fontWeight: weight);
  }
  GoogleFonts.instrumentSerif();
  GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700);
  GoogleFonts.playfairDisplay(
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
  );
  GoogleFonts.notoSans();
  await GoogleFonts.pendingFonts();
}

Future<void> _loadManifestFonts() async {
  final raw = await rootBundle.loadString('FontManifest.json');
  final list = json.decode(raw) as List<dynamic>;
  for (final entry in list) {
    final family = (entry as Map<String, dynamic>)['family'] as String;
    final loader = FontLoader(family);
    for (final font in entry['fonts'] as List<dynamic>) {
      final asset = (font as Map<String, dynamic>)['asset'] as String;
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}

/// Google-font asset loads and image streams finish outside the fake async
/// zone; pump real time until typography and layout stop changing.
Future<void> settleGallery(WidgetTester tester, {int rounds = 12}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.pump(const Duration(milliseconds: 60));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)),
    );
  }
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Pumps [app] at [frame]'s board size, waits for fonts, writes
/// `<kGalleryOutDir>/<board>.png`, then unmounts the tree and elapses a
/// second of fake time — drift's stream teardown schedules zero-duration
/// timers that must fire before the binding's pending-timer check. Pass the
/// scene's in-memory [db] to have it closed in teardown.
Future<void> shootBoard(
  WidgetTester tester,
  String board,
  Widget app, {
  GalleryFrame frame = GalleryFrame.desktop,
  AppDatabase? db,
  Future<void> Function(WidgetTester tester)? before,
}) async {
  tester.view.physicalSize = frame.size * frame.devicePixelRatio;
  tester.view.devicePixelRatio = frame.devicePixelRatio;
  addTearDown(tester.view.reset);
  debugDisableShadows = false;
  debugDefaultTargetPlatformOverride = frame == GalleryFrame.phone
      ? TargetPlatform.android
      : TargetPlatform.linux;
  await tester.pumpWidget(RepaintBoundary(key: _boundaryKey, child: app));
  await settleGallery(tester);
  if (before != null) {
    await before(tester);
    await settleGallery(tester);
  }
  final boundary =
      _boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: frame.devicePixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$kGalleryOutDir/$board.png');
    await file.parent.create(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
  debugDisableShadows = true;
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
  debugDefaultTargetPlatformOverride = null;
  if (db != null) {
    addTearDown(db.close);
  }
}
