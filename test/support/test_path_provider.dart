import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Pins app directories for tests (used by [FileStorage] and lasting-access helpers).
class TestPathProvider extends PathProviderPlatform {
  TestPathProvider(
    this.documentsPath, {
    String? supportPath,
    String? temporaryPath,
    String? cachePath,
  }) : supportPath = supportPath ?? documentsPath,
       temporaryPath = temporaryPath ?? p.join(documentsPath, '.os_tmp'),
       cachePath = cachePath ?? p.join(documentsPath, '.os_cache');

  final String documentsPath;

  /// Defaults to [documentsPath] when not given — fine for most tests,
  /// but callers exercising `getApplicationSupportDirectory()` (e.g. the
  /// local-DB recovery flow) should pass a distinct directory.
  final String supportPath;

  /// Distinct from [documentsPath] so link-vs-copy tests can place durable
  /// files outside the ephemeral roots.
  final String temporaryPath;

  final String cachePath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;

  @override
  Future<String?> getApplicationSupportPath() async => supportPath;

  @override
  Future<String?> getTemporaryPath() async => temporaryPath;

  @override
  Future<String?> getApplicationCachePath() async => cachePath;
}
