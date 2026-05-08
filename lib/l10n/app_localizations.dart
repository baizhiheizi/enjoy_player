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
  /// **'Open a file or drop one here to start.'**
  String get homeEmptyHint;

  /// No description provided for @libraryTabMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get libraryTabMusic;

  /// No description provided for @libraryTabVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get libraryTabVideo;

  /// No description provided for @libraryEmptyMusicTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any music'**
  String get libraryEmptyMusicTitle;

  /// No description provided for @libraryEmptyMusicHint.
  ///
  /// In en, this message translates to:
  /// **'Your library doesn\'t contain any music content.'**
  String get libraryEmptyMusicHint;

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
  /// **'Premium UI uses dark theme.'**
  String get settingsThemeDarkLocked;

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

  /// No description provided for @subtitlesEmbedded.
  ///
  /// In en, this message translates to:
  /// **'Embedded'**
  String get subtitlesEmbedded;

  /// No description provided for @subtitlesImported.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get subtitlesImported;

  /// No description provided for @subtitlesDeleteTrack.
  ///
  /// In en, this message translates to:
  /// **'Delete track'**
  String get subtitlesDeleteTrack;

  /// No description provided for @subtitlesDetected.
  ///
  /// In en, this message translates to:
  /// **'Subtitles detected — tap CC to choose'**
  String get subtitlesDetected;

  /// No description provided for @subtitlesChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get subtitlesChoose;

  /// No description provided for @importSubtitleSuccess.
  ///
  /// In en, this message translates to:
  /// **'Subtitle imported'**
  String get importSubtitleSuccess;

  /// No description provided for @noTranscriptHint.
  ///
  /// In en, this message translates to:
  /// **'Open a video with embedded subtitles, or import an .srt/.vtt file.'**
  String get noTranscriptHint;

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
