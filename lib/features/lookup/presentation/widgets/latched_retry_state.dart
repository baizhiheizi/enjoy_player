/// Tap-latch busy state shared by the lookup retry controls.
library;

import 'package:flutter/material.dart';

mixin LatchedRetryState<T extends StatefulWidget> on State<T> {
  bool _tapLatched = false;

  bool get parentRetryBusy;

  bool wasParentRetryBusy(covariant T oldWidget);

  bool get retryBusy => parentRetryBusy || _tapLatched;

  void retry(VoidCallback action) {
    setState(() => _tapLatched = true);
    action();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (parentRetryBusy) {
      if (_tapLatched) setState(() => _tapLatched = false);
    } else if (wasParentRetryBusy(oldWidget)) {
      if (_tapLatched) setState(() => _tapLatched = false);
    }
  }
}
