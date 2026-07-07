/// User-initiated diagnostic zip export (save / share dialog).
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import 'package:enjoy_player/core/diagnostics/diagnostic_export.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

bool get _isMobileSharePlatform => Platform.isIOS || Platform.isAndroid;

Future<void> exportDiagnosticReport(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final locale = Localizations.localeOf(context).toLanguageTag();
  try {
    final info = await PackageInfo.fromPlatform();
    final manifest = defaultExportManifest(
      appVersion: info.version,
      buildNumber: info.buildNumber,
      locale: locale,
    );
    final zipBytes = await buildDiagnosticExportZip(manifest: manifest);
    if (zipBytes.isEmpty) {
      throw StateError('Diagnostic export zip was empty');
    }
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final fileName = 'EnjoyPlayer-diagnostics-$date.zip';
    final bytes = Uint8List.fromList(zipBytes);

    if (_isMobileSharePlatform) {
      final file = XFile.fromData(
        bytes,
        mimeType: 'application/zip',
        name: fileName,
      );
      final result = await SharePlus.instance.share(ShareParams(files: [file]));
      if (!context.mounted) return;
      if (result.status == ShareResultStatus.dismissed) return;
      AppNotice.success(context, l10n.settingsDiagnosticsExportSuccess);
      return;
    }

    final savedPath = await FilePicker.saveFile(
      dialogTitle: l10n.settingsDiagnosticsExportTitle,
      fileName: fileName,
      bytes: bytes,
    );
    if (!context.mounted) return;
    if (savedPath == null) return;
    AppNotice.success(context, l10n.settingsDiagnosticsExportSuccess);
  } on Object {
    if (!context.mounted) return;
    AppNotice.error(context, l10n.settingsDiagnosticsExportError);
  }
}
