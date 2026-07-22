// ignore_for_file: scoped_providers_should_specify_dependencies
import 'package:enjoy_player/features/credits/application/credits_usage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreditsUsageFiltersCtrl', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has default values', () {
      final state = container.read(creditsUsageFiltersCtrlProvider);
      expect(state.startDate, isNull);
      expect(state.endDate, isNull);
      expect(state.serviceType, isNull);
      expect(state.offset, 0);
      expect(state.limit, 50);
    });

    test('setStartDate updates startDate and resets offset', () {
      final ctrl = container.read(creditsUsageFiltersCtrlProvider.notifier);
      ctrl.goToNextPage();
      ctrl.setStartDate('2026-01-01');

      final state = container.read(creditsUsageFiltersCtrlProvider);
      expect(state.startDate, '2026-01-01');
      expect(state.offset, 0);
    });

    test('setStartDate with null clears startDate', () {
      final ctrl = container.read(creditsUsageFiltersCtrlProvider.notifier);
      ctrl.setStartDate('2026-01-01');
      ctrl.setStartDate(null);

      final state = container.read(creditsUsageFiltersCtrlProvider);
      expect(state.startDate, isNull);
    });

    test('setEndDate updates endDate and resets offset', () {
      final ctrl = container.read(creditsUsageFiltersCtrlProvider.notifier);
      ctrl.goToNextPage();
      ctrl.setEndDate('2026-06-30');

      final state = container.read(creditsUsageFiltersCtrlProvider);
      expect(state.endDate, '2026-06-30');
      expect(state.offset, 0);
    });

    test('setServiceType updates serviceType and resets offset', () {
      final ctrl = container.read(creditsUsageFiltersCtrlProvider.notifier);
      ctrl.goToNextPage();
      ctrl.setServiceType('translation');

      final state = container.read(creditsUsageFiltersCtrlProvider);
      expect(state.serviceType, 'translation');
      expect(state.offset, 0);
    });

    test('setServiceType with null means all types', () {
      final ctrl = container.read(creditsUsageFiltersCtrlProvider.notifier);
      ctrl.setServiceType('asr');
      ctrl.setServiceType(null);

      final state = container.read(creditsUsageFiltersCtrlProvider);
      expect(state.serviceType, isNull);
    });

    test('clearFilters resets all filters but preserves limit', () {
      final ctrl = container.read(creditsUsageFiltersCtrlProvider.notifier);
      ctrl.setStartDate('2026-01-01');
      ctrl.setEndDate('2026-06-30');
      ctrl.setServiceType('tts');
      ctrl.goToNextPage();
      ctrl.clearFilters();

      final state = container.read(creditsUsageFiltersCtrlProvider);
      expect(state.startDate, isNull);
      expect(state.endDate, isNull);
      expect(state.serviceType, isNull);
      expect(state.offset, 0);
      expect(state.limit, 50);
    });

    test('goToNextPage increments offset by limit', () {
      final ctrl = container.read(creditsUsageFiltersCtrlProvider.notifier);
      ctrl.goToNextPage();

      var state = container.read(creditsUsageFiltersCtrlProvider);
      expect(state.offset, 50);

      ctrl.goToNextPage();
      state = container.read(creditsUsageFiltersCtrlProvider);
      expect(state.offset, 100);
    });

    test('goToPreviousPage decrements offset by limit', () {
      final ctrl = container.read(creditsUsageFiltersCtrlProvider.notifier);
      ctrl.goToNextPage();
      ctrl.goToNextPage();
      ctrl.goToPreviousPage();

      final state = container.read(creditsUsageFiltersCtrlProvider);
      expect(state.offset, 50);
    });

    test('goToPreviousPage clamps at zero', () {
      final ctrl = container.read(creditsUsageFiltersCtrlProvider.notifier);
      ctrl.goToPreviousPage();

      final state = container.read(creditsUsageFiltersCtrlProvider);
      expect(state.offset, 0);
    });

    test('goToPreviousPage is no-op when already at zero', () {
      final ctrl = container.read(creditsUsageFiltersCtrlProvider.notifier);
      final before = container.read(creditsUsageFiltersCtrlProvider);
      ctrl.goToPreviousPage();
      final after = container.read(creditsUsageFiltersCtrlProvider);
      expect(after.offset, before.offset);
    });

    test('filters preserve other fields when one is changed', () {
      final ctrl = container.read(creditsUsageFiltersCtrlProvider.notifier);
      ctrl.setStartDate('2026-01-01');
      ctrl.setEndDate('2026-06-30');
      ctrl.setServiceType('translation');

      final state = container.read(creditsUsageFiltersCtrlProvider);
      expect(state.startDate, '2026-01-01');
      expect(state.endDate, '2026-06-30');
      expect(state.serviceType, 'translation');
    });
  });
}
