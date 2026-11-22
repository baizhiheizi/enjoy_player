/// Locale-aware amount formatting shared by the unified purchase modal.
library;

import 'package:enjoy_player/core/format/cached_number_format.dart';

/// Formats a USD amount to two decimals, honouring the active locale instead
/// of the locale-blind `toStringAsFixed`.
String formatUsdAmount(num amount) => cachedNumberFormat('0.00').format(amount);
