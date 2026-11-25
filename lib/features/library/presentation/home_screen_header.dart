part of 'home_screen.dart';

/// Home editorial header — a time-of-day greeting under a date overline,
/// with the Craft + Import actions (icon-only on narrow panes). Shared by the
/// loaded and loading scroll views so both stay in sync.
class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? l10n.homeGreetingMorning
        : now.hour < 18
        ? l10n.homeGreetingAfternoon
        : l10n.homeGreetingEvening;
    final name = ref.watch(
      authCtrlProvider.select(
        (a) => a.maybeWhen(
          data: (s) => s is AuthSignedIn ? s.profile.name.trim() : null,
          orElse: () => null,
        ),
      ),
    );
    final firstName = (name == null || name.isEmpty)
        ? null
        : name.split(_homeNameWhitespaceRegExp).first;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return EditorialHeader(
      widthMode: EditorialHeaderWidthMode.browse,
      overline: cachedDateFormat('MMMMEEEEd', locale).format(now),
      title: firstName == null
          ? greeting
          : l10n.homeGreetingNamed(greeting, firstName),
      trailing: _HomeHeaderActions(
        onCraft: () => context.push('/craft'),
        onImport: (anchor) => showImportChooser(context, ref, anchor: anchor),
      ),
    );
  }
}

final RegExp _homeNameWhitespaceRegExp = RegExp(r'\s+');

/// Home header trailing actions — Craft entry + Import.
class _HomeHeaderActions extends ConsumerWidget {
  const _HomeHeaderActions({required this.onCraft, required this.onImport});

  final VoidCallback onCraft;
  final void Function(BuildContext? anchor) onImport;

  void _act(WidgetRef ref, OnboardingTipId tip, VoidCallback action) {
    unawaited(
      ref.read(onboardingControllerProvider.notifier).onTargetActed(tip),
    );
    action();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final narrow = MediaQuery.sizeOf(context).width < t.breakpointCompact;
    void craft() => _act(ref, OnboardingTipId.homeCraft, onCraft);
    void import(BuildContext anchor) =>
        _act(ref, OnboardingTipId.homeImport, () => onImport(anchor));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OnboardingTarget(
          tipId: OnboardingTipId.homeCraft,
          onTargetAction: onCraft,
          child: narrow
              ? EnjoyIconButton(
                  icon: EnjoyIcons.pencil,
                  tooltip: l10n.homeCraftAction,
                  onPressed: craft,
                )
              : EnjoyButton.secondary(
                  icon: EnjoyIcons.pencil,
                  onPressed: craft,
                  child: Text(l10n.homeCraftAction),
                ),
        ),
        SizedBox(width: t.space8),
        OnboardingTarget(
          tipId: OnboardingTipId.homeImport,
          onTargetAction: () => onImport(null),
          child: Builder(
            builder: (anchor) => narrow
                ? EnjoyIconButton(
                    icon: EnjoyIcons.add,
                    tooltip: l10n.actionImport,
                    variant: EnjoyButtonVariant.brand,
                    onPressed: () => import(anchor),
                  )
                : EnjoyButton.brand(
                    icon: EnjoyIcons.add,
                    onPressed: () => import(anchor),
                    child: Text(l10n.actionImport),
                  ),
          ),
        ),
      ],
    );
  }
}
