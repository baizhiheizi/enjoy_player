import 'package:flutter/material.dart';

final class CraftSyncedTextController {
  CraftSyncedTextController([String initialText = ''])
    : controller = TextEditingController(text: initialText),
      focusNode = FocusNode() {
    _incoming = initialText;
    focusNode.addListener(_applyIncoming);
  }

  final TextEditingController controller;
  final FocusNode focusNode;
  late String _incoming;

  void sync(String text) {
    _incoming = text;
    _applyIncoming();
  }

  void _applyIncoming() {
    if (focusNode.hasFocus || controller.text == _incoming) return;
    controller.value = TextEditingValue(
      text: _incoming,
      selection: TextSelection.collapsed(offset: _incoming.length),
    );
  }

  void dispose() {
    focusNode.removeListener(_applyIncoming);
    focusNode.dispose();
    controller.dispose();
  }
}
