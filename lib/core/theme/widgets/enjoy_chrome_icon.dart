/// Chrome glyphs for shell / transport / settings, rendered from the Aurora
/// icon family ([EnjoyIcons]) so chrome and content icons share one
/// stroke language.
library;

import 'package:flutter/material.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';

/// Semantic chrome glyphs (stable ids used by shell, transport, and tests).
enum EnjoyChromeGlyph {
  home,
  compass,
  library,
  user,
  play,
  pause,
  skipBack,
  skipForward,
  replay,
  mic,
  wave,
  cc,
  speed,
  volume,
  volumeOff,
  plus,
  search,
  close,
  sun,
  moon,
  monitor,
  gear,
  chevronDown,
  chevronRight,
  chevronLeft,
  dots,
  check,
}

extension EnjoyChromeGlyphIcon on EnjoyChromeGlyph {
  /// Outline glyph (resting state).
  IconData get icon => switch (this) {
    EnjoyChromeGlyph.home => EnjoyIcons.home,
    EnjoyChromeGlyph.compass => EnjoyIcons.compassNav,
    EnjoyChromeGlyph.library => EnjoyIcons.libraryNav,
    EnjoyChromeGlyph.user => EnjoyIcons.personNav,
    EnjoyChromeGlyph.play => EnjoyIcons.play,
    EnjoyChromeGlyph.pause => EnjoyIcons.pause,
    EnjoyChromeGlyph.skipBack => EnjoyIcons.skipBackLine,
    EnjoyChromeGlyph.skipForward => EnjoyIcons.skipForwardLine,
    EnjoyChromeGlyph.replay => EnjoyIcons.replay,
    EnjoyChromeGlyph.mic => EnjoyIcons.mic,
    EnjoyChromeGlyph.wave => EnjoyIcons.waveform,
    EnjoyChromeGlyph.cc => EnjoyIcons.subtitles,
    EnjoyChromeGlyph.speed => EnjoyIcons.speed,
    EnjoyChromeGlyph.volume => EnjoyIcons.volume,
    EnjoyChromeGlyph.volumeOff => EnjoyIcons.volumeOff,
    EnjoyChromeGlyph.plus => EnjoyIcons.add,
    EnjoyChromeGlyph.search => EnjoyIcons.search,
    EnjoyChromeGlyph.close => EnjoyIcons.close,
    EnjoyChromeGlyph.sun => EnjoyIcons.sun,
    EnjoyChromeGlyph.moon => EnjoyIcons.moon,
    EnjoyChromeGlyph.monitor => EnjoyIcons.monitor,
    EnjoyChromeGlyph.gear => EnjoyIcons.gear,
    EnjoyChromeGlyph.chevronDown => EnjoyIcons.chevronDown,
    EnjoyChromeGlyph.chevronRight => EnjoyIcons.chevronRight,
    EnjoyChromeGlyph.chevronLeft => EnjoyIcons.chevronLeft,
    EnjoyChromeGlyph.dots => EnjoyIcons.more,
    EnjoyChromeGlyph.check => EnjoyIcons.check,
  };

  /// Filled glyph for selected / active states.
  IconData get filledIcon => switch (this) {
    EnjoyChromeGlyph.home => EnjoyIcons.homeFill,
    EnjoyChromeGlyph.compass => EnjoyIcons.compassNavFill,
    EnjoyChromeGlyph.library => EnjoyIcons.libraryNavFill,
    EnjoyChromeGlyph.user => EnjoyIcons.personNavFill,
    EnjoyChromeGlyph.skipBack => EnjoyIcons.skipBack,
    EnjoyChromeGlyph.skipForward => EnjoyIcons.skipForward,
    EnjoyChromeGlyph.mic => EnjoyIcons.micFill,
    EnjoyChromeGlyph.wave => EnjoyIcons.waveformFill,
    EnjoyChromeGlyph.cc => EnjoyIcons.subtitlesFill,
    EnjoyChromeGlyph.speed => EnjoyIcons.speedFill,
    EnjoyChromeGlyph.volume => EnjoyIcons.volumeFill,
    EnjoyChromeGlyph.volumeOff => EnjoyIcons.volumeOffFill,
    EnjoyChromeGlyph.gear => EnjoyIcons.gearFill,
    EnjoyChromeGlyph.sun => EnjoyIcons.sunFill,
    EnjoyChromeGlyph.moon => EnjoyIcons.moonFill,
    EnjoyChromeGlyph.monitor => EnjoyIcons.monitorFill,
    _ => icon,
  };
}

/// Tinted chrome icon. Color and size follow [IconTheme] when omitted.
class EnjoyChromeIcon extends StatelessWidget {
  const EnjoyChromeIcon(
    this.glyph, {
    super.key,
    this.size,
    this.color,
    this.filled = false,
  });

  final EnjoyChromeGlyph glyph;
  final double? size;
  final Color? color;

  /// Render the filled variant (selected nav item, active toggle).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Icon(
      filled ? glyph.filledIcon : glyph.icon,
      size: size,
      color: color,
      semanticLabel: glyph.name,
    );
  }
}
