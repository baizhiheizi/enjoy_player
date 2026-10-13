/// Scaffold shared by the sign-in hub and the email OTP flow. Wide windows
/// add the Duet brand panel beside the form (the `SignIn` board).
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:enjoy_player/core/theme/colors.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Window width at which the brand panel joins the form.
const double kSignInBrandPanelMinWidth = 960;

class SignInFlowScaffold extends StatelessWidget {
  const SignInFlowScaffold({super.key, this.appBar, required this.child});

  final PreferredSizeWidget? appBar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: appBar,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final form = SafeArea(child: child);
          if (appBar != null ||
              constraints.maxWidth < kSignInBrandPanelMinWidth) {
            return form;
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(flex: 52, child: SignInBrandPanel()),
              Expanded(flex: 48, child: form),
            ],
          );
        },
      ),
    );
  }
}

/// Dark brand panel: wordmark, the logo's three triangles at large scale, and
/// the two-voices headline.
class SignInBrandPanel extends StatelessWidget {
  const SignInBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    return ColoredBox(
      color: AppColors.brandArtGround,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(painter: _LogoArtPainter(gradient: t.logo)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(48, 44, 48, 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/logo-light.svg',
                        width: 30,
                        height: 30,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.appTitle,
                        style: tt.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.authBrandHeadline,
                          style: enjoyDisplayStyle(
                            context,
                            size: 40,
                            color: Colors.white,
                            height: 1.18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.authBrandBody,
                          style: tt.bodyLarge?.copyWith(
                            fontSize: 15,
                            height: 1.6,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoArtPainter extends CustomPainter {
  const _LogoArtPainter({required this.gradient});

  final Gradient gradient;

  static const _viewBox = 700.0;
  static const _triangles = <(List<Offset>, double)>[
    ([Offset(120, 90), Offset(400, 230), Offset(120, 370)], 0.35),
    ([Offset(120, 230), Offset(400, 370), Offset(120, 510)], 0.65),
    ([Offset(260, 160), Offset(540, 300), Offset(260, 440)], 1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.height * 0.84;
    final scale = side / _viewBox;
    final origin = Offset(
      size.width - side + side * 0.17,
      (size.height - side) / 2,
    );
    final bounds = origin & Size.square(side);
    final shader = gradient.createShader(bounds);
    final paint = Paint()
      ..shader = shader
      ..strokeWidth = 34 * scale
      ..strokeJoin = StrokeJoin.round;
    for (final (points, opacity) in _triangles) {
      final path = Path()
        ..addPolygon([for (final p in points) origin + p * scale], true);
      canvas
        ..saveLayer(
          path.getBounds().inflate(paint.strokeWidth),
          Paint()..color = Colors.white.withValues(alpha: opacity),
        )
        ..drawPath(path, paint..style = PaintingStyle.fill)
        ..drawPath(path, paint..style = PaintingStyle.stroke)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_LogoArtPainter oldDelegate) =>
      oldDelegate.gradient != gradient;
}
