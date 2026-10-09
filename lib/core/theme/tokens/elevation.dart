part of '../enjoy_tokens.dart';

List<BoxShadow> _shadowLift(bool light) => light
    ? const [
        BoxShadow(
          color: Color.fromRGBO(18, 20, 26, 0.08),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
        BoxShadow(color: Color.fromRGBO(18, 20, 26, 0.05), spreadRadius: 1),
      ]
    : const [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.5),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
        BoxShadow(color: Color.fromRGBO(255, 255, 255, 0.06), spreadRadius: 1),
      ];

List<BoxShadow> _shadowFloat(bool light) => light
    ? const [
        BoxShadow(
          color: Color.fromRGBO(18, 20, 26, 0.05),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color.fromRGBO(18, 20, 26, 0.12),
          blurRadius: 44,
          offset: Offset(0, 14),
        ),
      ]
    : const [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.4),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.55),
          blurRadius: 52,
          offset: Offset(0, 18),
        ),
      ];

List<BoxShadow> _shadowBrandButton(bool light) => light
    ? const [
        BoxShadow(
          color: Color.fromRGBO(79, 70, 229, 0.26),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ]
    : const [];

List<BoxShadow> _shadowRecordButton(bool light) => light
    ? const [
        BoxShadow(
          color: Color.fromRGBO(124, 58, 237, 0.32),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ]
    : const [];

final class _ElevationTokens {
  const _ElevationTokens({
    required this.elevationNone,
    required this.elevationCard,
    required this.elevationSheet,
    required this.elevationModal,
    required this.elevationBar,
    required this.elevationSurface,
    required this.focusRingWidth,
    required this.shadowLift,
    required this.shadowFloat,
    required this.shadowPopover,
    required this.strokeReferencePitch,
    required this.strokeYourPitch,
    required this.strokeLoopBracket,
    required this.strokeRulerTrack,
    required this.shadowBrandButton,
    required this.shadowRecordButton,
  });

  factory _ElevationTokens.build({required bool light}) => _ElevationTokens(
    elevationNone: 0,
    elevationCard: 1,
    elevationSheet: 3,
    elevationModal: 8,
    elevationBar: 2,
    elevationSurface: 1,
    focusRingWidth: 2,
    shadowLift: _shadowLift(light),
    shadowFloat: _shadowFloat(light),
    shadowPopover: _shadowFloat(light),
    strokeReferencePitch: 9,
    strokeYourPitch: 3,
    strokeLoopBracket: 2,
    strokeRulerTrack: 4,
    shadowBrandButton: _shadowBrandButton(light),
    shadowRecordButton: _shadowRecordButton(light),
  );

  final double elevationNone;
  final double elevationCard;
  final double elevationSheet;
  final double elevationModal;

  /// Legacy aliases kept for widgets that still call elevationBar/elevationSurface.
  final double elevationBar;
  final double elevationSurface;

  /// Keyboard focus ring stroke width for custom controls.
  final double focusRingWidth;

  /// Resting card shadow.
  final List<BoxShadow> shadowLift;

  /// Floating chrome shadow (tab bar, dock, popovers).
  final List<BoxShadow> shadowFloat;

  /// Menus / dialogs shadow.
  final List<BoxShadow> shadowPopover;
  final double strokeReferencePitch;
  final double strokeYourPitch;
  final double strokeLoopBracket;
  final double strokeRulerTrack;

  /// Brand-gradient button shadow.
  final List<BoxShadow> shadowBrandButton;

  /// Record button shadow.
  final List<BoxShadow> shadowRecordButton;

  _ElevationTokens copyWith({
    double? elevationNone,
    double? elevationCard,
    double? elevationSheet,
    double? elevationModal,
    double? elevationBar,
    double? elevationSurface,
    double? focusRingWidth,
    List<BoxShadow>? shadowLift,
    List<BoxShadow>? shadowFloat,
    List<BoxShadow>? shadowPopover,
    double? strokeReferencePitch,
    double? strokeYourPitch,
    double? strokeLoopBracket,
    double? strokeRulerTrack,
    List<BoxShadow>? shadowBrandButton,
    List<BoxShadow>? shadowRecordButton,
  }) {
    return _ElevationTokens(
      elevationNone: elevationNone ?? this.elevationNone,
      elevationCard: elevationCard ?? this.elevationCard,
      elevationSheet: elevationSheet ?? this.elevationSheet,
      elevationModal: elevationModal ?? this.elevationModal,
      elevationBar: elevationBar ?? this.elevationBar,
      elevationSurface: elevationSurface ?? this.elevationSurface,
      focusRingWidth: focusRingWidth ?? this.focusRingWidth,
      shadowLift: shadowLift ?? this.shadowLift,
      shadowFloat: shadowFloat ?? this.shadowFloat,
      shadowPopover: shadowPopover ?? this.shadowPopover,
      strokeReferencePitch: strokeReferencePitch ?? this.strokeReferencePitch,
      strokeYourPitch: strokeYourPitch ?? this.strokeYourPitch,
      strokeLoopBracket: strokeLoopBracket ?? this.strokeLoopBracket,
      strokeRulerTrack: strokeRulerTrack ?? this.strokeRulerTrack,
      shadowBrandButton: shadowBrandButton ?? this.shadowBrandButton,
      shadowRecordButton: shadowRecordButton ?? this.shadowRecordButton,
    );
  }

  _ElevationTokens lerp(_ElevationTokens other, double t) {
    return _ElevationTokens(
      elevationNone: lerpDouble(elevationNone, other.elevationNone, t)!,
      elevationCard: lerpDouble(elevationCard, other.elevationCard, t)!,
      elevationSheet: lerpDouble(elevationSheet, other.elevationSheet, t)!,
      elevationModal: lerpDouble(elevationModal, other.elevationModal, t)!,
      elevationBar: lerpDouble(elevationBar, other.elevationBar, t)!,
      elevationSurface: lerpDouble(
        elevationSurface,
        other.elevationSurface,
        t,
      )!,
      focusRingWidth: lerpDouble(focusRingWidth, other.focusRingWidth, t)!,
      shadowLift: BoxShadow.lerpList(shadowLift, other.shadowLift, t)!,
      shadowFloat: BoxShadow.lerpList(shadowFloat, other.shadowFloat, t)!,
      shadowPopover: BoxShadow.lerpList(shadowPopover, other.shadowPopover, t)!,
      strokeReferencePitch: lerpDouble(
        strokeReferencePitch,
        other.strokeReferencePitch,
        t,
      )!,
      strokeYourPitch: lerpDouble(strokeYourPitch, other.strokeYourPitch, t)!,
      strokeLoopBracket: lerpDouble(
        strokeLoopBracket,
        other.strokeLoopBracket,
        t,
      )!,
      strokeRulerTrack: lerpDouble(
        strokeRulerTrack,
        other.strokeRulerTrack,
        t,
      )!,
      shadowBrandButton: BoxShadow.lerpList(
        shadowBrandButton,
        other.shadowBrandButton,
        t,
      )!,
      shadowRecordButton: BoxShadow.lerpList(
        shadowRecordButton,
        other.shadowRecordButton,
        t,
      )!,
    );
  }
}
