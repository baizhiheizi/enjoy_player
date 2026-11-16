/// Process-level memoization for `path_provider` directories, scoped by
/// [PathProviderPlatform.instance] identity so unit tests that swap mocks
/// stay isolated.
library;

import 'dart:async' show unawaited;
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

final Expando<Future<Directory>> _docsDirs = Expando<Future<Directory>>(
  'cachedDocsDir',
);
final Expando<Future<Directory>> _tempDirs = Expando<Future<Directory>>(
  'cachedTempDir',
);
final Expando<Future<Directory>> _cacheDirs = Expando<Future<Directory>>(
  'cachedAppCacheDir',
);

Future<Directory> _memoized(
  Expando<Future<Directory>> memo,
  Future<Directory> Function() load,
) {
  final platform = PathProviderPlatform.instance;
  final existing = memo[platform];
  if (existing != null) return existing;
  final future = load();
  memo[platform] = future;
  unawaited(
    future.catchError((Object _, StackTrace _) {
      if (identical(memo[platform], future)) {
        memo[platform] = null;
      }
      return Directory('');
    }),
  );
  return future;
}

Future<Directory> cachedApplicationDocumentsDirectory() =>
    _memoized(_docsDirs, getApplicationDocumentsDirectory);

Future<Directory> cachedTemporaryDirectory() =>
    _memoized(_tempDirs, getTemporaryDirectory);

Future<Directory> cachedApplicationCacheDirectory() =>
    _memoized(_cacheDirs, getApplicationCacheDirectory);
