import 'package:enjoy_player/features/vocabulary/domain/vocabulary_normalize.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeWord', () {
    test('lowercases', () {
      expect(normalizeWord('HELLO'), 'hello');
      expect(normalizeWord('HeLLo'), 'hello');
    });

    test('trims whitespace', () {
      expect(normalizeWord('  hello  '), 'hello');
      expect(normalizeWord('\thello\n'), 'hello');
    });

    test('strips punctuation', () {
      expect(normalizeWord('hello!'), 'hello');
      expect(normalizeWord("hello's"), 'hellos');
      expect(normalizeWord('hello,world'), 'helloworld');
      expect(normalizeWord('(hello)'), 'hello');
      expect(normalizeWord('hello...'), 'hello');
    });

    test('combined', () {
      expect(normalizeWord('  HELLO, WORLD!  '), 'hello world');
    });

    test('only punctuation / whitespace → empty', () {
      expect(normalizeWord('!!!'), '');
      expect(normalizeWord('   '), '');
      expect(normalizeWord(''), '');
    });

    test('keeps spaces between words', () {
      expect(normalizeWord('hello world'), 'hello world');
      expect(normalizeWord('foo bar baz'), 'foo bar baz');
    });

    test('keeps digits', () {
      expect(normalizeWord('123'), '123');
      expect(normalizeWord('abc123def'), 'abc123def');
    });

    test('unicode letters', () {
      expect(normalizeWord('你好'), '你好');
      expect(normalizeWord('こんにちは'), 'こんにちは');
    });
  });
}
