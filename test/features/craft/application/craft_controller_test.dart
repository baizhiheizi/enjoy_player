import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:enjoy_player/features/ai/domain/byok_not_configured_failure.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/craft/domain/craft_failure.dart';
import 'package:enjoy_player/features/craft/domain/craft_job_state.dart';
import 'package:enjoy_player/features/craft/domain/craft_synthesizer.dart';
import 'package:enjoy_player/features/craft/domain/craft_translator.dart';
import 'package:enjoy_player/features/craft/domain/translation_style.dart';
import 'package:enjoy_player/features/library/application/library_repository_provider.dart';
import 'package:enjoy_player/features/library/data/library_repository.dart';

// === Fakes ===

class _SignedInAuthCtrl extends AuthCtrl {
  _SignedInAuthCtrl(this.profile);
  final UserProfile profile;
  @override
  Future<AuthState> build() async => AuthSignedIn(profile: profile);
}

class _SignedOutAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedOut();
}

class _TogglableAuthCtrl extends AuthCtrl {
  _TogglableAuthCtrl(this.profile);
  final UserProfile profile;
  @override
  Future<AuthState> build() async => AuthSignedIn(profile: profile);
  void forceSignedOut() => state = const AsyncData(AuthSignedOut());
}

class _FakeTranslator implements CraftTranslator {
  _FakeTranslator({this.result = 'translated text', this.error});

  final String result;
  final Object? error;

  int callCount = 0;
  String? lastText;
  String? lastSourceLanguage;
  String? lastTargetLanguage;
  TranslationStyle? lastStyle;
  String? lastCustomPrompt;

  @override
  Future<String> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    TranslationStyle style = TranslationStyle.natural,
    String? customPrompt,
  }) async {
    callCount++;
    lastText = text;
    lastSourceLanguage = sourceLanguage;
    lastTargetLanguage = targetLanguage;
    lastStyle = style;
    lastCustomPrompt = customPrompt;
    if (error != null) throw error!;
    return result;
  }
}

class _FakeSynthesizer implements CraftSynthesizer {
  _FakeSynthesizer({
    Uint8List? audioBytes,
    this.format = 'wav',
    this.wordBoundaries = const [],
    this.error,
  }) : audioBytes = audioBytes ?? Uint8List.fromList(const [1, 2, 3, 4]);

  final Uint8List audioBytes;
  final String format;
  final List<CraftWordBoundary> wordBoundaries;
  final Object? error;

  int callCount = 0;
  String? lastText;
  String? lastLanguage;
  String? lastVoice;

  @override
  Future<CraftSynthesisResult> synthesize({
    required String text,
    required String language,
    String? voice,
  }) async {
    callCount++;
    lastText = text;
    lastLanguage = language;
    lastVoice = voice;
    if (error != null) throw error!;
    return CraftSynthesisResult(
      audioBytes: audioBytes,
      format: format,
      wordBoundaries: wordBoundaries,
    );
  }
}

class _FakeLibraryRepository extends MediaLibraryRepository {
  _FakeLibraryRepository(super.db, super.storage);

  String? existingId;
  String importResultId = 'media-new';
  Object? importError;

  int findExistingCalls = 0;
  int importCalls = 0;

  String? lastFindLearningLanguage;
  String? lastFindNormalizedText;
  String? lastFindSourceFlag;
  String? lastFindVoice;

  Uint8List? lastImportAudioBytes;
  String? lastImportAudioFormat;
  String? lastImportLearningLanguage;
  String? lastImportSourceLanguage;
  String? lastImportText;
  String? lastImportNormalizedText;
  String? lastImportTimelineJson;
  String? lastImportVoice;
  String? lastImportSourceFlag;
  String? lastImportSignedInUserId;

  @override
  Future<String?> findExistingCrafted({
    required String learningLanguage,
    required String normalizedText,
    required String sourceFlag,
    String? voice,
  }) async {
    findExistingCalls++;
    lastFindLearningLanguage = learningLanguage;
    lastFindNormalizedText = normalizedText;
    lastFindSourceFlag = sourceFlag;
    lastFindVoice = voice;
    return existingId;
  }

  @override
  Future<String> importCraftedFromText({
    required Uint8List audioBytes,
    required String audioFormat,
    required String learningLanguage,
    String? sourceLanguage,
    required String text,
    required String normalizedText,
    String? primaryTimelineJson,
    String? voice,
    required String sourceFlag,
    required String signedInUserId,
  }) async {
    importCalls++;
    lastImportAudioBytes = audioBytes;
    lastImportAudioFormat = audioFormat;
    lastImportLearningLanguage = learningLanguage;
    lastImportSourceLanguage = sourceLanguage;
    lastImportText = text;
    lastImportNormalizedText = normalizedText;
    lastImportTimelineJson = primaryTimelineJson;
    lastImportVoice = voice;
    lastImportSourceFlag = sourceFlag;
    lastImportSignedInUserId = signedInUserId;
    if (importError != null) throw importError!;
    return importResultId;
  }
}

// === Test harness ===

const _profile = UserProfile(id: 'user-1', email: 'a@b.com', name: 'Tester');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _FakeTranslator translator;
  late _FakeSynthesizer synthesizer;
  late _FakeLibraryRepository repo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    translator = _FakeTranslator();
    synthesizer = _FakeSynthesizer();
    repo = _FakeLibraryRepository(db, FileStorage());
  });

  tearDown(() async {
    await db.close();
  });

  ProviderContainer container({UserProfile? profile = _profile}) {
    return ProviderContainer(
      overrides: [
        craftTranslatorProvider.overrideWithValue(translator),
        craftSynthesizerProvider.overrideWithValue(synthesizer),
        mediaLibraryRepositoryProvider.overrideWithValue(repo),
        if (profile == null)
          authCtrlProvider.overrideWith(_SignedOutAuthCtrl.new)
        else
          authCtrlProvider.overrideWith(() => _SignedInAuthCtrl(profile)),
      ],
    );
  }

  CraftController notifierOf(ProviderContainer c) =>
      c.read(craftControllerProvider.notifier);

  CraftJobState stateOf(ProviderContainer c) => c.read(craftControllerProvider);

  group('build', () {
    test('starts with default empty state', () {
      final c = container();
      addTearDown(c.dispose);
      final s = stateOf(c);
      expect(s.sourceText, '');
      expect(s.sourceLanguage, isNull);
      expect(s.targetLanguage, 'en');
      expect(s.style, TranslationStyle.natural);
      expect(s.customPrompt, isNull);
      expect(s.translatedText, isNull);
      expect(s.isTranslating, isFalse);
      expect(s.synthText, '');
      expect(s.synthLanguage, 'en');
      expect(s.selectedVoice, isNull);
      expect(s.previewAudioBytes, isNull);
      expect(s.previewFormat, isNull);
      expect(s.previewWordBoundaries, isEmpty);
      expect(s.isSynthesizing, isFalse);
      expect(s.isSaving, isFalse);
      expect(s.resultMediaId, isNull);
      expect(s.dedupedExistingId, isNull);
      expect(s.failure, isNull);
      expect(s.isBusy, isFalse);
      expect(s.hasPreview, isFalse);
      expect(s.hasTranslation, isFalse);
    });
  });

  group('translate tool setters', () {
    test('setSourceText updates text and clears failure', () async {
      final c = container();
      addTearDown(c.dispose);
      final n = notifierOf(c);
      n.setSourceLanguage('en');
      n.setTargetLanguage('en');
      n.setSourceText('long enough text');
      await n.translate();
      expect(stateOf(c).failure, isA<CraftSameLanguageFailure>());

      n.setSourceText('new source text');
      expect(stateOf(c).sourceText, 'new source text');
      expect(stateOf(c).failure, isNull);
    });

    test('setSourceLanguage updates language and clears failure', () async {
      final c = container();
      addTearDown(c.dispose);
      final n = notifierOf(c);
      n.setSourceLanguage('en');
      n.setTargetLanguage('en');
      n.setSourceText('long enough text');
      await n.translate();
      expect(stateOf(c).failure, isNotNull);

      n.setSourceLanguage('zh');
      expect(stateOf(c).sourceLanguage, 'zh');
      expect(stateOf(c).failure, isNull);
    });

    test('setTargetLanguage updates language and clears failure', () async {
      final c = container();
      addTearDown(c.dispose);
      final n = notifierOf(c);
      n.setSourceLanguage('en');
      n.setTargetLanguage('en');
      n.setSourceText('long enough text');
      await n.translate();
      expect(stateOf(c).failure, isNotNull);

      n.setTargetLanguage('fr');
      expect(stateOf(c).targetLanguage, 'fr');
      expect(stateOf(c).failure, isNull);
    });

    test('setStyle updates style and clears failure', () async {
      final c = container();
      addTearDown(c.dispose);
      final n = notifierOf(c);
      n.setSourceLanguage('en');
      n.setTargetLanguage('en');
      n.setSourceText('long enough text');
      await n.translate();
      expect(stateOf(c).failure, isNotNull);

      n.setStyle(TranslationStyle.formal);
      expect(stateOf(c).style, TranslationStyle.formal);
      expect(stateOf(c).failure, isNull);
    });

    test('setCustomPrompt updates prompt and clears failure', () async {
      final c = container();
      addTearDown(c.dispose);
      final n = notifierOf(c);
      n.setSourceLanguage('en');
      n.setTargetLanguage('en');
      n.setSourceText('long enough text');
      await n.translate();
      expect(stateOf(c).failure, isNotNull);

      n.setCustomPrompt('be poetic');
      expect(stateOf(c).customPrompt, 'be poetic');
      expect(stateOf(c).failure, isNull);
    });

    test('setTranslatedText edits the result inline', () {
      final c = container();
      addTearDown(c.dispose);
      final n = notifierOf(c);
      n.setTranslatedText('hand edited');
      expect(stateOf(c).translatedText, 'hand edited');
      expect(stateOf(c).hasTranslation, isTrue);
    });
  });

  group('swapLanguages', () {
    test('swaps source and target when source is set', () {
      final c = container();
      addTearDown(c.dispose);
      final n = notifierOf(c);
      n.setSourceLanguage('zh');
      n.setTargetLanguage('en');
      n.swapLanguages();
      expect(stateOf(c).sourceLanguage, 'en');
      expect(stateOf(c).targetLanguage, 'zh');
    });

    test('keeps target when source is null', () {
      final c = container();
      addTearDown(c.dispose);
      final n = notifierOf(c);
      n.setTargetLanguage('fr');
      n.swapLanguages();
      expect(stateOf(c).sourceLanguage, 'fr');
      expect(stateOf(c).targetLanguage, 'fr');
    });
  });

  group('useTranslatedText', () {
    test('copies translated text and target language into synth tool', () {
      final c = container();
      addTearDown(c.dispose);
      final n = notifierOf(c);
      n.setTargetLanguage('es');
      n.setTranslatedText('hola mundo');
      n.useTranslatedText();
      expect(stateOf(c).synthText, 'hola mundo');
      expect(stateOf(c).synthLanguage, 'es');
    });

    test('is a no-op when translated text is null', () {
      final c = container();
      addTearDown(c.dispose);
      final n = notifierOf(c);
      n.setSynthText('existing');
      n.useTranslatedText();
      expect(stateOf(c).synthText, 'existing');
    });

    test('is a no-op when translated text is empty', () {
      final c = container();
      addTearDown(c.dispose);
      final n = notifierOf(c);
      n.setTranslatedText('');
      n.setSynthText('existing');
      n.useTranslatedText();
      expect(stateOf(c).synthText, 'existing');
    });
  });

  group('translate', () {
    test('returns early when normalized text is too short', () async {
      final c = container();
      addTearDown(c.dispose);
      final n = notifierOf(c);
      n.setSourceLanguage('zh');
      n.setTargetLanguage('en');
      n.setSourceText('short');
      await n.translate();
      expect(translator.callCount, 0);
      expect(stateOf(c).isTranslating, isFalse);
      expect(stateOf(c).translatedText, isNull);
    });

    test('returns early when source language is null', () async {
      final c = container();
      addTearDown(c.dispose);
      final n = notifierOf(c);
      n.setTargetLanguage('en');
      n.setSourceText('long enough text');
      await n.translate();
      expect(translator.callCount, 0);
      expect(stateOf(c).translatedText, isNull);
    });

    test('sets same-language failure when base languages match', () async {
      final c = container();
      addTearDown(c.dispose);
      final n = notifierOf(c);
      n.setSourceLanguage('en-US');
      n.setTargetLanguage('en-GB');
      n.setSourceText('long enough text');
      await n.translate();
      expect(translator.callCount, 0);
      expect(stateOf(c).failure, isA<CraftSameLanguageFailure>());
      expect(
        stateOf(c).failure!.action,
        CraftFailureAction.switchToSpeakDirectly,
      );
    });

    test('stores translated result on success', () async {
      translator = _FakeTranslator(result: 'Bonjour le monde');
      final c = container();
      addTearDown(c.dispose);
      final n = notifierOf(c);
      n.setSourceLanguage('en');
      n.setTargetLanguage('fr');
      n.setStyle(TranslationStyle.formal);
      n.setCustomPrompt('keep it short');
      n.setSourceText('  Hello   world  ');
      await n.translate();

      expect(translator.callCount, 1);
      expect(translator.lastText, 'Hello world');
      expect(translator.lastSourceLanguage, 'en');
      expect(translator.lastTargetLanguage, 'fr');
      expect(translator.lastStyle, TranslationStyle.formal);
      expect(translator.lastCustomPrompt, 'keep it short');
      expect(stateOf(c).translatedText, 'Bonjour le monde');
      expect(stateOf(c).isTranslating, isFalse);
      expect(stateOf(c).failure, isNull);
    });

    test('sets translate failure when translator throws', () async {
      translator = _FakeTranslator(error: StateError('boom'));
      final c = container();
      addTearDown(c.dispose);
      final n = notifierOf(c);
      n.setSourceLanguage('en');
      n.setTargetLanguage('fr');
      n.setSourceText('long enough text');
      await n.translate();

      expect(stateOf(c).isTranslating, isFalse);
      expect(stateOf(c).failure, isA<CraftTranslateFailure>());
      expect(stateOf(c).failure!.action, CraftFailureAction.retry);
      expect(stateOf(c).translatedText, isNull);
    });

    test('clears a prior failure when a later translation succeeds', () async {
      translator = _FakeTranslator(result: 'Bonjour');
      final c = container();
      addTearDown(c.dispose);
      final n = notifierOf(c);
      n.setSourceLanguage('en');
      n.setTargetLanguage('en');
      n.setSourceText('long enough text');
      await n.translate();
      expect(stateOf(c).failure, isA<CraftSameLanguageFailure>());

      n.setTargetLanguage('fr');
      await n.translate();
      expect(stateOf(c).failure, isNull);
      expect(stateOf(c).translatedText, 'Bonjour');
    });
  });

  group('synthesize tool setters', () {
    test('setSynthText updates text and clears failure', () async {
      final c = container();
      addTearDown(c.dispose);
      final n = notifierOf(c);
      n.setSourceLanguage('en');
      n.setTargetLanguage('en');
      n.setSourceText('long enough text');
      await n.translate();
      expect(stateOf(c).failure, isNotNull);

      n.setSynthText('speak this please');
      expect(stateOf(c).synthText, 'speak this please');
      expect(stateOf(c).failure, isNull);
    });

    test('setSynthLanguage picks default voice for the new language', () {
      final c = container();
      addTearDown(c.dispose);
      final n = notifierOf(c);
      n.setSynthLanguage('zh-CN');
      expect(stateOf(c).synthLanguage, 'zh-CN');
      expect(stateOf(c).selectedVoice, 'zh-CN-XiaoxiaoNeural');
    });

    test('setSynthLanguage keeps voice when it matches the new language', () {
      final c = container();
      addTearDown(c.dispose);
      final n = notifierOf(c);
      n.setSelectedVoice('zh-CN-YunxiNeural');
      n.setSynthLanguage('zh-CN');
      expect(stateOf(c).selectedVoice, 'zh-CN-YunxiNeural');
    });

    test('setSynthLanguage clears preview and failure', () async {
      final c = container();
      addTearDown(c.dispose);
      final n = notifierOf(c);
      await c.read(authCtrlProvider.future);
      n.setSynthText('long enough text');
      await n.synthesize();
      expect(stateOf(c).hasPreview, isTrue);

      n.setSynthLanguage('fr-FR');
      expect(stateOf(c).previewAudioBytes, isNull);
      expect(stateOf(c).previewFormat, isNull);
      expect(stateOf(c).previewWordBoundaries, isEmpty);
      expect(stateOf(c).selectedVoice, 'fr-FR-DeniseNeural');
    });

    test('setSelectedVoice updates voice and clears preview', () async {
      final c = container();
      addTearDown(c.dispose);
      final n = notifierOf(c);
      await c.read(authCtrlProvider.future);
      n.setSynthText('long enough text');
      await n.synthesize();
      expect(stateOf(c).hasPreview, isTrue);

      n.setSelectedVoice('en-US-GuyNeural');
      expect(stateOf(c).selectedVoice, 'en-US-GuyNeural');
      expect(stateOf(c).previewAudioBytes, isNull);
    });
  });

  group('synthesize', () {
    test('returns early when normalized text is too short', () async {
      final c = container();
      addTearDown(c.dispose);
      await c.read(authCtrlProvider.future);
      final n = notifierOf(c);
      n.setSynthText('short');
      await n.synthesize();
      expect(synthesizer.callCount, 0);
      expect(stateOf(c).isSynthesizing, isFalse);
      expect(stateOf(c).failure, isNull);
    });

    test('requires sign-in', () async {
      final c = container(profile: null);
      addTearDown(c.dispose);
      await c.read(authCtrlProvider.future);
      final n = notifierOf(c);
      n.setSynthText('long enough text');
      await n.synthesize();
      expect(synthesizer.callCount, 0);
      expect(stateOf(c).failure, isA<CraftSignInRequiredFailure>());
      expect(stateOf(c).failure!.action, CraftFailureAction.signIn);
    });

    test(
      'stores preview bytes, format, and word boundaries on success',
      () async {
        final bytes = Uint8List.fromList(const [9, 9, 9]);
        synthesizer = _FakeSynthesizer(
          audioBytes: bytes,
          format: 'mp3',
          wordBoundaries: const [
            CraftWordBoundary(text: 'Hello', audioOffsetMs: 0, durationMs: 300),
          ],
        );
        final c = container();
        addTearDown(c.dispose);
        await c.read(authCtrlProvider.future);
        final n = notifierOf(c);
        n.setSynthLanguage('en-US');
        n.setSelectedVoice('en-US-JennyNeural');
        n.setSynthText('  Hello   world  ');
        await n.synthesize();

        expect(synthesizer.callCount, 1);
        expect(synthesizer.lastText, 'Hello world');
        expect(synthesizer.lastLanguage, 'en-US');
        expect(synthesizer.lastVoice, 'en-US-JennyNeural');
        final s = stateOf(c);
        expect(s.previewAudioBytes, bytes);
        expect(s.previewFormat, 'mp3');
        expect(s.previewWordBoundaries, hasLength(1));
        expect(s.isSynthesizing, isFalse);
        expect(s.hasPreview, isTrue);
        expect(s.failure, isNull);
      },
    );

    test('maps ByokNotConfiguredFailure to openAiSettings action', () async {
      synthesizer = _FakeSynthesizer(
        error: const ByokNotConfiguredFailure(ModalityKind.tts),
      );
      final c = container();
      addTearDown(c.dispose);
      await c.read(authCtrlProvider.future);
      final n = notifierOf(c);
      n.setSynthText('long enough text');
      await n.synthesize();

      final failure = stateOf(c).failure;
      expect(failure, isA<CraftTtsFailure>());
      expect(failure!.action, CraftFailureAction.openAiSettings);
      expect(stateOf(c).isSynthesizing, isFalse);
    });

    test('maps 401 ApiException to openAiSettings action', () async {
      synthesizer = _FakeSynthesizer(
        error: const ApiException(message: 'unauthorized', statusCode: 401),
      );
      final c = container();
      addTearDown(c.dispose);
      await c.read(authCtrlProvider.future);
      final n = notifierOf(c);
      n.setSynthText('long enough text');
      await n.synthesize();

      final failure = stateOf(c).failure;
      expect(failure, isA<CraftTtsFailure>());
      expect(failure!.action, CraftFailureAction.openAiSettings);
    });

    test('maps other errors to a retryable tts failure', () async {
      synthesizer = _FakeSynthesizer(
        error: const ApiException(message: 'server error', statusCode: 500),
      );
      final c = container();
      addTearDown(c.dispose);
      await c.read(authCtrlProvider.future);
      final n = notifierOf(c);
      n.setSynthText('long enough text');
      await n.synthesize();

      final failure = stateOf(c).failure;
      expect(failure, isA<CraftTtsFailure>());
      expect(failure!.action, CraftFailureAction.retry);
      expect(stateOf(c).isSynthesizing, isFalse);
    });
  });

  group('saveToLibrary', () {
    test('returns null when there is no preview audio', () async {
      final c = container();
      addTearDown(c.dispose);
      await c.read(authCtrlProvider.future);
      final result = await notifierOf(c).saveToLibrary();
      expect(result, isNull);
      expect(repo.findExistingCalls, 0);
      expect(repo.importCalls, 0);
      expect(stateOf(c).isSaving, isFalse);
      expect(stateOf(c).failure, isNull);
    });

    test('requires sign-in at save time', () async {
      final auth = _TogglableAuthCtrl(_profile);
      final c = ProviderContainer(
        overrides: [
          craftTranslatorProvider.overrideWithValue(translator),
          craftSynthesizerProvider.overrideWithValue(synthesizer),
          mediaLibraryRepositoryProvider.overrideWithValue(repo),
          authCtrlProvider.overrideWith(() => auth),
        ],
      );
      addTearDown(c.dispose);
      await c.read(authCtrlProvider.future);
      final n = notifierOf(c);
      n.setSynthText('long enough text');
      await n.synthesize();
      expect(stateOf(c).hasPreview, isTrue);

      auth.forceSignedOut();
      final result = await n.saveToLibrary();
      expect(result, isNull);
      expect(stateOf(c).failure, isA<CraftSignInRequiredFailure>());
      expect(repo.importCalls, 0);
    });

    test('returns existing id and skips import on dedupe hit', () async {
      repo.existingId = 'media-existing';
      final c = container();
      addTearDown(c.dispose);
      await c.read(authCtrlProvider.future);
      final n = notifierOf(c);
      n.setSynthText('long enough text');
      await n.synthesize();

      final result = await n.saveToLibrary();
      expect(result, 'media-existing');
      expect(stateOf(c).dedupedExistingId, 'media-existing');
      expect(stateOf(c).isSaving, isFalse);
      expect(repo.findExistingCalls, 1);
      expect(repo.importCalls, 0);
    });

    test('imports with word-boundary timeline when boundaries exist', () async {
      synthesizer = _FakeSynthesizer(
        wordBoundaries: const [
          CraftWordBoundary(text: 'Hello', audioOffsetMs: 0, durationMs: 300),
          CraftWordBoundary(
            text: 'world.',
            audioOffsetMs: 300,
            durationMs: 400,
          ),
        ],
      );
      repo.importResultId = 'media-123';
      final c = container();
      addTearDown(c.dispose);
      await c.read(authCtrlProvider.future);
      final n = notifierOf(c);
      n.setSynthLanguage('en-US');
      n.setSelectedVoice('en-US-JennyNeural');
      n.setSynthText('Hello world.');
      await n.synthesize();

      final result = await n.saveToLibrary();
      expect(result, 'media-123');
      expect(stateOf(c).resultMediaId, 'media-123');
      expect(stateOf(c).isSaving, isFalse);
      expect(repo.importCalls, 1);
      expect(repo.lastImportSourceFlag, 'craft-direct');
      expect(repo.lastImportSignedInUserId, 'user-1');
      expect(repo.lastImportVoice, 'en-US-JennyNeural');
      expect(repo.lastImportLearningLanguage, 'en-US');

      final timeline = jsonDecode(repo.lastImportTimelineJson!) as List;
      expect(timeline, isNotEmpty);
      expect(timeline.first['text'], 'Hello world.');
    });

    test(
      'falls back to duration-estimated timeline without boundaries',
      () async {
        synthesizer = _FakeSynthesizer(wordBoundaries: const []);
        final c = container();
        addTearDown(c.dispose);
        await c.read(authCtrlProvider.future);
        final n = notifierOf(c);
        n.setSynthText('long enough text');
        await n.synthesize();

        final result = await n.saveToLibrary();
        expect(result, 'media-new');
        expect(repo.importCalls, 1);
        final timeline = jsonDecode(repo.lastImportTimelineJson!) as List;
        expect(timeline, isNotEmpty);
      },
    );

    test('uses craft-translate flag when a translation is present', () async {
      translator = _FakeTranslator(result: 'Bonjour le monde');
      final c = container();
      addTearDown(c.dispose);
      await c.read(authCtrlProvider.future);
      final n = notifierOf(c);
      n.setSourceLanguage('en');
      n.setTargetLanguage('fr');
      n.setSourceText('Hello world, friend');
      await n.translate();
      n.useTranslatedText();
      await n.synthesize();

      await n.saveToLibrary();
      expect(repo.lastImportSourceFlag, 'craft-translate');
      expect(repo.lastImportSourceLanguage, 'en');
    });

    test(
      'uses craft-direct flag and null source language for direct synth',
      () async {
        final c = container();
        addTearDown(c.dispose);
        await c.read(authCtrlProvider.future);
        final n = notifierOf(c);
        n.setSynthText('long enough text');
        await n.synthesize();

        await n.saveToLibrary();
        expect(repo.lastImportSourceFlag, 'craft-direct');
        expect(repo.lastImportSourceLanguage, isNull);
      },
    );

    test('truncates normalized text beyond the max length', () async {
      final longText = 'a' * 6000;
      final c = container();
      addTearDown(c.dispose);
      await c.read(authCtrlProvider.future);
      final n = notifierOf(c);
      n.setSynthText(longText);
      await n.synthesize();

      await n.saveToLibrary();
      expect(repo.lastImportNormalizedText!.length, 5000);
      expect(repo.lastFindNormalizedText!.length, 5000);
      expect(repo.lastImportText, longText);
    });

    test('returns save failure when import throws', () async {
      repo.importError = StateError('disk full');
      final c = container();
      addTearDown(c.dispose);
      await c.read(authCtrlProvider.future);
      final n = notifierOf(c);
      n.setSynthText('long enough text');
      await n.synthesize();

      final result = await n.saveToLibrary();
      expect(result, isNull);
      expect(stateOf(c).failure, isA<CraftSaveFailure>());
      expect(stateOf(c).isSaving, isFalse);
      expect(stateOf(c).resultMediaId, isNull);
    });

    test('passes preview audio bytes and format to the repository', () async {
      final bytes = Uint8List.fromList(const [5, 6, 7, 8]);
      synthesizer = _FakeSynthesizer(audioBytes: bytes, format: 'mp3');
      final c = container();
      addTearDown(c.dispose);
      await c.read(authCtrlProvider.future);
      final n = notifierOf(c);
      n.setSynthText('long enough text');
      await n.synthesize();

      await n.saveToLibrary();
      expect(repo.lastImportAudioBytes, bytes);
      expect(repo.lastImportAudioFormat, 'mp3');
    });
  });

  group('clearResult', () {
    test('clears the active failure', () async {
      repo.importError = StateError('disk full');
      final c = container();
      addTearDown(c.dispose);
      await c.read(authCtrlProvider.future);
      final n = notifierOf(c);
      n.setSynthText('long enough text');
      await n.synthesize();
      await n.saveToLibrary();
      expect(stateOf(c).failure, isA<CraftSaveFailure>());

      n.clearResult();
      expect(stateOf(c).failure, isNull);
    });
  });
}
