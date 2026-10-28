import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:logging/logging.dart';

import '../constants.dart';
import '../failures.dart';
import '../language_map.dart';
import 'espeak_events.dart';
import 'espeak_ffi.dart';
import 'espeak_ng_bindings.dart';
import 'espeak_reference_words.dart';
import 'native_paths.dart';
import 'resample.dart';
import 'spoken_reference.dart';

final _log = Logger('forced_alignment');

/// Production spoken reference: eSpeak-NG `espeak_Synth` + WORD/PHONEME events.
final class EspeakNgSynthesizer implements SpokenReferenceSynthesizer {
  EspeakNgSynthesizer({this._isCancelled, this.phonemesOnly = false});

  final bool Function()? _isCancelled;

  /// When true, discard native PCM (YouTube IPA). Still runs `espeak_Synth`
  /// so WORD/PHONEME events arrive; does not copy samples onto the Dart heap.
  final bool phonemesOnly;

  static DynamicLibrary? _lib;
  static EspeakNgBindings? _bindings;
  static bool _initialized = false;
  static int _nativeSampleRate = 22050;
  static NativeCallable<EspeakCallbackNative>? _callable;
  static Int16List _pcm = Int16List(0);
  static int _pcmCount = 0;
  static bool _capturePcm = true;
  static final List<EspeakWordEvent> _words = <EspeakWordEvent>[];
  static final List<EspeakPhoneEvent> _phones = <EspeakPhoneEvent>[];
  static bool Function()? _cancelHook;

  static void _appendPcm(Pointer<Int16> wav, int n) {
    if (n <= 0) return;
    if (_pcmCount + n > _pcm.length) {
      final next = Int16List(math.max((_pcm.length * 2), _pcmCount + n));
      if (_pcmCount > 0) {
        next.setRange(0, _pcmCount, _pcm);
      }
      _pcm = next;
    }
    _pcm.setRange(_pcmCount, _pcmCount + n, wav.asTypedList(n));
    _pcmCount += n;
  }

  static int _onSynth(
    Pointer<Int16> wav,
    int numsamples,
    Pointer<EspeakEvent> events,
  ) {
    if (_cancelHook?.call() ?? false) return 1;
    if (_capturePcm && wav != nullptr && numsamples > 0) {
      _appendPcm(wav, numsamples);
    }
    if (events != nullptr) {
      for (var i = 0; i < 64; i++) {
        final event = events[i];
        if (event.type == espeakEventListTerminated) break;
        if (event.type == espeakEventWord) {
          _words.add(
            EspeakWordEvent(
              textPosition: event.textPosition,
              length: event.length,
              audioMs: event.audioPosition,
            ),
          );
        } else if (event.type == espeakEventPhoneme) {
          final phone = _readPhoneme(event);
          if (phone.isNotEmpty) {
            _phones.add(
              EspeakPhoneEvent(
                phone: phone,
                audioMs: event.audioPosition,
                textPosition: event.textPosition,
              ),
            );
          }
        }
      }
    }
    return 0;
  }

  static String _readPhoneme(EspeakEvent event) {
    final units = <int>[];
    for (var i = 0; i < 8; i++) {
      final b = event.idBytes[i];
      if (b == 0) break;
      units.add(b);
    }
    return decodeEspeakPhonemeIdBytes(units);
  }

  static EspeakNgBindings _open() {
    if (_bindings != null) return _bindings!;
    final path = resolveEspeakLibraryPath();
    final data = resolveEspeakDataPath();
    if (path == null || data == null) {
      throw const SpokenReferenceException(
        message: 'eSpeak-NG library or data directory missing',
      );
    }
    try {
      _lib = _openDynamicLibrary(path);
      _bindings = EspeakNgBindings(_lib!);
    } catch (e, st) {
      _log.warning('failed to open eSpeak-NG', e, st);
      throw SpokenReferenceException(message: 'failed to open $path');
    }
    return _bindings!;
  }

  static DynamicLibrary _openDynamicLibrary(String path) {
    try {
      return DynamicLibrary.open(path);
    } on Object catch (e, st) {
      if (Platform.isAndroid && path != kEspeakAndroidSoname) {
        _log.warning(
          'failed to open eSpeak-NG at $path; retrying Android soname',
          e,
          st,
        );
        return DynamicLibrary.open(kEspeakAndroidSoname);
      }
      rethrow;
    }
  }

  static void _ensureInitialized(EspeakNgBindings bindings) {
    if (_initialized) return;
    final data = resolveEspeakDataPath();
    if (data == null) {
      throw const SpokenReferenceException(message: 'eSpeak-NG data missing');
    }
    final espeakDataParentPath = Directory(data).parent.path;
    final dataPtr = espeakDataParentPath.toNativeUtf8();
    try {
      final rate = bindings.initialize(
        audioOutputSynchronous,
        0,
        dataPtr,
        espeakInitializePhonemeEvents |
            espeakInitializePhonemeIpa |
            espeakInitializeDontExit,
      );
      if (rate <= 0) {
        throw const SpokenReferenceException(
          message: 'espeak_Initialize failed',
        );
      }
      _nativeSampleRate = rate;
      _callable = NativeCallable<EspeakCallbackNative>.isolateLocal(
        _onSynth,
        exceptionalReturn: 1,
      );
      bindings.setSynthCallback(_callable!.nativeFunction);
      _initialized = true;
    } finally {
      malloc.free(dataPtr);
    }
  }

  @override
  ReferenceAudio synthesize({required String text, required String language}) {
    if (espeakFfiForcedUnavailable) {
      throw const SpokenReferenceException(
        message: 'eSpeak-NG forced unavailable',
      );
    }
    final voice = espeakVoiceFor(language);
    if (voice == null) {
      throw const SpokenReferenceException(
        reason: AlignmentFailureReason.unsupportedLanguage,
        message: 'no spoken-reference voice',
      );
    }
    if (!espeakFfiIsAvailable()) {
      throw const SpokenReferenceException(
        message: 'eSpeak-NG library or data unavailable',
      );
    }

    final bindings = _open();
    _ensureInitialized(bindings);
    _cancelHook = _isCancelled;
    _capturePcm = !phonemesOnly;
    _pcmCount = 0;
    _words.clear();
    _phones.clear();

    final voicePtr = voice.toNativeUtf8();
    final textPtr = text.toNativeUtf8();
    try {
      final voiceStatus = bindings.setVoiceByName(voicePtr);
      if (voiceStatus != espeakOk) {
        throw SpokenReferenceException(
          message: 'espeak_SetVoiceByName($voice) failed',
        );
      }
      final status = bindings.synth(
        textPtr,
        textPtr.length + 1,
        0,
        0,
        0,
        espeakCharsUtf8,
        nullptr,
        nullptr,
      );
      if (status != espeakOk) {
        throw const SpokenReferenceException(message: 'espeak_Synth failed');
      }
      bindings.synchronize();
    } finally {
      malloc.free(voicePtr);
      malloc.free(textPtr);
      _cancelHook = null;
    }

    if (_isCancelled?.call() ?? false) {
      throw const SpokenReferenceException(
        reason: AlignmentFailureReason.cancelled,
        message: 'spoken reference cancelled',
      );
    }
    if (!phonemesOnly && _pcmCount <= 0) {
      throw const SpokenReferenceException(
        message: 'eSpeak-NG produced no PCM',
      );
    }

    if (phonemesOnly) {
      final duration = referenceEventDurationSeconds(_words, _phones);
      final words = buildReferenceWords(
        text: text,
        duration: duration,
        wordEvents: _words,
        phoneEvents: _phones,
        requireWordEvents: false,
      );
      return ReferenceAudio(
        pcm: Float32List(0),
        words: words,
        durationSeconds: duration,
      );
    }

    final floatNative = int16ToFloat32(_pcm.sublist(0, _pcmCount));
    final pcm = resampleToAlignmentRate(floatNative, _nativeSampleRate);
    final duration = pcm.length / kAlignmentSampleRate;
    final words = buildReferenceWords(
      text: text,
      duration: duration,
      wordEvents: _words,
      phoneEvents: _phones,
    );
    return ReferenceAudio(pcm: pcm, words: words, durationSeconds: duration);
  }
}
