/// Network section body — proxy mode, manual proxy address, effective proxy,
/// and connection test.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/network/proxy/proxy_config.dart';
import 'package:enjoy_player/core/network/proxy/proxy_probe.dart';
import 'package:enjoy_player/core/network/proxy/proxy_providers.dart';
import 'package:enjoy_player/core/network/proxy/resolved_proxy.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_segmented_control.dart';
import 'package:enjoy_player/data/api/api_client_provider.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_row.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const String _kYoutubeProbeUrl = 'https://www.youtube.com/generate_204';

class NetworkSectionBody extends ConsumerStatefulWidget {
  const NetworkSectionBody({super.key});

  @override
  ConsumerState<NetworkSectionBody> createState() => _NetworkSectionBodyState();
}

class _NetworkSectionBodyState extends ConsumerState<NetworkSectionBody> {
  final TextEditingController _urlController = TextEditingController();
  bool _urlSeeded = false;
  bool _showUrlError = false;
  bool _testing = false;
  List<ProxyProbeResult> _results = const [];

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _selectMode(ProxyMode mode) async {
    setState(() => _showUrlError = false);
    final saved = ref.read(networkProxySettingsProvider).asData?.value;
    final url = saved?.url.isNotEmpty == true
        ? saved!.url
        : _urlController.text.trim();
    await ref
        .read(networkProxySettingsProvider.notifier)
        .save(ProxyConfig(mode: mode, url: url));
  }

  Future<void> _saveManual(AppLocalizations l10n) async {
    final url = _urlController.text.trim();
    if (parseManualProxyUrl(url) == null) {
      setState(() => _showUrlError = true);
      return;
    }
    setState(() => _showUrlError = false);
    await ref
        .read(networkProxySettingsProvider.notifier)
        .save(ProxyConfig(mode: ProxyMode.manual, url: url));
    if (mounted) AppNotice.success(context, l10n.settingsNetworkProxySaved);
  }

  Future<void> _runTest(AppLocalizations l10n) async {
    setState(() {
      _testing = true;
      _results = const [];
    });
    try {
      final apiBase = await ref.read(apiBaseUrlProvider.future);
      final results = await probeConnectivity(
        coordinator: ref.read(systemProxyCoordinatorProvider),
        targets: [
          ProxyProbeTarget(
            label: l10n.settingsNetworkTestApi,
            uri: Uri.parse(apiBase),
          ),
          ProxyProbeTarget(
            label: l10n.settingsNetworkTestYoutube,
            uri: Uri.parse(_kYoutubeProbeUrl),
          ),
        ],
      );
      if (mounted) setState(() => _results = results);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  String _effectiveLabel(AppLocalizations l10n, ResolvedProxy resolved) {
    final endpoint = resolved.http ?? resolved.https;
    if (endpoint == null) return l10n.settingsNetworkEffectiveDirect;
    return l10n.settingsNetworkEffectiveProxy(
      endpoint.toString(),
      resolved.source,
    );
  }

  String _resultLabel(AppLocalizations l10n, ProxyProbeResult r) {
    final route = r.route == 'DIRECT' ? 'DIRECT' : r.route.substring(6);
    return r.reachable
        ? l10n.settingsNetworkTestOk(r.label, r.elapsed.inMilliseconds, route)
        : l10n.settingsNetworkTestFail(r.label, route, r.error ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final coordinator = ref.watch(systemProxyCoordinatorProvider);
    final saved = ref.watch(networkProxySettingsProvider).asData?.value;
    if (saved != null && !_urlSeeded) {
      _urlSeeded = true;
      _urlController.text = saved.url;
    }
    final mode = saved?.mode ?? ProxyMode.system;
    final padding = EdgeInsets.symmetric(
      horizontal: kSettingsRowHorizontalPadding,
      vertical: t.space12,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.settingsNetworkProxyModeTitle,
                style: tt.titleMedium?.copyWith(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: t.space4),
              Text(
                l10n.settingsNetworkProxyModeHint,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              SizedBox(height: t.space12),
              EnjoySegmentedControl<ProxyMode>(
                expand: true,
                segments: [
                  EnjoySegment(
                    value: ProxyMode.system,
                    label: l10n.settingsNetworkProxyModeSystem,
                  ),
                  EnjoySegment(
                    value: ProxyMode.manual,
                    label: l10n.settingsNetworkProxyModeManual,
                  ),
                  EnjoySegment(
                    value: ProxyMode.direct,
                    label: l10n.settingsNetworkProxyModeDirect,
                  ),
                ],
                value: mode,
                onChanged: _selectMode,
              ),
              if (mode == ProxyMode.manual) ...[
                SizedBox(height: t.space12),
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: l10n.settingsNetworkProxyUrlLabel,
                    hintText: l10n.settingsNetworkProxyUrlHint,
                    errorText: _showUrlError
                        ? l10n.settingsNetworkProxyUrlInvalid
                        : null,
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  onSubmitted: (_) => _saveManual(l10n),
                ),
                SizedBox(height: t.space12),
                FilledButton(
                  onPressed: () => _saveManual(l10n),
                  child: Text(l10n.settingsNetworkProxySave),
                ),
              ],
            ],
          ),
        ),
        const SettingsRowDivider(),
        ValueListenableBuilder<ResolvedProxy>(
          valueListenable: coordinator.resolved,
          builder: (context, resolved, _) => SettingsRow(
            leadingIcon: EnjoyIcons.server,
            title: l10n.settingsNetworkEffectiveTitle,
            subtitle: _effectiveLabel(l10n, resolved),
            showChevron: false,
          ),
        ),
        const SettingsRowDivider(),
        Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton(
                onPressed: _testing ? null : () => _runTest(l10n),
                child: _testing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const LoadingIcon(size: 20),
                          SizedBox(width: t.space8),
                          Text(l10n.settingsNetworkTestRunning),
                        ],
                      )
                    : Text(l10n.settingsNetworkTestButton),
              ),
              for (final r in _results) ...[
                SizedBox(height: t.space8),
                Text(
                  _resultLabel(l10n, r),
                  style: tt.bodySmall?.copyWith(
                    color: r.reachable ? cs.onSurfaceVariant : cs.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
