import 'dart:async';

import 'package:flutter/material.dart';
import 'package:la_favola/l10n/app_strings.dart';
import 'package:la_favola/week2/week2_theme.dart';

final class Week2SplashScreen extends StatefulWidget {
  const Week2SplashScreen({required this.onNext, super.key});
  final VoidCallback onNext;
  @override
  State<Week2SplashScreen> createState() => _Week2SplashScreenState();
}

final class _Week2SplashScreenState extends State<Week2SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;
  bool _advanced = false;
  bool _preferenceApplied = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      )
      ..forward().then(
        (_) => _timer = Timer(const Duration(milliseconds: 400), _advance),
      );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_preferenceApplied) return;
    _preferenceApplied = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      _timer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) => _advance());
    }
  }

  void _advance() {
    if (!mounted || _advanced) return;
    _advanced = true;
    widget.onNext();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    return Semantics(
      button: true,
      label: '${strings.appTitle}. ${strings.tapToContinue}',
      child: Material(
        color: Week2Colors.canvas,
        child: InkWell(
          onTap: _advance,
          canRequestFocus: true,
          child: SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeOut,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo_transparent.png',
                        width: 220,
                        errorBuilder:
                            (_, __, ___) => Text(
                              strings.appTitle,
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        strings.appTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          fontFamily: 'Lora',
                          color: Week2Colors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Week2Colors.primaryAction,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(strings.tapToContinue, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
