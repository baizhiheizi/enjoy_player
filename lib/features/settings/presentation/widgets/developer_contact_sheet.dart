/// Bottom sheet listing developer contact channels — tap any row to copy.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:enjoy_player/core/application/app_links.dart';
import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/theme/widgets/sheet_drag_handle.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Opens the developer contact sheet (Email / WeChat / Mixin, tap to copy).
Future<void> showDeveloperContactSheet(BuildContext context) {
  return showEnjoySheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      final t = EnjoyThemeTokens.of(ctx);
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: t.space8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PaddedSheetDragHandle(),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  t.space20,
                  t.space4,
                  t.space20,
                  t.space4,
                ),
                child: Text(
                  l10n.settingsAboutContactTitle,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  t.space20,
                  0,
                  t.space20,
                  t.space12,
                ),
                child: Text(
                  l10n.settingsAboutContactSubtitle,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              _ContactCopyRow(
                icon: EnjoyIcons.mail,
                label: l10n.settingsAboutContactEmailLabel,
                value: kDeveloperContactEmail,
                successMessage: l10n.settingsAboutContactCopiedEmail,
              ),
              _ContactCopyRow(
                icon: EnjoyIcons.chat,
                label: l10n.settingsAboutContactWeChatLabel,
                value: kDeveloperContactWeChatId,
                successMessage: l10n.settingsAboutContactCopiedWeChat,
              ),
              _ContactCopyRow(
                icon: EnjoyIcons.tag,
                label: l10n.settingsAboutContactMixinLabel,
                value: kDeveloperContactMixinId,
                successMessage: l10n.settingsAboutContactCopiedMixin,
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// One tappable "label / value" row that copies [value] to the clipboard.
class _ContactCopyRow extends StatelessWidget {
  const _ContactCopyRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.successMessage,
  });

  final IconData icon;
  final String label;
  final String value;
  final String successMessage;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    AppNotice.success(context, successMessage);
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: Haptics.wrapTap(context, () => _copy(context)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: t.space20,
            vertical: t.space12,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: cs.primary.withValues(alpha: 0.92)),
              SizedBox(width: t.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: t.space4),
                    Text(
                      value,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.86),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                EnjoyIcons.copy,
                size: 18,
                color: cs.onSurfaceVariant.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
