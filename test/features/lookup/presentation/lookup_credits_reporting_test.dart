import 'package:enjoy_player/features/credits/application/credits_summary_provider.dart';
import 'package:enjoy_player/features/credits/domain/credits_summary.dart';
import 'package:enjoy_player/features/lookup/application/lookup_credits_exhausted_provider.dart';
import 'package:enjoy_player/features/lookup/presentation/lookup_credits_reporting.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Recorder {
  int fetches = 0;
}

CreditsSummary _summary() => const CreditsSummary(
  tier: 'free',
  dailyUsed: 500,
  dailyLimit: 1000,
  dailyRemaining: 500,
  permanentAvailable: 0,
  resetAt: 0,
);

class _ChipStandIn extends ConsumerWidget {
  const _ChipStandIn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(creditsSummaryProvider);
    ref.watch(lookupCreditsExhaustedProvider);
    return const SizedBox.shrink();
  }
}

class _SectionHost extends ConsumerWidget {
  const _SectionHost({
    required this.tick,
    required this.tokenForTick,
    required this.sectionsForTick,
  });

  final ValueListenable<int> tick;
  final Object? Function(int tick) tokenForTick;
  final List<LookupSectionId> Function(int tick) sectionsForTick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<int>(
      valueListenable: tick,
      builder: (context, value, _) {
        for (final section in sectionsForTick(value)) {
          scheduleLookupCreditsClear(
            context,
            ref,
            section,
            resultToken: tokenForTick(value),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ReportingSectionHost extends ConsumerWidget {
  const _ReportingSectionHost({required this.tick, required this.tokenForTick});

  final ValueListenable<int> tick;
  final Object? Function(int tick) tokenForTick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<int>(
      valueListenable: tick,
      builder: (context, value, _) {
        scheduleLookupCreditsReport(
          context,
          ref,
          LookupSectionId.dictionary,
          'daily limit reached',
          resultToken: tokenForTick(value),
        );
        return const SizedBox.shrink();
      },
    );
  }
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required _Recorder recorder,
  required ValueNotifier<int> tick,
  required Object? Function(int tick) tokenForTick,
  List<LookupSectionId> Function(int tick) sectionsForTick = _allSections,
  bool report = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        creditsSummaryProvider.overrideWith((ref) {
          recorder.fetches += 1;
          return Future<CreditsSummary>.value(_summary());
        }),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const _ChipStandIn(),
              if (report)
                _ReportingSectionHost(tick: tick, tokenForTick: tokenForTick)
              else
                _SectionHost(
                  tick: tick,
                  tokenForTick: tokenForTick,
                  sectionsForTick: sectionsForTick,
                ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<LookupSectionId> _allSections(int tick) => LookupSectionId.values;

void main() {
  testWidgets(
    'refreshes once for the first result token and stays flat on identical re-emissions',
    (tester) async {
      final recorder = _Recorder();
      final tick = ValueNotifier<int>(0);
      const token = 'cached-result';

      await _pumpSheet(
        tester,
        recorder: recorder,
        tick: tick,
        tokenForTick: (_) => token,
      );
      expect(recorder.fetches, 2);

      for (var i = 0; i < 5; i++) {
        tick.value += 1;
        await tester.pumpAndSettle();
      }
      expect(recorder.fetches, 2);
    },
  );

  testWidgets('refreshes again when a section produces a fresh token', (
    tester,
  ) async {
    final recorder = _Recorder();
    final tick = ValueNotifier<int>(0);
    final first = Object();
    final second = Object();

    await _pumpSheet(
      tester,
      recorder: recorder,
      tick: tick,
      tokenForTick: (value) => value == 0 ? first : second,
    );
    expect(recorder.fetches, 2);

    tick.value += 1;
    await tester.pumpAndSettle();
    expect(recorder.fetches, 3);

    for (var i = 0; i < 3; i++) {
      tick.value += 1;
      await tester.pumpAndSettle();
    }
    expect(recorder.fetches, 3);
  });

  testWidgets('tracks sections independently for the same token instance', (
    tester,
  ) async {
    final recorder = _Recorder();
    final tick = ValueNotifier<int>(0);
    const token = 'shared-cached-result';

    await _pumpSheet(
      tester,
      recorder: recorder,
      tick: tick,
      tokenForTick: (_) => token,
      sectionsForTick: (value) => value == 0
          ? [LookupSectionId.translation]
          : [LookupSectionId.translation, LookupSectionId.dictionary],
    );
    expect(recorder.fetches, 2);

    tick.value += 1;
    await tester.pumpAndSettle();
    expect(recorder.fetches, 3);

    for (var i = 0; i < 4; i++) {
      tick.value += 1;
      await tester.pumpAndSettle();
    }
    expect(recorder.fetches, 3);
  });

  testWidgets('untokened schedules keep refreshing the wallet', (tester) async {
    final recorder = _Recorder();
    final tick = ValueNotifier<int>(0);

    await _pumpSheet(
      tester,
      recorder: recorder,
      tick: tick,
      tokenForTick: (_) => null,
    );
    expect(recorder.fetches, 2);

    tick.value += 1;
    await tester.pumpAndSettle();
    expect(recorder.fetches, 3);

    tick.value += 1;
    await tester.pumpAndSettle();
    expect(recorder.fetches, 4);
  });

  testWidgets('report path keeps writing the exhausted notice while deduped', (
    tester,
  ) async {
    final recorder = _Recorder();
    final tick = ValueNotifier<int>(0);
    final token = Object();

    await _pumpSheet(
      tester,
      recorder: recorder,
      tick: tick,
      tokenForTick: (_) => token,
      report: true,
    );
    expect(recorder.fetches, 2);

    tick.value += 1;
    await tester.pumpAndSettle();
    expect(recorder.fetches, 2);

    final context = tester.element(find.byType(_ChipStandIn));
    final container = ProviderScope.containerOf(context);
    expect(container.read(lookupCreditsExhaustedProvider), {
      LookupSectionId.dictionary: 'daily limit reached',
    });
  });
}
