/// Playground input state: the text controllers and the picked audio file.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';

class PlaygroundInputs {
  PlaygroundInputs({
    required this.systemPrompt,
    required this.userPrompt,
    required this.translateSource,
    required this.translateTarget,
    required this.translateText,
    required this.dictionaryWord,
    required this.dictionarySource,
    required this.dictionaryTarget,
    required this.assessmentReference,
    required this.assessmentLanguage,
  });

  final TextEditingController systemPrompt;
  final TextEditingController userPrompt;
  final TextEditingController translateSource;
  final TextEditingController translateTarget;
  final TextEditingController translateText;
  final TextEditingController dictionaryWord;
  final TextEditingController dictionarySource;
  final TextEditingController dictionaryTarget;
  final TextEditingController assessmentReference;
  final TextEditingController assessmentLanguage;

  Uint8List? _pickedAudio;
  String _pickedName = 'audio.wav';

  Uint8List? get pickedAudio => _pickedAudio;
  String get pickedName => _pickedName;
  int? get pickedByteCount => _pickedAudio?.length;

  void setPicked(Uint8List bytes, String name) {
    _pickedAudio = bytes;
    _pickedName = name;
  }

  void dispose() {
    systemPrompt.dispose();
    userPrompt.dispose();
    translateSource.dispose();
    translateTarget.dispose();
    translateText.dispose();
    dictionaryWord.dispose();
    dictionarySource.dispose();
    dictionaryTarget.dispose();
    assessmentReference.dispose();
    assessmentLanguage.dispose();
  }
}
