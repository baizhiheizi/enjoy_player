import 'package:enjoy_player/data/files/ffmpeg_command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('joins argv with a single space and leaves flags untouched', () {
    expect(
      ffmpegCommandFromArgs(const [
        '-nostdin',
        '-i',
        '/media/plain.mp4',
        '-vn',
        '/tmp/out.wav',
      ]),
      '-nostdin -i /media/plain.mp4 -vn /tmp/out.wav',
    );
  });

  test('quotes tokens containing whitespace or double quotes', () {
    expect(
      ffmpegCommandFromArgs(const ['-i', '/media/my file.mp4']),
      '-i "/media/my file.mp4"',
    );
    expect(
      ffmpegCommandFromArgs(const ['-i', '/media/quote"d.mp4']),
      '-i "/media/quote\\"d.mp4"',
    );
  });
}
