import 'package:flutter/material.dart';
import 'package:la_favola/l10n/app_strings.dart';

final class LocaleScope extends InheritedWidget {
  const LocaleScope({
    required this.locale,
    required this.onChanged,
    required super.child,
    super.key,
  });

  final Locale locale;
  final ValueChanged<Locale> onChanged;

  static LocaleScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope is missing above this context.');
    return scope!;
  }

  static LocaleScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocaleScope>();

  @override
  bool updateShouldNotify(LocaleScope oldWidget) => locale != oldWidget.locale;
}

final class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    final scope = LocaleScope.maybeOf(context);
    final locale = scope?.locale ?? Localizations.localeOf(context);
    return PopupMenuButton<String>(
      tooltip: strings.language,
      icon: const Icon(Icons.language_rounded),
      initialValue: locale.languageCode,
      onSelected:
          scope == null
              ? null
              : (value) => scope.onChanged(
                value == 'it' ? const Locale('it', 'IT') : const Locale('en'),
              ),
      itemBuilder:
          (context) => [
            PopupMenuItem(value: 'it', child: Text(strings.italian)),
            PopupMenuItem(value: 'en', child: Text(strings.english)),
          ],
    );
  }
}
