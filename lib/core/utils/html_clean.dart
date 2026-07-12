/// Lightweight HTML entity decoding and tag stripping for YouTube caption text.
library;

final _tagRegex = RegExp(r'<[^>]*>');
final _entityRegex = RegExp(r'&([#a-zA-Z0-9]+);');

/// Decodes common HTML entities used in YouTube captions (named, decimal, hex).
String htmlDecode(String input) {
  return input.replaceAllMapped(_entityRegex, (m) {
    final entity = m.group(1)!;
    if (entity.startsWith('#x') || entity.startsWith('#X')) {
      final code = int.tryParse(entity.substring(2), radix: 16);
      if (code != null) return String.fromCharCode(code);
    } else if (entity.startsWith('#')) {
      final code = int.tryParse(entity.substring(1));
      if (code != null) return String.fromCharCode(code);
    }
    switch (entity) {
      case 'amp':
        return '&';
      case 'lt':
        return '<';
      case 'gt':
        return '>';
      case 'quot':
        return '"';
      case 'apos':
        return "'";
      default:
        return m.group(0)!;
    }
  });
}

String stripTags(String input) => input.replaceAll(_tagRegex, '');

String cleanHtmlText(String input) {
  var result = htmlDecode(input);
  result = stripTags(result);
  result = result.trim();
  return result;
}
