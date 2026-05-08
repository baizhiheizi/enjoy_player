/// Display-only formatting for hotkey strings (subset of web `format-hotkey`).
library;

/// Turns `shift+slash` into `?`, formats modifiers for UI labels.
String formatHotkeyForDisplay(String binding) {
  final s = binding.trim().toLowerCase();
  if (s == 'shift+slash') return '?';

  final parts = s.split('+').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return binding;

  final out = <String>[];
  for (final p in parts) {
    switch (p) {
      case 'ctrl':
      case 'control':
        out.add('Ctrl');
        break;
      case 'shift':
        out.add('Shift');
        break;
      case 'alt':
        out.add('Alt');
        break;
      case 'meta':
      case 'cmd':
        out.add('Win');
        break;
      case 'comma':
        out.add(',');
        break;
      case 'period':
        out.add('.');
        break;
      case 'slash':
        out.add('/');
        break;
      case 'space':
        out.add('Space');
        break;
      case 'escape':
        out.add('Esc');
        break;
      case 'enter':
      case 'return':
        out.add('Enter');
        break;
      case 'tab':
        out.add('Tab');
        break;
      case 'backspace':
        out.add('Backspace');
        break;
      case 'delete':
        out.add('Del');
        break;
      case 'arrowleft':
        out.add('←');
        break;
      case 'arrowright':
        out.add('→');
        break;
      case 'arrowup':
        out.add('↑');
        break;
      case 'arrowdown':
        out.add('↓');
        break;
      case '{':
        out.add('{');
        break;
      case '}':
        out.add('}');
        break;
      default:
        if (p.length == 1) {
          if (p == '[' || p == ']' || p == '/' || p == '\\') {
            out.add(p);
          } else if (p.codeUnitAt(0) >= 0x61 && p.codeUnitAt(0) <= 0x7a) {
            out.add(p.toUpperCase());
          } else {
            out.add(p);
          }
        } else {
          out.add(p);
        }
    }
  }
  return out.join('+');
}
