import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/services/credits_packages_api.dart';
import 'package:enjoy_player/features/credits/application/credits_packages_provider.dart';
import 'package:enjoy_player/features/credits/application/credits_summary_provider.dart';
import 'package:enjoy_player/features/credits/data/credits_packages_repository.dart';
import 'package:enjoy_player/features/credits/domain/credits_package.dart';
import 'package:enjoy_player/features/credits/domain/credits_summary.dart';
import 'package:enjoy_player/features/subscription/application/tier_reconcile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  _FakeUrlLauncherPlatform({this.launchResult = true});

  final bool launchResult;
  String? lastLaunchedUrl;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    return launchResult;
  }

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<void> closeWebView() async {}

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;

  @override
  Future<bool> supportsCloseForMode(PreferredLaunchMode mode) async => false;
}

ApiClient _testApiClient() => ApiClient(
  httpClient: http.Client(),
  getBaseUrl: () async => 'https://enjoy.bot',
  getAccessToken: () async => null,
);

class _FakeCreditsPackagesRepository extends CreditsPackagesRepository {
  _FakeCreditsPackagesRepository({
    this.packages = const [],
    this.startPurchaseResult,
    this.startPurchaseError,
    this.listPackagesError,
  }) : super(CreditsPackagesApi(_testApiClient()));

  final List<CreditsPackage> packages;
  final CreditsPackagePurchaseSession? startPurchaseResult;
  final Object? startPurchaseError;
  final Object? listPackagesError;

  int listPackagesCalls = 0;
  int startPurchaseCalls = 0;
  String? lastPackageId;

  @override
  Future<List<CreditsPackage>> listPackages() async {
    listPackagesCalls++;
    if (listPackagesError != null) throw listPackagesError!;
    return packages;
  }

  @override
  Future<CreditsPackagePurchaseSession> startPurchase({
    required String packageId,
  }) async {
    startPurchaseCalls++;
    lastPackageId = packageId;
    if (startPurchaseError != null) throw startPurchaseError!;
    return startPurchaseResult!;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CreditsSummary _summary({required int permanent}) => CreditsSummary(
  tier: 'free',
  dailyUsed: 0,
  dailyLimit: 1000,
  dailyRemaining: 1000,
  permanentAvailable: permanent,
  resetAt: 0,
);

const _testPackage = CreditsPackage(
  id: 'pkg-1',
  amount: '9.99',
  currency: 'USD',
  credits: 100000,
  rate: CreditsTransferRate(usd: 9.99, credits: 100000),
);

const _validSession = CreditsPackagePurchaseSession(
  id: 'psess-1',
  status: 'pending',
  paymentType: 'stripe',
  amount: '9.99',
  payUrl: 'https://pay.example.com/credits/checkout',
  package: _testPackage,
);

const _sessionNoUrl = CreditsPackagePurchaseSession(
  id: 'psess-2',
  status: 'pending',
  paymentType: 'stripe',
  amount: '9.99',
  payUrl: null,
  package: _testPackage,
);

const _sessionEmptyUrl = CreditsPackagePurchaseSession(
  id: 'psess-3',
  status: 'pending',
  paymentType: 'stripe',
  amount: '9.99',
  payUrl: '',
  package: _testPackage,
);

ProviderContainer _container({
  required _FakeCreditsPackagesRepository repo,
  CreditsSummary? summary,
  Object? summaryError,
}) {
  return ProviderContainer(
    overrides: [
      creditsPackagesRepositoryProvider.overrideWithValue(repo),
      creditsSummaryProvider.overrideWith((ref) async {
        if (summaryError != null) throw summaryError;
        return summary ?? _summary(permanent: 500);
      }),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeUrlLauncherPlatform fakeUrlLauncher;

  setUp(() {
    fakeUrlLauncher = _FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakeUrlLauncher;
  });

  group('creditsPackages provider', () {
    test('returns packages from repository', () async {
      final repo = _FakeCreditsPackagesRepository(packages: [_testPackage]);
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      final packages = await container.read(creditsPackagesProvider.future);
      expect(packages, hasLength(1));
      expect(packages.first.id, 'pkg-1');
      expect(packages.first.credits, 100000);
      expect(repo.listPackagesCalls, 1);
    });

    test('propagates repository error', () async {
      final repo = _FakeCreditsPackagesRepository(
        listPackagesError: StateError('api_down'),
      );
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(creditsPackagesProvider.future),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('CreditsPackagePurchaseCtrl.purchaseExternal', () {
    test('initial state is AsyncData(null)', () {
      final repo = _FakeCreditsPackagesRepository(
        startPurchaseResult: _validSession,
      );
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      final state = container.read(creditsPackagePurchaseCtrlProvider);
      expect(state, const AsyncData<void>(null));
    });

    test(
      'successful purchase uses cached baseline, launches URL, marks pending',
      () async {
        final repo = _FakeCreditsPackagesRepository(
          startPurchaseResult: _validSession,
        );
        final container = _container(
          repo: repo,
          summary: _summary(permanent: 500),
        );
        addTearDown(container.dispose);

        // Prime the credits summary cache so baseline is available.
        await container.read(creditsSummaryProvider.future);

        final result = await container
            .read(creditsPackagePurchaseCtrlProvider.notifier)
            .purchaseExternal(packageId: 'pkg-1', expectedCredits: 100000);

        expect(result, isNotNull);
        expect(result!.id, 'psess-1');
        expect(repo.startPurchaseCalls, 1);
        expect(repo.lastPackageId, 'pkg-1');
        expect(
          fakeUrlLauncher.lastLaunchedUrl,
          'https://pay.example.com/credits/checkout',
        );

        // State returns to AsyncData after success.
        final state = container.read(creditsPackagePurchaseCtrlProvider);
        expect(state, const AsyncData<void>(null));

        // Tier reconcile pending flag is set with baseline.
        final reconcile = container.read(tierReconcileCtrlProvider.notifier);
        expect(reconcile.hasPendingPackagePurchase, isTrue);
      },
    );

    test('fetches baseline via future when cache is empty', () async {
      final repo = _FakeCreditsPackagesRepository(
        startPurchaseResult: _validSession,
      );
      final container = _container(
        repo: repo,
        summary: _summary(permanent: 200),
      );
      addTearDown(container.dispose);

      // Do NOT prime the cache — the provider must fetch via .future.
      final result = await container
          .read(creditsPackagePurchaseCtrlProvider.notifier)
          .purchaseExternal(packageId: 'pkg-1', expectedCredits: 50000);

      expect(result, isNotNull);
      expect(repo.startPurchaseCalls, 1);
    });

    test('proceeds without baseline when summary fetch fails', () async {
      final repo = _FakeCreditsPackagesRepository(
        startPurchaseResult: _validSession,
      );
      final container = _container(
        repo: repo,
        summaryError: StateError('summary_unavailable'),
      );
      addTearDown(container.dispose);

      final result = await container
          .read(creditsPackagePurchaseCtrlProvider.notifier)
          .purchaseExternal(packageId: 'pkg-1', expectedCredits: 100000);

      // Purchase still proceeds — baseline is null.
      expect(result, isNotNull);
      expect(repo.startPurchaseCalls, 1);
    });

    test('throws StateError when payUrl is null', () async {
      final repo = _FakeCreditsPackagesRepository(
        startPurchaseResult: _sessionNoUrl,
      );
      final container = _container(repo: repo);
      addTearDown(container.dispose);
      await container.read(creditsSummaryProvider.future);

      await expectLater(
        container
            .read(creditsPackagePurchaseCtrlProvider.notifier)
            .purchaseExternal(packageId: 'pkg-1', expectedCredits: 100000),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'missing_pay_url',
          ),
        ),
      );

      final state = container.read(creditsPackagePurchaseCtrlProvider);
      expect(state, isA<AsyncError<void>>());
    });

    test('throws StateError when payUrl is empty', () async {
      final repo = _FakeCreditsPackagesRepository(
        startPurchaseResult: _sessionEmptyUrl,
      );
      final container = _container(repo: repo);
      addTearDown(container.dispose);
      await container.read(creditsSummaryProvider.future);

      await expectLater(
        container
            .read(creditsPackagePurchaseCtrlProvider.notifier)
            .purchaseExternal(packageId: 'pkg-1', expectedCredits: 100000),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'missing_pay_url',
          ),
        ),
      );
    });

    test('throws StateError when URL launch fails', () async {
      fakeUrlLauncher = _FakeUrlLauncherPlatform(launchResult: false);
      UrlLauncherPlatform.instance = fakeUrlLauncher;

      final repo = _FakeCreditsPackagesRepository(
        startPurchaseResult: _validSession,
      );
      final container = _container(repo: repo);
      addTearDown(container.dispose);
      await container.read(creditsSummaryProvider.future);

      await expectLater(
        container
            .read(creditsPackagePurchaseCtrlProvider.notifier)
            .purchaseExternal(packageId: 'pkg-1', expectedCredits: 100000),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'launch_failed',
          ),
        ),
      );

      final state = container.read(creditsPackagePurchaseCtrlProvider);
      expect(state, isA<AsyncError<void>>());
    });

    test('propagates startPurchase repository error', () async {
      final repo = _FakeCreditsPackagesRepository(
        startPurchaseError: StateError('purchase_api_down'),
      );
      final container = _container(repo: repo);
      addTearDown(container.dispose);
      await container.read(creditsSummaryProvider.future);

      await expectLater(
        container
            .read(creditsPackagePurchaseCtrlProvider.notifier)
            .purchaseExternal(packageId: 'pkg-1', expectedCredits: 100000),
        throwsA(isA<StateError>()),
      );

      final state = container.read(creditsPackagePurchaseCtrlProvider);
      expect(state, isA<AsyncError<void>>());
    });
  });
}
