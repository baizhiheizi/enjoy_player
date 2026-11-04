/// Parent-driven retry contract and tap-latch busy state for lookup widgets.
library;

import 'package:flutter/material.dart';

abstract class ParentRetryWidget extends StatefulWidget {
  const ParentRetryWidget({
    required this.onRetry,
    this.isRetrying = false,
    super.key,
  });

  final VoidCallback onRetry;

  /// Parent-driven busy state (e.g. [AsyncValue.hasError] && [AsyncValue.isLoading]).
  final bool isRetrying;
}

mixin LatchedRetryState<T extends ParentRetryWidget> on State<T> {
  bool _tapLatched = false;

  bool get retryBusy => widget.isRetrying || _tapLatched;

  void retry() {
    setState(() => _tapLatched = true);
    widget.onRetry();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRetrying || oldWidget.isRetrying) {
      if (_tapLatched) setState(() => _tapLatched = false);
    }
  }
}
