import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/core/theme/typography.dart';
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
/// The `store…` presets render at the exact pixel sizes of the store
/// listings in `assets/store/` (see `tool/store_screenshots.sh`).
enum GalleryFrame {
  desktop(1440, 900, 1),
  compact(880, 560, 1),
  phone(390, 844, 2, mobile: true),
  storeIosPhone(430, 932, 3, mobile: true),
  storeAndroidPhone(400, 890, 3, mobile: true),
  storeIosPadPortrait(1032, 1376, 2, mobile: true),
  storeIosPadLandscape(1376, 1032, 2, mobile: true),
  storeAndroidPad(1600, 1068, 2, mobile: true),
  storeMacos(1671, 1162, 2);

  const GalleryFrame(
    this.width,
    this.height,
    this.devicePixelRatio, {
    this.mobile = false,
  });

  final double width;
  final double height;
  final double devicePixelRatio;

  /// Shot as a touch platform (Android) rather than a desktop one (Linux).
  final bool mobile;

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
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('com.llfbandit.record/messages'),
        (call) async => switch (call.method) {
          'hasPermission' => true,
          'listInputDevices' => <Object>[],
          _ => null,
        },
      );
  await _loadManifestFonts();
  await _loadHostCjkFonts();
  buildAppTheme(Brightness.dark);
  buildAppTheme(Brightness.light);
  for (final weight in [FontWeight.w400, FontWeight.w500, FontWeight.w600]) {
    GoogleFonts.geist(fontWeight: weight);
    GoogleFonts.literata(fontWeight: weight);
  }
  for (final weight in [FontWeight.w500, FontWeight.w600]) {
    GoogleFonts.geistMono(fontWeight: weight);
  }
  GoogleFonts.notoSans();
  await GoogleFonts.pendingFonts();
}

/// Registers the host's Noto CJK Simplified Chinese faces under every CJK
/// fallback name the theme lists, and under `Roboto` for unstyled text;
/// `flutter test` has no platform fallback, and an unregistered fallback name
/// resolves to the built-in `FlutterTest` font, whose boxes would win for
/// code points it claims (六, 是, 一, …). Missing files are skipped.
Future<void> _loadHostCjkFonts() async {
  const dirs = ['/usr/share/fonts/noto-cjk', '/usr/share/fonts/opentype/noto'];
  const scFaceIndex = 2;
  for (final (families, file) in [
    (
      [...kCjkNotoSansFallbacks, ...kCjkSansFallbacks, 'Roboto'],
      'NotoSansCJK-Regular.ttc',
    ),
    (
      [...kCjkNotoSerifFallbacks, ...kCjkSerifFallbacks],
      'NotoSerifCJK-Regular.ttc',
    ),
  ]) {
    for (final dir in dirs) {
      final font = File('$dir/$file');
      if (!font.existsSync()) continue;
      final face = _ttcFace(font.readAsBytesSync(), scFaceIndex);
      for (final family in families) {
        await (FontLoader(family)..addFont(Future.value(face))).load();
      }
      break;
    }
  }
}

/// Rebuilds face [index] of a TrueType collection as a standalone sfnt.
ByteData _ttcFace(Uint8List ttc, int index) {
  final src = ByteData.sublistView(ttc);
  final faceOffset = src.getUint32(12 + 4 * index);
  final numTables = src.getUint16(faceOffset + 4);
  final headerSize = 12 + 16 * numTables;
  final tables = [
    for (var i = 0; i < numTables; i++)
      (
        record: faceOffset + 12 + 16 * i,
        offset: src.getUint32(faceOffset + 12 + 16 * i + 8),
        length: src.getUint32(faceOffset + 12 + 16 * i + 12),
      ),
  ];
  final total = tables.fold(
    headerSize,
    (sum, t) => sum + ((t.length + 3) & ~3),
  );
  final out = Uint8List(total);
  out.setRange(0, 12, ttc, faceOffset);
  final dst = ByteData.sublistView(out);
  var cursor = headerSize;
  for (final (i, t) in tables.indexed) {
    out.setRange(12 + 16 * i, 12 + 16 * i + 16, ttc, t.record);
    dst.setUint32(12 + 16 * i + 8, cursor);
    out.setRange(cursor, cursor + t.length, ttc, t.offset);
    cursor += (t.length + 3) & ~3;
  }
  return dst;
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
  debugDefaultTargetPlatformOverride = frame.mobile
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
