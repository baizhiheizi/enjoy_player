/// Billing interval for the catalog's price toggle, plus the wire-format
/// translation shared by the catalog cards and the unified purchase sheet.
///
/// Lives in its own leaf module so the catalog cards can depend on the
/// interval vocabulary without importing the [TierCatalog] hub that composes
/// them — see [`tier_catalog.dart`](tier_catalog.dart), which re-exports
/// this library to keep its importable surface unchanged.
library;

/// Billing interval for the catalog's price toggle.
enum CatalogInterval { month, year }

CatalogInterval _intervalFromString(String s) =>
    s == 'year' ? CatalogInterval.year : CatalogInterval.month;

String _intervalToString(CatalogInterval interval) =>
    interval == CatalogInterval.year ? 'year' : 'month';

/// Public helper so callers (e.g. the unified purchase modal) can translate
/// the catalog's [CatalogInterval] into the wire-format string the backend
/// expects (`month` / `year`).
String catalogIntervalWire(CatalogInterval interval) =>
    _intervalToString(interval);

/// Translates a plan's `interval` string into a [CatalogInterval].
CatalogInterval catalogIntervalFromString(String? interval) =>
    _intervalFromString(interval ?? 'month');
