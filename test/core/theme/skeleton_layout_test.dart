import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/widgets/skeleton.dart';

void main() {
  testWidgets('SkeletonMediaList lays out inside a sliver box adapter', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SkeletonMediaList(itemCount: 3),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SkeletonMediaList), findsOneWidget);
  });

  testWidgets('SkeletonSettingsList lays out inside a scroll view column', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SkeletonSettingsList(rowCount: 4),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SkeletonSettingsList), findsOneWidget);
  });
}
