/// Shared Drift column mixins for sync / audit metadata.
library;

import 'package:drift/drift.dart';

/// Sync status + server/local timestamps used by cloud-synced entities.
///
/// Apply with `class Foo extends Table with SyncMetadataColumns`.
mixin SyncMetadataColumns on Table {
  TextColumn get syncStatus => text().nullable()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Local audit columns for tables that are never cloud-synced.
///
/// Same shape as [SyncMetadataColumns] minus [serverUpdatedAt].
mixin LocalAuditColumns on Table {
  TextColumn get syncStatus => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
