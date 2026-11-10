part of 'cloud_library_body.dart';

/// Cursor + loading state for one cloud catalog tab.
class _CloudPagedList {
  final List<RemoteLibraryItem> items = [];
  String? cursor;
  bool loading = false;
  bool done = false;

  Future<void> load({
    required bool reset,
    required bool Function() isMounted,
    required void Function(VoidCallback fn) setState,
    required Future<List<RemoteLibraryItem>> Function(String? cursor) fetch,
  }) async {
    if (loading || done && !reset) return;
    setState(() => loading = true);
    try {
      if (reset) {
        items.clear();
        cursor = null;
        done = false;
      }
      final batch = await fetch(cursor);
      if (!isMounted()) return;
      setState(() {
        items.addAll(batch);
        if (batch.isEmpty) {
          done = true;
        } else {
          cursor = batch.last.rawJson['updatedAt']?.toString();
          if (batch.length < CloudIndexRepository.pageSize) {
            done = true;
          }
        }
      });
    } finally {
      if (isMounted()) setState(() => loading = false);
    }
  }
}
