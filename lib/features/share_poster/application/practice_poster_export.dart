/// PNG capture and platform share / save for practice posters.
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:enjoy_player/core/logging/log.dart';

final _log = logNamed('PracticePosterExport');

/// Capture scale — 360×640 logical → 1080×1920 PNG.
const double practicePosterExportPixelRatio = 3;

Future<Uint8List?> captureRepaintBoundaryPng(
  GlobalKey boundaryKey, {
  double pixelRatio = practicePosterExportPixelRatio,
}) async {
  final context = boundaryKey.currentContext;
  if (context == null) return null;

  final renderObject = context.findRenderObject();
  if (renderObject is! RenderRepaintBoundary) return null;
  if (renderObject.debugNeedsPaint) {
    await Future<void>.delayed(Duration.zero);
  }

  final image = await renderObject.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData?.buffer.asUint8List();
}

bool get _isMobileSharePlatform => Platform.isIOS || Platform.isAndroid;

Future<void> sharePracticePosterPng(Uint8List pngBytes) async {
  final file = XFile.fromData(
    pngBytes,
    mimeType: 'image/png',
    name: 'enjoy-practice-poster.png',
  );
  await SharePlus.instance.share(ShareParams(files: [file]));
}

Future<String?> savePracticePosterPng(Uint8List pngBytes) async {
  final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final fileName = 'EnjoyPlayer-practice-$date.png';
  return FilePicker.saveFile(fileName: fileName, bytes: pngBytes);
}

enum PracticePosterExportOutcome { shared, saved, cancelled, failed }

Future<PracticePosterExportOutcome> exportPracticePosterPng(
  Uint8List pngBytes,
) async {
  try {
    if (_isMobileSharePlatform) {
      await sharePracticePosterPng(pngBytes);
      return PracticePosterExportOutcome.shared;
    }
    final path = await savePracticePosterPng(pngBytes);
    if (path == null) return PracticePosterExportOutcome.cancelled;
    return PracticePosterExportOutcome.saved;
  } on Object catch (e, st) {
    _log.warning('Practice poster export failed', e, st);
    return PracticePosterExportOutcome.failed;
  }
}
