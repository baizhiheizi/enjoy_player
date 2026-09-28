/// Aurora-lit scaffold shared by sign-in hub and email OTP flow.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/widgets/app_background.dart';

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
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: AuroraGlow(intensity: 2.2)),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}
