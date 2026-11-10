part of 'cloud_library_body.dart';

mixin _CloudInfiniteScroll<W extends ConsumerStatefulWidget>
    on ConsumerState<W> {
  final scroll = ScrollController();

  bool get cloudDone;
  bool get cloudLoading;
  Future<void> Function() get cloudLoadMore;

  @override
  void initState() {
    super.initState();
    scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    scroll.removeListener(_onScroll);
    scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!cloudDone &&
        !cloudLoading &&
        scroll.hasClients &&
        scroll.position.pixels > scroll.position.maxScrollExtent - 200) {
      unawaited(cloudLoadMore());
    }
  }
}

class _CloudEmptyState extends StatelessWidget {
  const _CloudEmptyState({
    required this.onRefresh,
    required this.title,
    required this.subtitle,
  });

  final Future<void> Function() onRefresh;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.55,
          child: EmptyState(title: title, subtitle: subtitle),
        ),
      ),
    );
  }
}

typedef _CloudPageContent =
    Widget Function(
      BuildContext context,
      ScrollController scroll,
      _CloudPagedList page,
    );

class _CloudPagedMedia extends ConsumerStatefulWidget {
  const _CloudPagedMedia({
    required this.page,
    required this.onLoadMore,
    required this.onRefresh,
    required this.skeleton,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.contentBuilder,
  });

  final _CloudPagedList page;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRefresh;
  final Widget skeleton;
  final String emptyTitle;
  final String emptySubtitle;
  final _CloudPageContent contentBuilder;

  @override
  ConsumerState<_CloudPagedMedia> createState() => _CloudPagedMediaState();
}

class _CloudPagedMediaState extends ConsumerState<_CloudPagedMedia>
    with _CloudInfiniteScroll<_CloudPagedMedia> {
  @override
  bool get cloudDone => widget.page.done;

  @override
  bool get cloudLoading => widget.page.loading;

  @override
  Future<void> Function() get cloudLoadMore => widget.onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (widget.page.items.isEmpty && widget.page.loading) {
      return widget.skeleton;
    }

    if (widget.page.items.isEmpty && widget.page.done) {
      return _CloudEmptyState(
        onRefresh: widget.onRefresh,
        title: widget.emptyTitle,
        subtitle: widget.emptySubtitle,
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: widget.contentBuilder(context, scroll, widget.page),
    );
  }
}
