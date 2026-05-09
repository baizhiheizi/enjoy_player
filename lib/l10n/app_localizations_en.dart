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
  String get shadowRecordingPause => 'Pause';

  @override
  String get shadowRecordingChooseTake => 'Switch take';

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

  @override
  String get hotkeysTitle => 'Keyboard shortcuts';

  @override
  String get hotkeysHintFooter => 'Press Shift+/ (?) to open this list.';

  @override
  String get hotkeysCustomizedBadge => 'Custom';

  @override
  String get hotkeysSectionKeyboard => 'Keyboard shortcuts';

  @override
  String get hotkeysResetBinding => 'Reset';

  @override
  String get hotkeysResetAll => 'Reset all shortcuts';

  @override
  String get hotkeysCaptureTitle => 'Press new shortcut';

  @override
  String get hotkeysCaptureHint => 'Press a key combination. Escape cancels.';

  @override
  String get hotkeysConflictError => 'That shortcut is already used.';

  @override
  String get hotkeysScopeGlobal => 'Global';

  @override
  String get hotkeysScopePlayer => 'Player';

  @override
  String get hotkeysScopeLibrary => 'Library';

  @override
  String get hotkeysScopeModal => 'Modal';

  @override
  String get hotkeysDescHelp => 'Show keyboard shortcuts';

  @override
  String get hotkeysDescSearch => 'Open search';

  @override
  String get hotkeysDescSettings => 'Open settings';

  @override
  String get hotkeysDescTogglePlay => 'Play / Pause';

  @override
  String get hotkeysDescToggleExpand => 'Toggle player expand/collapse';

  @override
  String get hotkeysDescPrevLine => 'Play previous line';

  @override
  String get hotkeysDescNextLine => 'Play next line';

  @override
  String get hotkeysDescReplayLine => 'Replay current line';

  @override
  String get hotkeysDescToggleEchoMode => 'Toggle Echo mode';

  @override
  String get hotkeysDescToggleDictationMode => 'Toggle dictation mode';

  @override
  String get hotkeysDescToggleRecording => 'Start/Stop recording';

  @override
  String get hotkeysDescToggleAssessment =>
      'Show/Hide pronunciation assessment';

  @override
  String get hotkeysDescTogglePitchContour => 'Show/Hide pitch contour';

  @override
  String get hotkeysDescPlayRecording => 'Play/Pause recording';

  @override
  String get hotkeysDescSlowDown => 'Slow down playback speed';

  @override
  String get hotkeysDescSpeedUp => 'Speed up playback speed';

  @override
  String get hotkeysDescExpandEchoBackward => 'Expand Echo region backward';

  @override
  String get hotkeysDescExpandEchoForward => 'Expand Echo region forward';

  @override
  String get hotkeysDescShrinkEchoBackward => 'Shrink Echo region backward';

  @override
  String get hotkeysDescShrinkEchoForward => 'Shrink Echo region forward';

  @override
  String get hotkeysDescLibrarySearch => 'Focus search';

  @override
  String get hotkeysDescCloseModal => 'Close modal';

  @override
  String get hotkeysStubSearch => 'Search is not available yet.';

  @override
  String get hotkeysStubAssessment =>
      'Pronunciation assessment is not available yet.';

  @override
  String get hotkeysStubDictation => 'Dictation mode is not available yet.';

  @override
  String get authSignInTitle => 'Sign in to Enjoy';

  @override
  String get authSignInSubtitle =>
      'We will open your browser to sign in. When you are done, return here — we will detect completion automatically.';

  @override
  String get authSignInCta => 'Continue in browser';

  @override
  String get authWaitingForApproval => 'Waiting for approval in your browser…';

  @override
  String get authCancel => 'Cancel';

  @override
  String get authSignedInSuccess => 'Signed in successfully';

  @override
  String get authReOpenBrowser => 'Re-open browser';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileFieldName => 'Name';

  @override
  String get profileFieldEmail => 'Email';

  @override
  String get profileFieldGoal => 'Daily goal (minutes)';

  @override
  String get profileFieldLearningLanguage => 'Learning language';

  @override
  String get profileFieldNativeLanguage => 'Native language';

  @override
  String get profileFieldRequired => 'Required';

  @override
  String get profileSave => 'Save';

  @override
  String get profileSaveSuccess => 'Profile saved';

  @override
  String get profileSubscriptionFree => 'Free';

  @override
  String get profileSubscriptionPro => 'Pro';

  @override
  String profileBalance(String value) {
    return 'Balance: $value';
  }

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsSectionAdvanced => 'Advanced';

  @override
  String get settingsApiBaseUrl => 'API base URL';

  @override
  String get settingsApiBaseUrlHint => 'Example: https://enjoy.bot';

  @override
  String get settingsApiBaseUrlSave => 'Save API URL';

  @override
  String get settingsAccountSignedOut => 'Not signed in';

  @override
  String get settingsAccountOpenProfile => 'Open profile';

  @override
  String get settingsAccountSignIn => 'Sign in';

  @override
  String get errorNetwork => 'Network error';

  @override
  String get errorUnauthorized => 'Session expired — please sign in again';

  @override
  String get communityActivity => 'Community Activity';

  @override
  String get communityToday => 'Community Today';

  @override
  String get homeRecordingsToday => 'Recordings';

  @override
  String get homePracticeTime => 'Practice Time';

  @override
  String get homeActiveLearners => 'Active Learners';

  @override
  String homePeopleLearning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people learning',
      one: '$count person learning',
    );
    return '$_temp0';
  }

  @override
  String get homeNoActiveUsers => 'No active users';
}
