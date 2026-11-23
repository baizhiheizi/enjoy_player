import 'package:drift/native.dart';
import 'package:enjoy_player/core/cache/lru_store.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/ai/application/ai_capability_providers.dart';
import 'package:enjoy_player/features/ai/application/ai_kind_policies.dart';
import 'package:enjoy_player/features/ai/application/ai_result_cache.dart';
import 'package:enjoy_player/features/ai/domain/ai_kind.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/dictionary_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/translation_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/ai/domain/models/translation_result.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/lookup/application/lookup_credits_exhausted_provider.dart';
import 'package:enjoy_player/features/lookup/application/lookup_section_providers.dart';
import 'package:enjoy_player/features/lookup/domain/lookup_request.dart';
import 'package:enjoy_player/features/lookup/presentation/sections/dictionary_lookup_section.dart';
import 'package:enjoy_player/features/lookup/presentation/sections/translation_lookup_section.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_ai_section_card.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_error_row.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_section_shimmer.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:enjoy_player/l10n/l10n_delegates.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

class _AuthSignedInCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedIn(
    profile: UserProfile(id: 'tester', email: 't@example.com', name: 'Tester'),
  );
}

class _FlakyTranslationCapability implements TranslationCapability {
  _FlakyTranslationCapability(this._outcomes);

  final List<Object> _outcomes;
  int calls = 0;

  @override
  Future<TranslationResult> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    bool? forceRefresh,
  }) async {
    final outcome =
        _outcomes[calls < _outcomes.length ? calls : _outcomes.length - 1];
    calls++;
    if (outcome is Exception) throw outcome;
    return outcome as TranslationResult;
  }
}

class _FakeDictionaryCapability implements DictionaryCapability {
  _FakeDictionaryCapability(this._outcomes);

  final List<Object> _outcomes;
  int calls = 0;

  @override
  Future<DictionaryResult> lookupDictionary({
    required String word,
    required String sourceLanguage,
    required String targetLanguage,
    bool? forceRefresh,
  }) async {
    final outcome =
        _outcomes[calls < _outcomes.length ? calls : _outcomes.length - 1];
    calls++;
    if (outcome is Exception) throw outcome;
    return outcome as DictionaryResult;
  }
}

Widget _harness({required List<Override> overrides, required Widget child}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('the card renders the shimmer until the value arrives', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        overrides: [
          authCtrlProvider.overrideWith(_AuthSignedInCtrl.new),
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: LookupAiSectionCard<String>(
          title: 'Section',
          initiallyExpanded: true,
          leading: const Icon(Icons.book),
          surface: AuthRequiredSurface.lookupTranslation,
          section: LookupSectionId.translation,
          provider: FutureProvider<String>((ref) async => 'value'),
          onRetry: () {},
          bodyBuilder: (context, data, value) => Text(data),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LookupSectionShimmer), findsOneWidget);
    expect(find.text('value'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('value'), findsOneWidget);
  });

  testWidgets('the card renders the shared error surface', (tester) async {
    await tester.pumpWidget(
      _harness(
        overrides: [
          authCtrlProvider.overrideWith(_AuthSignedInCtrl.new),
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: LookupAiSectionCard<String>(
          title: 'Section',
          initiallyExpanded: true,
          leading: const Icon(Icons.book),
          surface: AuthRequiredSurface.lookupTranslation,
          section: LookupSectionId.translation,
          provider: FutureProvider<String>(
            (ref) async => throw StateError('boom'),
          ),
          onRetry: () {},
          bodyBuilder: (context, data, value) => Text(data),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LookupErrorRow), findsOneWidget);
  });

  testWidgets('a translation retry re-attempts the fetch', (tester) async {
    final capability = _FlakyTranslationCapability([
      StateError('first attempt fails'),
      const TranslationResult(translatedText: '你好', targetLanguage: 'zh'),
    ]);

    await tester.pumpWidget(
      _harness(
        overrides: [
          authCtrlProvider.overrideWith(_AuthSignedInCtrl.new),
          appDatabaseProvider.overrideWithValue(db),
          translationCapabilityProvider.overrideWithValue(capability),
        ],
        child: const TranslationLookupSection(
          request: LookupRequest(
            selectedText: 'hello',
            sourceLanguage: 'en',
            targetLanguage: 'zh',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LookupErrorRow), findsOneWidget);
    expect(capability.calls, 1);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.byType(LookupErrorRow), findsNothing);
    expect(find.text('你好'), findsOneWidget);
    expect(capability.calls, 2);
  });

  testWidgets('a refresh re-fetches instead of replaying the cached payload', (
    tester,
  ) async {
    final capability = _FakeDictionaryCapability([
      const DictionaryResult(
        word: 'run',
        sourceLanguage: 'en',
        targetLanguage: 'zh',
        senses: [DictionarySense(definition: 'cached')],
      ),
      const DictionaryResult(
        word: 'run',
        sourceLanguage: 'en',
        targetLanguage: 'zh',
        senses: [DictionarySense(definition: 'fresh')],
      ),
    ]);
    final cache = AiResultCache<DictionaryResult>(
      dao: db.aiCacheDao,
      l1: L1Store<String, DictionaryResult>(
        capacity: 16,
        ttl: const Duration(minutes: 30),
      ),
      policies: defaultAiKindPolicies,
      fromJson: DictionaryResult.fromJson,
      toJson: (value) => value.toJson(),
    );

    await tester.pumpWidget(
      _harness(
        overrides: [
          authCtrlProvider.overrideWith(_AuthSignedInCtrl.new),
          appDatabaseProvider.overrideWithValue(db),
          aiDictionaryCacheProvider.overrideWithValue(cache),
          dictionaryCapabilityProvider.overrideWithValue(capability),
        ],
        child: const DictionaryLookupSection(
          request: LookupRequest(
            selectedText: 'run',
            sourceLanguage: 'en',
            targetLanguage: 'zh',
          ),
        ),
      ),
    );
    await tester.tap(find.text('Definition'));
    await tester.pumpAndSettle();

    expect(find.textContaining('cached'), findsOneWidget);
    expect(capability.calls, 1);

    await tester.tap(find.byTooltip('Refresh'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.textContaining('fresh'), findsOneWidget);
    expect(capability.calls, 2);
  });

  testWidgets('a cached payload is served without a new fetch', (tester) async {
    final cache = AiResultCache<TranslationResult>(
      dao: db.aiCacheDao,
      l1: L1Store<String, TranslationResult>(
        capacity: 16,
        ttl: const Duration(minutes: 30),
      ),
      policies: defaultAiKindPolicies,
      fromJson: TranslationResult.fromJson,
      toJson: (value) => value.toJson(),
    );
    const request = LookupRequest(
      selectedText: 'hello',
      sourceLanguage: 'en',
      targetLanguage: 'zh',
    );
    final params = LookupTranslationParams(
      text: request.selectedText,
      sourceLanguage: request.sourceLanguage,
      targetLanguage: request.targetLanguage,
    );
    final key = lookupTranslationCacheKey(params);

    await cache.remember(
      kind: AiKind.translation,
      key: key,
      value: const TranslationResult(
        translatedText: 'cached',
        targetLanguage: 'zh',
      ),
    );
    expect(cache.peek(kind: AiKind.translation, key: key), isNotNull);

    final capability = _FlakyTranslationCapability([
      const TranslationResult(translatedText: 'fetched', targetLanguage: 'zh'),
    ]);

    await tester.pumpWidget(
      _harness(
        overrides: [
          authCtrlProvider.overrideWith(_AuthSignedInCtrl.new),
          appDatabaseProvider.overrideWithValue(db),
          aiTranslationCacheProvider.overrideWithValue(cache),
          translationCapabilityProvider.overrideWithValue(capability),
        ],
        child: const TranslationLookupSection(request: request),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('cached'), findsOneWidget);
    expect(capability.calls, 0);
  });
}
