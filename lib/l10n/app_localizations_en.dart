// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Enjoy Player';

  @override
  String get libraryTitle => 'Library';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get importMedia => 'Import media';

  @override
  String get noMediaYet => 'No media yet';

  @override
  String get tapImportToAdd => 'Tap + to import audio or video files.';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get previousLine => 'Previous line';

  @override
  String get nextLine => 'Next line';

  @override
  String get replayLine => 'Replay line';

  @override
  String get echoMode => 'Echo mode';

  @override
  String get exitEchoMode => 'Exit echo mode';

  @override
  String get transcript => 'Transcript';

  @override
  String get importSubtitle => 'Import subtitle';

  @override
  String get noTranscript => 'No transcript';

  @override
  String get importSrtOrVtt => 'Import an .srt or .vtt file.';

  @override
  String get miniPlayerOpen => 'Open player';

  @override
  String get loading => 'Loading…';

  @override
  String get error => 'Error';

  @override
  String get speed => 'Speed';

  @override
  String get volume => 'Volume';

  @override
  String get repeatNone => 'Repeat off';

  @override
  String get repeatSegment => 'Repeat segment';

  @override
  String get settingsPlaceholder => 'Player preferences will appear here.';

  @override
  String get subtitles => 'Subtitles';

  @override
  String get subtitlesPrimary => 'Primary';

  @override
  String get subtitlesTranslation => 'Translation (optional)';

  @override
  String get subtitlesNone => 'None';

  @override
  String get subtitlesImportFile => 'Import subtitle file…';

  @override
  String get subtitlesEmbedded => 'Embedded';

  @override
  String get subtitlesImported => 'Imported';

  @override
  String get subtitlesDeleteTrack => 'Delete track';

  @override
  String get subtitlesDetected => 'Subtitles detected — tap CC to choose';

  @override
  String get subtitlesChoose => 'Choose';

  @override
  String get importSubtitleSuccess => 'Subtitle imported';

  @override
  String get noTranscriptHint =>
      'Open a video with embedded subtitles, or import an .srt/.vtt file.';
}
