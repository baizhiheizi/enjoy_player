/// Parse web-style hotkey strings and match [KeyDownEvent] (Flutter desktop).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Parsed modifiers + main key token (lowercase name or single-char punctuation).
@immutable
class ParsedHotkey {
  const ParsedHotkey({
    required this.ctrl,
    required this.shift,
    required this.alt,
    required this.meta,
    required this.mainToken,
  });

  final bool ctrl;
  final bool shift;
  final bool alt;
  final bool meta;

  /// Lowercase named key (`a`, `space`, `comma`, `[`, etc.).
  final String mainToken;

  /// Canonical string for conflict detection (modifier order: alt, ctrl, meta, shift).
  String get canonical {
    final mods = <String>[];
    if (alt) mods.add('alt');
    if (ctrl) mods.add('ctrl');
    if (meta) mods.add('meta');
    if (shift) mods.add('shift');
    mods.sort();
    if (mods.isEmpty) return mainToken;
    return '${mods.join('+')}+$mainToken';
  }
}

ParsedHotkey parseHotkeyString(String binding) {
  final raw = binding.trim();
  if (raw.isEmpty) {
    throw const FormatException('Empty hotkey binding');
  }
  final parts = raw
      .split('+')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    throw FormatException('Invalid hotkey binding: $binding');
  }

  bool ctrl = false;
  bool shift = false;
  bool alt = false;
  bool meta = false;

  final mod = <String, void Function()>{
    'ctrl': () => ctrl = true,
    'control': () => ctrl = true,
    'shift': () => shift = true,
    'alt': () => alt = true,
    'meta': () => meta = true,
    'cmd': () => meta = true,
  };

  var i = 0;
  while (i < parts.length - 1) {
    final m = mod[parts[i].toLowerCase()];
    if (m == null) {
      break;
    }
    m();
    i++;
  }

  var mainRaw = parts.sublist(i).join('+');
  if (mainRaw.isEmpty) {
    throw FormatException('Invalid hotkey binding: $binding');
  }

  if (mainRaw == '{') {
    shift = true;
    mainRaw = '[';
  } else if (mainRaw == '}') {
    shift = true;
    mainRaw = ']';
  }

  final mainToken = _normalizeMainToken(mainRaw);
  return ParsedHotkey(
    ctrl: ctrl,
    shift: shift,
    alt: alt,
    meta: meta,
    mainToken: mainToken,
  );
}

String _normalizeMainToken(String raw) {
  final t = raw.trim();
  if (t.length == 1) {
    final c = t.codeUnitAt(0);
    if ((c >= 0x41 && c <= 0x5a) || (c >= 0x61 && c <= 0x7a)) {
      return t.toLowerCase();
    }
    return t;
  }
  return t.toLowerCase();
}

bool _modifiersMatch(ParsedHotkey p) {
  final hk = HardwareKeyboard.instance;
  if (p.ctrl && !p.meta && defaultTargetPlatform == TargetPlatform.macOS) {
    return (hk.isControlPressed || hk.isMetaPressed) &&
        p.shift == hk.isShiftPressed &&
        p.alt == hk.isAltPressed;
  }
  return p.ctrl == hk.isControlPressed &&
      p.shift == hk.isShiftPressed &&
      p.alt == hk.isAltPressed &&
      p.meta == hk.isMetaPressed;
}

/// Single-letter a–z without modifiers in [pattern] — do not match if Ctrl/Meta/Alt held.
bool _isBareLetterPattern(ParsedHotkey p) {
  if (p.ctrl || p.shift || p.alt || p.meta) return false;
  if (p.mainToken.length != 1) return false;
  final c = p.mainToken.codeUnitAt(0);
  return c >= 0x61 && c <= 0x7a;
}

bool hotkeyMatchesParsed(KeyEvent event, ParsedHotkey p) {
  if (event is! KeyDownEvent) return false;
  if (!_modifiersMatch(p)) return false;

  if (_isBareLetterPattern(p)) {
    final hk = HardwareKeyboard.instance;
    if (hk.isControlPressed || hk.isMetaPressed || hk.isAltPressed) {
      return false;
    }
    if (hk.isShiftPressed) {
      return false;
    }
  }

  return _mainKeyMatches(event, p.mainToken, p);
}

bool hotkeyMatchesBinding(KeyEvent event, String binding) {
  try {
    return hotkeyMatchesParsed(event, parseHotkeyString(binding));
  } on FormatException {
    return false;
  }
}

/// Shifted punctuation the platforms report as its own logical key (Linux and
/// macOS send `?` for Shift+/, `<` for Shift+, …), mapped back to the key that
/// bindings name.
final Map<LogicalKeyboardKey, LogicalKeyboardKey> _shiftedToBase = {
  LogicalKeyboardKey.question: LogicalKeyboardKey.slash,
  LogicalKeyboardKey.less: LogicalKeyboardKey.comma,
  LogicalKeyboardKey.greater: LogicalKeyboardKey.period,
  LogicalKeyboardKey.braceLeft: LogicalKeyboardKey.bracketLeft,
  LogicalKeyboardKey.braceRight: LogicalKeyboardKey.bracketRight,
  LogicalKeyboardKey.colon: LogicalKeyboardKey.semicolon,
  LogicalKeyboardKey.quote: LogicalKeyboardKey.quoteSingle,
  LogicalKeyboardKey.underscore: LogicalKeyboardKey.minus,
  LogicalKeyboardKey.add: LogicalKeyboardKey.equal,
  LogicalKeyboardKey.tilde: LogicalKeyboardKey.backquote,
  LogicalKeyboardKey.bar: LogicalKeyboardKey.backslash,
};

/// US-position punctuation by physical key, used only when the logical key is
/// not one the bindings know (layouts or IMEs that report another character).
final Map<PhysicalKeyboardKey, LogicalKeyboardKey> _physicalPunctuation = {
  PhysicalKeyboardKey.slash: LogicalKeyboardKey.slash,
  PhysicalKeyboardKey.comma: LogicalKeyboardKey.comma,
  PhysicalKeyboardKey.period: LogicalKeyboardKey.period,
  PhysicalKeyboardKey.bracketLeft: LogicalKeyboardKey.bracketLeft,
  PhysicalKeyboardKey.bracketRight: LogicalKeyboardKey.bracketRight,
  PhysicalKeyboardKey.semicolon: LogicalKeyboardKey.semicolon,
  PhysicalKeyboardKey.quote: LogicalKeyboardKey.quoteSingle,
  PhysicalKeyboardKey.minus: LogicalKeyboardKey.minus,
  PhysicalKeyboardKey.equal: LogicalKeyboardKey.equal,
  PhysicalKeyboardKey.backquote: LogicalKeyboardKey.backquote,
  PhysicalKeyboardKey.backslash: LogicalKeyboardKey.backslash,
};

/// The unshifted key a binding names for [event]: shifted punctuation folds
/// back to its base key, and unknown punctuation falls back to the physical
/// key's US position.
LogicalKeyboardKey hotkeyBaseKey(KeyEvent event) {
  final logical = event.logicalKey;
  final base = _shiftedToBase[logical];
  if (base != null) return base;
  if (_physicalPunctuation.containsValue(logical)) return logical;
  final isPrintable =
      logical.keyId <= LogicalKeyboardKey.valueMask &&
      !(logical.keyId >= 0x61 && logical.keyId <= 0x7a) &&
      !(logical.keyId >= 0x30 && logical.keyId <= 0x39) &&
      logical != LogicalKeyboardKey.space;
  if (isPrintable) {
    return _physicalPunctuation[event.physicalKey] ?? logical;
  }
  return logical;
}

bool _mainKeyMatches(KeyDownEvent e, String main, ParsedHotkey full) {
  final key = hotkeyBaseKey(e);
  switch (main) {
    case 'space':
      return key == LogicalKeyboardKey.space;
    case 'escape':
      return key == LogicalKeyboardKey.escape;
    case 'enter':
    case 'return':
      return key == LogicalKeyboardKey.enter;
    case 'tab':
      return key == LogicalKeyboardKey.tab;
    case 'backspace':
      return key == LogicalKeyboardKey.backspace;
    case 'delete':
      return key == LogicalKeyboardKey.delete;
    case 'comma':
      return key == LogicalKeyboardKey.comma;
    case 'period':
      return key == LogicalKeyboardKey.period;
    case 'slash':
      return key == LogicalKeyboardKey.slash;
    case 'backslash':
      return key == LogicalKeyboardKey.backslash;
    case 'minus':
      return key == LogicalKeyboardKey.minus;
    case 'equal':
      return key == LogicalKeyboardKey.equal;
    case 'semicolon':
      return key == LogicalKeyboardKey.semicolon;
    case 'quote':
    case 'apostrophe':
      return key == LogicalKeyboardKey.quoteSingle;
    case 'bracketleft':
    case '[':
      return key == LogicalKeyboardKey.bracketLeft;
    case 'bracketright':
    case ']':
      return key == LogicalKeyboardKey.bracketRight;
    case 'arrowleft':
      return key == LogicalKeyboardKey.arrowLeft;
    case 'arrowright':
      return key == LogicalKeyboardKey.arrowRight;
    case 'arrowup':
      return key == LogicalKeyboardKey.arrowUp;
    case 'arrowdown':
      return key == LogicalKeyboardKey.arrowDown;
  }

  if (main.length == 1) {
    final code = main.codeUnitAt(0);
    if (code >= 0x61 && code <= 0x7a) {
      const letterKeys = <LogicalKeyboardKey>[
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyB,
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyE,
        LogicalKeyboardKey.keyF,
        LogicalKeyboardKey.keyG,
        LogicalKeyboardKey.keyH,
        LogicalKeyboardKey.keyI,
        LogicalKeyboardKey.keyJ,
        LogicalKeyboardKey.keyK,
        LogicalKeyboardKey.keyL,
        LogicalKeyboardKey.keyM,
        LogicalKeyboardKey.keyN,
        LogicalKeyboardKey.keyO,
        LogicalKeyboardKey.keyP,
        LogicalKeyboardKey.keyQ,
        LogicalKeyboardKey.keyR,
        LogicalKeyboardKey.keyS,
        LogicalKeyboardKey.keyT,
        LogicalKeyboardKey.keyU,
        LogicalKeyboardKey.keyV,
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.keyX,
        LogicalKeyboardKey.keyY,
        LogicalKeyboardKey.keyZ,
      ];
      return key == letterKeys[code - 0x61];
    }
    switch (main) {
      case '/':
        return key == LogicalKeyboardKey.slash;
      case '`':
        return key == LogicalKeyboardKey.backquote;
      case '[':
        return key == LogicalKeyboardKey.bracketLeft;
      case ']':
        return key == LogicalKeyboardKey.bracketRight;
      case ',':
        return key == LogicalKeyboardKey.comma;
      case '.':
        return key == LogicalKeyboardKey.period;
      case ';':
        return key == LogicalKeyboardKey.semicolon;
      case '\'':
        return key == LogicalKeyboardKey.quoteSingle;
      case '-':
        return key == LogicalKeyboardKey.minus;
      case '=':
        return key == LogicalKeyboardKey.equal;
    }
  }

  if (main.startsWith('f')) {
    final n = int.tryParse(main.substring(1));
    if (n != null && n >= 1 && n <= 24) {
      const bases = <LogicalKeyboardKey>[
        LogicalKeyboardKey.f1,
        LogicalKeyboardKey.f2,
        LogicalKeyboardKey.f3,
        LogicalKeyboardKey.f4,
        LogicalKeyboardKey.f5,
        LogicalKeyboardKey.f6,
        LogicalKeyboardKey.f7,
        LogicalKeyboardKey.f8,
        LogicalKeyboardKey.f9,
        LogicalKeyboardKey.f10,
        LogicalKeyboardKey.f11,
        LogicalKeyboardKey.f12,
      ];
      if (n <= 12) return key == bases[n - 1];
    }
  }

  return false;
}

/// Whether [candidate] conflicts with [existing] (same canonical chord).
bool hotkeyBindingsConflict(String candidate, String existing) {
  try {
    return parseHotkeyString(candidate).canonical ==
        parseHotkeyString(existing).canonical;
  } on FormatException {
    return false;
  }
}

/// Builds a web-style binding string from a key event (for customization capture).
String? serializeChordFromKeyEvent(KeyDownEvent event) {
  final hk = HardwareKeyboard.instance;
  final mods = <String>[];
  if (hk.isControlPressed) mods.add('ctrl');
  if (hk.isShiftPressed) mods.add('shift');
  if (hk.isAltPressed) mods.add('alt');
  if (hk.isMetaPressed) mods.add('meta');

  final key = hotkeyBaseKey(event);

  if (hk.isShiftPressed &&
      !hk.isControlPressed &&
      !hk.isAltPressed &&
      !hk.isMetaPressed &&
      key == LogicalKeyboardKey.bracketLeft) {
    return '{';
  }
  if (hk.isShiftPressed &&
      !hk.isControlPressed &&
      !hk.isAltPressed &&
      !hk.isMetaPressed &&
      key == LogicalKeyboardKey.bracketRight) {
    return '}';
  }

  String? mainToken;
  if (key == LogicalKeyboardKey.space) {
    mainToken = 'space';
  } else if (key == LogicalKeyboardKey.escape) {
    mainToken = 'escape';
  } else if (key == LogicalKeyboardKey.enter) {
    mainToken = 'enter';
  } else if (key == LogicalKeyboardKey.tab) {
    mainToken = 'tab';
  } else if (key == LogicalKeyboardKey.backspace) {
    mainToken = 'backspace';
  } else if (key == LogicalKeyboardKey.delete) {
    mainToken = 'delete';
  } else if (key == LogicalKeyboardKey.comma) {
    mainToken = 'comma';
  } else if (key == LogicalKeyboardKey.period) {
    mainToken = 'period';
  } else if (key == LogicalKeyboardKey.slash) {
    mainToken = hk.isShiftPressed ? 'slash' : '/';
  } else if (key == LogicalKeyboardKey.bracketLeft) {
    mainToken = '[';
  } else if (key == LogicalKeyboardKey.bracketRight) {
    mainToken = ']';
  } else if (key == LogicalKeyboardKey.backslash) {
    mainToken = 'backslash';
  } else if (key == LogicalKeyboardKey.minus) {
    mainToken = 'minus';
  } else if (key == LogicalKeyboardKey.equal) {
    mainToken = 'equal';
  } else if (key == LogicalKeyboardKey.arrowLeft) {
    mainToken = 'arrowleft';
  } else if (key == LogicalKeyboardKey.arrowRight) {
    mainToken = 'arrowright';
  } else if (key == LogicalKeyboardKey.arrowUp) {
    mainToken = 'arrowup';
  } else if (key == LogicalKeyboardKey.arrowDown) {
    mainToken = 'arrowdown';
  } else {
    const letterKeys = <LogicalKeyboardKey>[
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyB,
      LogicalKeyboardKey.keyC,
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.keyE,
      LogicalKeyboardKey.keyF,
      LogicalKeyboardKey.keyG,
      LogicalKeyboardKey.keyH,
      LogicalKeyboardKey.keyI,
      LogicalKeyboardKey.keyJ,
      LogicalKeyboardKey.keyK,
      LogicalKeyboardKey.keyL,
      LogicalKeyboardKey.keyM,
      LogicalKeyboardKey.keyN,
      LogicalKeyboardKey.keyO,
      LogicalKeyboardKey.keyP,
      LogicalKeyboardKey.keyQ,
      LogicalKeyboardKey.keyR,
      LogicalKeyboardKey.keyS,
      LogicalKeyboardKey.keyT,
      LogicalKeyboardKey.keyU,
      LogicalKeyboardKey.keyV,
      LogicalKeyboardKey.keyW,
      LogicalKeyboardKey.keyX,
      LogicalKeyboardKey.keyY,
      LogicalKeyboardKey.keyZ,
    ];
    for (var i = 0; i < letterKeys.length; i++) {
      if (key == letterKeys[i]) {
        mainToken = String.fromCharCode(0x61 + i);
        break;
      }
    }
  }

  if (mainToken == null) return null;
  if (mods.isEmpty) return mainToken;
  return '${mods.join('+')}+$mainToken';
}
