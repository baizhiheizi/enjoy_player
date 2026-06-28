/// Gradient scaffold shared by sign-in hub and email OTP flow.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

class SignInFlowScaffold extends StatelessWidget {
  const SignInFlowScaffold({super.key, this.appBar, required this.child});

  final PreferredSizeWidget? appBar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Scaffold(
      appBar: appBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [t.gradientStart, t.gradientEnd],
              ),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}
