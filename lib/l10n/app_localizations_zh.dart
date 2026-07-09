// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Enjoy 播放器';

  @override
  String get libraryTitle => '资料库';

  @override
  String get librarySourceLocal => '本地';

  @override
  String get librarySourceCloud => '云端';

  @override
  String get librarySourceCloudEyebrow => '云端';

  @override
  String get librarySourceSwitchSemantics => '资料库来源';

  @override
  String get librarySourceToggleToCloud => '切换到云端';

  @override
  String get librarySourceToggleToLocal => '切换到本地';

  @override
  String get homeTitle => '首页';

  @override
  String get homeRecentMedia => '最近媒体';

  @override
  String get homeEmptyTitle => '暂无最近媒体';

  @override
  String get homeEmptyHint => '导入媒体或将文件拖放到此处开始。';

  @override
  String get libraryTabAudio => '音频';

  @override
  String get libraryTabVideo => '视频';

  @override
  String get libraryEmptyAudioTitle => '未找到任何音频';

  @override
  String get libraryEmptyAudioHint => '你的资料库中没有任何音频内容。';

  @override
  String get libraryEmptyVideoTitle => '未找到任何视频';

  @override
  String get libraryEmptyVideoHint => '你的资料库中没有任何视频内容。';

  @override
  String get librarySearchNoMatchesTitle => '没有匹配结果';

  @override
  String get librarySearchNoMatchesHint => '资料库中没有符合此搜索的内容。';

  @override
  String get librarySearchClear => '清除搜索';

  @override
  String get libraryDeleteFailed => '无法删除该项目，请重试。';

  @override
  String get transcriptAccessibilityTranscriptList => '字幕';

  @override
  String transcriptAccessibilityCue(String time, String snippet) {
    return '$time。$snippet';
  }

  @override
  String get transcriptAccessibilityCurrentLine => '当前播放行。';

  @override
  String get transcriptAccessibilityEchoRegion => '跟读练习区域。';

  @override
  String get transcriptAccessibilityEchoCurrentLine => '当前跟读行。';

  @override
  String transcriptLineRecordingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条录音',
      one: '1 条录音',
    );
    return '$_temp0';
  }

  @override
  String get transcriptErrorFriendlyTitle => '字幕暂不可用';

  @override
  String get transcriptErrorFriendlyHint => '请尝试选择其他字幕轨道或导入字幕文件。';

  @override
  String get transcriptFetchingSubtitles => '正在获取字幕…';

  @override
  String get actionOpenFiles => '打开文件';

  @override
  String get actionImport => '导入';

  @override
  String get importFromFile => '从文件…';

  @override
  String get importFromYoutube => '从 YouTube 链接…';

  @override
  String get discoverTitle => '发现';

  @override
  String get discoverBrowseAction => '浏览发现';

  @override
  String get discoverRecommendedHeading => '推荐频道';

  @override
  String get discoverSubscriptionsHeading => '订阅';

  @override
  String get discoverTimelineHeading => '最近上传';

  @override
  String get discoverSubscribeTitle => '订阅频道';

  @override
  String get discoverSubscribeHint => '粘贴 YouTube 频道链接或 @用户名。';

  @override
  String get discoverSubscribePlaceholder => 'https://www.youtube.com/@channel';

  @override
  String get discoverSubscribeAction => '订阅';

  @override
  String get discoverSubscribed => '已订阅频道';

  @override
  String get discoverSubscribedLabel => '已订阅';

  @override
  String get discoverSubscribeFailed => '无法订阅该频道。';

  @override
  String get discoverUnsubscribeAction => '取消订阅';

  @override
  String get discoverUnsubscribed => '已取消订阅';

  @override
  String get discoverViewFeed => '查看动态';

  @override
  String get discoverAddToLibrary => '加入库';

  @override
  String get discoverAddedToLibrary => '已加入你的库';

  @override
  String get discoverAddFailed => '无法添加此视频。';

  @override
  String get discoverInLibrary => '已在库中';

  @override
  String get discoverPlay => '播放';

  @override
  String get discoverFeedEmptyTitle => '暂无视频';

  @override
  String get discoverFeedEmptyHint => '订阅频道并刷新以加载最近上传。';

  @override
  String get discoverFeedErrorTitle => '无法加载动态';

  @override
  String get discoverFeedErrorHint => '请检查网络连接后重试。';

  @override
  String get discoverRetry => '重试';

  @override
  String get discoverRefreshPartialFailed => '部分频道动态刷新失败。';

  @override
  String discoverRefreshPartialFailedDetail(int count, String names) {
    return '无法刷新 $count 个频道：$names';
  }

  @override
  String discoverRefreshSingleFailed(Object name) {
    return '无法刷新 $name。';
  }

  @override
  String get discoverRecommendedLoadFailed => '无法加载推荐频道。';

  @override
  String get discoverSubscriptionsLoadFailed => '无法加载订阅。';

  @override
  String get discoverNoSubscriptionsHint => '订阅推荐频道或粘贴频道链接。';

  @override
  String get discoverManageChannels => '管理频道';

  @override
  String get discoverFilterAll => '全部';

  @override
  String get discoverYourChannelsHeading => '你的频道';

  @override
  String get discoverRecommendedAllSubscribed => '你已订阅全部推荐频道。';

  @override
  String get youtubeImportTitle => '导入 YouTube 视频';

  @override
  String get youtubeImportHint => '粘贴 YouTube 链接或视频 ID';

  @override
  String get youtubeImportInvalid => '无法识别有效的 YouTube 视频 ID。';

  @override
  String get youtubeImporting => '正在添加视频…';

  @override
  String get youtubeBadge => 'YouTube';

  @override
  String get youtubeLoginTooltip => 'YouTube 账号';

  @override
  String get youtubeLoginClose => '关闭';

  @override
  String get youtubeLoginScreenTitle => 'YouTube 登录';

  @override
  String get youtubeLogout => '退出登录（清除 Cookie）';

  @override
  String get searchHint => '搜索';

  @override
  String get transportRepeat => '循环';

  @override
  String get transportFullscreen => '全屏';

  @override
  String get transportExitFullscreen => '退出全屏';

  @override
  String get transportMore => '更多';

  @override
  String get transportCollapse => '收起播放器';

  @override
  String get transportExpand => '展开播放器';

  @override
  String get transportDismissPlayer => '关闭播放器';

  @override
  String get settingsTitle => '设置';

  @override
  String get importMedia => '导入媒体';

  @override
  String get importingMedia => '正在导入媒体…';

  @override
  String get importMediaFailed => '无法导入此文件。';

  @override
  String get importUnsupportedFileType => '不支持此文件类型。请选择音频或视频文件。';

  @override
  String get noMediaYet => '暂无媒体';

  @override
  String get tapImportToAdd => '从工具栏导入音频或视频。';

  @override
  String get navMainLabel => '主导航';

  @override
  String get miniPlayerMediaVideo => '视频';

  @override
  String get miniPlayerMediaAudio => '音频';

  @override
  String get retry => '重试';

  @override
  String get settingsSectionAppearance => '外观';

  @override
  String get settingsAppearanceSubtitle => '主题跟随系统设置。';

  @override
  String get settingsSectionAbout => '关于';

  @override
  String get settingsAboutSubtitle => 'Enjoy 播放器 — 本地字幕与跟读练习。';

  @override
  String get settingsThemeRowTitle => '主题';

  @override
  String get settingsThemeDarkLocked => '跟随系统外观。';

  @override
  String get settingsThemeSystem => '系统';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get play => '播放';

  @override
  String get pause => '暂停';

  @override
  String get previousLine => '上一句';

  @override
  String get nextLine => '下一句';

  @override
  String get replayLine => '重播本句';

  @override
  String get echoMode => '回声模式';

  @override
  String get exitEchoMode => '退出回声模式';

  @override
  String get transcript => '字幕稿';

  @override
  String get transcriptNowReading => '正在朗读';

  @override
  String get playerTranscriptResizeHint => '拖动以调整字幕稿面板大小';

  @override
  String get importSubtitle => '导入字幕';

  @override
  String get noTranscript => '无字幕稿';

  @override
  String get importSrtOrVtt => '导入 .srt 或 .vtt 文件。';

  @override
  String get miniPlayerOpen => '打开播放器';

  @override
  String get loading => '加载中…';

  @override
  String get error => '错误';

  @override
  String get playerOpenGenericError => '无法打开此项目。';

  @override
  String playbackRateTimes(String rate) {
    return '$rate 倍';
  }

  @override
  String get speed => '速度';

  @override
  String get volume => '音量';

  @override
  String get transportMute => '静音';

  @override
  String get transportUnmute => '取消静音';

  @override
  String get repeatNone => '关闭循环';

  @override
  String get repeatSegment => '循环片段';

  @override
  String get settingsPlaceholder => '播放器偏好将显示在此处。';

  @override
  String get subtitles => '字幕';

  @override
  String get subtitlesPrimary => '主字幕';

  @override
  String get subtitlesTranslation => '翻译（可选）';

  @override
  String get subtitlesNone => '无';

  @override
  String get subtitlesNotSelected => '未选择';

  @override
  String get subtitlesImportFile => '导入字幕文件…';

  @override
  String get subtitlesDeleteTrack => '删除轨道';

  @override
  String get importSubtitleSuccess => '字幕已导入';

  @override
  String get noTranscriptHint =>
      '打开媒体时云端字幕会在后台加载（每项在刷新前仅一次）。本地视频请使用提取或添加字幕（.srt/.vtt）。';

  @override
  String get transcriptEmptyExtract => '提取';

  @override
  String get transcriptEmptyAddSubtitle => '添加字幕';

  @override
  String get subtitlesExtractEmbedded => '提取内嵌字幕';

  @override
  String get subtitlesRefreshCloud => '从云端刷新字幕稿';

  @override
  String get subtitlesImportLanguageTitle => '字幕语言';

  @override
  String get subtitlesImportLanguageHint => 'BCP-47 代码（如 en、zh-TW）。未知请填 und。';

  @override
  String get subtitlesImportLanguageFieldLabel => '语言代码';

  @override
  String get subtitlesProviderOfficial => '官方';

  @override
  String get subtitlesProviderAuto => '自动';

  @override
  String get subtitlesProviderAi => 'AI';

  @override
  String get subtitlesProviderUser => '用户';

  @override
  String get subtitlesAutoTranslate => '自动翻译';

  @override
  String subtitlesAutoTranslateLanguageChip(String language) {
    return '译为 $language';
  }

  @override
  String get subtitlesAutoTranslateRetranslateLine => '重新翻译此行';

  @override
  String get subtitlesAutoTranslateBlockedStalePrimary =>
      '主字幕已更改，自动翻译将根据新的主字幕重建。';

  @override
  String get subtitlesAutoTranslateLineFailed => '此行未能翻译';

  @override
  String get subtitlesAutoTranslatePendingLine => '翻译中…';

  @override
  String get subtitlesAutoTranslateBlockedSignedOut => '请登录后使用自动翻译。';

  @override
  String get subtitlesAutoTranslateBlockedSameLanguage => '母语与主字幕相同时无需自动翻译。';

  @override
  String get subtitlesAutoTranslateBlockedNoPrimary => '请先选择主字幕。';

  @override
  String get subtitlesAutoTranslateBlockedCredits => '积分不足，无法翻译。请查看订阅。';

  @override
  String get subtitlesExtractNoTracks =>
      '此文件中无内嵌字幕轨道（仅有视频与音频）。若有单独的 .srt 或 .vtt，请使用导入文件。';

  @override
  String subtitlesExtractedCount(int count) {
    return '已提取 $count 条字幕轨道。';
  }

  @override
  String get subtitlesRefreshDone => '已从云端更新字幕稿。';

  @override
  String get subtitlesNoPlayableUri => '无法解析此项目的可播放文件。';

  @override
  String get expandEchoBackward => '向后扩展回声';

  @override
  String get expandEchoForward => '向前扩展回声';

  @override
  String get shrinkEchoBackward => '向后收缩回声';

  @override
  String get shrinkEchoForward => '向前收缩回声';

  @override
  String get shadowReadingTitle => '跟读';

  @override
  String get shadowReadingHint => '跟读本段并练习口语。录制你的声音并与参考音高对比。';

  @override
  String get shadowReadingReferenceSnippet => '参考';

  @override
  String get pitchContourTitle => '音高曲线';

  @override
  String get pitchContourError => '无法分析本段的音高。';

  @override
  String get pitchContourWaveform => '波形';

  @override
  String get pitchContourReference => '参考音高';

  @override
  String get pitchContourUser => '你的音高';

  @override
  String get pitchContourAnalyzing => '正在分析音高…';

  @override
  String get shadowRecordingExisting => '已保存的录音';

  @override
  String get shadowRecordingEmpty => '本段尚无录音。';

  @override
  String get shadowRecordingTake => '录音';

  @override
  String get shadowRecordingPlay => '播放';

  @override
  String get shadowRecordingPause => '暂停';

  @override
  String get shadowRecordingChooseTake => '切换录音';

  @override
  String get shadowRecordingDelete => '删除';

  @override
  String get shadowRecordingDeleteConfirmTitle => '删除此条录音？';

  @override
  String shadowRecordingDeleteConfirmMessage(String takeLabel) {
    return '将永久删除 $takeLabel，无法撤销。';
  }

  @override
  String get shadowRecordingRecord => '录音';

  @override
  String get shadowRecordingStop => '停止';

  @override
  String get shadowRecordingMicDenied => '需要麦克风权限才能录音。';

  @override
  String shadowRecordingSaveFailed(String reason) {
    return '无法保存录音：$reason';
  }

  @override
  String get settingsSectionAi => 'AI';

  @override
  String get settingsSectionAiHint => '选择 Enjoy AI 或自备 API 密钥。';

  @override
  String get settingsAiProvidersTileTitle => 'AI 提供商';

  @override
  String get settingsAiProvidersTileSubtitle => '默认使用 Enjoy AI，也可为各功能配置自己的密钥';

  @override
  String get settingsAiProvidersTitle => 'AI 提供商';

  @override
  String get settingsAiProvidersSubtitle => '配置 Enjoy Player 各 AI 功能的调用方式。';

  @override
  String get settingsAiProvidersPrivacyNotice =>
      'API 密钥仅安全存储在本设备，不会同步到 Enjoy 云端。';

  @override
  String get settingsAiProvidersEnjoyAi => 'Enjoy AI';

  @override
  String get settingsAiProvidersByok => '自备密钥';

  @override
  String get settingsAiProvidersModalityLlm => '语言模型';

  @override
  String get settingsAiProvidersModalityLlmHint => '对话、翻译、词典与语境翻译';

  @override
  String get settingsAiProvidersModalityAsr => '语音识别';

  @override
  String get settingsAiProvidersModalityAsrHint => '将音频转写为文字';

  @override
  String get settingsAiProvidersModalityTts => '文字转语音';

  @override
  String get settingsAiProvidersModalityTtsHint => '将文字合成为语音';

  @override
  String get settingsAiProvidersModalityAssessment => '发音评估';

  @override
  String get settingsAiProvidersModalityAssessmentHint =>
      '使用 Azure Speech 为跟读录音打分';

  @override
  String get settingsAiProvidersLlmSpecLabel => '协议';

  @override
  String get settingsAiProvidersLlmSpecOpenAi => 'OpenAI 兼容';

  @override
  String get settingsAiProvidersLlmSpecAnthropic => 'Anthropic 兼容';

  @override
  String get settingsAiProvidersLlmSpecGoogle => 'Google 兼容';

  @override
  String get settingsAiProvidersPresetsLabel => '预设';

  @override
  String get settingsAiProvidersBaseUrlLabel => 'Base URL';

  @override
  String get settingsAiProvidersBaseUrlHint => 'https://api.example.com/v1';

  @override
  String get settingsAiProvidersApiKeyLabel => 'API 密钥';

  @override
  String get settingsAiProvidersApiKeyExistingHint => '留空则保留已保存的密钥';

  @override
  String get settingsAiProvidersShowApiKey => '显示 API 密钥';

  @override
  String get settingsAiProvidersHideApiKey => '隐藏 API 密钥';

  @override
  String get settingsAiProvidersModelLabel => '模型';

  @override
  String get settingsAiProvidersFetchModels => '获取模型列表';

  @override
  String get settingsAiProvidersFetchedModelsLabel => '已获取的模型';

  @override
  String get settingsAiProvidersFetchModelsFailed =>
      '无法获取模型列表，请检查 Base URL 和 API 密钥。';

  @override
  String get settingsAiProvidersFetchModelsEmpty => '此端点未返回任何模型。';

  @override
  String get settingsAiProvidersSave => '保存';

  @override
  String get settingsAiProvidersSaveSuccess => 'AI 提供商设置已保存。';

  @override
  String get settingsAiProvidersRemoveByok => '移除 BYOK';

  @override
  String get settingsAiProvidersRemoveByokTitle => '移除 BYOK 凭据？';

  @override
  String get settingsAiProvidersRemoveByokBody =>
      '将删除本设备上保存的 API 密钥，并将该功能恢复为 Enjoy AI。';

  @override
  String get settingsAiProvidersRemoveByokSuccess => 'BYOK 凭据已移除。';

  @override
  String get settingsAiProvidersCancel => '取消';

  @override
  String get settingsAiProvidersComingSoon => '此功能的 BYOK 配置即将推出。';

  @override
  String get settingsAiProvidersSpeechSubscriptionKeyLabel => 'Azure 订阅密钥';

  @override
  String get settingsAiProvidersSpeechRegionLabel => 'Azure 区域';

  @override
  String get settingsAiProvidersSpeechRegionHint => 'eastus';

  @override
  String get settingsAiProvidersSpeechKindLabel => '供应商';

  @override
  String get settingsAiProvidersSpeechKindOpenAi => 'OpenAI Whisper';

  @override
  String get settingsAiProvidersSpeechKindAzure => 'Azure Speech';

  @override
  String get settingsAiProvidersSpeechWhisperModelLabel => 'Whisper 模型';

  @override
  String get settingsAiProvidersSpeechWhisperModelHint => 'whisper-1';

  @override
  String get settingsAiProvidersSpeechTtsModelLabel => 'TTS 模型';

  @override
  String get settingsAiProvidersSpeechTtsModelHint => 'tts-1';

  @override
  String get settingsAiProvidersApiKeySavedMask => '••••••••••••';

  @override
  String get settingsAiProvidersApiKeyEdit => '编辑密钥';

  @override
  String byokNotConfiguredMessage(String modality) {
    return '已为 $modality 选择 BYOK，但本设备未保存 API 密钥。';
  }

  @override
  String get byokNotConfiguredOpenSettings => '请打开 设置 → AI 提供商 添加密钥。';

  @override
  String get byokValidationApiKeyRequired => '需要 API 密钥。';

  @override
  String get byokValidationBaseUrlRequired => '需要 Base URL。';

  @override
  String get byokValidationBaseUrlInvalid => 'Base URL 必须是公网 HTTPS 地址。';

  @override
  String get byokValidationModelRequired => '需要填写模型。';

  @override
  String get byokValidationRegionRequired => '需要 Azure 区域。';

  @override
  String get byokValidationApiSpecRequired => '协议配置不完整。';

  @override
  String get byokValidationAzureKindRequired => '发音评估 BYOK 需要使用 Azure Speech。';

  @override
  String get settingsSectionRecording => '录音';

  @override
  String get settingsSectionRecordingHint => '跟读录音所使用的麦克风。';

  @override
  String get settingsRecordingMicTitle => '麦克风';

  @override
  String settingsRecordingMicAuto(String label) {
    return '自动 · $label';
  }

  @override
  String get settingsRecordingMicAutoNoDevice => '自动 · 系统默认';

  @override
  String get settingsRecordingMicEmpty => '未检测到麦克风';

  @override
  String get settingsRecordingMicAutoOption => '自动（跳过虚拟麦克风）';

  @override
  String get settingsRecordingMicDialogTitle => '选择麦克风';

  @override
  String get shadowRecordingSilentWarning => '未检测到麦克风信号。请打开「设置 → 录音」选择其他麦克风。';

  @override
  String get shadowRecordingPlaybackFailed => '无法播放此条录音。';

  @override
  String shadowRecordingOverTarget(String seconds) {
    return '超出目标 +$seconds 秒';
  }

  @override
  String get hotkeysTitle => '键盘快捷键';

  @override
  String get hotkeysHintFooter => '按 Shift+/（?）打开此列表。';

  @override
  String get hotkeysCustomizedBadge => '已自定义';

  @override
  String get hotkeysSectionKeyboard => '键盘快捷键';

  @override
  String get hotkeysResetBinding => '重置';

  @override
  String get hotkeysResetAll => '重置全部快捷键';

  @override
  String get hotkeysResetAllConfirmTitle => '重置全部快捷键？';

  @override
  String get hotkeysResetAllConfirmMessage => '所有快捷键将恢复为默认绑定，自定义设置无法撤销。';

  @override
  String get hotkeysCaptureTitle => '按下新快捷键';

  @override
  String get hotkeysCaptureHint => '按下组合键。Esc 取消。';

  @override
  String get hotkeysConflictError => '该快捷键已被使用。';

  @override
  String get hotkeysScopeGlobal => '全局';

  @override
  String get hotkeysScopePlayer => '播放器';

  @override
  String get hotkeysScopeLibrary => '资料库';

  @override
  String get hotkeysScopeModal => '弹窗';

  @override
  String get hotkeysDescHelp => '显示键盘快捷键';

  @override
  String get hotkeysDescSearch => '打开搜索';

  @override
  String get hotkeysDescSettings => '打开设置';

  @override
  String get hotkeysDescTogglePlay => '播放 / 暂停';

  @override
  String get hotkeysDescToggleExpand => '切换播放器展开/收起';

  @override
  String get hotkeysDescToggleFullscreen => '切换全屏';

  @override
  String get hotkeysDescPrevLine => '播放上一句';

  @override
  String get hotkeysDescNextLine => '播放下一句';

  @override
  String get hotkeysDescReplayLine => '重播当前句';

  @override
  String get hotkeysDescToggleEchoMode => '切换回声模式';

  @override
  String get hotkeysDescToggleBlurPractice => '切换听力专注（模糊练习）';

  @override
  String get hotkeysDescToggleRecording => '开始/停止录音';

  @override
  String get hotkeysDescToggleAssessment => '显示/隐藏发音评测';

  @override
  String get hotkeysDescTogglePitchContour => '显示/隐藏音高曲线';

  @override
  String get hotkeysDescPlayRecording => '播放/暂停录音';

  @override
  String get hotkeysDescSlowDown => '减慢播放速度';

  @override
  String get hotkeysDescSpeedUp => '加快播放速度';

  @override
  String get hotkeysDescExpandEchoBackward => '向后扩展回声区域';

  @override
  String get hotkeysDescExpandEchoForward => '向前扩展回声区域';

  @override
  String get hotkeysDescShrinkEchoBackward => '向后收缩回声区域';

  @override
  String get hotkeysDescShrinkEchoForward => '向前收缩回声区域';

  @override
  String get hotkeysDescLibrarySearch => '聚焦搜索框';

  @override
  String get hotkeysDescCloseModal => '关闭浮层、退出全屏或取消录音';

  @override
  String get hotkeysStubSearch => '搜索功能尚未提供。';

  @override
  String get assessmentTitle => '发音评测';

  @override
  String get assessmentDescription => '为你的朗读提供详细评分。';

  @override
  String get assessmentRun => '运行发音评测';

  @override
  String get assessmentView => '查看发音评测';

  @override
  String get assessmentReassess => '重新评测';

  @override
  String get assessmentOverallScore => '总分';

  @override
  String get assessmentAccuracy => '准确度';

  @override
  String get assessmentCompleteness => '完整度';

  @override
  String get assessmentFluency => '流利度';

  @override
  String get assessmentProsody => '韵律';

  @override
  String get assessmentPronunciationAnalysis => '发音分析';

  @override
  String get assessmentAccuracyScore => '准确度分数';

  @override
  String get assessmentSyllables => '音节';

  @override
  String get assessmentPhonemes => '音素';

  @override
  String get assessmentNoRecording => '录音文件缺失或为空。';

  @override
  String get assessmentNoResultSummary => '此条录音没有可用的详细评分。';

  @override
  String assessmentRunFailed(String reason) {
    return '无法运行评测：$reason';
  }

  @override
  String get assessmentErrorTypeOmission => '遗漏';

  @override
  String get assessmentErrorTypeInsertion => '插入';

  @override
  String get assessmentErrorTypeMispronunciation => '发音错误';

  @override
  String get assessmentErrorTypeUnexpectedBreak => '意外停顿';

  @override
  String get assessmentErrorTypeMissingBreak => '缺少停顿';

  @override
  String get assessmentErrorTypeMonotone => '单调';

  @override
  String get assessmentErrorTypeCorrect => '正确';

  @override
  String get assessmentErrorExplOmission => '预期应有此词但未检测到。';

  @override
  String get assessmentErrorExplInsertion => '检测到参考中不存在的额外词语。';

  @override
  String get assessmentErrorExplMispronunciation => '此词发音可能不正确。';

  @override
  String get assessmentErrorExplUnexpectedBreak => '在此词前检测到意外停顿。';

  @override
  String get assessmentErrorExplMissingBreak => '在此词前未检测到应有的停顿。';

  @override
  String get assessmentErrorExplMonotone => '音高变化低于预期。';

  @override
  String get assessmentErrorExplCorrect => '此词未发现问题。';

  @override
  String get assessmentEmptyReference => '参考文本为空。';

  @override
  String get assessmentInvalidStored => '无法读取已保存的评测数据。';

  @override
  String get authSignInTitle => '欢迎使用 Enjoy';

  @override
  String get authSignInSubtitle => '登录后即可同步媒体库、记录学习进度，并在任意设备继续学习。';

  @override
  String get authSignInCta => '继续';

  @override
  String get authContinueWithGoogle => '使用 Google 继续';

  @override
  String get authContinueWithApple => '使用 Apple 继续';

  @override
  String get authContinueWithEmail => '使用邮箱继续';

  @override
  String get authOtherSignInOptions => '其他登录方式';

  @override
  String get authOrDivider => '或';

  @override
  String get authEmailPrompt => '我们将向您的邮箱发送一次性验证码。';

  @override
  String get authEmailLabel => '邮箱';

  @override
  String get authEmailInvalid => '请输入有效的邮箱地址。';

  @override
  String get authSendOtp => '发送验证码';

  @override
  String get authOtpTitle => '输入验证码';

  @override
  String authOtpSentTo(String email) {
    return '验证码已发送至 $email';
  }

  @override
  String get authOtpLabel => '6 位验证码';

  @override
  String get authVerifyOtp => '验证';

  @override
  String get authOtpResend => '重新发送';

  @override
  String authOtpResendIn(int seconds) {
    return '$seconds 秒后可重新发送';
  }

  @override
  String get authChangeEmail => '更换邮箱';

  @override
  String get authOtpResumeTitle => '继续登录';

  @override
  String authOtpResumeSubtitle(String email) {
    return '请输入发送至 $email 的验证码';
  }

  @override
  String get authOtpResumeAction => '继续验证';

  @override
  String get authWebSignInWaiting => '请在浏览器中完成登录…';

  @override
  String get authWaitingForApproval => '正在完成登录…';

  @override
  String get authCancel => '取消';

  @override
  String get authSignedInSuccess => '登录成功';

  @override
  String get authReloadSignInPage => '重新加载登录页';

  @override
  String get authOpenInSystemBrowser => '在系统浏览器中打开';

  @override
  String get authSignOut => '退出登录';

  @override
  String get profileTitle => '个人资料';

  @override
  String get profileRefreshTooltip => '刷新个人资料';

  @override
  String get profileFieldName => '姓名';

  @override
  String get profileFieldEmail => '邮箱';

  @override
  String get profileFieldGoal => '每日目标（分钟）';

  @override
  String get profileFieldLearningLanguage => '学习语言';

  @override
  String get profileFieldNativeLanguage => '母语';

  @override
  String get profileFieldRequired => '必填';

  @override
  String get profileSave => '保存';

  @override
  String get profileSaveSuccess => '资料已保存';

  @override
  String get profileSubscriptionFree => '免费';

  @override
  String get profileSubscriptionPro => '专业版';

  @override
  String profileBalance(String value) {
    return '余额：$value';
  }

  @override
  String get profileStatTodayTitle => '今日';

  @override
  String get profileStatWeekTitle => '本周';

  @override
  String get profileStatMonthTitle => '本月';

  @override
  String get profileSectionPractice => '练习';

  @override
  String get profileSectionPracticeHint => '账户同步的练习时长';

  @override
  String get profileCreditsUsageTile => '积分使用记录';

  @override
  String get profileCreditsUsageSubtitle => '查看 Enjoy AI Worker 上的积分消耗';

  @override
  String get profileSectionAccount => '账户';

  @override
  String get profileSectionAccountHint => '积分余额与使用记录';

  @override
  String get profileSectionPreferences => '偏好设置';

  @override
  String get profileSectionPreferencesHint => '姓名、每日目标与语言';

  @override
  String get profileSignOutConfirmTitle => '退出登录？';

  @override
  String get profileSignOutConfirmMessage => '退出后需要重新登录才能同步和使用 AI 功能。';

  @override
  String get profileSubscriptionTile => '订阅';

  @override
  String get profileSubscriptionSubtitle => '查看方案并升级至专业版';

  @override
  String get subscriptionTitle => '订阅';

  @override
  String get subscriptionDescription => '管理订阅方案与 Pro 权益。';

  @override
  String get subscriptionErrorLoading => '无法加载订阅状态';

  @override
  String get subscriptionStatusCardTitle => '订阅状态';

  @override
  String get subscriptionCurrentPlan => '当前方案';

  @override
  String get subscriptionStatusTier => '档位';

  @override
  String get subscriptionStatusActive => '状态';

  @override
  String get subscriptionActive => '有效';

  @override
  String get subscriptionInactive => '无效';

  @override
  String get subscriptionStatusExpiration => '到期时间';

  @override
  String get subscriptionNeverExpires => '永不过期';

  @override
  String subscriptionExpiresOn(String date) {
    return '到期于 $date';
  }

  @override
  String get subscriptionStatusCreditsLimit => '每日积分上限';

  @override
  String subscriptionDailyCredits(String count) {
    return '$count 积分';
  }

  @override
  String get subscriptionTierComparisonTitle => '选择方案';

  @override
  String get subscriptionTierFreeName => '免费';

  @override
  String get subscriptionTierFreeDescription => '适合轻度使用';

  @override
  String get subscriptionTierFreePrice => '免费';

  @override
  String get subscriptionTierFreeDailyCredits => '1,000 积分/天';

  @override
  String get subscriptionTierProName => '专业版';

  @override
  String get subscriptionTierProDescription => '适合认真学习者';

  @override
  String get subscriptionTierProPrice => '9.99 USD/月';

  @override
  String get subscriptionTierProDailyCredits => '60,000 积分/天';

  @override
  String get subscriptionFeatureFreeTranslation => '基础翻译';

  @override
  String get subscriptionFeatureFreeSmartTranslation => '有限智能翻译';

  @override
  String get subscriptionFeatureFreeDictionary => '有限词典';

  @override
  String get subscriptionFeatureFreeAsr => '有限语音识别';

  @override
  String get subscriptionFeatureFreeTts => '有限语音合成';

  @override
  String get subscriptionFeatureFreeAssessment => '有限发音评估';

  @override
  String get subscriptionFeatureProTranslation => '无限翻译';

  @override
  String get subscriptionFeatureProSmartTranslation => '大量智能翻译';

  @override
  String get subscriptionFeatureProDictionary => '大量词典查询';

  @override
  String get subscriptionFeatureProAsr => '大量语音识别';

  @override
  String get subscriptionFeatureProTts => '大量语音合成';

  @override
  String get subscriptionFeatureProAssessment => '大量发音评估';

  @override
  String get subscriptionUpgrade => '升级至专业版';

  @override
  String get subscriptionUpgradeShort => '升级';

  @override
  String get subscriptionRecommendedPlan => '推荐';

  @override
  String get subscriptionExtend => '续订';

  @override
  String get subscriptionPurchaseTitle => '购买 Pro 订阅';

  @override
  String get subscriptionPurchaseSelectDuration => '选择时长';

  @override
  String get subscriptionPurchaseDuration => '时长';

  @override
  String get subscriptionPurchaseOneMonth => '1 个月';

  @override
  String get subscriptionPurchaseOneSeason => '1 季';

  @override
  String get subscriptionPurchaseOneYear => '1 年';

  @override
  String get subscriptionPurchaseCustomDuration => '自定义';

  @override
  String get subscriptionPurchaseCustomMonthsLabel => '月数';

  @override
  String get subscriptionPurchaseCustomMonthsHint => '1–12';

  @override
  String get subscriptionPurchaseCustomMonthsHelper => '请输入 1 到 12 个月';

  @override
  String subscriptionPurchaseMonths(int count) {
    return '$count 个月';
  }

  @override
  String get subscriptionPurchasePaymentMethod => '支付方式';

  @override
  String get subscriptionProcessorStripe => 'Stripe';

  @override
  String get subscriptionProcessorMixin => '虚拟货币';

  @override
  String get subscriptionPaymentMethodCard => '银行卡';

  @override
  String get subscriptionPaymentMethodWechat => '微信';

  @override
  String get subscriptionPaymentMethodAlipay => '支付宝';

  @override
  String get subscriptionPaymentMethodGooglePay => 'Google Pay';

  @override
  String get subscriptionPaymentMethodUsdt => 'USDT';

  @override
  String get subscriptionPaymentMethodUsdc => 'USDC';

  @override
  String get subscriptionPaymentMethodBtc => 'BTC';

  @override
  String get subscriptionPaymentMethodEth => 'ETH';

  @override
  String get subscriptionPaymentMethodDoge => 'Doge';

  @override
  String get subscriptionPaymentMethodAndMore => '更多';

  @override
  String get subscriptionTotalPriceLabel => '合计';

  @override
  String subscriptionTotalPrice(String amount) {
    return '$amount USD';
  }

  @override
  String get subscriptionContinueToPayment => '继续支付';

  @override
  String get subscriptionRedirectingToPayment => '正在跳转到支付页面…';

  @override
  String get subscriptionPaymentUrlMissing => '支付链接不可用';

  @override
  String get subscriptionPaymentLaunchFailed => '无法打开支付页面';

  @override
  String get subscriptionPurchaseFailed => '购买失败';

  @override
  String get subscriptionMobilePurchaseTitle => '移动端购买即将推出';

  @override
  String get subscriptionMobilePurchaseMessage =>
      'iOS 和 Android 的应用内购买尚未开放。若您已在网页或桌面端购买 Pro，上方会显示您的状态。';

  @override
  String get subscriptionCreditsLimitMessage => 'AI 积分已达上限。升级可获得更高额度。';

  @override
  String get subscriptionViewPlans => '查看方案';

  @override
  String get creditsUsageTitle => '积分使用';

  @override
  String get creditsUsageDescription => 'Enjoy AI Worker 上的积分校验记录（UTC 日期）。';

  @override
  String get creditsUsageStartDate => '开始日期';

  @override
  String get creditsUsageEndDate => '结束日期';

  @override
  String get creditsUsageServiceType => '服务';

  @override
  String get creditsUsageClearFilters => '清除筛选';

  @override
  String get creditsUsageError => '无法加载记录';

  @override
  String get creditsUsageErrorDescription => '请检查网络与设置中的 AI API 地址。';

  @override
  String get creditsUsageRetry => '重试';

  @override
  String get creditsUsageNoRecords => '暂无记录';

  @override
  String get creditsUsageNoRecordsWithFilters => '请尝试调整或清除筛选条件。';

  @override
  String get creditsUsageNoRecordsDescription => '登录后使用 AI 功能，记录将显示在此处。';

  @override
  String get creditsUsageTableDate => '日期';

  @override
  String get creditsUsageTableTime => '时间';

  @override
  String get creditsUsageTableService => '服务';

  @override
  String get creditsUsageTableTier => '档位';

  @override
  String get creditsUsageTableRequired => '需要';

  @override
  String get creditsUsageTableUsedAfter => '用后';

  @override
  String get creditsUsageTableStatus => '状态';

  @override
  String get creditsUsageAllowed => '允许';

  @override
  String get creditsUsageDenied => '拒绝';

  @override
  String creditsUsagePageInfo(int page) {
    return '第 $page 页';
  }

  @override
  String creditsUsageTotalRecords(int count) {
    return '共 $count 条';
  }

  @override
  String get creditsUsagePrevious => '上一页';

  @override
  String get creditsUsageNext => '下一页';

  @override
  String get creditsServiceTypeAll => '全部';

  @override
  String get creditsServiceTypeTts => '语音合成';

  @override
  String get creditsServiceTypeAsr => '语音识别';

  @override
  String get creditsServiceTypeTranslation => '翻译';

  @override
  String get creditsServiceTypeLlm => '大模型';

  @override
  String get creditsServiceTypeAssessment => '发音评估';

  @override
  String get settingsSectionAccount => '账号';

  @override
  String get settingsSectionAccountHint => '个人资料、订阅与退出登录';

  @override
  String get settingsSectionSyncHint => '上传队列、离线状态与手动同步';

  @override
  String get settingsSectionAppearanceLanguageHint => '主题密度、字幕稿字体与区域设置';

  @override
  String get hotkeysSectionKeyboardHint => '查看并自定义快捷键';

  @override
  String get settingsSectionAdvancedHint => 'API 地址与实验性开关';

  @override
  String get settingsSectionDeveloperHint => '诊断与内部工具';

  @override
  String get settingsSectionAboutHint => '版本、许可与链接';

  @override
  String get settingsSectionSync => '云端同步';

  @override
  String get syncSettingsTileTitle => '同步状态';

  @override
  String get syncSettingsTileSubtitleSignedOut => '登录后可同步资料库与录音';

  @override
  String get syncSettingsTileSubtitleUpToDate => '已是最新';

  @override
  String syncSettingsTileSubtitleCounts(int retryable, int failed) {
    return '$retryable 项等待中 · $failed 项失败';
  }

  @override
  String get syncScreenTitle => '同步状态';

  @override
  String get syncScreenLastSyncLabel => '上次成功同步';

  @override
  String get syncScreenLastSyncNever => '从未';

  @override
  String get syncScreenStatRetryable => '等待上传';

  @override
  String get syncScreenStatFailed => '永久失败';

  @override
  String get syncScreenSyncNow => '立即同步';

  @override
  String get syncScreenRetryFailed => '重试失败项';

  @override
  String get syncScreenSignedOutBody => '使用 Enjoy 账号登录以在设备间同步元数据。';

  @override
  String get syncScreenGoSignIn => '登录';

  @override
  String get cloudScreenTitle => '云端';

  @override
  String get cloudTabAudio => '音频';

  @override
  String get cloudTabVideo => '视频';

  @override
  String get cloudSignedOutBody => '登录后可浏览保存到 Enjoy 账号的媒体。';

  @override
  String get cloudAddToLibrary => '添加到资料库';

  @override
  String get cloudAlreadyInLibrary => '已在资料库中';

  @override
  String get cloudAddedToLibrary => '已添加到本地资料库。';

  @override
  String get cloudEmpty => '此列表为空。';

  @override
  String get cloudHasMediaUrlHint => '打开时从已保存的 URL 流式播放。';

  @override
  String get cloudNoMediaUrlHint => '无远程文件 URL — 打开此项目时请在播放器中使用「定位文件」。';

  @override
  String get cloudRefreshTooltip => '刷新此标签页';

  @override
  String get cloudAddToLibraryTooltip => '添加到资料库';

  @override
  String get cloudEmptyAudioTitle => '暂无云端音频';

  @override
  String get cloudEmptyAudioSubtitle => '登录后保存的项目将显示在此处。';

  @override
  String get cloudEmptyVideoTitle => '暂无云端视频';

  @override
  String get cloudEmptyVideoSubtitle => '登录后保存的项目将显示在此处。';

  @override
  String get syncSnackSuccess => '同步已成功完成。';

  @override
  String syncSnackIssues(int synced, int failed) {
    return '同步结束：$synced 项成功，$failed 项失败。';
  }

  @override
  String get syncQueueDetails => '队列详情';

  @override
  String get syncQueueEmpty => '队列为空。';

  @override
  String get settingsSectionAdvanced => '高级';

  @override
  String get settingsApiBaseUrl => 'API 基础地址';

  @override
  String get settingsApiBaseUrlHint => '示例：https://enjoy.bot';

  @override
  String get settingsApiBaseUrlSave => '保存 API 地址';

  @override
  String get settingsAiApiBaseUrl => 'AI API 基础地址';

  @override
  String get settingsAiApiBaseUrlHint => '示例：https://worker.enjoy.bot';

  @override
  String get settingsAiApiBaseUrlSave => '保存 AI API 地址';

  @override
  String get settingsAiApiBaseUrlUseDefault => '使用主 API 地址';

  @override
  String get settingsAiApiBaseUrlCleared => 'AI API 现在跟随主 API 地址。';

  @override
  String get settingsAccountSignedOut => '未登录';

  @override
  String get settingsAccountOpenProfile => '打开个人资料';

  @override
  String get settingsAccountSignIn => '登录';

  @override
  String get errorNetwork => '网络错误';

  @override
  String get errorUnauthorized => '会话已过期 — 请重新登录';

  @override
  String get communityActivity => '社区动态';

  @override
  String get communityToday => '今日社区';

  @override
  String get homeRecordingsToday => '录音';

  @override
  String get homePracticeTime => '练习时长';

  @override
  String get homeActiveLearners => '活跃学习者';

  @override
  String homePeopleLearning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 人正在学习',
      one: '$count 人正在学习',
    );
    return '$_temp0';
  }

  @override
  String get homeNoActiveUsers => '暂无活跃用户';

  @override
  String get homeTodaysGoal => '今日目标';

  @override
  String get homeMinutes => '分钟';

  @override
  String get homeCompleted => '已完成';

  @override
  String get homeGoalCompleted => '目标完成！太棒了！';

  @override
  String get homeGoalAlmostThere => '快完成了！继续加油！';

  @override
  String get homeGoalHalfway => '已经完成一半！你可以的！';

  @override
  String get homeGoalGoodStart => '不错的开始！坚持练习！';

  @override
  String get homeGoalJustStarted => '刚刚开始！每一分钟都很重要！';

  @override
  String get homeGoalStartNow => '现在开始练习吧！';

  @override
  String get mediaLocateTitle => '定位媒体文件';

  @override
  String get mediaLocateBody => '此项目是在其他设备上添加的。请在本机选择同一文件。我们会通过安全指纹校验是否与资料库匹配。';

  @override
  String get mediaLocateChooseFile => '选择文件';

  @override
  String get mediaLocateHashMismatch => '该文件与此项目不匹配。请确认选择了正确文件。';

  @override
  String mediaLocateExpectedSize(String sizeLabel) {
    return '预期大小：$sizeLabel';
  }

  @override
  String get mediaLocateSizeUnknown => '预期大小：未知';

  @override
  String get libraryDeleteMediaTitle => '从资料库删除？';

  @override
  String libraryDeleteMediaMessage(String title) {
    return '从本机移除「$title」。此操作无法撤销。';
  }

  @override
  String get libraryDeleteMediaTooltip => '从资料库删除';

  @override
  String get libraryMediaDeleted => '已从资料库移除。';

  @override
  String get libraryDeleteMediaFailed => '无法移除此项目。';

  @override
  String get settingsSectionDeveloper => '开发者';

  @override
  String get settingsAiPlaygroundTileTitle => 'AI 试验台';

  @override
  String get settingsAiPlaygroundTileSubtitle => '调用 ASR、聊天、翻译与词典 API';

  @override
  String get aiPlaygroundTitle => 'AI 试验台';

  @override
  String get aiPlaygroundIntro =>
      '通过 Enjoy 云端或「设置 → AI 提供商」中的 BYOK 凭据测试各 AI 能力。翻译与词典跟随 LLM 提供商。';

  @override
  String get aiPlaygroundActiveProviders => '当前提供商';

  @override
  String aiPlaygroundProviderByokDetail(String detail) {
    return 'BYOK · $detail';
  }

  @override
  String get aiPlaygroundProviderLocal => '本地（不可用）';

  @override
  String get aiPlaygroundPickAudio => '选择音频文件';

  @override
  String get aiPlaygroundTranscribe => '转写';

  @override
  String get aiPlaygroundChatSystem => '系统（可选）';

  @override
  String get aiPlaygroundChatUser => '用户消息';

  @override
  String get aiPlaygroundSendChat => '发送聊天';

  @override
  String get aiPlaygroundTranslateSource => '源语言';

  @override
  String get aiPlaygroundTranslateTarget => '目标语言';

  @override
  String get aiPlaygroundTranslateText => '待翻译文本';

  @override
  String get aiPlaygroundTranslate => '翻译';

  @override
  String get aiPlaygroundDictWord => '单词';

  @override
  String get aiPlaygroundDictSource => '源语言';

  @override
  String get aiPlaygroundDictTarget => '目标语言';

  @override
  String get aiPlaygroundDictLookup => '词典查询';

  @override
  String get aiPlaygroundAssessmentReference => '参考文本（你所说的内容）';

  @override
  String get aiPlaygroundAssessmentLanguage => '语言（如 en、en-US）';

  @override
  String get aiPlaygroundAssess => '运行发音评测';

  @override
  String get aiPlaygroundAssessmentTtsNote =>
      'Enjoy TTS 尚未接入；可在 AI 提供商中配置 TTS BYOK。评测使用上方所示提供商。';

  @override
  String get aiPlaygroundOutput => '输出';

  @override
  String get aiPlaygroundClearOutput => '清空输出';

  @override
  String get aiPlaygroundSectionAsr => '语音识别';

  @override
  String get aiPlaygroundSectionChat => '聊天';

  @override
  String get aiPlaygroundSectionTranslation => '翻译';

  @override
  String get aiPlaygroundSectionDictionary => '词典';

  @override
  String get aiPlaygroundSectionTtsAssessment => 'TTS / 评测';

  @override
  String get youtubePasteFromClipboard => '粘贴';

  @override
  String get settingsSubtitle => '按你的学习方式调整 Enjoy。';

  @override
  String get settingsAuthLoadFailed => '无法刷新账户信息，请检查网络后重试。';

  @override
  String get settingsSectionAppearanceLanguage => '外观与语言';

  @override
  String get settingsAppearanceTheme => '主题';

  @override
  String get settingsAppearanceThemeValue => '深色 · 影院风';

  @override
  String get settingsAppearanceDisplayLanguage => '显示语言';

  @override
  String get settingsAppearanceLearningLanguage => '学习语言';

  @override
  String get settingsAppearanceNativeLanguage => '母语';

  @override
  String get settingsAppearanceSyncedFromProfile => '与账号个人资料同步';

  @override
  String get settingsLanguageSubtitleSignedIn => '联网时会同步到你的 Enjoy 账号。';

  @override
  String get settingsLanguageSubtitleDeviceOnly => '保存在本机，登录账号后可同步。';

  @override
  String get settingsLanguageOptionEnUs => '英语（美国）';

  @override
  String get settingsLanguageOptionEnGb => '英语（英国）';

  @override
  String get settingsLanguageOptionJaJp => '日语';

  @override
  String get settingsLanguageOptionKoKr => '韩语';

  @override
  String get settingsLanguageOptionEsEs => '西班牙语（西班牙）';

  @override
  String get settingsLanguageOptionEsMx => '西班牙语（墨西哥）';

  @override
  String get settingsLanguageOptionFrFr => '法语（法国）';

  @override
  String get settingsLanguageOptionFrCa => '法语（加拿大）';

  @override
  String get settingsLanguageOptionZhCn => '中文（简体，中国）';

  @override
  String get settingsLearningLanguageSubtitle => '用于发现页推荐和导入时的默认语言。';

  @override
  String get settingsLanguagePickerTitleLearning => '学习语言';

  @override
  String get mediaLanguageUnknown => '未知';

  @override
  String get mediaLanguagePickerTitle => '内容语言';

  @override
  String get mediaEditLanguage => '编辑语言';

  @override
  String get mediaLanguageUpdated => '语言已更新。';

  @override
  String get mediaLanguageUpdateFailed => '无法更新语言。';

  @override
  String get assessmentUnavailableLanguage => '该语言暂不支持发音评估。';

  @override
  String get discoverLanguageFilterAll => '全部语言';

  @override
  String get discoverLanguageFilterLabel => '语言';

  @override
  String get settingsNativeMustDifferHint => '不能与学习语言相同。';

  @override
  String get settingsLanguagePickerTitleDisplay => '显示语言';

  @override
  String get settingsLanguagePickerTitleNative => '母语';

  @override
  String get profileFieldDisplayLanguage => '显示语言';

  @override
  String get profileLearningLanguageReadOnly => '选择你正在学习的语言。';

  @override
  String get settingsKeyboardOpenCheatsheet => '打开快捷键速查';

  @override
  String get settingsKeyboardOpenCheatsheetSubtitle => '浏览并自定义所有快捷键';

  @override
  String get settingsKeyboardCustomizeTitle => '自定义快捷键';

  @override
  String hotkeysHelpSubtitle(String key) {
    return '随时按 $key 打开此列表。';
  }

  @override
  String get hotkeysHelpSearchHint => '搜索快捷键';

  @override
  String get hotkeysHelpEmpty => '无匹配的快捷键';

  @override
  String get hotkeysHelpCustomize => '自定义快捷键';

  @override
  String hotkeysSettingsSubtitle(String key) {
    return '点按一行即可修改。随时按 $key。';
  }

  @override
  String get hotkeysFilterHint => '筛选快捷键';

  @override
  String get hotkeysResetTooltip => '重置此快捷键';

  @override
  String get hotkeysEditTooltip => '更改快捷键';

  @override
  String get settingsAboutMadeWithCare => '为语言学习者用心打造。';

  @override
  String settingsAboutVersion(String version) {
    return 'v$version';
  }

  @override
  String get settingsAboutOpenSourceTitle => '开源项目';

  @override
  String get settingsAboutOpenSourceSubtitle => '在 GitHub 查看源代码';

  @override
  String get settingsAboutContactTitle => '联系开发者';

  @override
  String get settingsAboutContactSubtitle => '向开发者反馈问题或建议';

  @override
  String get settingsAboutContactEmailLabel => '邮箱';

  @override
  String get settingsAboutContactWeChatLabel => '微信';

  @override
  String get settingsAboutContactMixinLabel => 'Mixin';

  @override
  String get settingsAboutContactCopiedEmail => '邮箱已复制到剪贴板';

  @override
  String get settingsAboutContactCopiedWeChat => '微信号已复制到剪贴板';

  @override
  String get settingsAboutContactCopiedMixin => 'Mixin ID 已复制到剪贴板';

  @override
  String get settingsDiagnosticsLoggingTitle => '诊断日志';

  @override
  String get settingsDiagnosticsLoggingSubtitle => '为 YouTube、同步和登录问题记录更多细节';

  @override
  String get settingsDiagnosticsPrivacyNote =>
      '日志保存在本设备，导出前不会上传。令牌和 Cookie 会被脱敏。';

  @override
  String get settingsDiagnosticsExportTitle => '导出诊断报告';

  @override
  String get settingsDiagnosticsExportSubtitle => '保存近期日志压缩包以便反馈问题';

  @override
  String get settingsDiagnosticsExportSuccess => '诊断报告已保存。';

  @override
  String get settingsDiagnosticsExportError => '无法导出诊断报告。';

  @override
  String get settingsCheckForUpdatesTitle => '检查更新';

  @override
  String get settingsCheckForUpdatesSubtitle => '查看是否有新的直接下载版本';

  @override
  String get updateAvailableTitle => '有可用更新';

  @override
  String get updateMandatoryTitle => '需要更新';

  @override
  String updateVersionLine(String current, String latest) {
    return '已安装 $current → $latest';
  }

  @override
  String get updateNow => '立即更新';

  @override
  String get updateLater => '稍后';

  @override
  String get updateDismiss => '忽略';

  @override
  String get updateUpToDate => '已是最新版本。';

  @override
  String get updateCheckOffline => '无法检查更新，请检查网络连接。';

  @override
  String get updateStoreChannelHint => '此版本来自 TestFlight 或 Play 商店，更新由商店处理。';

  @override
  String get lookupSheetTitle => '查词';

  @override
  String get lookupSectionTranslation => '翻译';

  @override
  String get lookupSectionContextualTranslation => '语境翻译';

  @override
  String get lookupSectionDictionary => '释义';

  @override
  String get lookupLoading => '加载中…';

  @override
  String get lookupErrorRetry => '重试';

  @override
  String get lookupEmpty => '暂无结果。';

  @override
  String get lookupLemma => '词干';

  @override
  String get lookupIpa => '音标';

  @override
  String get lookupExamples => '例句';

  @override
  String get lookupClose => '关闭';

  @override
  String get lookupCopy => '复制';

  @override
  String get lookupCopySuccess => '已复制到剪贴板';

  @override
  String get lookupTapToExpand => '展开以加载';

  @override
  String get lookupSourceLanguage => '原文语言';

  @override
  String get lookupTargetLanguage => '目标语言';

  @override
  String get lookupSwapLanguages => '交换语言';

  @override
  String get lookupPickSourceTitle => '选择原文语言';

  @override
  String get lookupPickTargetTitle => '选择目标语言';

  @override
  String get lookupRefresh => '刷新';

  @override
  String get lookupCloudRequiresSignIn => '请在「设置」中登录后使用云端词典、翻译与语境翻译。';

  @override
  String get lookupLanguageEnUs => '英语';

  @override
  String get lookupLanguageEnGb => '英语（英国）';

  @override
  String get lookupLanguageZhCn => '中文';

  @override
  String get lookupLanguageJaJp => '日语';

  @override
  String get lookupLanguageKoKr => '韩语';

  @override
  String get lookupLanguageEsEs => '西班牙语（西班牙）';

  @override
  String get lookupLanguageEsMx => '西班牙语（墨西哥）';

  @override
  String get lookupLanguageFrFr => '法语（法国）';

  @override
  String get lookupLanguageFrCa => '法语（加拿大）';

  @override
  String get lookupLanguageDeDe => '德语';

  @override
  String get lookupLanguageItIt => '意大利语';

  @override
  String get lookupLanguagePtBr => '葡萄牙语（巴西）';

  @override
  String get lookupLanguagePtPt => '葡萄牙语（葡萄牙）';

  @override
  String get lookupLanguageRuRu => '俄语';

  @override
  String get lookupSourceResetToLearning => '源语言已重置为学习语言默认值';

  @override
  String get authRequiredCloudFeaturesTitle => '需要登录账户';

  @override
  String get practicePosterShareTooltip => '分享练习海报';

  @override
  String get practicePosterPreviewTitle => '分享你的练习';

  @override
  String get practicePosterTagline => '跟读练习';

  @override
  String get practicePosterStatTakes => '录音';

  @override
  String get practicePosterStatSentences => '句子';

  @override
  String get practicePosterStatSpoken => '开口';

  @override
  String get practicePosterQrHint => '扫码下载 Enjoy Player\nplayer.enjoy.bot';

  @override
  String get practicePosterShareAction => '分享海报';

  @override
  String get practicePosterShareSuccess => '海报已分享。';

  @override
  String get practicePosterSaveSuccess => '海报已保存。';

  @override
  String get practicePosterExportError => '无法分享练习海报。';

  @override
  String get practicePosterLoadError => '无法加载此视频的练习数据。';

  @override
  String get notFoundTitle => '页面未找到';

  @override
  String notFoundSubtitle(String uri) {
    return '找不到 $uri。';
  }

  @override
  String get notFoundBackHome => '返回首页';

  @override
  String get recoveryTitle => '本地数据需要处理';

  @override
  String get recoverySubtitle =>
      'Enjoy Player 无法打开本地数据库。最常见的原因是更新不完整。数据仍然在磁盘上;继续操作前你可以先复制错误信息。';

  @override
  String get recoveryOpenLogs => '打开日志文件夹';

  @override
  String get recoveryOpenLogsError => '无法打开日志文件夹。';

  @override
  String get recoveryCopyError => '复制错误';

  @override
  String get recoveryCopiedToClipboard => '错误详情已复制到剪贴板。';

  @override
  String get recoveryResetLibrary => '重置本地资料库';

  @override
  String get recoveryResetLibrarySubtitle =>
      '清除本地数据库并重新开始。云端资料库不受影响。清除前会将当前状态备份到应用支持目录。';

  @override
  String get recoveryResetLibraryConfirmTitle => '重置本地资料库?';

  @override
  String get recoveryResetLibraryConfirmBody =>
      '这将永久删除你的本地资料库、录音、转写和同步队列。如果已登录,云端资料库会保留。清除前会先在应用支持目录写入一份备份。';

  @override
  String get recoveryResetLibraryConfirmAction => '全部清除';

  @override
  String get recoveryResetLibraryBackupError => '备份失败,本地数据库未被清除。错误已记录。';

  @override
  String get recoveryResetLibrarySuccess => '本地资料库已重置，正在重新加载数据……';

  @override
  String get recoveryResetLibraryError => '无法重置本地资料库。';

  @override
  String get widgetErrorTitle => '出了点问题';

  @override
  String get widgetErrorSubtitle => '此界面遇到意外错误。你可以复制下面的详情，然后尝试前往其他页面。';

  @override
  String get settingsSearchHint => '搜索设置';

  @override
  String get settingsSearchNoResultsTitle => '没有匹配的设置';

  @override
  String get settingsSearchNoResultsHint => '换个关键词试试，或清除搜索以浏览全部设置。';

  @override
  String get settingsSearchClear => '清除搜索';

  @override
  String get settingsSectionExpandSemantics => '展开分组';

  @override
  String get settingsSectionCollapseSemantics => '收起分组';

  @override
  String get settingsSectionNeedsAttention => '需要注意';

  @override
  String get transcriptBlurToggleTooltip =>
      'Blur practice (focus on listening)';

  @override
  String get transcriptBlurToggleOn => 'Listening-focus mode on';

  @override
  String get transcriptBlurToggleOff => 'Listening-focus mode off';

  @override
  String get transcriptBlurEmptyTooltip =>
      'No transcript lines to practice with';

  @override
  String get transcriptBlurSemanticsOn =>
      'Blur practice on. Tap or hover to reveal a line.';

  @override
  String get transcriptBlurSemanticsOff => 'Blur practice off.';

  @override
  String get importCraftFromText => '从文本自制…';

  @override
  String get craftSheetTitle => '从文本合成音频';

  @override
  String get craftModeTranslateThenSpeak => '先翻译再朗读';

  @override
  String get craftModeSpeakDirectly => '直接朗读';

  @override
  String get craftSourceLanguageLabel => '原文语言';

  @override
  String get craftTargetLanguageLabel => '学习语言';

  @override
  String get craftTextInputHint => '粘贴或输入文本…';

  @override
  String get craftPasteFromClipboard => '从剪贴板粘贴';

  @override
  String get craftAction => '合成';

  @override
  String get craftCraftingProgress => '正在合成音频…';

  @override
  String get craftEmptyTextHint => '请至少输入一句话以开始合成。';

  @override
  String get craftSameLanguageHint => '这段文字已经是学习语言了。';

  @override
  String get craftSameLanguageSwitch => '直接朗读';

  @override
  String get craftOfflineBanner => '当前离线，合成需要联网。';

  @override
  String get craftSignInRequired => '请登录后使用合成';

  @override
  String get craftFailureTts => '无法将文本转为语音。请检查 TTS 提供商设置或重试。';

  @override
  String get craftFailureTranslate => '无法翻译文本。请重试或切换到直接朗读。';

  @override
  String get craftFailureSave => '音频已生成但保存失败。请释放空间后重试。';

  @override
  String get craftAlreadyInLibrary => '已在你的资料库中';

  @override
  String get craftOpenExisting => '打开';

  @override
  String get craftRetry => '重试';

  @override
  String get craftOpenAiSettings => '打开 AI 设置';

  @override
  String get craftLengthCapNotice => '仅合成了前 5000 个字符，其余部分未合成。';

  @override
  String get libraryProviderCraftBadge => '自制';

  @override
  String get craftTtsSettingsHint => '合成使用下方的 TTS 提供商。';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn() : super('zh_CN');

  @override
  String get appTitle => 'Enjoy 播放器';

  @override
  String get libraryTitle => '资料库';

  @override
  String get librarySourceLocal => '本地';

  @override
  String get librarySourceCloud => '云端';

  @override
  String get librarySourceCloudEyebrow => '云端';

  @override
  String get librarySourceSwitchSemantics => '资料库来源';

  @override
  String get librarySourceToggleToCloud => '切换到云端';

  @override
  String get librarySourceToggleToLocal => '切换到本地';

  @override
  String get homeTitle => '首页';

  @override
  String get homeRecentMedia => '最近媒体';

  @override
  String get homeEmptyTitle => '暂无最近媒体';

  @override
  String get homeEmptyHint => '导入媒体或将文件拖放到此处开始。';

  @override
  String get libraryTabAudio => '音频';

  @override
  String get libraryTabVideo => '视频';

  @override
  String get libraryEmptyAudioTitle => '未找到任何音频';

  @override
  String get libraryEmptyAudioHint => '你的资料库中没有任何音频内容。';

  @override
  String get libraryEmptyVideoTitle => '未找到任何视频';

  @override
  String get libraryEmptyVideoHint => '你的资料库中没有任何视频内容。';

  @override
  String get librarySearchNoMatchesTitle => '没有匹配结果';

  @override
  String get librarySearchNoMatchesHint => '资料库中没有符合此搜索的内容。';

  @override
  String get librarySearchClear => '清除搜索';

  @override
  String get libraryDeleteFailed => '无法删除该项目，请重试。';

  @override
  String get transcriptAccessibilityTranscriptList => '字幕';

  @override
  String transcriptAccessibilityCue(String time, String snippet) {
    return '$time。$snippet';
  }

  @override
  String get transcriptAccessibilityCurrentLine => '当前播放行。';

  @override
  String get transcriptAccessibilityEchoRegion => '跟读练习区域。';

  @override
  String get transcriptAccessibilityEchoCurrentLine => '当前跟读行。';

  @override
  String transcriptLineRecordingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条录音',
      one: '1 条录音',
    );
    return '$_temp0';
  }

  @override
  String get transcriptErrorFriendlyTitle => '字幕暂不可用';

  @override
  String get transcriptErrorFriendlyHint => '请尝试选择其他字幕轨道或导入字幕文件。';

  @override
  String get transcriptFetchingSubtitles => '正在获取字幕…';

  @override
  String get actionOpenFiles => '打开文件';

  @override
  String get actionImport => '导入';

  @override
  String get importFromFile => '从文件…';

  @override
  String get importFromYoutube => '从 YouTube 链接…';

  @override
  String get discoverTitle => '发现';

  @override
  String get discoverBrowseAction => '浏览发现';

  @override
  String get discoverRecommendedHeading => '推荐频道';

  @override
  String get discoverSubscriptionsHeading => '订阅';

  @override
  String get discoverTimelineHeading => '最近上传';

  @override
  String get discoverSubscribeTitle => '订阅频道';

  @override
  String get discoverSubscribeHint => '粘贴 YouTube 频道链接或 @用户名。';

  @override
  String get discoverSubscribePlaceholder => 'https://www.youtube.com/@channel';

  @override
  String get discoverSubscribeAction => '订阅';

  @override
  String get discoverSubscribed => '已订阅频道';

  @override
  String get discoverSubscribedLabel => '已订阅';

  @override
  String get discoverSubscribeFailed => '无法订阅该频道。';

  @override
  String get discoverUnsubscribeAction => '取消订阅';

  @override
  String get discoverUnsubscribed => '已取消订阅';

  @override
  String get discoverViewFeed => '查看动态';

  @override
  String get discoverAddToLibrary => '加入库';

  @override
  String get discoverAddedToLibrary => '已加入你的库';

  @override
  String get discoverAddFailed => '无法添加此视频。';

  @override
  String get discoverInLibrary => '已在库中';

  @override
  String get discoverPlay => '播放';

  @override
  String get discoverFeedEmptyTitle => '暂无视频';

  @override
  String get discoverFeedEmptyHint => '订阅频道并刷新以加载最近上传。';

  @override
  String get discoverFeedErrorTitle => '无法加载动态';

  @override
  String get discoverFeedErrorHint => '请检查网络连接后重试。';

  @override
  String get discoverRetry => '重试';

  @override
  String get discoverRefreshPartialFailed => '部分频道动态刷新失败。';

  @override
  String discoverRefreshPartialFailedDetail(int count, String names) {
    return '无法刷新 $count 个频道：$names';
  }

  @override
  String discoverRefreshSingleFailed(Object name) {
    return '无法刷新 $name。';
  }

  @override
  String get discoverRecommendedLoadFailed => '无法加载推荐频道。';

  @override
  String get discoverSubscriptionsLoadFailed => '无法加载订阅。';

  @override
  String get discoverNoSubscriptionsHint => '订阅推荐频道或粘贴频道链接。';

  @override
  String get discoverManageChannels => '管理频道';

  @override
  String get discoverFilterAll => '全部';

  @override
  String get discoverYourChannelsHeading => '你的频道';

  @override
  String get discoverRecommendedAllSubscribed => '你已订阅全部推荐频道。';

  @override
  String get youtubeImportTitle => '导入 YouTube 视频';

  @override
  String get youtubeImportHint => '粘贴 YouTube 链接或视频 ID';

  @override
  String get youtubeImportInvalid => '无法识别有效的 YouTube 视频 ID。';

  @override
  String get youtubeImporting => '正在添加视频…';

  @override
  String get youtubeBadge => 'YouTube';

  @override
  String get youtubeLoginTooltip => 'YouTube 账号';

  @override
  String get youtubeLoginClose => '关闭';

  @override
  String get youtubeLoginScreenTitle => 'YouTube 登录';

  @override
  String get youtubeLogout => '退出登录（清除 Cookie）';

  @override
  String get searchHint => '搜索';

  @override
  String get transportRepeat => '循环';

  @override
  String get transportFullscreen => '全屏';

  @override
  String get transportExitFullscreen => '退出全屏';

  @override
  String get transportMore => '更多';

  @override
  String get transportCollapse => '收起播放器';

  @override
  String get transportExpand => '展开播放器';

  @override
  String get transportDismissPlayer => '关闭播放器';

  @override
  String get settingsTitle => '设置';

  @override
  String get importMedia => '导入媒体';

  @override
  String get importingMedia => '正在导入媒体…';

  @override
  String get importMediaFailed => '无法导入此文件。';

  @override
  String get importUnsupportedFileType => '不支持此文件类型。请选择音频或视频文件。';

  @override
  String get noMediaYet => '暂无媒体';

  @override
  String get tapImportToAdd => '从工具栏导入音频或视频。';

  @override
  String get navMainLabel => '主导航';

  @override
  String get miniPlayerMediaVideo => '视频';

  @override
  String get miniPlayerMediaAudio => '音频';

  @override
  String get retry => '重试';

  @override
  String get settingsSectionAppearance => '外观';

  @override
  String get settingsAppearanceSubtitle => '主题跟随系统设置。';

  @override
  String get settingsSectionAbout => '关于';

  @override
  String get settingsAboutSubtitle => 'Enjoy 播放器 — 本地字幕与跟读练习。';

  @override
  String get settingsThemeRowTitle => '主题';

  @override
  String get settingsThemeDarkLocked => '跟随系统外观。';

  @override
  String get settingsThemeSystem => '系统';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get play => '播放';

  @override
  String get pause => '暂停';

  @override
  String get previousLine => '上一句';

  @override
  String get nextLine => '下一句';

  @override
  String get replayLine => '重播本句';

  @override
  String get echoMode => '回声模式';

  @override
  String get exitEchoMode => '退出回声模式';

  @override
  String get transcript => '字幕稿';

  @override
  String get transcriptNowReading => '正在朗读';

  @override
  String get playerTranscriptResizeHint => '拖动以调整字幕稿面板大小';

  @override
  String get importSubtitle => '导入字幕';

  @override
  String get noTranscript => '无字幕稿';

  @override
  String get importSrtOrVtt => '导入 .srt 或 .vtt 文件。';

  @override
  String get miniPlayerOpen => '打开播放器';

  @override
  String get loading => '加载中…';

  @override
  String get error => '错误';

  @override
  String get playerOpenGenericError => '无法打开此项目。';

  @override
  String playbackRateTimes(String rate) {
    return '$rate 倍';
  }

  @override
  String get speed => '速度';

  @override
  String get volume => '音量';

  @override
  String get transportMute => '静音';

  @override
  String get transportUnmute => '取消静音';

  @override
  String get repeatNone => '关闭循环';

  @override
  String get repeatSegment => '循环片段';

  @override
  String get settingsPlaceholder => '播放器偏好将显示在此处。';

  @override
  String get subtitles => '字幕';

  @override
  String get subtitlesPrimary => '主字幕';

  @override
  String get subtitlesTranslation => '翻译（可选）';

  @override
  String get subtitlesNone => '无';

  @override
  String get subtitlesNotSelected => '未选择';

  @override
  String get subtitlesImportFile => '导入字幕文件…';

  @override
  String get subtitlesDeleteTrack => '删除轨道';

  @override
  String get importSubtitleSuccess => '字幕已导入';

  @override
  String get noTranscriptHint =>
      '打开媒体时云端字幕会在后台加载（每项在刷新前仅一次）。本地视频请使用提取或添加字幕（.srt/.vtt）。';

  @override
  String get transcriptEmptyExtract => '提取';

  @override
  String get transcriptEmptyAddSubtitle => '添加字幕';

  @override
  String get subtitlesExtractEmbedded => '提取内嵌字幕';

  @override
  String get subtitlesRefreshCloud => '从云端刷新字幕稿';

  @override
  String get subtitlesImportLanguageTitle => '字幕语言';

  @override
  String get subtitlesImportLanguageHint => 'BCP-47 代码（如 en、zh-TW）。未知请填 und。';

  @override
  String get subtitlesImportLanguageFieldLabel => '语言代码';

  @override
  String get subtitlesProviderOfficial => '官方';

  @override
  String get subtitlesProviderAuto => '自动';

  @override
  String get subtitlesProviderAi => 'AI';

  @override
  String get subtitlesProviderUser => '用户';

  @override
  String get subtitlesAutoTranslate => '自动翻译';

  @override
  String subtitlesAutoTranslateLanguageChip(String language) {
    return '译为 $language';
  }

  @override
  String get subtitlesAutoTranslateRetranslateLine => '重新翻译此行';

  @override
  String get subtitlesAutoTranslateBlockedStalePrimary =>
      '主字幕已更改，自动翻译将根据新的主字幕重建。';

  @override
  String get subtitlesAutoTranslateLineFailed => '此行未能翻译';

  @override
  String get subtitlesAutoTranslatePendingLine => '翻译中…';

  @override
  String get subtitlesAutoTranslateBlockedSignedOut => '请登录后使用自动翻译。';

  @override
  String get subtitlesAutoTranslateBlockedSameLanguage => '母语与主字幕相同时无需自动翻译。';

  @override
  String get subtitlesAutoTranslateBlockedNoPrimary => '请先选择主字幕。';

  @override
  String get subtitlesAutoTranslateBlockedCredits => '积分不足，无法翻译。请查看订阅。';

  @override
  String get subtitlesExtractNoTracks =>
      '此文件中无内嵌字幕轨道（仅有视频与音频）。若有单独的 .srt 或 .vtt，请使用导入文件。';

  @override
  String subtitlesExtractedCount(int count) {
    return '已提取 $count 条字幕轨道。';
  }

  @override
  String get subtitlesRefreshDone => '已从云端更新字幕稿。';

  @override
  String get subtitlesNoPlayableUri => '无法解析此项目的可播放文件。';

  @override
  String get expandEchoBackward => '向后扩展回声';

  @override
  String get expandEchoForward => '向前扩展回声';

  @override
  String get shrinkEchoBackward => '向后收缩回声';

  @override
  String get shrinkEchoForward => '向前收缩回声';

  @override
  String get shadowReadingTitle => '跟读';

  @override
  String get shadowReadingHint => '跟读本段并练习口语。录制你的声音并与参考音高对比。';

  @override
  String get shadowReadingReferenceSnippet => '参考';

  @override
  String get pitchContourTitle => '音高曲线';

  @override
  String get pitchContourError => '无法分析本段的音高。';

  @override
  String get pitchContourWaveform => '波形';

  @override
  String get pitchContourReference => '参考音高';

  @override
  String get pitchContourUser => '你的音高';

  @override
  String get pitchContourAnalyzing => '正在分析音高…';

  @override
  String get shadowRecordingExisting => '已保存的录音';

  @override
  String get shadowRecordingEmpty => '本段尚无录音。';

  @override
  String get shadowRecordingTake => '录音';

  @override
  String get shadowRecordingPlay => '播放';

  @override
  String get shadowRecordingPause => '暂停';

  @override
  String get shadowRecordingChooseTake => '切换录音';

  @override
  String get shadowRecordingDelete => '删除';

  @override
  String get shadowRecordingDeleteConfirmTitle => '删除此条录音？';

  @override
  String shadowRecordingDeleteConfirmMessage(String takeLabel) {
    return '将永久删除 $takeLabel，无法撤销。';
  }

  @override
  String get shadowRecordingRecord => '录音';

  @override
  String get shadowRecordingStop => '停止';

  @override
  String get shadowRecordingMicDenied => '需要麦克风权限才能录音。';

  @override
  String shadowRecordingSaveFailed(String reason) {
    return '无法保存录音：$reason';
  }

  @override
  String get settingsSectionRecording => '录音';

  @override
  String get settingsSectionRecordingHint => '跟读录音所使用的麦克风。';

  @override
  String get settingsRecordingMicTitle => '麦克风';

  @override
  String settingsRecordingMicAuto(String label) {
    return '自动 · $label';
  }

  @override
  String get settingsRecordingMicAutoNoDevice => '自动 · 系统默认';

  @override
  String get settingsRecordingMicEmpty => '未检测到麦克风';

  @override
  String get settingsRecordingMicAutoOption => '自动（跳过虚拟麦克风）';

  @override
  String get settingsRecordingMicDialogTitle => '选择麦克风';

  @override
  String get shadowRecordingSilentWarning => '未检测到麦克风信号。请打开「设置 → 录音」选择其他麦克风。';

  @override
  String get shadowRecordingPlaybackFailed => '无法播放此条录音。';

  @override
  String shadowRecordingOverTarget(String seconds) {
    return '超出目标 +$seconds 秒';
  }

  @override
  String get hotkeysTitle => '键盘快捷键';

  @override
  String get hotkeysHintFooter => '按 Shift+/（?）打开此列表。';

  @override
  String get hotkeysCustomizedBadge => '已自定义';

  @override
  String get hotkeysSectionKeyboard => '键盘快捷键';

  @override
  String get hotkeysResetBinding => '重置';

  @override
  String get hotkeysResetAll => '重置全部快捷键';

  @override
  String get hotkeysResetAllConfirmTitle => '重置全部快捷键？';

  @override
  String get hotkeysResetAllConfirmMessage => '所有快捷键将恢复为默认绑定，自定义设置无法撤销。';

  @override
  String get hotkeysCaptureTitle => '按下新快捷键';

  @override
  String get hotkeysCaptureHint => '按下组合键。Esc 取消。';

  @override
  String get hotkeysConflictError => '该快捷键已被使用。';

  @override
  String get hotkeysScopeGlobal => '全局';

  @override
  String get hotkeysScopePlayer => '播放器';

  @override
  String get hotkeysScopeLibrary => '资料库';

  @override
  String get hotkeysScopeModal => '弹窗';

  @override
  String get hotkeysDescHelp => '显示键盘快捷键';

  @override
  String get hotkeysDescSearch => '打开搜索';

  @override
  String get hotkeysDescSettings => '打开设置';

  @override
  String get hotkeysDescTogglePlay => '播放 / 暂停';

  @override
  String get hotkeysDescToggleExpand => '切换播放器展开/收起';

  @override
  String get hotkeysDescToggleFullscreen => '切换全屏';

  @override
  String get hotkeysDescPrevLine => '播放上一句';

  @override
  String get hotkeysDescNextLine => '播放下一句';

  @override
  String get hotkeysDescReplayLine => '重播当前句';

  @override
  String get hotkeysDescToggleEchoMode => '切换回声模式';

  @override
  String get hotkeysDescToggleBlurPractice => '切换听力专注（模糊练习）';

  @override
  String get hotkeysDescToggleRecording => '开始/停止录音';

  @override
  String get hotkeysDescToggleAssessment => '显示/隐藏发音评测';

  @override
  String get hotkeysDescTogglePitchContour => '显示/隐藏音高曲线';

  @override
  String get hotkeysDescPlayRecording => '播放/暂停录音';

  @override
  String get hotkeysDescSlowDown => '减慢播放速度';

  @override
  String get hotkeysDescSpeedUp => '加快播放速度';

  @override
  String get hotkeysDescExpandEchoBackward => '向后扩展回声区域';

  @override
  String get hotkeysDescExpandEchoForward => '向前扩展回声区域';

  @override
  String get hotkeysDescShrinkEchoBackward => '向后收缩回声区域';

  @override
  String get hotkeysDescShrinkEchoForward => '向前收缩回声区域';

  @override
  String get hotkeysDescLibrarySearch => '聚焦搜索框';

  @override
  String get hotkeysDescCloseModal => '关闭浮层、退出全屏或取消录音';

  @override
  String get hotkeysStubSearch => '搜索功能尚未提供。';

  @override
  String get assessmentTitle => '发音评测';

  @override
  String get assessmentDescription => '为你的朗读提供详细评分。';

  @override
  String get assessmentRun => '运行发音评测';

  @override
  String get assessmentView => '查看发音评测';

  @override
  String get assessmentReassess => '重新评测';

  @override
  String get assessmentOverallScore => '总分';

  @override
  String get assessmentAccuracy => '准确度';

  @override
  String get assessmentCompleteness => '完整度';

  @override
  String get assessmentFluency => '流利度';

  @override
  String get assessmentProsody => '韵律';

  @override
  String get assessmentPronunciationAnalysis => '发音分析';

  @override
  String get assessmentAccuracyScore => '准确度分数';

  @override
  String get assessmentSyllables => '音节';

  @override
  String get assessmentPhonemes => '音素';

  @override
  String get assessmentNoRecording => '录音文件缺失或为空。';

  @override
  String get assessmentNoResultSummary => '此条录音没有可用的详细评分。';

  @override
  String assessmentRunFailed(String reason) {
    return '无法运行评测：$reason';
  }

  @override
  String get assessmentErrorTypeOmission => '遗漏';

  @override
  String get assessmentErrorTypeInsertion => '插入';

  @override
  String get assessmentErrorTypeMispronunciation => '发音错误';

  @override
  String get assessmentErrorTypeUnexpectedBreak => '意外停顿';

  @override
  String get assessmentErrorTypeMissingBreak => '缺少停顿';

  @override
  String get assessmentErrorTypeMonotone => '单调';

  @override
  String get assessmentErrorTypeCorrect => '正确';

  @override
  String get assessmentErrorExplOmission => '预期应有此词但未检测到。';

  @override
  String get assessmentErrorExplInsertion => '检测到参考中不存在的额外词语。';

  @override
  String get assessmentErrorExplMispronunciation => '此词发音可能不正确。';

  @override
  String get assessmentErrorExplUnexpectedBreak => '在此词前检测到意外停顿。';

  @override
  String get assessmentErrorExplMissingBreak => '在此词前未检测到应有的停顿。';

  @override
  String get assessmentErrorExplMonotone => '音高变化低于预期。';

  @override
  String get assessmentErrorExplCorrect => '此词未发现问题。';

  @override
  String get assessmentEmptyReference => '参考文本为空。';

  @override
  String get assessmentInvalidStored => '无法读取已保存的评测数据。';

  @override
  String get authSignInTitle => '欢迎使用 Enjoy';

  @override
  String get authSignInSubtitle => '登录后即可同步媒体库、记录学习进度，并在任意设备继续学习。';

  @override
  String get authSignInCta => '继续';

  @override
  String get authContinueWithGoogle => '使用 Google 继续';

  @override
  String get authContinueWithApple => '使用 Apple 继续';

  @override
  String get authContinueWithEmail => '使用邮箱继续';

  @override
  String get authOtherSignInOptions => '其他登录方式';

  @override
  String get authOrDivider => '或';

  @override
  String get authEmailPrompt => '我们将向您的邮箱发送一次性验证码。';

  @override
  String get authEmailLabel => '邮箱';

  @override
  String get authEmailInvalid => '请输入有效的邮箱地址。';

  @override
  String get authSendOtp => '发送验证码';

  @override
  String get authOtpTitle => '输入验证码';

  @override
  String authOtpSentTo(String email) {
    return '验证码已发送至 $email';
  }

  @override
  String get authOtpLabel => '6 位验证码';

  @override
  String get authVerifyOtp => '验证';

  @override
  String get authOtpResend => '重新发送';

  @override
  String authOtpResendIn(int seconds) {
    return '$seconds 秒后可重新发送';
  }

  @override
  String get authChangeEmail => '更换邮箱';

  @override
  String get authOtpResumeTitle => '继续登录';

  @override
  String authOtpResumeSubtitle(String email) {
    return '请输入发送至 $email 的验证码';
  }

  @override
  String get authOtpResumeAction => '继续验证';

  @override
  String get authWebSignInWaiting => '请在浏览器中完成登录…';

  @override
  String get authWaitingForApproval => '正在完成登录…';

  @override
  String get authCancel => '取消';

  @override
  String get authSignedInSuccess => '登录成功';

  @override
  String get authReloadSignInPage => '重新加载登录页';

  @override
  String get authOpenInSystemBrowser => '在系统浏览器中打开';

  @override
  String get authSignOut => '退出登录';

  @override
  String get profileTitle => '个人资料';

  @override
  String get profileRefreshTooltip => '刷新个人资料';

  @override
  String get profileFieldName => '姓名';

  @override
  String get profileFieldEmail => '邮箱';

  @override
  String get profileFieldGoal => '每日目标（分钟）';

  @override
  String get profileFieldLearningLanguage => '学习语言';

  @override
  String get profileFieldNativeLanguage => '母语';

  @override
  String get profileFieldRequired => '必填';

  @override
  String get profileSave => '保存';

  @override
  String get profileSaveSuccess => '资料已保存';

  @override
  String get profileSubscriptionFree => '免费';

  @override
  String get profileSubscriptionPro => '专业版';

  @override
  String profileBalance(String value) {
    return '余额：$value';
  }

  @override
  String get profileStatTodayTitle => '今日';

  @override
  String get profileStatWeekTitle => '本周';

  @override
  String get profileStatMonthTitle => '本月';

  @override
  String get profileSectionPractice => '练习';

  @override
  String get profileSectionPracticeHint => '账户同步的练习时长';

  @override
  String get profileCreditsUsageTile => '积分使用记录';

  @override
  String get profileCreditsUsageSubtitle => '查看 Enjoy AI Worker 上的积分消耗';

  @override
  String get profileSectionAccount => '账户';

  @override
  String get profileSectionAccountHint => '积分余额与使用记录';

  @override
  String get profileSectionPreferences => '偏好设置';

  @override
  String get profileSectionPreferencesHint => '姓名、每日目标与语言';

  @override
  String get profileSignOutConfirmTitle => '退出登录？';

  @override
  String get profileSignOutConfirmMessage => '退出后需要重新登录才能同步和使用 AI 功能。';

  @override
  String get creditsUsageTitle => '积分使用';

  @override
  String get creditsUsageDescription => 'Enjoy AI Worker 上的积分校验记录（UTC 日期）。';

  @override
  String get creditsUsageStartDate => '开始日期';

  @override
  String get creditsUsageEndDate => '结束日期';

  @override
  String get creditsUsageServiceType => '服务';

  @override
  String get creditsUsageClearFilters => '清除筛选';

  @override
  String get creditsUsageError => '无法加载记录';

  @override
  String get creditsUsageErrorDescription => '请检查网络与设置中的 AI API 地址。';

  @override
  String get creditsUsageRetry => '重试';

  @override
  String get creditsUsageNoRecords => '暂无记录';

  @override
  String get creditsUsageNoRecordsWithFilters => '请尝试调整或清除筛选条件。';

  @override
  String get creditsUsageNoRecordsDescription => '登录后使用 AI 功能，记录将显示在此处。';

  @override
  String get creditsUsageTableDate => '日期';

  @override
  String get creditsUsageTableTime => '时间';

  @override
  String get creditsUsageTableService => '服务';

  @override
  String get creditsUsageTableTier => '档位';

  @override
  String get creditsUsageTableRequired => '需要';

  @override
  String get creditsUsageTableUsedAfter => '用后';

  @override
  String get creditsUsageTableStatus => '状态';

  @override
  String get creditsUsageAllowed => '允许';

  @override
  String get creditsUsageDenied => '拒绝';

  @override
  String creditsUsagePageInfo(int page) {
    return '第 $page 页';
  }

  @override
  String creditsUsageTotalRecords(int count) {
    return '共 $count 条';
  }

  @override
  String get creditsUsagePrevious => '上一页';

  @override
  String get creditsUsageNext => '下一页';

  @override
  String get creditsServiceTypeAll => '全部';

  @override
  String get creditsServiceTypeTts => '语音合成';

  @override
  String get creditsServiceTypeAsr => '语音识别';

  @override
  String get creditsServiceTypeTranslation => '翻译';

  @override
  String get creditsServiceTypeLlm => '大模型';

  @override
  String get creditsServiceTypeAssessment => '发音评估';

  @override
  String get settingsSectionAccount => '账号';

  @override
  String get settingsSectionAccountHint => '个人资料、订阅与退出登录';

  @override
  String get settingsSectionSyncHint => '上传队列、离线状态与手动同步';

  @override
  String get settingsSectionAppearanceLanguageHint => '主题密度、字幕稿字体与区域设置';

  @override
  String get hotkeysSectionKeyboardHint => '查看并自定义快捷键';

  @override
  String get settingsSectionAdvancedHint => 'API 地址与实验性开关';

  @override
  String get settingsSectionDeveloperHint => '诊断与内部工具';

  @override
  String get settingsSectionAboutHint => '版本、许可与链接';

  @override
  String get settingsSectionSync => '云端同步';

  @override
  String get syncSettingsTileTitle => '同步状态';

  @override
  String get syncSettingsTileSubtitleSignedOut => '登录后可同步资料库与录音';

  @override
  String get syncSettingsTileSubtitleUpToDate => '已是最新';

  @override
  String syncSettingsTileSubtitleCounts(int retryable, int failed) {
    return '$retryable 项等待中 · $failed 项失败';
  }

  @override
  String get syncScreenTitle => '同步状态';

  @override
  String get syncScreenLastSyncLabel => '上次成功同步';

  @override
  String get syncScreenLastSyncNever => '从未';

  @override
  String get syncScreenStatRetryable => '等待上传';

  @override
  String get syncScreenStatFailed => '永久失败';

  @override
  String get syncScreenSyncNow => '立即同步';

  @override
  String get syncScreenRetryFailed => '重试失败项';

  @override
  String get syncScreenSignedOutBody => '使用 Enjoy 账号登录以在设备间同步元数据。';

  @override
  String get syncScreenGoSignIn => '登录';

  @override
  String get cloudScreenTitle => '云端';

  @override
  String get cloudTabAudio => '音频';

  @override
  String get cloudTabVideo => '视频';

  @override
  String get cloudSignedOutBody => '登录后可浏览保存到 Enjoy 账号的媒体。';

  @override
  String get cloudAddToLibrary => '添加到资料库';

  @override
  String get cloudAlreadyInLibrary => '已在资料库中';

  @override
  String get cloudAddedToLibrary => '已添加到本地资料库。';

  @override
  String get cloudEmpty => '此列表为空。';

  @override
  String get cloudHasMediaUrlHint => '打开时从已保存的 URL 流式播放。';

  @override
  String get cloudNoMediaUrlHint => '无远程文件 URL — 打开此项目时请在播放器中使用「定位文件」。';

  @override
  String get cloudRefreshTooltip => '刷新此标签页';

  @override
  String get cloudAddToLibraryTooltip => '添加到资料库';

  @override
  String get cloudEmptyAudioTitle => '暂无云端音频';

  @override
  String get cloudEmptyAudioSubtitle => '登录后保存的项目将显示在此处。';

  @override
  String get cloudEmptyVideoTitle => '暂无云端视频';

  @override
  String get cloudEmptyVideoSubtitle => '登录后保存的项目将显示在此处。';

  @override
  String get syncSnackSuccess => '同步已成功完成。';

  @override
  String syncSnackIssues(int synced, int failed) {
    return '同步结束：$synced 项成功，$failed 项失败。';
  }

  @override
  String get syncQueueDetails => '队列详情';

  @override
  String get syncQueueEmpty => '队列为空。';

  @override
  String get settingsSectionAdvanced => '高级';

  @override
  String get settingsApiBaseUrl => 'API 基础地址';

  @override
  String get settingsApiBaseUrlHint => '示例：https://enjoy.bot';

  @override
  String get settingsApiBaseUrlSave => '保存 API 地址';

  @override
  String get settingsAiApiBaseUrl => 'AI API 基础地址';

  @override
  String get settingsAiApiBaseUrlHint => '示例：https://worker.enjoy.bot';

  @override
  String get settingsAiApiBaseUrlSave => '保存 AI API 地址';

  @override
  String get settingsAiApiBaseUrlUseDefault => '使用主 API 地址';

  @override
  String get settingsAiApiBaseUrlCleared => 'AI API 现在跟随主 API 地址。';

  @override
  String get settingsAccountSignedOut => '未登录';

  @override
  String get settingsAccountOpenProfile => '打开个人资料';

  @override
  String get settingsAccountSignIn => '登录';

  @override
  String get errorNetwork => '网络错误';

  @override
  String get errorUnauthorized => '会话已过期 — 请重新登录';

  @override
  String get communityActivity => '社区动态';

  @override
  String get communityToday => '今日社区';

  @override
  String get homeRecordingsToday => '录音';

  @override
  String get homePracticeTime => '练习时长';

  @override
  String get homeActiveLearners => '活跃学习者';

  @override
  String homePeopleLearning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 人正在学习',
      one: '$count 人正在学习',
    );
    return '$_temp0';
  }

  @override
  String get homeNoActiveUsers => '暂无活跃用户';

  @override
  String get homeTodaysGoal => '今日目标';

  @override
  String get homeMinutes => '分钟';

  @override
  String get homeCompleted => '已完成';

  @override
  String get homeGoalCompleted => '目标完成！太棒了！';

  @override
  String get homeGoalAlmostThere => '快完成了！继续加油！';

  @override
  String get homeGoalHalfway => '已经完成一半！你可以的！';

  @override
  String get homeGoalGoodStart => '不错的开始！坚持练习！';

  @override
  String get homeGoalJustStarted => '刚刚开始！每一分钟都很重要！';

  @override
  String get homeGoalStartNow => '现在开始练习吧！';

  @override
  String get mediaLocateTitle => '定位媒体文件';

  @override
  String get mediaLocateBody => '此项目是在其他设备上添加的。请在本机选择同一文件。我们会通过安全指纹校验是否与资料库匹配。';

  @override
  String get mediaLocateChooseFile => '选择文件';

  @override
  String get mediaLocateHashMismatch => '该文件与此项目不匹配。请确认选择了正确文件。';

  @override
  String mediaLocateExpectedSize(String sizeLabel) {
    return '预期大小：$sizeLabel';
  }

  @override
  String get mediaLocateSizeUnknown => '预期大小：未知';

  @override
  String get libraryDeleteMediaTitle => '从资料库删除？';

  @override
  String libraryDeleteMediaMessage(String title) {
    return '从本机移除「$title」。此操作无法撤销。';
  }

  @override
  String get libraryDeleteMediaTooltip => '从资料库删除';

  @override
  String get libraryMediaDeleted => '已从资料库移除。';

  @override
  String get libraryDeleteMediaFailed => '无法移除此项目。';

  @override
  String get settingsSectionDeveloper => '开发者';

  @override
  String get settingsAiPlaygroundTileTitle => 'AI 试验台';

  @override
  String get settingsAiPlaygroundTileSubtitle => '调用 ASR、聊天、翻译与词典 API';

  @override
  String get aiPlaygroundTitle => 'AI 试验台';

  @override
  String get aiPlaygroundIntro =>
      '使用已保存的基础地址与访问令牌调用 Enjoy API。Flutter 上尚未接入 TTS；登录后发音评测通过原生插件使用 Azure Speech。';

  @override
  String get aiPlaygroundPickAudio => '选择音频文件';

  @override
  String get aiPlaygroundTranscribe => '转写';

  @override
  String get aiPlaygroundChatSystem => '系统（可选）';

  @override
  String get aiPlaygroundChatUser => '用户消息';

  @override
  String get aiPlaygroundSendChat => '发送聊天';

  @override
  String get aiPlaygroundTranslateSource => '源语言';

  @override
  String get aiPlaygroundTranslateTarget => '目标语言';

  @override
  String get aiPlaygroundTranslateText => '待翻译文本';

  @override
  String get aiPlaygroundTranslate => '翻译';

  @override
  String get aiPlaygroundDictWord => '单词';

  @override
  String get aiPlaygroundDictSource => '源语言';

  @override
  String get aiPlaygroundDictTarget => '目标语言';

  @override
  String get aiPlaygroundDictLookup => '词典查询';

  @override
  String get aiPlaygroundAssessmentReference => '参考文本（你所说的内容）';

  @override
  String get aiPlaygroundAssessmentLanguage => '语言（如 en、en-US）';

  @override
  String get aiPlaygroundAssess => '运行发音评测';

  @override
  String get aiPlaygroundAssessmentTtsNote =>
      '本版本暂不提供 TTS（Azure Speech 集成进行中）。';

  @override
  String get aiPlaygroundOutput => '输出';

  @override
  String get aiPlaygroundClearOutput => '清空输出';

  @override
  String get aiPlaygroundSectionAsr => '语音识别';

  @override
  String get aiPlaygroundSectionChat => '聊天';

  @override
  String get aiPlaygroundSectionTranslation => '翻译';

  @override
  String get aiPlaygroundSectionDictionary => '词典';

  @override
  String get aiPlaygroundSectionTtsAssessment => 'TTS / 评测';

  @override
  String get youtubePasteFromClipboard => '粘贴';

  @override
  String get settingsSubtitle => '按你的学习方式调整 Enjoy。';

  @override
  String get settingsAuthLoadFailed => '无法刷新账户信息，请检查网络后重试。';

  @override
  String get settingsSectionAppearanceLanguage => '外观与语言';

  @override
  String get settingsAppearanceTheme => '主题';

  @override
  String get settingsAppearanceThemeValue => '深色 · 影院风';

  @override
  String get settingsAppearanceDisplayLanguage => '显示语言';

  @override
  String get settingsAppearanceLearningLanguage => '学习语言';

  @override
  String get settingsAppearanceNativeLanguage => '母语';

  @override
  String get settingsAppearanceSyncedFromProfile => '与账号个人资料同步';

  @override
  String get settingsLanguageSubtitleSignedIn => '联网时会同步到你的 Enjoy 账号。';

  @override
  String get settingsLanguageSubtitleDeviceOnly => '保存在本机，登录账号后可同步。';

  @override
  String get settingsLanguageOptionEnUs => '英语（美国）';

  @override
  String get settingsLanguageOptionEnGb => '英语（英国）';

  @override
  String get settingsLanguageOptionJaJp => '日语';

  @override
  String get settingsLanguageOptionKoKr => '韩语';

  @override
  String get settingsLanguageOptionEsEs => '西班牙语（西班牙）';

  @override
  String get settingsLanguageOptionEsMx => '西班牙语（墨西哥）';

  @override
  String get settingsLanguageOptionFrFr => '法语（法国）';

  @override
  String get settingsLanguageOptionFrCa => '法语（加拿大）';

  @override
  String get settingsLanguageOptionZhCn => '中文（简体，中国）';

  @override
  String get settingsLearningLanguageSubtitle => '用于发现页推荐和导入时的默认语言。';

  @override
  String get settingsLanguagePickerTitleLearning => '学习语言';

  @override
  String get mediaLanguageUnknown => '未知';

  @override
  String get mediaLanguagePickerTitle => '内容语言';

  @override
  String get mediaEditLanguage => '编辑语言';

  @override
  String get mediaLanguageUpdated => '语言已更新。';

  @override
  String get mediaLanguageUpdateFailed => '无法更新语言。';

  @override
  String get assessmentUnavailableLanguage => '该语言暂不支持发音评估。';

  @override
  String get discoverLanguageFilterAll => '全部语言';

  @override
  String get discoverLanguageFilterLabel => '语言';

  @override
  String get settingsNativeMustDifferHint => '不能与学习语言相同。';

  @override
  String get settingsLanguagePickerTitleDisplay => '显示语言';

  @override
  String get settingsLanguagePickerTitleNative => '母语';

  @override
  String get profileFieldDisplayLanguage => '显示语言';

  @override
  String get profileLearningLanguageReadOnly => '选择你正在学习的语言。';

  @override
  String get settingsKeyboardOpenCheatsheet => '打开快捷键速查';

  @override
  String get settingsKeyboardOpenCheatsheetSubtitle => '浏览并自定义所有快捷键';

  @override
  String get settingsKeyboardCustomizeTitle => '自定义快捷键';

  @override
  String hotkeysHelpSubtitle(String key) {
    return '随时按 $key 打开此列表。';
  }

  @override
  String get hotkeysHelpSearchHint => '搜索快捷键';

  @override
  String get hotkeysHelpEmpty => '无匹配的快捷键';

  @override
  String get hotkeysHelpCustomize => '自定义快捷键';

  @override
  String hotkeysSettingsSubtitle(String key) {
    return '点按一行即可修改。随时按 $key。';
  }

  @override
  String get hotkeysFilterHint => '筛选快捷键';

  @override
  String get hotkeysResetTooltip => '重置此快捷键';

  @override
  String get hotkeysEditTooltip => '更改快捷键';

  @override
  String get settingsAboutMadeWithCare => '为语言学习者用心打造。';

  @override
  String settingsAboutVersion(String version) {
    return 'v$version';
  }

  @override
  String get settingsAboutOpenSourceTitle => '开源项目';

  @override
  String get settingsAboutOpenSourceSubtitle => '在 GitHub 查看源代码';

  @override
  String get settingsAboutContactTitle => '联系开发者';

  @override
  String get settingsAboutContactSubtitle => '向开发者反馈问题或建议';

  @override
  String get settingsAboutContactEmailLabel => '邮箱';

  @override
  String get settingsAboutContactWeChatLabel => '微信';

  @override
  String get settingsAboutContactMixinLabel => 'Mixin';

  @override
  String get settingsAboutContactCopiedEmail => '邮箱已复制到剪贴板';

  @override
  String get settingsAboutContactCopiedWeChat => '微信号已复制到剪贴板';

  @override
  String get settingsAboutContactCopiedMixin => 'Mixin ID 已复制到剪贴板';

  @override
  String get settingsDiagnosticsLoggingTitle => '诊断日志';

  @override
  String get settingsDiagnosticsLoggingSubtitle => '为 YouTube、同步和登录问题记录更多细节';

  @override
  String get settingsDiagnosticsPrivacyNote =>
      '日志保存在本设备，导出前不会上传。令牌和 Cookie 会被脱敏。';

  @override
  String get settingsDiagnosticsExportTitle => '导出诊断报告';

  @override
  String get settingsDiagnosticsExportSubtitle => '保存近期日志压缩包以便反馈问题';

  @override
  String get settingsDiagnosticsExportSuccess => '诊断报告已保存。';

  @override
  String get settingsDiagnosticsExportError => '无法导出诊断报告。';

  @override
  String get settingsCheckForUpdatesTitle => '检查更新';

  @override
  String get settingsCheckForUpdatesSubtitle => '查看是否有新的直接下载版本';

  @override
  String get updateAvailableTitle => '有可用更新';

  @override
  String get updateMandatoryTitle => '需要更新';

  @override
  String updateVersionLine(String current, String latest) {
    return '已安装 $current → $latest';
  }

  @override
  String get updateNow => '立即更新';

  @override
  String get updateLater => '稍后';

  @override
  String get updateDismiss => '忽略';

  @override
  String get updateUpToDate => '已是最新版本。';

  @override
  String get updateCheckOffline => '无法检查更新，请检查网络连接。';

  @override
  String get updateStoreChannelHint => '此版本来自 TestFlight 或 Play 商店，更新由商店处理。';

  @override
  String get lookupSheetTitle => '查词';

  @override
  String get lookupSectionTranslation => '翻译';

  @override
  String get lookupSectionContextualTranslation => '语境翻译';

  @override
  String get lookupSectionDictionary => '释义';

  @override
  String get lookupLoading => '加载中…';

  @override
  String get lookupErrorRetry => '重试';

  @override
  String get lookupEmpty => '暂无结果。';

  @override
  String get lookupLemma => '词干';

  @override
  String get lookupIpa => '音标';

  @override
  String get lookupExamples => '例句';

  @override
  String get lookupClose => '关闭';

  @override
  String get lookupCopy => '复制';

  @override
  String get lookupCopySuccess => '已复制到剪贴板';

  @override
  String get lookupTapToExpand => '展开以加载';

  @override
  String get lookupSourceLanguage => '原文语言';

  @override
  String get lookupTargetLanguage => '目标语言';

  @override
  String get lookupSwapLanguages => '交换语言';

  @override
  String get lookupPickSourceTitle => '选择原文语言';

  @override
  String get lookupPickTargetTitle => '选择目标语言';

  @override
  String get lookupRefresh => '刷新';

  @override
  String get lookupCloudRequiresSignIn => '请在「设置」中登录后使用云端词典、翻译与语境翻译。';

  @override
  String get lookupLanguageEnUs => '英语';

  @override
  String get lookupLanguageEnGb => '英语（英国）';

  @override
  String get lookupLanguageZhCn => '中文';

  @override
  String get lookupLanguageJaJp => '日语';

  @override
  String get lookupLanguageKoKr => '韩语';

  @override
  String get lookupLanguageEsEs => '西班牙语（西班牙）';

  @override
  String get lookupLanguageEsMx => '西班牙语（墨西哥）';

  @override
  String get lookupLanguageFrFr => '法语（法国）';

  @override
  String get lookupLanguageFrCa => '法语（加拿大）';

  @override
  String get lookupLanguageDeDe => '德语';

  @override
  String get lookupLanguageItIt => '意大利语';

  @override
  String get lookupLanguagePtBr => '葡萄牙语（巴西）';

  @override
  String get lookupLanguagePtPt => '葡萄牙语（葡萄牙）';

  @override
  String get lookupLanguageRuRu => '俄语';

  @override
  String get lookupSourceResetToLearning => '源语言已重置为学习语言默认值';

  @override
  String get authRequiredCloudFeaturesTitle => '需要登录账户';

  @override
  String get practicePosterShareTooltip => '分享练习海报';

  @override
  String get practicePosterPreviewTitle => '分享你的练习';

  @override
  String get practicePosterTagline => '跟读练习';

  @override
  String get practicePosterStatTakes => '录音';

  @override
  String get practicePosterStatSentences => '句子';

  @override
  String get practicePosterStatSpoken => '开口';

  @override
  String get practicePosterQrHint => '扫码下载 Enjoy Player\nplayer.enjoy.bot';

  @override
  String get practicePosterShareAction => '分享海报';

  @override
  String get practicePosterShareSuccess => '海报已分享。';

  @override
  String get practicePosterSaveSuccess => '海报已保存。';

  @override
  String get practicePosterExportError => '无法分享练习海报。';

  @override
  String get practicePosterLoadError => '无法加载此视频的练习数据。';

  @override
  String get notFoundTitle => '页面未找到';

  @override
  String notFoundSubtitle(String uri) {
    return '找不到 $uri。';
  }

  @override
  String get notFoundBackHome => '返回首页';

  @override
  String get recoveryTitle => '本地数据需要处理';

  @override
  String get recoverySubtitle =>
      'Enjoy Player 无法打开本地数据库。最常见的原因是更新不完整。数据仍然在磁盘上;继续操作前你可以先复制错误信息。';

  @override
  String get recoveryOpenLogs => '打开日志文件夹';

  @override
  String get recoveryOpenLogsError => '无法打开日志文件夹。';

  @override
  String get recoveryCopyError => '复制错误';

  @override
  String get recoveryCopiedToClipboard => '错误详情已复制到剪贴板。';

  @override
  String get recoveryResetLibrary => '重置本地资料库';

  @override
  String get recoveryResetLibrarySubtitle =>
      '清除本地数据库并重新开始。云端资料库不受影响。清除前会将当前状态备份到应用支持目录。';

  @override
  String get recoveryResetLibraryConfirmTitle => '重置本地资料库?';

  @override
  String get recoveryResetLibraryConfirmBody =>
      '这将永久删除你的本地资料库、录音、转写和同步队列。如果已登录,云端资料库会保留。清除前会先在应用支持目录写入一份备份。';

  @override
  String get recoveryResetLibraryConfirmAction => '全部清除';

  @override
  String get recoveryResetLibraryBackupError => '备份失败,本地数据库未被清除。错误已记录。';

  @override
  String get recoveryResetLibrarySuccess => '本地资料库已重置，正在重新加载数据……';

  @override
  String get recoveryResetLibraryError => '无法重置本地资料库。';

  @override
  String get widgetErrorTitle => '出了点问题';

  @override
  String get widgetErrorSubtitle => '此界面遇到意外错误。你可以复制下面的详情，然后尝试前往其他页面。';

  @override
  String get settingsSearchHint => '搜索设置';

  @override
  String get settingsSearchNoResultsTitle => '没有匹配的设置';

  @override
  String get settingsSearchNoResultsHint => '换个关键词试试，或清除搜索以浏览全部设置。';

  @override
  String get settingsSearchClear => '清除搜索';

  @override
  String get settingsSectionExpandSemantics => '展开分组';

  @override
  String get settingsSectionCollapseSemantics => '收起分组';

  @override
  String get settingsSectionNeedsAttention => '需要注意';

  @override
  String get transcriptBlurToggleTooltip => '听写练习（专注听力）';

  @override
  String get transcriptBlurToggleOn => '已开启专注听力模式';

  @override
  String get transcriptBlurToggleOff => '已关闭专注听力模式';

  @override
  String get transcriptBlurEmptyTooltip => '当前没有字幕可练习';

  @override
  String get transcriptBlurSemanticsOn => '听写练习已开启。点按或悬停以查看一行字幕。';

  @override
  String get transcriptBlurSemanticsOff => '听写练习已关闭。';

  @override
  String get importCraftFromText => '从文本自制…';

  @override
  String get craftSheetTitle => '从文本合成音频';

  @override
  String get craftModeTranslateThenSpeak => '先翻译再朗读';

  @override
  String get craftModeSpeakDirectly => '直接朗读';

  @override
  String get craftSourceLanguageLabel => '原文语言';

  @override
  String get craftTargetLanguageLabel => '学习语言';

  @override
  String get craftTextInputHint => '粘贴或输入文本…';

  @override
  String get craftPasteFromClipboard => '从剪贴板粘贴';

  @override
  String get craftAction => '合成';

  @override
  String get craftCraftingProgress => '正在合成音频…';

  @override
  String get craftEmptyTextHint => '请至少输入一句话以开始合成。';

  @override
  String get craftSameLanguageHint => '这段文字已经是学习语言了。';

  @override
  String get craftSameLanguageSwitch => '直接朗读';

  @override
  String get craftOfflineBanner => '当前离线，合成需要联网。';

  @override
  String get craftSignInRequired => '请登录后使用合成';

  @override
  String get craftFailureTts => '无法将文本转为语音。请检查 TTS 提供商设置或重试。';

  @override
  String get craftFailureTranslate => '无法翻译文本。请重试或切换到直接朗读。';

  @override
  String get craftFailureSave => '音频已生成但保存失败。请释放空间后重试。';

  @override
  String get craftAlreadyInLibrary => '已在你的资料库中';

  @override
  String get craftOpenExisting => '打开';

  @override
  String get craftRetry => '重试';

  @override
  String get craftOpenAiSettings => '打开 AI 设置';

  @override
  String get craftLengthCapNotice => '仅合成了前 5000 个字符，其余部分未合成。';

  @override
  String get libraryProviderCraftBadge => '自制';

  @override
  String get craftTtsSettingsHint => '合成使用下方的 TTS 提供商。';
}
