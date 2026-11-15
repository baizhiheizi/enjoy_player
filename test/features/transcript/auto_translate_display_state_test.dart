import 'package:enjoy_player/features/transcript/application/auto_translate_controller.dart';
import 'package:enjoy_player/features/transcript/application/auto_translate_display_providers.dart';
import 'package:enjoy_player/features/transcript/application/active_transcript_provider.dart';
import 'package:enjoy_player/features/transcript/domain/auto_translate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active AI track matching the live secondary derives active=true', () async {
    final container = ProviderContainer(
      overrides: [
        autoTranslateCtrlProvider('m-1').overrideWithValue(
          const AutoTranslateUiState(
            status: AutoTranslateStatus.active,
            aiTranscriptId: 'ai-1',
            sourceLanguage: 'en',
            targetLanguage: 'zh',
          ),
        ),
        secondaryTranscriptIdProvider(
          'm-1',
        ).overrideWith((ref) => Stream<String?>.value('ai-1')),
      ],
    );
    addTearDown(container.dispose);

    container.listen(secondaryTranscriptIdProvider('m-1'), (_, _) {});
    await container.read(secondaryTranscriptIdProvider('m-1').future);
    final state = container.read(autoTranslateDisplayStateProvider('m-1'));

    expect(state.active, isTrue);
    expect(state.sourceLanguage, 'en');
    expect(state.targetLanguage, 'zh');
  });

  test('a secondary that is not the AI track keeps active=false', () {
    final container = ProviderContainer(
      overrides: [
        autoTranslateCtrlProvider('m-1').overrideWithValue(
          const AutoTranslateUiState(
            status: AutoTranslateStatus.active,
            aiTranscriptId: 'ai-1',
          ),
        ),
        secondaryTranscriptIdProvider(
          'm-1',
        ).overrideWith((ref) => Stream<String?>.value('human-track')),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(autoTranslateDisplayStateProvider('m-1')).active,
      isFalse,
    );
  });

  test(
    'an inactive controller keeps active=false even on a matching secondary',
    () {
      final container = ProviderContainer(
        overrides: [
          autoTranslateCtrlProvider('m-1').overrideWithValue(
            const AutoTranslateUiState(aiTranscriptId: 'ai-1'),
          ),
          secondaryTranscriptIdProvider(
            'm-1',
          ).overrideWith((ref) => Stream<String?>.value('ai-1')),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(autoTranslateDisplayStateProvider('m-1')).active,
        isFalse,
      );
    },
  );
}
