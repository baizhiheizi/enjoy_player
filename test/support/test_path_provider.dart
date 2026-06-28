import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Pins [getApplicationDocumentsPath] for tests (used by [FileStorage]).
class TestPathProvider extends PathProviderPlatform {
  TestPathProvider(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;

  @override
  Future<String?> getTemporaryPath() async => documentsPath;
}
