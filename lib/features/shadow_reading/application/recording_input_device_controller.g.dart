// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_input_device_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RecordingInputDeviceCtrl)
final recordingInputDeviceCtrlProvider = RecordingInputDeviceCtrlProvider._();

final class RecordingInputDeviceCtrlProvider
    extends
        $AsyncNotifierProvider<
          RecordingInputDeviceCtrl,
          RecordingInputDeviceState
        > {
  RecordingInputDeviceCtrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordingInputDeviceCtrlProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordingInputDeviceCtrlHash();

  @$internal
  @override
  RecordingInputDeviceCtrl create() => RecordingInputDeviceCtrl();
}

String _$recordingInputDeviceCtrlHash() =>
    r'a02c2f7e9c7fc15c0cd96a9ab8a6b9c97fbaae60';

abstract class _$RecordingInputDeviceCtrl
    extends $AsyncNotifier<RecordingInputDeviceState> {
  FutureOr<RecordingInputDeviceState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<RecordingInputDeviceState>,
              RecordingInputDeviceState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<RecordingInputDeviceState>,
                RecordingInputDeviceState
              >,
              AsyncValue<RecordingInputDeviceState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
