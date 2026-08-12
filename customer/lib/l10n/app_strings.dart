import 'package:flutter/widgets.dart';
import 'package:la_favola/l10n/generated/app_localizations.dart';
import 'package:la_favola/l10n/generated/app_localizations_it.dart';

/// Returns generated localizations in the application and an Italian fallback
/// for isolated component tests that intentionally omit MaterialApp delegates.
AppLocalizations appStrings(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    AppLocalizationsIt();
