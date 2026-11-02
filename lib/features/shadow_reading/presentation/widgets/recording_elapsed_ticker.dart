/// Shared elapsed-recording timebase for live take surfaces.
///
/// One [Ticker] per surface is the only timing source: each vsync it sets
/// the elapsed seconds on an unbounded [elapsedController] that exists
/// purely as a painter's `repaint:` listenable (so rings and bars repaint
/// without rebuilding any element), bumps the whole-tenths [elapsedTenths]
/// notifier (captions rebuild 10 times a second, never per frame), and
/// calls the overridable [onRecordingTick] hook for discrete over-target
/// state.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

mixin RecordingElapsedTicker<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T> {
  final ValueNotifier<int> _elapsedTenths = ValueNotifier<int>(0);
  late final AnimationController elapsedController;
  late final Ticker _ticker;

  ValueListenable<int> get elapsedTenths => _elapsedTenths;

  void onRecordingTick(Duration elapsed) {}

  void _handleTick(Duration elapsed) {
    elapsedController.value = elapsed.inMicroseconds / 1e6;
    final tenths = elapsed.inMicroseconds ~/ 100000;
    if (tenths != _elapsedTenths.value) _elapsedTenths.value = tenths;
    onRecordingTick(elapsed);
  }

  @override
  void initState() {
    super.initState();
    elapsedController = AnimationController.unbounded(vsync: this);
    _ticker = createTicker(_handleTick);
    unawaited(_ticker.start());
  }

  @override
  void dispose() {
    _ticker.dispose();
    elapsedController.dispose();
    _elapsedTenths.dispose();
    super.dispose();
  }
}
