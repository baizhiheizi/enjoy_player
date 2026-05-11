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
  String get homeEmptyHint => 'Import media or drop a file here to start.';

  @override
  String get libraryTabAudio => 'Audio';

  @override
  String get libraryTabVideo => 'Video';

  @override
  String get libraryEmptyAudioTitle => 'We couldn\'t find any audio';

  @override
  String get libraryEmptyAudioHint =>
      'Your library doesn\'t contain any audio content.';

  @override
  String get libraryEmptyVideoTitle => 'We couldn\'t find any videos';

  @override
  String get libraryEmptyVideoHint =>
      'Your library doesn\'t contain any video content.';

  @override
  String get actionOpenFiles => 'Open file(s)';

  @override
  String get actionImport => 'Import';

  @override
  String get importFromFile => 'From file…';

  @override
  String get importFromYoutube => 'From YouTube URL…';

  @override
  String get youtubeImportTitle => 'Import YouTube video';

  @override
  String get youtubeImportHint => 'Paste a YouTube link or video ID';

  @override
  String get youtubeImportInvalid => 'Could not read a valid YouTube video ID.';

  @override
  String get youtubeImporting => 'Adding video…';

  @override
  String get youtubeBadge => 'YouTube';

  @override
  String get youtubeLoginTooltip => 'YouTube account';

  @override
  String get youtubeLoginClose => 'Close';

  @override
  String get youtubeLoginScreenTitle => 'YouTube sign-in';

  @override
  String get youtubeLogout => 'Sign out (clear cookies)';

  @override
  String get searchHint => 'Search';

  @override
  String get transportRepeat => 'Repeat';

  @override
  String get transportFullscreen => 'Fullscreen';

  @override
  String get transportExitFullscreen => 'Exit fullscreen';

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
  String get settingsThemeDarkLocked => 'Follows your system appearance.';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

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
  String get transcriptNowReading => 'Now reading';

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
  String get playerOpenGenericError => 'Could not open this item.';

  @override
  String playbackRateTimes(String rate) {
    return '${rate}x';
  }

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
  String get subtitlesDeleteTrack => 'Delete track';

  @override
  String get importSubtitleSuccess => 'Subtitle imported';

  @override
  String get noTranscriptHint =>
      'Cloud transcripts load when you play media (once). For video, use Extract embedded or import an .srt/.vtt file.';

  @override
  String get subtitlesExtractEmbedded => 'Extract embedded subtitles';

  @override
  String get subtitlesRefreshCloud => 'Refresh transcripts from cloud';

  @override
  String get subtitlesImportLanguageTitle => 'Subtitle language';

  @override
  String get subtitlesImportLanguageHint =>
      'BCP-47 code (e.g. en, zh-TW). Use und if unknown.';

  @override
  String get subtitlesProviderOfficial => 'Official';

  @override
  String get subtitlesProviderAuto => 'Auto';

  @override
  String get subtitlesProviderAi => 'AI';

  @override
  String get subtitlesProviderUser => 'User';

  @override
  String get subtitlesExtractNoTracks => 'No embedded subtitle tracks found.';

  @override
  String subtitlesExtractedCount(int count) {
    return 'Extracted $count subtitle track(s).';
  }

  @override
  String get subtitlesRefreshDone => 'Transcripts updated from cloud.';

  @override
  String get subtitlesNoPlayableUri =>
      'Could not resolve a playable file for this item.';

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
  String get shadowRecordingDeleteConfirmTitle => 'Delete this take?';

  @override
  String shadowRecordingDeleteConfirmMessage(String takeLabel) {
    return '$takeLabel will be permanently deleted. This cannot be undone.';
  }

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
  String shadowRecordingOverTarget(String seconds) {
    return '+${seconds}s over target';
  }

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
  String get hotkeysDescToggleFullscreen => 'Toggle fullscreen';

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
  String get settingsSectionSync => 'Cloud sync';

  @override
  String get settingsSectionDataMigration => 'Local data';

  @override
  String get syncSettingsTileTitle => 'Sync status';

  @override
  String get syncSettingsTileSubtitleSignedOut =>
      'Sign in to sync library and recordings';

  @override
  String get syncSettingsTileSubtitleUpToDate => 'Up to date';

  @override
  String syncSettingsTileSubtitleCounts(int retryable, int failed) {
    return '$retryable waiting · $failed failed';
  }

  @override
  String get syncScreenTitle => 'Sync status';

  @override
  String get syncScreenLastSyncLabel => 'Last successful sync';

  @override
  String get syncScreenLastSyncNever => 'Never';

  @override
  String get syncScreenStatRetryable => 'Waiting to upload';

  @override
  String get syncScreenStatFailed => 'Failed permanently';

  @override
  String get syncScreenSyncNow => 'Sync now';

  @override
  String get syncScreenRetryFailed => 'Retry failed items';

  @override
  String get syncScreenSignedOutBody =>
      'Sign in with your Enjoy account to sync metadata across devices.';

  @override
  String get syncScreenGoSignIn => 'Sign in';

  @override
  String get syncPendingRekeyLabel => 'Imports pending account link';

  @override
  String get syncPendingRekeyHint =>
      'These items were added while signed out. They will be linked to your account and queued for upload after you sign in.';

  @override
  String get cloudScreenTitle => 'Cloud';

  @override
  String get cloudTabAudio => 'Audio';

  @override
  String get cloudTabVideo => 'Video';

  @override
  String get cloudSignedOutBody =>
      'Sign in to browse media saved to your Enjoy account.';

  @override
  String get cloudAddToLibrary => 'Add to library';

  @override
  String get cloudAlreadyInLibrary => 'Already in library';

  @override
  String get cloudAddedToLibrary => 'Added to your local library.';

  @override
  String get cloudEmpty => 'No items in this list.';

  @override
  String get cloudHasMediaUrlHint => 'Streams from your saved URL when opened.';

  @override
  String get cloudNoMediaUrlHint =>
      'No remote file URL — use Locate file in the player when you open this item.';

  @override
  String get cloudRefreshTooltip => 'Refresh this tab';

  @override
  String get cloudAddToLibraryTooltip => 'Add to library';

  @override
  String get cloudEmptyAudioTitle => 'No cloud audio yet';

  @override
  String get cloudEmptyAudioSubtitle =>
      'Items you save while signed in will appear here.';

  @override
  String get cloudEmptyVideoTitle => 'No cloud video yet';

  @override
  String get cloudEmptyVideoSubtitle =>
      'Items you save while signed in will appear here.';

  @override
  String get syncSnackSuccess => 'Sync finished successfully.';

  @override
  String syncSnackIssues(int synced, int failed) {
    return 'Sync finished: $synced succeeded, $failed failed.';
  }

  @override
  String get syncQueueDetails => 'Queue details';

  @override
  String get syncQueueEmpty => 'Nothing in the queue.';

  @override
  String get settingsSectionAdvanced => 'Advanced';

  @override
  String get settingsApiBaseUrl => 'API base URL';

  @override
  String get settingsApiBaseUrlHint => 'Example: https://enjoy.bot';

  @override
  String get settingsApiBaseUrlSave => 'Save API URL';

  @override
  String get settingsAiApiBaseUrl => 'AI API base URL';

  @override
  String get settingsAiApiBaseUrlHint => 'Example: https://worker.enjoy.bot';

  @override
  String get settingsAiApiBaseUrlSave => 'Save AI API URL';

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

  @override
  String get homeTodaysGoal => 'Today\'s Goal';

  @override
  String get homeMinutes => 'min';

  @override
  String get homeCompleted => 'completed';

  @override
  String get homeGoalCompleted => 'Goal completed! Great job!';

  @override
  String get homeGoalAlmostThere => 'Almost there! Keep going!';

  @override
  String get homeGoalHalfway => 'Halfway there! You can do it!';

  @override
  String get homeGoalGoodStart => 'Good start! Keep practicing!';

  @override
  String get homeGoalJustStarted => 'Just started! Every minute counts!';

  @override
  String get homeGoalStartNow => 'Start your practice now!';

  @override
  String get mediaLocateTitle => 'Locate media file';

  @override
  String get mediaLocateBody =>
      'This item was added on another device. Choose the same file on this computer. We verify it matches your library using a secure fingerprint.';

  @override
  String get mediaLocateChooseFile => 'Choose file';

  @override
  String get mediaLocateHashMismatch =>
      'That file does not match this item. Make sure you selected the correct file.';

  @override
  String mediaLocateExpectedSize(String sizeLabel) {
    return 'Expected size: $sizeLabel';
  }

  @override
  String get mediaLocateSizeUnknown => 'Expected size: unknown';

  @override
  String get migrationBannerTitle => 'Move your local data';

  @override
  String get migrationBannerBody =>
      'We noticed you have media and practice history saved locally. Would you like to move it to your account?';

  @override
  String get migrationBannerActionMove => 'Move data';

  @override
  String get migrationBannerActionDismiss => 'Not now';

  @override
  String get settingsMigrationTitle => 'Migrate local data';

  @override
  String get settingsMigrationSubtitle =>
      'Move your guest media and history to this account';

  @override
  String get migrationSuccess => 'Data moved successfully';

  @override
  String get migrationMigrationFailed =>
      'Could not move data. Try again later.';

  @override
  String get libraryDeleteMediaTitle => 'Delete from library?';

  @override
  String libraryDeleteMediaMessage(String title) {
    return 'Remove \"$title\" from this device. This cannot be undone.';
  }

  @override
  String get libraryDeleteMediaTooltip => 'Delete from library';

  @override
  String get libraryMediaDeleted => 'Removed from library.';

  @override
  String get libraryDeleteMediaFailed => 'Could not remove this item.';

  @override
  String get settingsSectionDeveloper => 'Developer';

  @override
  String get settingsAiPlaygroundTileTitle => 'AI playground';

  @override
  String get settingsAiPlaygroundTileSubtitle =>
      'Exercise ASR, chat, translation, and dictionary APIs';

  @override
  String get aiPlaygroundTitle => 'AI playground';

  @override
  String get aiPlaygroundIntro =>
      'Calls the Enjoy API using your saved base URL and access token. TTS and pronunciation assessment are not wired on Flutter yet (see ADR-0014).';

  @override
  String get aiPlaygroundPickAudio => 'Pick audio file';

  @override
  String get aiPlaygroundTranscribe => 'Transcribe';

  @override
  String get aiPlaygroundChatSystem => 'System (optional)';

  @override
  String get aiPlaygroundChatUser => 'User message';

  @override
  String get aiPlaygroundSendChat => 'Send chat';

  @override
  String get aiPlaygroundTranslateSource => 'Source language';

  @override
  String get aiPlaygroundTranslateTarget => 'Target language';

  @override
  String get aiPlaygroundTranslateText => 'Text to translate';

  @override
  String get aiPlaygroundTranslate => 'Translate';

  @override
  String get aiPlaygroundDictWord => 'Word';

  @override
  String get aiPlaygroundDictSource => 'Source language';

  @override
  String get aiPlaygroundDictTarget => 'Target language';

  @override
  String get aiPlaygroundDictLookup => 'Dictionary lookup';

  @override
  String get aiPlaygroundTtsDisabled =>
      'TTS is not available in this build (Azure Speech integration pending).';

  @override
  String get aiPlaygroundAssessmentDisabled =>
      'Pronunciation assessment is not available in this build (Azure Speech integration pending).';

  @override
  String get aiPlaygroundOutput => 'Output';

  @override
  String get aiPlaygroundClearOutput => 'Clear output';

  @override
  String get aiPlaygroundSectionAsr => 'ASR';

  @override
  String get aiPlaygroundSectionChat => 'Chat';

  @override
  String get aiPlaygroundSectionTranslation => 'Translation';

  @override
  String get aiPlaygroundSectionDictionary => 'Dictionary';

  @override
  String get aiPlaygroundSectionTtsAssessment => 'TTS / Assessment';

  @override
  String get youtubePasteFromClipboard => 'Paste';
}
