/// Locale-aware amount formatting shared by the unified purchase modal.
library;

import 'package:intl/intl.dart';

/// Formats a USD amount to two decimals, honouring the active locale instead
/// of the locale-blind `toStringAsFixed`.
String formatUsdAmount(num amount) => NumberFormat('0.00').format(amount);
