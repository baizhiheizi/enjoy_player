/// FFmpegKit command-string construction from a CLI argv list.
library;

import 'ffmpeg_media_probe.dart';

/// Renders [args] as the single command string FFmpegKit expects.
///
/// Keeps the FFmpegKit path and the `Process.run` path on exactly the same
/// token sequence: each invocation is authored once as a `List<String>`.
String ffmpegCommandFromArgs(List<String> args) =>
    args.map(shellEscape).join(' ');
