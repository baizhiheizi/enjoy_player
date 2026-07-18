/// Adaptive page scaffold — chrome + width family for shell content.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_subpage_app_bar.dart';

typedef EnjoyPageBodyBuilder =
    Widget Function(BuildContext context, EnjoyPageMetrics metrics);

/// Scaffold that applies [EnjoyPageKind] width rules and optional page chrome.
///
/// - Primary / hub with [editorialHeader]: large [EditorialHeader].
/// - Push routes with [title] + [showBack]: [EnjoySubpageAppBar].
/// - Body receives [EnjoyPageMetrics] for gutters / centering insets.
class EnjoyPage extends StatelessWidget {
  const EnjoyPage({
    super.key,
    required this.kind,
    required this.body,
    this.title,
    this.subtitle,
    this.titleAccessory,
    this.trailing,
    this.actions,
    this.showBack = false,
    this.onBack,
    this.editorialHeader = false,
    this.editorialCompact = false,
    this.backgroundColor,
    this.floatingActionButton,
    this.extendBody = false,
  });

  final EnjoyPageKind kind;
  final EnjoyPageBodyBuilder body;

  /// Subpage / app-bar title (also used when [editorialHeader] is true).
  final String? title;
  final String? subtitle;
  final Widget? titleAccessory;
  final Widget? trailing;
  final List<Widget>? actions;

  /// When true, shows [EnjoySubpageAppBar] with a back affordance.
  final bool showBack;

  /// Optional custom back handler for [EnjoySubpageAppBar].
  final VoidCallback? onBack;

  /// When true, shows [EditorialHeader] above the body (primary tabs / Settings).
  final bool editorialHeader;

  final bool editorialCompact;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    final PreferredSizeWidget? appBar = showBack && title != null
        ? EnjoySubpageAppBar(title: title!, actions: actions, onBack: onBack)
        : null;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      extendBody: extendBody,
      floatingActionButton: floatingActionButton,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = EnjoyPageMetrics.of(
            context,
            kind: kind,
            paneWidth: constraints.maxWidth,
          );

          final built = body(context, metrics);

          // Embed header above body for simple (non-sliver) hub pages.
          // Browse screens keep [EditorialHeader] inside their scroll views.
          if (!editorialHeader || title == null) {
            return built;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EditorialHeader(
                title: title!,
                subtitle: subtitle,
                titleAccessory: titleAccessory,
                trailing: trailing ?? _actionsAsTrailing(actions),
                compact: editorialCompact,
                widthMode: kind == EnjoyPageKind.browse
                    ? EditorialHeaderWidthMode.gutter
                    : EditorialHeaderWidthMode.column,
                columnMaxWidth: metrics.maxWidth,
              ),
              Expanded(child: built),
            ],
          );
        },
      ),
    );
  }

  static Widget? _actionsAsTrailing(List<Widget>? actions) {
    if (actions == null || actions.isEmpty) return null;
    if (actions.length == 1) return actions.first;
    return Row(mainAxisSize: MainAxisSize.min, children: actions);
  }
}
