import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Enjoy Player'**
  String get appTitle;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeRecentMedia.
  ///
  /// In en, this message translates to:
  /// **'Recent media'**
  String get homeRecentMedia;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recent media'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Import media or drop a file here to start.'**
  String get homeEmptyHint;

  /// No description provided for @libraryTabAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get libraryTabAudio;

  /// No description provided for @libraryTabVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get libraryTabVideo;

  /// No description provided for @libraryEmptyAudioTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any audio'**
  String get libraryEmptyAudioTitle;

  /// No description provided for @libraryEmptyAudioHint.
  ///
  /// In en, this message translates to:
  /// **'Your library doesn\'t contain any audio content.'**
  String get libraryEmptyAudioHint;

  /// No description provided for @libraryEmptyVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any videos'**
  String get libraryEmptyVideoTitle;

  /// No description provided for @libraryEmptyVideoHint.
  ///
  /// In en, this message translates to:
  /// **'Your library doesn\'t contain any video content.'**
  String get libraryEmptyVideoHint;

  /// No description provided for @actionOpenFiles.
  ///
  /// In en, this message translates to:
  /// **'Open file(s)'**
  String get actionOpenFiles;

  /// No description provided for @actionImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get actionImport;

  /// No description provided for @importFromFile.
  ///
  /// In en, this message translates to:
  /// **'From file…'**
  String get importFromFile;

  /// No description provided for @importFromYoutube.
  ///
  /// In en, this message translates to:
  /// **'From YouTube URL…'**
  String get importFromYoutube;

  /// No description provided for @youtubeImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import YouTube video'**
  String get youtubeImportTitle;

  /// No description provided for @youtubeImportHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a YouTube link or video ID'**
  String get youtubeImportHint;

  /// No description provided for @youtubeImportInvalid.
  ///
  /// In en, this message translates to:
  /// **'Could not read a valid YouTube video ID.'**
  String get youtubeImportInvalid;

  /// No description provided for @youtubeImporting.
  ///
  /// In en, this message translates to:
  /// **'Adding video…'**
  String get youtubeImporting;

  /// No description provided for @youtubeBadge.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get youtubeBadge;

  /// No description provided for @youtubeLoginTooltip.
  ///
  /// In en, this message translates to:
  /// **'YouTube account'**
  String get youtubeLoginTooltip;

  /// No description provided for @youtubeLoginClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get youtubeLoginClose;

  /// No description provided for @youtubeLoginScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'YouTube sign-in'**
  String get youtubeLoginScreenTitle;

  /// No description provided for @youtubeLogout.
  ///
  /// In en, this message translates to:
  /// **'Sign out (clear cookies)'**
  String get youtubeLogout;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// No description provided for @transportRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get transportRepeat;

  /// No description provided for @transportFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get transportFullscreen;

  /// No description provided for @transportExitFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Exit fullscreen'**
  String get transportExitFullscreen;

  /// No description provided for @transportMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get transportMore;

  /// No description provided for @transportCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse player'**
  String get transportCollapse;

  /// No description provided for @transportExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand player'**
  String get transportExpand;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @importMedia.
  ///
  /// In en, this message translates to:
  /// **'Import media'**
  String get importMedia;

  /// No description provided for @importingMedia.
  ///
  /// In en, this message translates to:
  /// **'Importing media…'**
  String get importingMedia;

  /// No description provided for @importMediaFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not import this file.'**
  String get importMediaFailed;

  /// No description provided for @noMediaYet.
  ///
  /// In en, this message translates to:
  /// **'No media yet'**
  String get noMediaYet;

  /// No description provided for @tapImportToAdd.
  ///
  /// In en, this message translates to:
  /// **'Import audio or video from the toolbar.'**
  String get tapImportToAdd;

  /// No description provided for @navMainLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary navigation'**
  String get navMainLabel;

  /// No description provided for @miniPlayerMediaVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get miniPlayerMediaVideo;

  /// No description provided for @miniPlayerMediaAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get miniPlayerMediaAudio;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsAppearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme follows your system settings.'**
  String get settingsAppearanceSubtitle;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enjoy Player — local transcripts and shadow reading.'**
  String get settingsAboutSubtitle;

  /// No description provided for @settingsThemeRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeRowTitle;

  /// No description provided for @settingsThemeDarkLocked.
  ///
  /// In en, this message translates to:
  /// **'Follows your system appearance.'**
  String get settingsThemeDarkLocked;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @previousLine.
  ///
  /// In en, this message translates to:
  /// **'Previous line'**
  String get previousLine;

  /// No description provided for @nextLine.
  ///
  /// In en, this message translates to:
  /// **'Next line'**
  String get nextLine;

  /// No description provided for @replayLine.
  ///
  /// In en, this message translates to:
  /// **'Replay line'**
  String get replayLine;

  /// No description provided for @echoMode.
  ///
  /// In en, this message translates to:
  /// **'Echo mode'**
  String get echoMode;

  /// No description provided for @exitEchoMode.
  ///
  /// In en, this message translates to:
  /// **'Exit echo mode'**
  String get exitEchoMode;

  /// No description provided for @transcript.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get transcript;

  /// No description provided for @transcriptNowReading.
  ///
  /// In en, this message translates to:
  /// **'Now reading'**
  String get transcriptNowReading;

  /// No description provided for @playerTranscriptResizeHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to resize the transcript panel'**
  String get playerTranscriptResizeHint;

  /// No description provided for @importSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import subtitle'**
  String get importSubtitle;

  /// No description provided for @noTranscript.
  ///
  /// In en, this message translates to:
  /// **'No transcript'**
  String get noTranscript;

  /// No description provided for @importSrtOrVtt.
  ///
  /// In en, this message translates to:
  /// **'Import an .srt or .vtt file.'**
  String get importSrtOrVtt;

  /// No description provided for @miniPlayerOpen.
  ///
  /// In en, this message translates to:
  /// **'Open player'**
  String get miniPlayerOpen;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @playerOpenGenericError.
  ///
  /// In en, this message translates to:
  /// **'Could not open this item.'**
  String get playerOpenGenericError;

  /// No description provided for @playbackRateTimes.
  ///
  /// In en, this message translates to:
  /// **'{rate}x'**
  String playbackRateTimes(String rate);

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @transportMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get transportMute;

  /// No description provided for @transportUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get transportUnmute;

  /// No description provided for @repeatNone.
  ///
  /// In en, this message translates to:
  /// **'Repeat off'**
  String get repeatNone;

  /// No description provided for @repeatSegment.
  ///
  /// In en, this message translates to:
  /// **'Repeat segment'**
  String get repeatSegment;

  /// No description provided for @settingsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Player preferences will appear here.'**
  String get settingsPlaceholder;

  /// No description provided for @subtitles.
  ///
  /// In en, this message translates to:
  /// **'Subtitles'**
  String get subtitles;

  /// No description provided for @subtitlesPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get subtitlesPrimary;

  /// No description provided for @subtitlesTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation (optional)'**
  String get subtitlesTranslation;

  /// No description provided for @subtitlesNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get subtitlesNone;

  /// No description provided for @subtitlesImportFile.
  ///
  /// In en, this message translates to:
  /// **'Import subtitle file…'**
  String get subtitlesImportFile;

  /// No description provided for @subtitlesDeleteTrack.
  ///
  /// In en, this message translates to:
  /// **'Delete track'**
  String get subtitlesDeleteTrack;

  /// No description provided for @importSubtitleSuccess.
  ///
  /// In en, this message translates to:
  /// **'Subtitle imported'**
  String get importSubtitleSuccess;

  /// No description provided for @noTranscriptHint.
  ///
  /// In en, this message translates to:
  /// **'Cloud transcripts load when you play media (once). For video, use Extract embedded or import an .srt/.vtt file.'**
  String get noTranscriptHint;

  /// No description provided for @subtitlesExtractEmbedded.
  ///
  /// In en, this message translates to:
  /// **'Extract embedded subtitles'**
  String get subtitlesExtractEmbedded;

  /// No description provided for @subtitlesRefreshCloud.
  ///
  /// In en, this message translates to:
  /// **'Refresh transcripts from cloud'**
  String get subtitlesRefreshCloud;

  /// No description provided for @subtitlesImportLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Subtitle language'**
  String get subtitlesImportLanguageTitle;

  /// No description provided for @subtitlesImportLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'BCP-47 code (e.g. en, zh-TW). Use und if unknown.'**
  String get subtitlesImportLanguageHint;

  /// No description provided for @subtitlesProviderOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get subtitlesProviderOfficial;

  /// No description provided for @subtitlesProviderAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get subtitlesProviderAuto;

  /// No description provided for @subtitlesProviderAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get subtitlesProviderAi;

  /// No description provided for @subtitlesProviderUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get subtitlesProviderUser;

  /// No description provided for @subtitlesExtractNoTracks.
  ///
  /// In en, this message translates to:
  /// **'No embedded subtitle tracks found.'**
  String get subtitlesExtractNoTracks;

  /// No description provided for @subtitlesExtractedCount.
  ///
  /// In en, this message translates to:
  /// **'Extracted {count} subtitle track(s).'**
  String subtitlesExtractedCount(int count);

  /// No description provided for @subtitlesRefreshDone.
  ///
  /// In en, this message translates to:
  /// **'Transcripts updated from cloud.'**
  String get subtitlesRefreshDone;

  /// No description provided for @subtitlesNoPlayableUri.
  ///
  /// In en, this message translates to:
  /// **'Could not resolve a playable file for this item.'**
  String get subtitlesNoPlayableUri;

  /// No description provided for @expandEchoBackward.
  ///
  /// In en, this message translates to:
  /// **'Expand echo backward'**
  String get expandEchoBackward;

  /// No description provided for @expandEchoForward.
  ///
  /// In en, this message translates to:
  /// **'Expand echo forward'**
  String get expandEchoForward;

  /// No description provided for @shrinkEchoBackward.
  ///
  /// In en, this message translates to:
  /// **'Shrink echo backward'**
  String get shrinkEchoBackward;

  /// No description provided for @shrinkEchoForward.
  ///
  /// In en, this message translates to:
  /// **'Shrink echo forward'**
  String get shrinkEchoForward;

  /// No description provided for @shadowReadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Shadow reading'**
  String get shadowReadingTitle;

  /// No description provided for @shadowReadingHint.
  ///
  /// In en, this message translates to:
  /// **'Practice speaking along this segment. Record your voice and compare pitch with the reference.'**
  String get shadowReadingHint;

  /// No description provided for @shadowReadingReferenceSnippet.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get shadowReadingReferenceSnippet;

  /// No description provided for @pitchContourTitle.
  ///
  /// In en, this message translates to:
  /// **'Pitch contour'**
  String get pitchContourTitle;

  /// No description provided for @pitchContourError.
  ///
  /// In en, this message translates to:
  /// **'Could not analyze pitch for this segment.'**
  String get pitchContourError;

  /// No description provided for @pitchContourWaveform.
  ///
  /// In en, this message translates to:
  /// **'Waveform'**
  String get pitchContourWaveform;

  /// No description provided for @pitchContourReference.
  ///
  /// In en, this message translates to:
  /// **'Reference pitch'**
  String get pitchContourReference;

  /// No description provided for @pitchContourUser.
  ///
  /// In en, this message translates to:
  /// **'Your pitch'**
  String get pitchContourUser;

  /// No description provided for @shadowRecordingExisting.
  ///
  /// In en, this message translates to:
  /// **'Saved takes'**
  String get shadowRecordingExisting;

  /// No description provided for @shadowRecordingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recordings for this segment yet.'**
  String get shadowRecordingEmpty;

  /// No description provided for @shadowRecordingTake.
  ///
  /// In en, this message translates to:
  /// **'Take'**
  String get shadowRecordingTake;

  /// No description provided for @shadowRecordingPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get shadowRecordingPlay;

  /// No description provided for @shadowRecordingPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get shadowRecordingPause;

  /// No description provided for @shadowRecordingChooseTake.
  ///
  /// In en, this message translates to:
  /// **'Switch take'**
  String get shadowRecordingChooseTake;

  /// No description provided for @shadowRecordingDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get shadowRecordingDelete;

  /// No description provided for @shadowRecordingDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this take?'**
  String get shadowRecordingDeleteConfirmTitle;

  /// No description provided for @shadowRecordingDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'{takeLabel} will be permanently deleted. This cannot be undone.'**
  String shadowRecordingDeleteConfirmMessage(String takeLabel);

  /// No description provided for @shadowRecordingRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get shadowRecordingRecord;

  /// No description provided for @shadowRecordingStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get shadowRecordingStop;

  /// No description provided for @shadowRecordingMicDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required to record.'**
  String get shadowRecordingMicDenied;

  /// Save failed after recording stopped; reason is a short technical detail.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save recording: {reason}'**
  String shadowRecordingSaveFailed(String reason);

  /// No description provided for @shadowRecordingPlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t play this take.'**
  String get shadowRecordingPlaybackFailed;

  /// Shown while recording after elapsed time exceeds the reference segment duration.
  ///
  /// In en, this message translates to:
  /// **'+{seconds}s over target'**
  String shadowRecordingOverTarget(String seconds);

  /// No description provided for @hotkeysTitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get hotkeysTitle;

  /// No description provided for @hotkeysHintFooter.
  ///
  /// In en, this message translates to:
  /// **'Press Shift+/ (?) to open this list.'**
  String get hotkeysHintFooter;

  /// No description provided for @hotkeysCustomizedBadge.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get hotkeysCustomizedBadge;

  /// No description provided for @hotkeysSectionKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get hotkeysSectionKeyboard;

  /// No description provided for @hotkeysResetBinding.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get hotkeysResetBinding;

  /// No description provided for @hotkeysResetAll.
  ///
  /// In en, this message translates to:
  /// **'Reset all shortcuts'**
  String get hotkeysResetAll;

  /// No description provided for @hotkeysCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Press new shortcut'**
  String get hotkeysCaptureTitle;

  /// No description provided for @hotkeysCaptureHint.
  ///
  /// In en, this message translates to:
  /// **'Press a key combination. Escape cancels.'**
  String get hotkeysCaptureHint;

  /// No description provided for @hotkeysConflictError.
  ///
  /// In en, this message translates to:
  /// **'That shortcut is already used.'**
  String get hotkeysConflictError;

  /// No description provided for @hotkeysScopeGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get hotkeysScopeGlobal;

  /// No description provided for @hotkeysScopePlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get hotkeysScopePlayer;

  /// No description provided for @hotkeysScopeLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get hotkeysScopeLibrary;

  /// No description provided for @hotkeysScopeModal.
  ///
  /// In en, this message translates to:
  /// **'Modal'**
  String get hotkeysScopeModal;

  /// No description provided for @hotkeysDescHelp.
  ///
  /// In en, this message translates to:
  /// **'Show keyboard shortcuts'**
  String get hotkeysDescHelp;

  /// No description provided for @hotkeysDescSearch.
  ///
  /// In en, this message translates to:
  /// **'Open search'**
  String get hotkeysDescSearch;

  /// No description provided for @hotkeysDescSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get hotkeysDescSettings;

  /// No description provided for @hotkeysDescTogglePlay.
  ///
  /// In en, this message translates to:
  /// **'Play / Pause'**
  String get hotkeysDescTogglePlay;

  /// No description provided for @hotkeysDescToggleExpand.
  ///
  /// In en, this message translates to:
  /// **'Toggle player expand/collapse'**
  String get hotkeysDescToggleExpand;

  /// No description provided for @hotkeysDescToggleFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Toggle fullscreen'**
  String get hotkeysDescToggleFullscreen;

  /// No description provided for @hotkeysDescPrevLine.
  ///
  /// In en, this message translates to:
  /// **'Play previous line'**
  String get hotkeysDescPrevLine;

  /// No description provided for @hotkeysDescNextLine.
  ///
  /// In en, this message translates to:
  /// **'Play next line'**
  String get hotkeysDescNextLine;

  /// No description provided for @hotkeysDescReplayLine.
  ///
  /// In en, this message translates to:
  /// **'Replay current line'**
  String get hotkeysDescReplayLine;

  /// No description provided for @hotkeysDescToggleEchoMode.
  ///
  /// In en, this message translates to:
  /// **'Toggle Echo mode'**
  String get hotkeysDescToggleEchoMode;

  /// No description provided for @hotkeysDescToggleDictationMode.
  ///
  /// In en, this message translates to:
  /// **'Toggle dictation mode'**
  String get hotkeysDescToggleDictationMode;

  /// No description provided for @hotkeysDescToggleRecording.
  ///
  /// In en, this message translates to:
  /// **'Start/Stop recording'**
  String get hotkeysDescToggleRecording;

  /// No description provided for @hotkeysDescToggleAssessment.
  ///
  /// In en, this message translates to:
  /// **'Show/Hide pronunciation assessment'**
  String get hotkeysDescToggleAssessment;

  /// No description provided for @hotkeysDescTogglePitchContour.
  ///
  /// In en, this message translates to:
  /// **'Show/Hide pitch contour'**
  String get hotkeysDescTogglePitchContour;

  /// No description provided for @hotkeysDescPlayRecording.
  ///
  /// In en, this message translates to:
  /// **'Play/Pause recording'**
  String get hotkeysDescPlayRecording;

  /// No description provided for @hotkeysDescSlowDown.
  ///
  /// In en, this message translates to:
  /// **'Slow down playback speed'**
  String get hotkeysDescSlowDown;

  /// No description provided for @hotkeysDescSpeedUp.
  ///
  /// In en, this message translates to:
  /// **'Speed up playback speed'**
  String get hotkeysDescSpeedUp;

  /// No description provided for @hotkeysDescExpandEchoBackward.
  ///
  /// In en, this message translates to:
  /// **'Expand Echo region backward'**
  String get hotkeysDescExpandEchoBackward;

  /// No description provided for @hotkeysDescExpandEchoForward.
  ///
  /// In en, this message translates to:
  /// **'Expand Echo region forward'**
  String get hotkeysDescExpandEchoForward;

  /// No description provided for @hotkeysDescShrinkEchoBackward.
  ///
  /// In en, this message translates to:
  /// **'Shrink Echo region backward'**
  String get hotkeysDescShrinkEchoBackward;

  /// No description provided for @hotkeysDescShrinkEchoForward.
  ///
  /// In en, this message translates to:
  /// **'Shrink Echo region forward'**
  String get hotkeysDescShrinkEchoForward;

  /// No description provided for @hotkeysDescLibrarySearch.
  ///
  /// In en, this message translates to:
  /// **'Focus search'**
  String get hotkeysDescLibrarySearch;

  /// No description provided for @hotkeysDescCloseModal.
  ///
  /// In en, this message translates to:
  /// **'Close modal'**
  String get hotkeysDescCloseModal;

  /// No description provided for @hotkeysStubSearch.
  ///
  /// In en, this message translates to:
  /// **'Search is not available yet.'**
  String get hotkeysStubSearch;

  /// No description provided for @hotkeysStubAssessment.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation assessment is not available yet.'**
  String get hotkeysStubAssessment;

  /// No description provided for @hotkeysStubDictation.
  ///
  /// In en, this message translates to:
  /// **'Dictation mode is not available yet.'**
  String get hotkeysStubDictation;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Enjoy'**
  String get authSignInTitle;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We will open your browser to sign in. When you are done, return here — we will detect completion automatically.'**
  String get authSignInSubtitle;

  /// No description provided for @authSignInCta.
  ///
  /// In en, this message translates to:
  /// **'Continue in browser'**
  String get authSignInCta;

  /// No description provided for @authWaitingForApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval in your browser…'**
  String get authWaitingForApproval;

  /// No description provided for @authCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get authCancel;

  /// No description provided for @authSignedInSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed in successfully'**
  String get authSignedInSuccess;

  /// No description provided for @authReOpenBrowser.
  ///
  /// In en, this message translates to:
  /// **'Re-open browser'**
  String get authReOpenBrowser;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileFieldName;

  /// No description provided for @profileFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileFieldEmail;

  /// No description provided for @profileFieldGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily goal (minutes)'**
  String get profileFieldGoal;

  /// No description provided for @profileFieldLearningLanguage.
  ///
  /// In en, this message translates to:
  /// **'Learning language'**
  String get profileFieldLearningLanguage;

  /// No description provided for @profileFieldNativeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Native language'**
  String get profileFieldNativeLanguage;

  /// No description provided for @profileFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get profileFieldRequired;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSave;

  /// No description provided for @profileSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaveSuccess;

  /// No description provided for @profileSubscriptionFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get profileSubscriptionFree;

  /// No description provided for @profileSubscriptionPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get profileSubscriptionPro;

  /// No description provided for @profileBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance: {value}'**
  String profileBalance(String value);

  /// No description provided for @settingsSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSectionAccount;

  /// No description provided for @settingsSectionSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync'**
  String get settingsSectionSync;

  /// No description provided for @settingsSectionDataMigration.
  ///
  /// In en, this message translates to:
  /// **'Local data'**
  String get settingsSectionDataMigration;

  /// No description provided for @syncSettingsTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get syncSettingsTileTitle;

  /// No description provided for @syncSettingsTileSubtitleSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync library and recordings'**
  String get syncSettingsTileSubtitleSignedOut;

  /// No description provided for @syncSettingsTileSubtitleUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get syncSettingsTileSubtitleUpToDate;

  /// Subtitle on Settings → Sync status when there are queue items.
  ///
  /// In en, this message translates to:
  /// **'{retryable} waiting · {failed} failed'**
  String syncSettingsTileSubtitleCounts(int retryable, int failed);

  /// No description provided for @syncScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get syncScreenTitle;

  /// No description provided for @syncScreenLastSyncLabel.
  ///
  /// In en, this message translates to:
  /// **'Last successful sync'**
  String get syncScreenLastSyncLabel;

  /// No description provided for @syncScreenLastSyncNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get syncScreenLastSyncNever;

  /// No description provided for @syncScreenStatRetryable.
  ///
  /// In en, this message translates to:
  /// **'Waiting to upload'**
  String get syncScreenStatRetryable;

  /// No description provided for @syncScreenStatFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed permanently'**
  String get syncScreenStatFailed;

  /// No description provided for @syncScreenSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncScreenSyncNow;

  /// No description provided for @syncScreenRetryFailed.
  ///
  /// In en, this message translates to:
  /// **'Retry failed items'**
  String get syncScreenRetryFailed;

  /// No description provided for @syncScreenSignedOutBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your Enjoy account to sync metadata across devices.'**
  String get syncScreenSignedOutBody;

  /// No description provided for @syncScreenGoSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get syncScreenGoSignIn;

  /// No description provided for @syncPendingRekeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Imports pending account link'**
  String get syncPendingRekeyLabel;

  /// No description provided for @syncPendingRekeyHint.
  ///
  /// In en, this message translates to:
  /// **'These items were added while signed out. They will be linked to your account and queued for upload after you sign in.'**
  String get syncPendingRekeyHint;

  /// No description provided for @cloudScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get cloudScreenTitle;

  /// No description provided for @cloudTabAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get cloudTabAudio;

  /// No description provided for @cloudTabVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get cloudTabVideo;

  /// No description provided for @cloudSignedOutBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to browse media saved to your Enjoy account.'**
  String get cloudSignedOutBody;

  /// No description provided for @cloudAddToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add to library'**
  String get cloudAddToLibrary;

  /// No description provided for @cloudAlreadyInLibrary.
  ///
  /// In en, this message translates to:
  /// **'Already in library'**
  String get cloudAlreadyInLibrary;

  /// No description provided for @cloudAddedToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Added to your local library.'**
  String get cloudAddedToLibrary;

  /// No description provided for @cloudEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items in this list.'**
  String get cloudEmpty;

  /// No description provided for @cloudHasMediaUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Streams from your saved URL when opened.'**
  String get cloudHasMediaUrlHint;

  /// No description provided for @cloudNoMediaUrlHint.
  ///
  /// In en, this message translates to:
  /// **'No remote file URL — use Locate file in the player when you open this item.'**
  String get cloudNoMediaUrlHint;

  /// No description provided for @cloudRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh this tab'**
  String get cloudRefreshTooltip;

  /// No description provided for @cloudAddToLibraryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add to library'**
  String get cloudAddToLibraryTooltip;

  /// No description provided for @cloudEmptyAudioTitle.
  ///
  /// In en, this message translates to:
  /// **'No cloud audio yet'**
  String get cloudEmptyAudioTitle;

  /// No description provided for @cloudEmptyAudioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Items you save while signed in will appear here.'**
  String get cloudEmptyAudioSubtitle;

  /// No description provided for @cloudEmptyVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'No cloud video yet'**
  String get cloudEmptyVideoTitle;

  /// No description provided for @cloudEmptyVideoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Items you save while signed in will appear here.'**
  String get cloudEmptyVideoSubtitle;

  /// No description provided for @syncSnackSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sync finished successfully.'**
  String get syncSnackSuccess;

  /// No description provided for @syncSnackIssues.
  ///
  /// In en, this message translates to:
  /// **'Sync finished: {synced} succeeded, {failed} failed.'**
  String syncSnackIssues(int synced, int failed);

  /// No description provided for @syncQueueDetails.
  ///
  /// In en, this message translates to:
  /// **'Queue details'**
  String get syncQueueDetails;

  /// No description provided for @syncQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing in the queue.'**
  String get syncQueueEmpty;

  /// No description provided for @settingsSectionAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get settingsSectionAdvanced;

  /// No description provided for @settingsApiBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'API base URL'**
  String get settingsApiBaseUrl;

  /// No description provided for @settingsApiBaseUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Example: https://enjoy.bot'**
  String get settingsApiBaseUrlHint;

  /// No description provided for @settingsApiBaseUrlSave.
  ///
  /// In en, this message translates to:
  /// **'Save API URL'**
  String get settingsApiBaseUrlSave;

  /// No description provided for @settingsAiApiBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'AI API base URL'**
  String get settingsAiApiBaseUrl;

  /// No description provided for @settingsAiApiBaseUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Example: https://worker.enjoy.bot'**
  String get settingsAiApiBaseUrlHint;

  /// No description provided for @settingsAiApiBaseUrlSave.
  ///
  /// In en, this message translates to:
  /// **'Save AI API URL'**
  String get settingsAiApiBaseUrlSave;

  /// No description provided for @settingsAccountSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get settingsAccountSignedOut;

  /// No description provided for @settingsAccountOpenProfile.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get settingsAccountOpenProfile;

  /// No description provided for @settingsAccountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get settingsAccountSignIn;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get errorNetwork;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Session expired — please sign in again'**
  String get errorUnauthorized;

  /// No description provided for @communityActivity.
  ///
  /// In en, this message translates to:
  /// **'Community Activity'**
  String get communityActivity;

  /// No description provided for @communityToday.
  ///
  /// In en, this message translates to:
  /// **'Community Today'**
  String get communityToday;

  /// No description provided for @homeRecordingsToday.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get homeRecordingsToday;

  /// No description provided for @homePracticeTime.
  ///
  /// In en, this message translates to:
  /// **'Practice Time'**
  String get homePracticeTime;

  /// No description provided for @homeActiveLearners.
  ///
  /// In en, this message translates to:
  /// **'Active Learners'**
  String get homeActiveLearners;

  /// Headline for how many people are learning in the community.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} person learning} other{{count} people learning}}'**
  String homePeopleLearning(int count);

  /// No description provided for @homeNoActiveUsers.
  ///
  /// In en, this message translates to:
  /// **'No active users'**
  String get homeNoActiveUsers;

  /// No description provided for @homeTodaysGoal.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Goal'**
  String get homeTodaysGoal;

  /// No description provided for @homeMinutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get homeMinutes;

  /// No description provided for @homeCompleted.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get homeCompleted;

  /// No description provided for @homeGoalCompleted.
  ///
  /// In en, this message translates to:
  /// **'Goal completed! Great job!'**
  String get homeGoalCompleted;

  /// No description provided for @homeGoalAlmostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost there! Keep going!'**
  String get homeGoalAlmostThere;

  /// No description provided for @homeGoalHalfway.
  ///
  /// In en, this message translates to:
  /// **'Halfway there! You can do it!'**
  String get homeGoalHalfway;

  /// No description provided for @homeGoalGoodStart.
  ///
  /// In en, this message translates to:
  /// **'Good start! Keep practicing!'**
  String get homeGoalGoodStart;

  /// No description provided for @homeGoalJustStarted.
  ///
  /// In en, this message translates to:
  /// **'Just started! Every minute counts!'**
  String get homeGoalJustStarted;

  /// No description provided for @homeGoalStartNow.
  ///
  /// In en, this message translates to:
  /// **'Start your practice now!'**
  String get homeGoalStartNow;

  /// No description provided for @mediaLocateTitle.
  ///
  /// In en, this message translates to:
  /// **'Locate media file'**
  String get mediaLocateTitle;

  /// No description provided for @mediaLocateBody.
  ///
  /// In en, this message translates to:
  /// **'This item was added on another device. Choose the same file on this computer. We verify it matches your library using a secure fingerprint.'**
  String get mediaLocateBody;

  /// No description provided for @mediaLocateChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get mediaLocateChooseFile;

  /// No description provided for @mediaLocateHashMismatch.
  ///
  /// In en, this message translates to:
  /// **'That file does not match this item. Make sure you selected the correct file.'**
  String get mediaLocateHashMismatch;

  /// No description provided for @mediaLocateExpectedSize.
  ///
  /// In en, this message translates to:
  /// **'Expected size: {sizeLabel}'**
  String mediaLocateExpectedSize(String sizeLabel);

  /// No description provided for @mediaLocateSizeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Expected size: unknown'**
  String get mediaLocateSizeUnknown;

  /// No description provided for @migrationBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Move your local data'**
  String get migrationBannerTitle;

  /// No description provided for @migrationBannerBody.
  ///
  /// In en, this message translates to:
  /// **'We noticed you have media and practice history saved locally. Would you like to move it to your account?'**
  String get migrationBannerBody;

  /// No description provided for @migrationBannerActionMove.
  ///
  /// In en, this message translates to:
  /// **'Move data'**
  String get migrationBannerActionMove;

  /// No description provided for @migrationBannerActionDismiss.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get migrationBannerActionDismiss;

  /// No description provided for @settingsMigrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Migrate local data'**
  String get settingsMigrationTitle;

  /// No description provided for @settingsMigrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Move your guest media and history to this account'**
  String get settingsMigrationSubtitle;

  /// No description provided for @migrationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data moved successfully'**
  String get migrationSuccess;

  /// No description provided for @migrationMigrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not move data. Try again later.'**
  String get migrationMigrationFailed;

  /// No description provided for @libraryDeleteMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete from library?'**
  String get libraryDeleteMediaTitle;

  /// No description provided for @libraryDeleteMediaMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" from this device. This cannot be undone.'**
  String libraryDeleteMediaMessage(String title);

  /// No description provided for @libraryDeleteMediaTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete from library'**
  String get libraryDeleteMediaTooltip;

  /// No description provided for @libraryMediaDeleted.
  ///
  /// In en, this message translates to:
  /// **'Removed from library.'**
  String get libraryMediaDeleted;

  /// No description provided for @libraryDeleteMediaFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove this item.'**
  String get libraryDeleteMediaFailed;

  /// No description provided for @settingsSectionDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get settingsSectionDeveloper;

  /// No description provided for @settingsAiPlaygroundTileTitle.
  ///
  /// In en, this message translates to:
  /// **'AI playground'**
  String get settingsAiPlaygroundTileTitle;

  /// No description provided for @settingsAiPlaygroundTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise ASR, chat, translation, and dictionary APIs'**
  String get settingsAiPlaygroundTileSubtitle;

  /// No description provided for @aiPlaygroundTitle.
  ///
  /// In en, this message translates to:
  /// **'AI playground'**
  String get aiPlaygroundTitle;

  /// No description provided for @aiPlaygroundIntro.
  ///
  /// In en, this message translates to:
  /// **'Calls the Enjoy API using your saved base URL and access token. TTS and pronunciation assessment are not wired on Flutter yet (see ADR-0014).'**
  String get aiPlaygroundIntro;

  /// No description provided for @aiPlaygroundPickAudio.
  ///
  /// In en, this message translates to:
  /// **'Pick audio file'**
  String get aiPlaygroundPickAudio;

  /// No description provided for @aiPlaygroundTranscribe.
  ///
  /// In en, this message translates to:
  /// **'Transcribe'**
  String get aiPlaygroundTranscribe;

  /// No description provided for @aiPlaygroundChatSystem.
  ///
  /// In en, this message translates to:
  /// **'System (optional)'**
  String get aiPlaygroundChatSystem;

  /// No description provided for @aiPlaygroundChatUser.
  ///
  /// In en, this message translates to:
  /// **'User message'**
  String get aiPlaygroundChatUser;

  /// No description provided for @aiPlaygroundSendChat.
  ///
  /// In en, this message translates to:
  /// **'Send chat'**
  String get aiPlaygroundSendChat;

  /// No description provided for @aiPlaygroundTranslateSource.
  ///
  /// In en, this message translates to:
  /// **'Source language'**
  String get aiPlaygroundTranslateSource;

  /// No description provided for @aiPlaygroundTranslateTarget.
  ///
  /// In en, this message translates to:
  /// **'Target language'**
  String get aiPlaygroundTranslateTarget;

  /// No description provided for @aiPlaygroundTranslateText.
  ///
  /// In en, this message translates to:
  /// **'Text to translate'**
  String get aiPlaygroundTranslateText;

  /// No description provided for @aiPlaygroundTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get aiPlaygroundTranslate;

  /// No description provided for @aiPlaygroundDictWord.
  ///
  /// In en, this message translates to:
  /// **'Word'**
  String get aiPlaygroundDictWord;

  /// No description provided for @aiPlaygroundDictSource.
  ///
  /// In en, this message translates to:
  /// **'Source language'**
  String get aiPlaygroundDictSource;

  /// No description provided for @aiPlaygroundDictTarget.
  ///
  /// In en, this message translates to:
  /// **'Target language'**
  String get aiPlaygroundDictTarget;

  /// No description provided for @aiPlaygroundDictLookup.
  ///
  /// In en, this message translates to:
  /// **'Dictionary lookup'**
  String get aiPlaygroundDictLookup;

  /// No description provided for @aiPlaygroundTtsDisabled.
  ///
  /// In en, this message translates to:
  /// **'TTS is not available in this build (Azure Speech integration pending).'**
  String get aiPlaygroundTtsDisabled;

  /// No description provided for @aiPlaygroundAssessmentDisabled.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation assessment is not available in this build (Azure Speech integration pending).'**
  String get aiPlaygroundAssessmentDisabled;

  /// No description provided for @aiPlaygroundOutput.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get aiPlaygroundOutput;

  /// No description provided for @aiPlaygroundClearOutput.
  ///
  /// In en, this message translates to:
  /// **'Clear output'**
  String get aiPlaygroundClearOutput;

  /// No description provided for @aiPlaygroundSectionAsr.
  ///
  /// In en, this message translates to:
  /// **'ASR'**
  String get aiPlaygroundSectionAsr;

  /// No description provided for @aiPlaygroundSectionChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get aiPlaygroundSectionChat;

  /// No description provided for @aiPlaygroundSectionTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get aiPlaygroundSectionTranslation;

  /// No description provided for @aiPlaygroundSectionDictionary.
  ///
  /// In en, this message translates to:
  /// **'Dictionary'**
  String get aiPlaygroundSectionDictionary;

  /// No description provided for @aiPlaygroundSectionTtsAssessment.
  ///
  /// In en, this message translates to:
  /// **'TTS / Assessment'**
  String get aiPlaygroundSectionTtsAssessment;

  /// No description provided for @youtubePasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get youtubePasteFromClipboard;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
