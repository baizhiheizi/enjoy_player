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
  String get homeTitle => 'Home';

  @override
  String get homeRecentMedia => 'Recent media';

  @override
  String get homeEmptyTitle => 'No recent media';

  @override
  String get homeEmptyHint => 'Open a file or drop one here to start.';

  @override
  String get libraryTabMusic => 'Music';

  @override
  String get libraryTabVideo => 'Video';

  @override
  String get libraryEmptyMusicTitle => 'We couldn\'t find any music';

  @override
  String get libraryEmptyMusicHint =>
      'Your library doesn\'t contain any music content.';

  @override
  String get libraryEmptyVideoTitle => 'We couldn\'t find any videos';

  @override
  String get libraryEmptyVideoHint =>
      'Your library doesn\'t contain any video content.';

  @override
  String get actionOpenFiles => 'Open file(s)';

  @override
  String get searchHint => 'Search';

  @override
  String get transportRepeat => 'Repeat';

  @override
  String get transportFullscreen => 'Fullscreen';

  @override
  String get transportMore => 'More';

  @override
  String get transportCollapse => 'Collapse player';

  @override
  String get transportExpand => 'Expand player';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get importMedia => 'Import media';

  @override
  String get importingMedia => 'Importing media…';

  @override
  String get importMediaFailed => 'Could not import this file.';

  @override
  String get noMediaYet => 'No media yet';

  @override
  String get tapImportToAdd => 'Import audio or video from the toolbar.';

  @override
  String get navMainLabel => 'Primary navigation';

  @override
  String get miniPlayerMediaVideo => 'Video';

  @override
  String get miniPlayerMediaAudio => 'Audio';

  @override
  String get retry => 'Retry';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsAppearanceSubtitle =>
      'Theme follows your system settings.';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsAboutSubtitle =>
      'Enjoy Player — local transcripts and shadow reading.';

  @override
  String get settingsThemeRowTitle => 'Theme';

  @override
  String get settingsThemeDarkLocked => 'Premium UI uses dark theme.';

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
  String get playerTranscriptResizeHint =>
      'Drag to resize the transcript panel';

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
  String get transportMute => 'Mute';

  @override
  String get transportUnmute => 'Unmute';

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

  @override
  String get expandEchoBackward => 'Expand echo backward';

  @override
  String get expandEchoForward => 'Expand echo forward';

  @override
  String get shrinkEchoBackward => 'Shrink echo backward';

  @override
  String get shrinkEchoForward => 'Shrink echo forward';

  @override
  String get shadowReadingTitle => 'Shadow reading';

  @override
  String get shadowReadingHint =>
      'Practice speaking along this segment. Record your voice and compare pitch with the reference.';

  @override
  String get shadowReadingReferenceSnippet => 'Reference';

  @override
  String get pitchContourTitle => 'Pitch contour';

  @override
  String get pitchContourError => 'Could not analyze pitch for this segment.';

  @override
  String get pitchContourWaveform => 'Waveform';

  @override
  String get pitchContourReference => 'Reference pitch';

  @override
  String get pitchContourUser => 'Your pitch';

  @override
  String get shadowRecordingExisting => 'Saved takes';

  @override
  String get shadowRecordingEmpty => 'No recordings for this segment yet.';

  @override
  String get shadowRecordingTake => 'Take';

  @override
  String get shadowRecordingPlay => 'Play';

  @override
  String get shadowRecordingDelete => 'Delete';

  @override
  String get shadowRecordingRecord => 'Record';

  @override
  String get shadowRecordingStop => 'Stop';

  @override
  String get shadowRecordingMicDenied =>
      'Microphone permission is required to record.';

  @override
  String shadowRecordingSaveFailed(String reason) {
    return 'Couldn\'t save recording: $reason';
  }

  @override
  String get shadowRecordingPlaybackFailed => 'Couldn\'t play this take.';
}
