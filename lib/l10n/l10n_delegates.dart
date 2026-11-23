/// Localization delegates matching the material_ui widget tree.
library;

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalCupertinoLocalizations, GlobalMaterialLocalizations;
import 'package:material_ui/material_ui.dart' show GlobalMaterialLocalizations;

import 'app_localizations.dart';

/// Delegates for [MaterialApp.localizationsDelegates].
///
/// Use this instead of the gen-l10n output's `localizationsDelegates`: that
/// list binds the pre-3.50 `flutter_localizations` classes whose
/// `MaterialLocalizations` type does not match the material_ui widget tree,
/// so widgets would resolve only the en-only defaults.
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];
