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
  String get librarySourceLocal => 'Local';

  @override
  String get librarySourceCloud => 'Cloud';

  @override
  String get librarySourceCloudEyebrow => 'Cloud';

  @override
  String get librarySourceSwitchSemantics => 'Library source';

  @override
  String get librarySourceToggleToCloud => 'Switch to cloud';

  @override
  String get librarySourceToggleToLocal => 'Switch to local';

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
  String get librarySearchNoMatchesTitle => 'No matches';

  @override
  String get librarySearchNoMatchesHint =>
      'Nothing in your library matches this search.';

  @override
  String get librarySearchClear => 'Clear search';

  @override
  String get libraryDeleteFailed => 'Could not remove this item. Try again.';

  @override
  String get transcriptAccessibilityTranscriptList => 'Transcript';

  @override
  String transcriptAccessibilityCue(String time, String snippet) {
    return '$time. $snippet';
  }

  @override
  String get transcriptAccessibilityCurrentLine => 'Current playback line.';

  @override
  String get transcriptAccessibilityEchoRegion => 'Echo practice region.';

  @override
  String get transcriptAccessibilityEchoCurrentLine => 'Current echo line.';

  @override
  String transcriptLineRecordingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recordings',
      one: '1 recording',
    );
    return '$_temp0';
  }

  @override
  String get transcriptErrorFriendlyTitle => 'Transcript unavailable';

  @override
  String get transcriptErrorFriendlyHint =>
      'Try choosing another subtitle track or importing a file.';

  @override
  String get transcriptFetchingSubtitles => 'Fetching subtitles…';

  @override
  String get actionOpenFiles => 'Open file(s)';

  @override
  String get actionImport => 'Import';

  @override
  String get importFromFile => 'From file…';

  @override
  String get importFromYoutube => 'From YouTube URL…';

  @override
  String get discoverTitle => 'Discover';

  @override
  String get discoverBrowseAction => 'Browse Discover';

  @override
  String get discoverRecommendedHeading => 'Recommended';

  @override
  String get discoverSubscriptionsHeading => 'Subscriptions';

  @override
  String get discoverTimelineHeading => 'Recent uploads';

  @override
  String get discoverSubscribeTitle => 'Subscribe to channel';

  @override
  String get discoverSubscribeHint => 'Paste a YouTube channel URL or @handle.';

  @override
  String get discoverSubscribePlaceholder => 'https://www.youtube.com/@channel';

  @override
  String get discoverSubscribeAction => 'Subscribe';

  @override
  String get discoverSubscribed => 'Subscribed to channel';

  @override
  String get discoverSubscribedLabel => 'Subscribed';

  @override
  String get discoverSubscribeFailed => 'Could not subscribe to that channel.';

  @override
  String get discoverUnsubscribeAction => 'Unsubscribe';

  @override
  String get discoverUnsubscribed => 'Unsubscribed from channel';

  @override
  String get discoverViewFeed => 'View feed';

  @override
  String get discoverAddToLibrary => 'Add to library';

  @override
  String get discoverAddedToLibrary => 'Added to your library';

  @override
  String get discoverAddFailed => 'Could not add this video.';

  @override
  String get discoverInLibrary => 'In library';

  @override
  String get discoverPlay => 'Play';

  @override
  String get discoverFeedEmptyTitle => 'No videos in feed yet';

  @override
  String get discoverFeedEmptyHint =>
      'Subscribe to a channel and refresh to load recent uploads.';

  @override
  String get discoverFeedErrorTitle => 'Could not load feed';

  @override
  String get discoverFeedErrorHint => 'Check your connection and try again.';

  @override
  String get discoverRetry => 'Retry';

  @override
  String get discoverRefreshPartialFailed =>
      'Some channel feeds could not be refreshed.';

  @override
  String get discoverRecommendedLoadFailed =>
      'Could not load recommended channels.';

  @override
  String get discoverSubscriptionsLoadFailed => 'Could not load subscriptions.';

  @override
  String get discoverNoSubscriptionsHint =>
      'Subscribe to a recommended channel or paste a channel URL.';

  @override
  String get discoverManageChannels => 'Manage channels';

  @override
  String get discoverFilterAll => 'All';

  @override
  String get discoverYourChannelsHeading => 'Your channels';

  @override
  String get discoverRecommendedAllSubscribed =>
      'You are subscribed to all recommended channels.';

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
  String get transportDismissPlayer => 'Close player';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get importMedia => 'Import media';

  @override
  String get importingMedia => 'Importing media…';

  @override
  String get importMediaFailed => 'Could not import this file.';

  @override
  String get importUnsupportedFileType =>
      'This file type isn’t supported. Choose an audio or video file.';

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
      'Cloud transcripts load in the background when you open media (once per item until you refresh). For local video, use Extract or Add subtitle (.srt/.vtt).';

  @override
  String get transcriptEmptyExtract => 'Extract';

  @override
  String get transcriptEmptyAddSubtitle => 'Add subtitle';

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
  String get subtitlesImportLanguageFieldLabel => 'Language code';

  @override
  String get subtitlesProviderOfficial => 'Official';

  @override
  String get subtitlesProviderAuto => 'Auto';

  @override
  String get subtitlesProviderAi => 'AI';

  @override
  String get subtitlesProviderUser => 'User';

  @override
  String get subtitlesExtractNoTracks =>
      'No embedded subtitle tracks in this file (only video and audio). If you have a separate .srt or .vtt, use Import file.';

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
  String get pitchContourAnalyzing => 'Analyzing pitch…';

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
  String get settingsSectionRecording => 'Recording';

  @override
  String get settingsSectionRecordingHint =>
      'Microphone used for shadow-reading takes.';

  @override
  String get settingsRecordingMicTitle => 'Microphone';

  @override
  String settingsRecordingMicAuto(String label) {
    return 'Auto · $label';
  }

  @override
  String get settingsRecordingMicAutoNoDevice => 'Auto · system default';

  @override
  String get settingsRecordingMicEmpty => 'No microphones detected';

  @override
  String get settingsRecordingMicAutoOption => 'Auto (skip virtual mics)';

  @override
  String get settingsRecordingMicDialogTitle => 'Choose microphone';

  @override
  String get shadowRecordingSilentWarning =>
      'No microphone signal detected. Open Settings → Recording to pick a different microphone.';

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
  String get hotkeysResetAllConfirmTitle => 'Reset all shortcuts?';

  @override
  String get hotkeysResetAllConfirmMessage =>
      'This restores every shortcut to its default binding. Custom bindings cannot be undone.';

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
  String get hotkeysDescCloseModal =>
      'Close overlay, exit fullscreen, or cancel recording';

  @override
  String get hotkeysStubSearch => 'Search is not available yet.';

  @override
  String get hotkeysStubDictation => 'Dictation mode is not available yet.';

  @override
  String get assessmentTitle => 'Pronunciation assessment';

  @override
  String get assessmentDescription => 'Detailed scoring for your reading.';

  @override
  String get assessmentRun => 'Run pronunciation assessment';

  @override
  String get assessmentView => 'View pronunciation assessment';

  @override
  String get assessmentReassess => 'Re-assess';

  @override
  String get assessmentOverallScore => 'Overall score';

  @override
  String get assessmentAccuracy => 'Accuracy';

  @override
  String get assessmentCompleteness => 'Completeness';

  @override
  String get assessmentFluency => 'Fluency';

  @override
  String get assessmentProsody => 'Prosody';

  @override
  String get assessmentPronunciationAnalysis => 'Pronunciation analysis';

  @override
  String get assessmentAccuracyScore => 'Accuracy score';

  @override
  String get assessmentSyllables => 'Syllables';

  @override
  String get assessmentPhonemes => 'Phonemes';

  @override
  String get assessmentNoRecording => 'Recording file is missing or empty.';

  @override
  String get assessmentNoResultSummary =>
      'No detailed scores are available for this take.';

  @override
  String assessmentRunFailed(String reason) {
    return 'Couldn\'t run assessment: $reason';
  }

  @override
  String get assessmentErrorTypeOmission => 'Omission';

  @override
  String get assessmentErrorTypeInsertion => 'Insertion';

  @override
  String get assessmentErrorTypeMispronunciation => 'Mispronunciation';

  @override
  String get assessmentErrorTypeUnexpectedBreak => 'Unexpected break';

  @override
  String get assessmentErrorTypeMissingBreak => 'Missing break';

  @override
  String get assessmentErrorTypeMonotone => 'Monotone';

  @override
  String get assessmentErrorTypeCorrect => 'Correct';

  @override
  String get assessmentErrorExplOmission =>
      'This word was expected but not detected.';

  @override
  String get assessmentErrorExplInsertion =>
      'Extra word detected that wasn\'t in the reference.';

  @override
  String get assessmentErrorExplMispronunciation =>
      'This word may have been pronounced incorrectly.';

  @override
  String get assessmentErrorExplUnexpectedBreak =>
      'Unexpected pause detected before this word.';

  @override
  String get assessmentErrorExplMissingBreak =>
      'Expected pause was not detected before this word.';

  @override
  String get assessmentErrorExplMonotone =>
      'Pitch variation was lower than expected.';

  @override
  String get assessmentErrorExplCorrect => 'No issues detected for this word.';

  @override
  String get assessmentEmptyReference => 'Reference text is empty.';

  @override
  String get assessmentInvalidStored =>
      'Stored assessment data could not be read.';

  @override
  String get authSignInTitle => 'Sign in to Enjoy';

  @override
  String get authSignInSubtitle =>
      'Sign in with Google, Apple, or email. Your progress syncs when you are signed in.';

  @override
  String get authSignInCta => 'Continue';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueWithApple => 'Continue with Apple';

  @override
  String get authContinueWithEmail => 'Continue with Email';

  @override
  String get authOtherSignInOptions => 'Other sign-in options';

  @override
  String get authOrDivider => 'or';

  @override
  String get authEmailPrompt => 'We will send a one-time code to your email.';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailInvalid => 'Enter a valid email address.';

  @override
  String get authSendOtp => 'Send code';

  @override
  String get authOtpTitle => 'Enter verification code';

  @override
  String authOtpSentTo(String email) {
    return 'Code sent to $email';
  }

  @override
  String get authOtpLabel => '6-digit code';

  @override
  String get authVerifyOtp => 'Verify';

  @override
  String get authOtpResend => 'Resend code';

  @override
  String authOtpResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get authChangeEmail => 'Change email';

  @override
  String get authOtpResumeTitle => 'Finish signing in';

  @override
  String authOtpResumeSubtitle(String email) {
    return 'Enter the verification code sent to $email';
  }

  @override
  String get authOtpResumeAction => 'Continue verification';

  @override
  String get authWebSignInWaiting => 'Complete sign-in in your browser…';

  @override
  String get authWaitingForApproval => 'Finishing sign-in…';

  @override
  String get authCancel => 'Cancel';

  @override
  String get authSignedInSuccess => 'Signed in successfully';

  @override
  String get authReloadSignInPage => 'Reload sign-in page';

  @override
  String get authOpenInSystemBrowser => 'Open in system browser';

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
  String get profileStatTodayTitle => 'Today';

  @override
  String get profileStatWeekTitle => 'This week';

  @override
  String get profileStatMonthTitle => 'This month';

  @override
  String get profileSectionPractice => 'Practice';

  @override
  String get profileSectionPracticeHint =>
      'Synced practice time from your account';

  @override
  String get profileCreditsUsageTile => 'Credits usage';

  @override
  String get profileCreditsUsageSubtitle =>
      'View AI credits consumption from your account';

  @override
  String get profileSectionAccount => 'Account';

  @override
  String get profileSectionAccountHint => 'Credits balance and usage history';

  @override
  String get profileSectionPreferences => 'Preferences';

  @override
  String get profileSectionPreferencesHint =>
      'Name, daily goal, and language settings';

  @override
  String get profileSignOutConfirmTitle => 'Sign out?';

  @override
  String get profileSignOutConfirmMessage =>
      'You will need to sign in again to sync and use AI features.';

  @override
  String get creditsUsageTitle => 'Credits usage';

  @override
  String get creditsUsageDescription =>
      'Records of credits checks on the Enjoy AI worker (UTC dates).';

  @override
  String get creditsUsageStartDate => 'Start date';

  @override
  String get creditsUsageEndDate => 'End date';

  @override
  String get creditsUsageServiceType => 'Service';

  @override
  String get creditsUsageClearFilters => 'Clear filters';

  @override
  String get creditsUsageError => 'Could not load usage';

  @override
  String get creditsUsageErrorDescription =>
      'Check your network and AI API base URL in Settings.';

  @override
  String get creditsUsageRetry => 'Retry';

  @override
  String get creditsUsageNoRecords => 'No records';

  @override
  String get creditsUsageNoRecordsWithFilters =>
      'Try changing or clearing filters.';

  @override
  String get creditsUsageNoRecordsDescription =>
      'Usage will appear here after you use AI features while signed in.';

  @override
  String get creditsUsageTableDate => 'Date';

  @override
  String get creditsUsageTableTime => 'Time';

  @override
  String get creditsUsageTableService => 'Service';

  @override
  String get creditsUsageTableTier => 'Tier';

  @override
  String get creditsUsageTableRequired => 'Required';

  @override
  String get creditsUsageTableUsedAfter => 'Used after';

  @override
  String get creditsUsageTableStatus => 'Status';

  @override
  String get creditsUsageAllowed => 'Allowed';

  @override
  String get creditsUsageDenied => 'Denied';

  @override
  String creditsUsagePageInfo(int page) {
    return 'Page $page';
  }

  @override
  String creditsUsageTotalRecords(int count) {
    return '$count shown';
  }

  @override
  String get creditsUsagePrevious => 'Previous';

  @override
  String get creditsUsageNext => 'Next';

  @override
  String get creditsServiceTypeAll => 'All';

  @override
  String get creditsServiceTypeTts => 'TTS';

  @override
  String get creditsServiceTypeAsr => 'ASR';

  @override
  String get creditsServiceTypeTranslation => 'Translation';

  @override
  String get creditsServiceTypeLlm => 'LLM';

  @override
  String get creditsServiceTypeAssessment => 'Assessment';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsSectionAccountHint =>
      'Profile, subscription, and sign out';

  @override
  String get settingsSectionDataMigrationHint =>
      'Move guest data after you sign in';

  @override
  String get settingsSectionSyncHint =>
      'Upload queue, offline state, and manual sync';

  @override
  String get settingsSectionAppearanceLanguageHint =>
      'Theme density, transcript font, and locale';

  @override
  String get hotkeysSectionKeyboardHint => 'Reference and customize shortcuts';

  @override
  String get settingsSectionAdvancedHint =>
      'API endpoints and experimental toggles';

  @override
  String get settingsSectionDeveloperHint => 'Diagnostics and internal tooling';

  @override
  String get settingsSectionAboutHint => 'Version, licenses, and links';

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
      'Calls the Enjoy API using your saved base URL and access token. TTS is not wired on Flutter yet; pronunciation assessment uses Azure Speech via a native plugin when signed in.';

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
  String get aiPlaygroundAssessmentReference =>
      'Reference text (what you spoke)';

  @override
  String get aiPlaygroundAssessmentLanguage => 'Language (e.g. en, en-US)';

  @override
  String get aiPlaygroundAssess => 'Run pronunciation assessment';

  @override
  String get aiPlaygroundAssessmentTtsNote =>
      'TTS is not available in this build (Azure Speech integration pending).';

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

  @override
  String get settingsSubtitle => 'Tune Enjoy to fit how you study.';

  @override
  String get settingsAuthLoadFailed =>
      'We couldn\'t refresh your account. Check your connection and try again.';

  @override
  String get settingsSectionAppearanceLanguage => 'Appearance & Language';

  @override
  String get settingsAppearanceTheme => 'Theme';

  @override
  String get settingsAppearanceThemeValue => 'Dark · Cinematic';

  @override
  String get settingsAppearanceDisplayLanguage => 'Display language';

  @override
  String get settingsAppearanceLearningLanguage => 'Learning language';

  @override
  String get settingsAppearanceNativeLanguage => 'Native language';

  @override
  String get settingsAppearanceSyncedFromProfile =>
      'Synced from your account profile';

  @override
  String get settingsLanguageSubtitleSignedIn =>
      'Also updates your Enjoy profile when online.';

  @override
  String get settingsLanguageSubtitleDeviceOnly =>
      'Stored on this device until you sign in.';

  @override
  String get settingsLanguageOptionEnUs => 'English (United States)';

  @override
  String get settingsLanguageOptionZhCn => 'Chinese (Simplified, China)';

  @override
  String get settingsLearningLanguageFixedSubtitle =>
      'English (US) only for now.';

  @override
  String get settingsNativeMustDifferHint =>
      'Must differ from your learning language.';

  @override
  String get settingsLanguagePickerTitleDisplay => 'Display language';

  @override
  String get settingsLanguagePickerTitleNative => 'Native language';

  @override
  String get profileFieldDisplayLanguage => 'Display language';

  @override
  String get profileLearningLanguageReadOnly =>
      'Learning language is English (US) in this version.';

  @override
  String get settingsKeyboardOpenCheatsheet => 'Open shortcuts cheatsheet';

  @override
  String get settingsKeyboardOpenCheatsheetSubtitle =>
      'Browse and customize every shortcut';

  @override
  String get settingsKeyboardCustomizeTitle => 'Customize shortcuts';

  @override
  String hotkeysHelpSubtitle(String key) {
    return 'Press $key anytime to open this list.';
  }

  @override
  String get hotkeysHelpSearchHint => 'Search shortcuts';

  @override
  String get hotkeysHelpEmpty => 'No matching shortcuts';

  @override
  String get hotkeysHelpCustomize => 'Customize shortcuts';

  @override
  String hotkeysSettingsSubtitle(String key) {
    return 'Tap a row to change. Press $key anytime.';
  }

  @override
  String get hotkeysFilterHint => 'Filter shortcuts';

  @override
  String get hotkeysResetTooltip => 'Reset this shortcut';

  @override
  String get hotkeysEditTooltip => 'Change shortcut';

  @override
  String get settingsAboutMadeWithCare =>
      'Made with care for language learners.';

  @override
  String settingsAboutVersion(String version) {
    return 'v$version';
  }

  @override
  String get settingsAboutOpenSourceTitle => 'Open source';

  @override
  String get settingsAboutOpenSourceSubtitle => 'View source code on GitHub';

  @override
  String get settingsDiagnosticsLoggingTitle => 'Diagnostic logging';

  @override
  String get settingsDiagnosticsLoggingSubtitle =>
      'Record extra detail for YouTube, sync, and sign-in issues';

  @override
  String get settingsDiagnosticsPrivacyNote =>
      'Logs stay on this device until you export them. Tokens and cookies are redacted.';

  @override
  String get settingsDiagnosticsExportTitle => 'Export diagnostic report';

  @override
  String get settingsDiagnosticsExportSubtitle =>
      'Save a zip of recent logs for support';

  @override
  String get settingsDiagnosticsExportSuccess => 'Diagnostic report saved.';

  @override
  String get settingsDiagnosticsExportError =>
      'Could not export diagnostic report.';

  @override
  String get settingsCheckForUpdatesTitle => 'Check for updates';

  @override
  String get settingsCheckForUpdatesSubtitle =>
      'See if a newer direct-download build is available';

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String get updateMandatoryTitle => 'Update required';

  @override
  String updateVersionLine(String current, String latest) {
    return 'Installed $current → $latest';
  }

  @override
  String get updateNow => 'Update now';

  @override
  String get updateLater => 'Later';

  @override
  String get updateDismiss => 'Dismiss';

  @override
  String get updateUpToDate => 'You\'re on the latest version.';

  @override
  String get updateCheckOffline =>
      'Could not check for updates. Check your connection.';

  @override
  String get updateStoreChannelHint =>
      'This build is from TestFlight or the Play Store — updates are handled by the store.';

  @override
  String get lookupSheetTitle => 'Look up';

  @override
  String get lookupSectionTranslation => 'Translation';

  @override
  String get lookupSectionContextualTranslation => 'Contextual translation';

  @override
  String get lookupSectionDictionary => 'Definition';

  @override
  String get lookupLoading => 'Loading…';

  @override
  String get lookupErrorRetry => 'Retry';

  @override
  String get lookupEmpty => 'No result.';

  @override
  String get lookupLemma => 'Lemma';

  @override
  String get lookupIpa => 'IPA';

  @override
  String get lookupExamples => 'Examples';

  @override
  String get lookupClose => 'Close';

  @override
  String get lookupCopy => 'Copy';

  @override
  String get lookupCopySuccess => 'Copied to clipboard';

  @override
  String get lookupTapToExpand => 'Expand to load';

  @override
  String get lookupSourceLanguage => 'Source language';

  @override
  String get lookupTargetLanguage => 'Target language';

  @override
  String get lookupSwapLanguages => 'Swap languages';

  @override
  String get lookupPickSourceTitle => 'Choose source language';

  @override
  String get lookupPickTargetTitle => 'Choose target language';

  @override
  String get lookupRefresh => 'Refresh';

  @override
  String get lookupCloudRequiresSignIn =>
      'Sign in under Settings to use cloud dictionary, translation, and contextual translation.';

  @override
  String get authRequiredCloudFeaturesTitle => 'Account required';

  @override
  String get practicePosterShareTooltip => 'Share practice poster';

  @override
  String get practicePosterPreviewTitle => 'Share your practice';

  @override
  String get practicePosterTagline => 'Shadow reading';

  @override
  String get practicePosterStatTakes => 'Takes';

  @override
  String get practicePosterStatSentences => 'Sentences';

  @override
  String get practicePosterStatSpoken => 'Spoken';

  @override
  String get practicePosterQrHint =>
      'Scan to download Enjoy Player\nplayer.enjoy.bot';

  @override
  String get practicePosterShareAction => 'Share poster';

  @override
  String get practicePosterShareSuccess => 'Poster shared.';

  @override
  String get practicePosterSaveSuccess => 'Poster saved.';

  @override
  String get practicePosterExportError => 'Could not share practice poster.';

  @override
  String get practicePosterLoadError =>
      'Could not load practice data for this video.';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String notFoundSubtitle(String uri) {
    return 'We couldn\'t find $uri.';
  }

  @override
  String get notFoundBackHome => 'Back to home';
}
