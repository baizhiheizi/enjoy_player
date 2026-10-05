/// Aurora-lit scaffold shared by sign-in hub and email OTP flow.
library;

import 'package:flutter/material.dart';

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
      body: SafeArea(child: child),
    );
  }
}
