import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/lookup/application/lookup_credits_exhausted_provider.dart';
import 'package:enjoy_player/features/lookup/presentation/lookup_section_error_widget.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_credits_notice.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_error_row.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _tree(AppLocalizations l10n, Object error, {bool isRetrying = false}) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) => lookupSectionErrorWidget(
            context: context,
            ref: ref,
            l10n: l10n,
            section: LookupSectionId.dictionary,
            surface: AuthRequiredSurface.lookupDictionary,
            error: error,
            onRetry: () {},
            isRetrying: isRetrying,
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets('renders AuthRequiredCallout for AuthFailure', (tester) async {
    await tester.pumpWidget(_tree(l10n, const AuthFailure('nope')));
    await tester.pump();
    expect(find.byType(AuthRequiredCallout), findsOneWidget);
    expect(find.byType(LookupErrorRow), findsNothing);
    expect(find.byType(LookupCreditsNotice), findsNothing);
  });

  testWidgets('renders LookupCreditsNotice for CreditsFailure', (tester) async {
    await tester.pumpWidget(
      _tree(l10n, const CreditsFailure('out of credits')),
    );
    await tester.pump();
    expect(find.byType(LookupCreditsNotice), findsOneWidget);
    expect(find.byType(LookupErrorRow), findsNothing);
  });

  testWidgets('renders LookupErrorRow for other errors', (tester) async {
    await tester.pumpWidget(_tree(l10n, const NetworkFailure('net down')));
    await tester.pump();
    expect(find.byType(LookupErrorRow), findsOneWidget);
    expect(find.byType(LookupCreditsNotice), findsNothing);
    expect(find.byType(AuthRequiredCallout), findsNothing);
  });

  testWidgets('forwards isRetrying to LookupCreditsNotice', (tester) async {
    await tester.pumpWidget(
      _tree(l10n, const CreditsFailure('out of credits'), isRetrying: true),
    );
    await tester.pump();
    final notice = tester.widget<LookupCreditsNotice>(
      find.byType(LookupCreditsNotice),
    );
    expect(notice.isRetrying, isTrue);
  });
}
