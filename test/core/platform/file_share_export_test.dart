import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

import 'package:enjoy_player/core/platform/file_share_export.dart';

class _FakeSharePlatform extends SharePlatform {
  ShareResult Function(ShareParams params) onShare = (_) =>
      throw UnimplementedError();
  ShareParams? lastParams;
  var calls = 0;

  void reset() {
    lastParams = null;
    calls = 0;
  }

  @override
  Future<ShareResult> share(ShareParams params) {
    calls++;
    lastParams = params;
    return Future.value(onShare(params));
  }
}

class _FakeFilePickerPlatform extends FilePickerPlatform {
  Future<Uri?> Function({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
  })
  onSave =
      ({required fileName, required bytes, required mimeType, dialogTitle}) =>
          throw UnimplementedError();
  String? lastDialogTitle;
  Uint8List? lastBytes;
  String? lastMimeType;
  var calls = 0;

  void reset() {
    lastDialogTitle = null;
    lastBytes = null;
    lastMimeType = null;
    calls = 0;
  }

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) {
    calls++;
    lastDialogTitle = dialogTitle;
    lastBytes = bytes;
    lastMimeType = mimeType;
    return Future.value(
      onSave(
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
        dialogTitle: dialogTitle,
      ),
    );
  }
}

void main() {
  final shareFake = _FakeSharePlatform();
  final pickerFake = _FakeFilePickerPlatform();
  late final SharePlatform originalSharePlatform;
  late final FilePickerPlatform originalPickerPlatform;

  setUpAll(() {
    originalSharePlatform = SharePlatform.instance;
    originalPickerPlatform = FilePickerPlatform.instance;
    SharePlatform.instance = shareFake;
    FilePickerPlatform.instance = pickerFake;
  });

  tearDownAll(() {
    SharePlatform.instance = originalSharePlatform;
    FilePickerPlatform.instance = originalPickerPlatform;
  });

  setUp(() {
    shareFake.reset();
    pickerFake.reset();
  });

  Future<void> withPlatform(TargetPlatform platform) async {
    debugDefaultTargetPlatformOverride = platform;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
  }

  group('saveOrShareBytes', () {
    test(
      'mobile: accepted share resolves shared and carries mime / payload',
      () async {
        await withPlatform(TargetPlatform.iOS);
        shareFake.onShare = (_) =>
            const ShareResult('raw', ShareResultStatus.success);

        final outcome = await saveOrShareBytes(
          bytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'clip.mp4',
          mimeType: 'video/mp4',
        );

        expect(outcome, FileShareOutcome.shared);
        expect(shareFake.calls, 1);
        expect(shareFake.lastParams?.files?.single.mimeType, 'video/mp4');
        expect(
          await shareFake.lastParams?.files?.single.readAsBytes(),
          Uint8List.fromList([1, 2, 3]),
        );
        expect(pickerFake.calls, 0);
      },
    );

    test('mobile: dismissed share sheet resolves cancelled', () async {
      await withPlatform(TargetPlatform.android);
      shareFake.onShare = (_) =>
          const ShareResult('raw', ShareResultStatus.dismissed);

      final outcome = await saveOrShareBytes(
        bytes: Uint8List.fromList([1]),
        fileName: 'a.csv',
        mimeType: 'text/csv',
      );

      expect(outcome, FileShareOutcome.cancelled);
    });

    test('mobile: platform error resolves failed', () async {
      await withPlatform(TargetPlatform.iOS);
      shareFake.onShare = (_) => throw StateError('no share target');

      final outcome = await saveOrShareBytes(
        bytes: Uint8List.fromList([1]),
        fileName: 'a.zip',
        mimeType: 'application/zip',
      );

      expect(outcome, FileShareOutcome.failed);
    });

    test(
      'desktop: chosen destination resolves saved with staged bytes',
      () async {
        await withPlatform(TargetPlatform.linux);
        pickerFake.onSave =
            ({
              required fileName,
              required bytes,
              required mimeType,
              dialogTitle,
            }) => Future.value(Uri.file('/tmp/$fileName'));

        final outcome = await saveOrShareBytes(
          bytes: Uint8List.fromList([7, 8]),
          fileName: 'a.srt',
          mimeType: 'application/x-subrip',
          dialogTitle: 'Download transcript',
        );

        expect(outcome, FileShareOutcome.saved);
        expect(pickerFake.calls, 1);
        expect(pickerFake.lastBytes, Uint8List.fromList([7, 8]));
        expect(pickerFake.lastMimeType, 'application/x-subrip');
        expect(pickerFake.lastDialogTitle, 'Download transcript');
        expect(shareFake.calls, 0);
      },
    );

    test('desktop: cancelled dialog resolves cancelled', () async {
      await withPlatform(TargetPlatform.macOS);
      pickerFake.onSave =
          ({
            required fileName,
            required bytes,
            required mimeType,
            dialogTitle,
          }) => Future.value(null);

      final outcome = await saveOrShareBytes(
        bytes: Uint8List.fromList([1]),
        fileName: 'a.srt',
        mimeType: 'application/x-subrip',
      );

      expect(outcome, FileShareOutcome.cancelled);
    });

    test('desktop: platform error resolves failed', () async {
      await withPlatform(TargetPlatform.windows);
      pickerFake.onSave =
          ({
            required fileName,
            required bytes,
            required mimeType,
            dialogTitle,
          }) => throw StateError('picker unavailable');

      final outcome = await saveOrShareBytes(
        bytes: Uint8List.fromList([1]),
        fileName: 'a.srt',
        mimeType: 'application/x-subrip',
      );

      expect(outcome, FileShareOutcome.failed);
    });
  });

  group('saveOrShareFile', () {
    test('mobile: shares the on-disk path without staging bytes', () async {
      await withPlatform(TargetPlatform.iOS);
      final tmp = await Directory.systemTemp.createTemp('share-file-test');
      addTearDown(() => tmp.delete(recursive: true));
      final source = File('${tmp.path}/big-clip.mp4')
        ..writeAsBytesSync(Uint8List.fromList([9, 9, 9]));
      shareFake.onShare = (_) =>
          const ShareResult('raw', ShareResultStatus.success);

      final outcome = await saveOrShareFile(
        sourcePath: source.path,
        fileName: 'big-clip.mp4',
        mimeType: 'video/mp4',
      );

      expect(outcome, FileShareOutcome.shared);
      expect(shareFake.lastParams?.files?.single.path, source.path);
      expect(pickerFake.calls, 0);
    });

    test('desktop: stages the on-disk bytes through the save dialog', () async {
      await withPlatform(TargetPlatform.linux);
      final tmp = await Directory.systemTemp.createTemp('share-file-test');
      addTearDown(() => tmp.delete(recursive: true));
      final source = File('${tmp.path}/clip.mp4')
        ..writeAsBytesSync(Uint8List.fromList([4, 5, 6]));
      pickerFake.onSave =
          ({
            required fileName,
            required bytes,
            required mimeType,
            dialogTitle,
          }) => Future.value(Uri.file('/tmp/$fileName'));

      final outcome = await saveOrShareFile(
        sourcePath: source.path,
        fileName: 'clip.mp4',
        mimeType: 'video/mp4',
        dialogTitle: 'Export the loop as a clip…',
      );

      expect(outcome, FileShareOutcome.saved);
      expect(pickerFake.lastBytes, Uint8List.fromList([4, 5, 6]));
      expect(pickerFake.lastDialogTitle, 'Export the loop as a clip…');
    });
  });
}
