/// Aurora icon set — semantic names over the vendored Phosphor icon fonts
/// (MIT, `assets/fonts/phosphor/`; ADR-0089).
///
/// Use these instead of Material [Icons]: one consistent stroke family on
/// every platform. Outline (`PhosphorRegular`) is the default; `…Fill`
/// variants mark selected / active states. Constants stay `const` so
/// release builds tree-shake the icon fonts.
library;

import 'package:flutter/widgets.dart';

abstract final class EnjoyIcons {
  static const IconData add = IconData(0xe3d4, fontFamily: 'PhosphorRegular');
  static const IconData addLink = IconData(
    0xe2e2,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData apple = IconData(0xe516, fontFamily: 'PhosphorFill');
  static const IconData archive = IconData(
    0xe00c,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData arrowDown = IconData(
    0xe03e,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData arrowRight = IconData(
    0xe06c,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData arrowUpRight = IconData(
    0xe092,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData article = IconData(
    0xe0a8,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData audio = IconData(0xe342, fontFamily: 'PhosphorRegular');
  static const IconData back = IconData(0xe138, fontFamily: 'PhosphorRegular');
  static const IconData bellOff = IconData(
    0xe0d4,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData bolt = IconData(0xe2de, fontFamily: 'PhosphorRegular');
  static const IconData boltFill = IconData(0xe2de, fontFamily: 'PhosphorFill');
  static const IconData book = IconData(0xe8f2, fontFamily: 'PhosphorRegular');
  static const IconData bookmarkAdd = IconData(
    0xe0ea,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData bookmarkFill = IconData(
    0xe0ea,
    fontFamily: 'PhosphorFill',
  );
  static const IconData bug = IconData(0xe5f4, fontFamily: 'PhosphorRegular');
  static const IconData calendar = IconData(
    0xe10a,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData calendarMonth = IconData(
    0xe7b4,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData camera = IconData(
    0xe10e,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData cards = IconData(0xe0f8, fontFamily: 'PhosphorRegular');
  static const IconData caretUpDown = IconData(
    0xe140,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData cc = IconData(0xe1a4, fontFamily: 'PhosphorRegular');
  static const IconData chart = IconData(0xe156, fontFamily: 'PhosphorRegular');
  static const IconData chat = IconData(0xe168, fontFamily: 'PhosphorRegular');
  static const IconData check = IconData(0xe182, fontFamily: 'PhosphorBold');
  static const IconData checkCircle = IconData(
    0xe184,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData checkCircleFill = IconData(
    0xe184,
    fontFamily: 'PhosphorFill',
  );
  static const IconData chevronDown = IconData(
    0xe136,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData chevronLeft = IconData(
    0xe138,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData chevronRight = IconData(
    0xe13a,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData chevronUp = IconData(
    0xe13c,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData clearAll = IconData(
    0xec54,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData clock = IconData(0xe19a, fontFamily: 'PhosphorRegular');
  static const IconData clockFill = IconData(
    0xe19a,
    fontFamily: 'PhosphorFill',
  );
  static const IconData close = IconData(0xe4f6, fontFamily: 'PhosphorRegular');
  static const IconData cloudDone = IconData(
    0xe1b0,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData cloudDownload = IconData(
    0xe1ac,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData cloudOff = IconData(
    0xe1b6,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData cloudSync = IconData(
    0xe1ae,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData cloudUpload = IconData(
    0xe1ae,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData code = IconData(0xe1bc, fontFamily: 'PhosphorRegular');
  static const IconData command = IconData(
    0xe1c4,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData compass = IconData(
    0xe1c8,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData compassFill = IconData(
    0xe1c8,
    fontFamily: 'PhosphorFill',
  );
  static const IconData compassNav = IconData(
    0xe1c8,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData compassNavFill = IconData(
    0xe1c8,
    fontFamily: 'PhosphorFill',
  );
  static const IconData compassOff = IconData(
    0xe3de,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData copy = IconData(0xe1ca, fontFamily: 'PhosphorRegular');
  static const IconData crown = IconData(0xe616, fontFamily: 'PhosphorFill');
  static const IconData dateRange = IconData(
    0xe7b4,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData delete = IconData(
    0xe4a6,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData developer = IconData(
    0xeae8,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData dot = IconData(0xe18a, fontFamily: 'PhosphorFill');
  static const IconData dotsVertical = IconData(
    0xe208,
    fontFamily: 'PhosphorBold',
  );
  static const IconData download = IconData(
    0xe20c,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData edit = IconData(0xe34c, fontFamily: 'PhosphorRegular');
  static const IconData error = IconData(0xe4e2, fontFamily: 'PhosphorRegular');
  static const IconData errorFill = IconData(
    0xe4e2,
    fontFamily: 'PhosphorFill',
  );
  static const IconData event = IconData(0xe10a, fontFamily: 'PhosphorRegular');
  static const IconData eventAvailable = IconData(
    0xe712,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData expand = IconData(
    0xe0a6,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData eye = IconData(0xe220, fontFamily: 'PhosphorRegular');
  static const IconData eyeOff = IconData(
    0xe224,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData fileUpload = IconData(
    0xe61e,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData filter = IconData(
    0xe268,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData flame = IconData(0xe624, fontFamily: 'PhosphorFill');
  static const IconData folder = IconData(
    0xe256,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData forum = IconData(0xe17c, fontFamily: 'PhosphorRegular');
  static const IconData fullscreen = IconData(
    0xe1d0,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData fullscreenExit = IconData(
    0xe1ce,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData gear = IconData(0xe272, fontFamily: 'PhosphorRegular');
  static const IconData gearFill = IconData(0xe272, fontFamily: 'PhosphorFill');
  static const IconData google = IconData(0xe292, fontFamily: 'PhosphorBold');
  static const IconData headphones = IconData(
    0xe2a6,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData help = IconData(0xe3e8, fontFamily: 'PhosphorRegular');
  static const IconData highlight = IconData(
    0xec76,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData history = IconData(
    0xe1a0,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData home = IconData(0xe2c2, fontFamily: 'PhosphorRegular');
  static const IconData homeFill = IconData(0xe2c2, fontFamily: 'PhosphorFill');
  static const IconData homeNav = IconData(
    0xe2c2,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData homeNavFill = IconData(
    0xe2c2,
    fontFamily: 'PhosphorFill',
  );
  static const IconData hourglass = IconData(
    0xe2ba,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData hub = IconData(0xeb58, fontFamily: 'PhosphorRegular');
  static const IconData inbox = IconData(0xe4aa, fontFamily: 'PhosphorRegular');
  static const IconData info = IconData(0xe2ce, fontFamily: 'PhosphorRegular');
  static const IconData infoFill = IconData(0xe2ce, fontFamily: 'PhosphorFill');
  static const IconData insights = IconData(
    0xe4ae,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData key = IconData(0xe2d6, fontFamily: 'PhosphorRegular');
  static const IconData keyboard = IconData(
    0xe2d8,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData lab = IconData(0xe79e, fontFamily: 'PhosphorRegular');
  static const IconData language = IconData(
    0xe28e,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData library = IconData(
    0xe758,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData libraryAdd = IconData(
    0xed4a,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData libraryAdded = IconData(
    0xe186,
    fontFamily: 'PhosphorFill',
  );
  static const IconData libraryNav = IconData(
    0xe758,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData libraryNavFill = IconData(
    0xe758,
    fontFamily: 'PhosphorFill',
  );
  static const IconData lightbulb = IconData(
    0xe2dc,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData link = IconData(0xe2e2, fontFamily: 'PhosphorRegular');
  static const IconData list = IconData(0xe2f2, fontFamily: 'PhosphorRegular');
  static const IconData lock = IconData(0xe308, fontFamily: 'PhosphorRegular');
  static const IconData lockPerson = IconData(
    0xe2fe,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData magic = IconData(0xe6b6, fontFamily: 'PhosphorRegular');
  static const IconData mail = IconData(0xe218, fontFamily: 'PhosphorRegular');
  static const IconData manageAccount = IconData(
    0xe4cc,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData mic = IconData(0xe326, fontFamily: 'PhosphorRegular');
  static const IconData micFill = IconData(0xe326, fontFamily: 'PhosphorFill');
  static const IconData minus = IconData(0xe32a, fontFamily: 'PhosphorRegular');
  static const IconData monitor = IconData(
    0xe32e,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData monitorFill = IconData(
    0xe32e,
    fontFamily: 'PhosphorFill',
  );
  static const IconData moon = IconData(0xe330, fontFamily: 'PhosphorRegular');
  static const IconData moonFill = IconData(0xe330, fontFamily: 'PhosphorFill');
  static const IconData more = IconData(0xe1fe, fontFamily: 'PhosphorBold');
  static const IconData openExternal = IconData(
    0xe5de,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData palette = IconData(
    0xe6c8,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData paste = IconData(0xe198, fontFamily: 'PhosphorRegular');
  static const IconData pause = IconData(0xe39e, fontFamily: 'PhosphorFill');
  static const IconData people = IconData(
    0xe4d6,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData person = IconData(
    0xe4c2,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData personFill = IconData(
    0xe4c2,
    fontFamily: 'PhosphorFill',
  );
  static const IconData personNav = IconData(
    0xe4c4,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData personNavFill = IconData(
    0xe4c4,
    fontFamily: 'PhosphorFill',
  );
  static const IconData play = IconData(0xe3d0, fontFamily: 'PhosphorFill');
  static const IconData playCircle = IconData(
    0xe3d2,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData plusBold = IconData(0xe3d4, fontFamily: 'PhosphorBold');
  static const IconData premium = IconData(
    0xe616,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData quote = IconData(0xe660, fontFamily: 'PhosphorRegular');
  static const IconData radioOff = IconData(
    0xe18a,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData radioOn = IconData(0xeb08, fontFamily: 'PhosphorFill');
  static const IconData receipt = IconData(
    0xe3ec,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData refresh = IconData(
    0xe036,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData replay = IconData(
    0xe038,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData robot = IconData(0xe762, fontFamily: 'PhosphorRegular');
  static const IconData route = IconData(0xe39c, fontFamily: 'PhosphorRegular');
  static const IconData rss = IconData(0xe400, fontFamily: 'PhosphorRegular');
  static const IconData save = IconData(0xe248, fontFamily: 'PhosphorRegular');
  static const IconData savings = IconData(
    0xea04,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData search = IconData(
    0xe30c,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData searchOff = IconData(
    0xe30e,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData server = IconData(
    0xe2a0,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData settings = IconData(
    0xe272,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData share = IconData(0xeaf0, fontFamily: 'PhosphorRegular');
  static const IconData shield = IconData(
    0xe40c,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData sidebar = IconData(
    0xec24,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData signIn = IconData(
    0xe428,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData signOut = IconData(
    0xe42a,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData skipBack = IconData(0xe5a4, fontFamily: 'PhosphorFill');
  static const IconData skipBackLine = IconData(
    0xe5a4,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData skipForward = IconData(
    0xe5a6,
    fontFamily: 'PhosphorFill',
  );
  static const IconData skipForwardLine = IconData(
    0xe5a6,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData sparkle = IconData(
    0xe6a2,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData sparkleFill = IconData(
    0xe6a2,
    fontFamily: 'PhosphorFill',
  );
  static const IconData speak = IconData(0xeca8, fontFamily: 'PhosphorRegular');
  static const IconData speed = IconData(0xe628, fontFamily: 'PhosphorRegular');
  static const IconData speedFill = IconData(
    0xe628,
    fontFamily: 'PhosphorFill',
  );
  static const IconData stop = IconData(0xe46c, fontFamily: 'PhosphorFill');
  static const IconData subtitles = IconData(
    0xe1a8,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData subtitlesFill = IconData(
    0xe1a8,
    fontFamily: 'PhosphorFill',
  );
  static const IconData sun = IconData(0xe472, fontFamily: 'PhosphorRegular');
  static const IconData sunFill = IconData(0xe472, fontFamily: 'PhosphorFill');
  static const IconData swap = IconData(0xe0a0, fontFamily: 'PhosphorRegular');
  static const IconData sync = IconData(0xe094, fontFamily: 'PhosphorRegular');
  static const IconData tag = IconData(0xe2a2, fontFamily: 'PhosphorRegular');
  static const IconData target = IconData(
    0xe47c,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData targetFill = IconData(
    0xe47c,
    fontFamily: 'PhosphorFill',
  );
  static const IconData translate = IconData(
    0xe4a2,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData tune = IconData(0xe434, fontFamily: 'PhosphorRegular');
  static const IconData undo = IconData(0xe08a, fontFamily: 'PhosphorRegular');
  static const IconData update = IconData(
    0xe028,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData upload = IconData(
    0xe4c0,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData usersFill = IconData(
    0xe4d6,
    fontFamily: 'PhosphorFill',
  );
  static const IconData verified = IconData(
    0xe606,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData verifiedFill = IconData(
    0xe606,
    fontFamily: 'PhosphorFill',
  );
  static const IconData video = IconData(0xe792, fontFamily: 'PhosphorRegular');
  static const IconData videoCamera = IconData(
    0xe4da,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData videoLibrary = IconData(
    0xe8c2,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData vocabulary = IconData(
    0xe0e4,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData volume = IconData(
    0xe44a,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData volumeFill = IconData(
    0xe44a,
    fontFamily: 'PhosphorFill',
  );
  static const IconData volumeOff = IconData(
    0xe45a,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData volumeOffFill = IconData(
    0xe45a,
    fontFamily: 'PhosphorFill',
  );
  static const IconData wallet = IconData(
    0xe68a,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData warning = IconData(
    0xe4e0,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData waveform = IconData(
    0xe802,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData waveformFill = IconData(
    0xe802,
    fontFamily: 'PhosphorFill',
  );
  static const IconData youtube = IconData(0xe4fc, fontFamily: 'PhosphorFill');
}
