/// Narrow-screen modal bottom sheet for the pronunciation assessment result.
///
/// Used when [MediaQuery.sizeOf].width is below the [EnjoyThemeTokens]
/// `breakpointRail`. The sheet is built around a [DraggableScrollableSheet]
/// with the standard [PaddedSheetDragHandle] and shares the body widget
/// with the wide [AssessmentResultDialog].
library;

import 'package:azure_speech/azure_speech.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/sheet_drag_handle.dart';

import 'assessment_result_body.dart';
import 'assessment_result_header.dart';

class AssessmentResultSheet extends ConsumerStatefulWidget {
  const AssessmentResultSheet({
    required this.assessment,
    required this.localeTag,
    this.recordingPath,
    super.key,
  });

  final AzurePronunciationAssessmentResult assessment;
  final String localeTag;
  final String? recordingPath;

  @override
  ConsumerState<AssessmentResultSheet> createState() =>
      _AssessmentResultSheetState();
}

class _AssessmentResultSheetState extends ConsumerState<AssessmentResultSheet> {
  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final nBest = widget.assessment.nBest.first;
    final padH = t.space16 + t.space4;
    final bottomInset = MediaQuery.paddingOf(context).bottom + t.space24;

    return DraggableScrollableSheet(
      initialChildSize: 0.58,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PaddedSheetDragHandle(),
            AssessmentResultHeader(
              padding: EdgeInsets.fromLTRB(padH, t.space8, t.space8, 0),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  padH,
                  t.space16,
                  padH,
                  bottomInset,
                ),
                children: [
                  AssessmentResultBody(
                    nBest: nBest,
                    localeTag: widget.localeTag,
                    recordingPath: widget.recordingPath,
                    layoutCompact: true,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
