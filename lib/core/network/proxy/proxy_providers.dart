import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'proxy_config.dart';
import 'proxy_http_overrides.dart';

part 'proxy_providers.g.dart';

@Riverpod(keepAlive: true)
SystemProxyCoordinator systemProxyCoordinator(Ref ref) {
  final coordinator = SystemProxyCoordinator();
  ref.onDispose(coordinator.dispose);
  return coordinator;
}

@Riverpod(keepAlive: true)
class NetworkProxySettings extends _$NetworkProxySettings {
  @override
  Future<ProxyConfig> build() async {
    final db = ref.watch(deviceGlobalAppDatabaseProvider);
    final mode = ProxyMode.parse(
      await db.settingsDao.readSetting(SettingsKeys.networkProxyMode),
    );
    final url = await db.settingsDao.readSetting(SettingsKeys.networkProxyUrl);
    final config = ProxyConfig(mode: mode, url: url);
    await ref.read(systemProxyCoordinatorProvider).applyConfig(config);
    return config;
  }

  Future<void> save(ProxyConfig config) async {
    final dao = ref.read(deviceGlobalAppDatabaseProvider).settingsDao;
    await dao.writeSetting(SettingsKeys.networkProxyMode, config.mode.name);
    await dao.writeSetting(SettingsKeys.networkProxyUrl, config.url);
    await ref.read(systemProxyCoordinatorProvider).applyConfig(config);
    state = AsyncData(config);
  }
}
