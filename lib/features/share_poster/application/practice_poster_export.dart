/// PNG capture and platform share / save for practice posters.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/platform/file_share_export.dart';

final _log = logNamed('PracticePosterExport');

/// Capture scale — 360×640 logical → 1080×1920 PNG.
const double practicePosterExportPixelRatio = 3;

/// Rasterize a [RepaintBoundary] keyed by [boundaryKey] to PNG bytes.
///
/// Do **not** read [RenderObject.debugNeedsPaint] here: on Flutter versions
/// that still implement that getter with `late` + `assert`, accessing it in
/// release/profile throws `LateInitializationError` and aborts export.
/// Callers should already wait for a settled frame; this method adds a short
/// paint settle + retry loop for boundaries that are still compositing.
Future<Uint8List?> captureRepaintBoundaryPng(
  GlobalKey boundaryKey, {
  double pixelRatio = practicePosterExportPixelRatio,
  int maxAttempts = 3,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final renderObject = boundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;

    await Future<void>.delayed(Duration.zero);

    try {
      final image = await renderObject.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } on Object catch (e, st) {
      if (attempt == maxAttempts - 1) {
        _log.warning('Practice poster capture failed', e, st);
        return null;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }
  return null;
}

Future<FileShareOutcome> exportPracticePosterPng(Uint8List pngBytes) {
  final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
  return saveOrShareBytes(
    bytes: pngBytes,
    fileName: 'EnjoyPlayer-practice-$date.png',
    mimeType: 'image/png',
  );
}
