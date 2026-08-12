import 'package:flutter/material.dart';
import 'package:la_favola/l10n/app_strings.dart';
import 'package:la_favola/week2/week2_models.dart';
import 'package:la_favola/week2/week2_theme.dart';

enum Week2LayoutMode { compact, medium, expanded }

Week2LayoutMode week2LayoutMode(double width) {
  if (width < 600) return Week2LayoutMode.compact;
  if (width < 1024) return Week2LayoutMode.medium;
  return Week2LayoutMode.expanded;
}

final class Week2Page extends StatelessWidget {
  const Week2Page({
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
    this.actions = const [],
    this.maxWidth = 1120,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          key: const Key('week2-page-heading'),
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Week2Colors.secondaryText),
                        ),
                      ],
                      if (actions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(spacing: 12, runSpacing: 12, children: actions),
                      ],
                      const SizedBox(height: 24),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class Week2StatePanel extends StatelessWidget {
  const Week2StatePanel({
    required this.title,
    required this.message,
    super.key,
    this.kind = Week2FailureKind.dependencyUnavailable,
    this.correlationId,
    this.onRetry,
  });

  factory Week2StatePanel.failure(
    Week2Failure failure, {
    VoidCallback? onRetry,
    Key? key,
  }) {
    return Week2StatePanel(
      key: key,
      title: '',
      message: failure.message,
      kind: failure.kind,
      correlationId: failure.correlationId,
      onRetry: failure.retryable ? onRetry : null,
    );
  }

  final String title;
  final String message;
  final Week2FailureKind kind;
  final String? correlationId;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    final effectiveTitle = title.isEmpty ? strings.errorTitle : title;
    final destructive =
        kind == Week2FailureKind.validation ||
        kind == Week2FailureKind.forbidden ||
        kind == Week2FailureKind.sessionExpired ||
        kind == Week2FailureKind.sessionRevoked ||
        kind == Week2FailureKind.sessionReuseDetected ||
        kind == Week2FailureKind.providerDenied;
    final color = destructive ? Week2Colors.error : Week2Colors.warning;
    final background =
        destructive ? Week2Colors.errorContainer : Week2Colors.warningContainer;
    return Semantics(
      liveRegion: true,
      container: true,
      label: '$effectiveTitle. $message',
      child: Container(
        key: const Key('week2-state-panel'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  destructive
                      ? Icons.error_outline
                      : Icons.warning_amber_rounded,
                  color: color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    effectiveTitle,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message),
            if (correlationId != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                strings.referenceCode(correlationId!),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(appStrings(context).retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class Week2SuccessPanel extends StatelessWidget {
  const Week2SuccessPanel({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      label: '$title. $message',
      child: Container(
        key: const Key('week2-success-panel'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Week2Colors.successContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Week2Colors.success),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline, color: Week2Colors.success),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Week2Colors.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class Week2Loading extends StatelessWidget {
  const Week2Loading({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      liveRegion: true,
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

final class Week2Empty extends StatelessWidget {
  const Week2Empty({
    required this.title,
    required this.message,
    super.key,
    this.action,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title. $message',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.inbox_outlined, size: 40),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          ),
        ),
      ),
    );
  }
}

final class Week2SectionCard extends StatelessWidget {
  const Week2SectionCard({
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Week2Colors.secondaryText,
                ),
              ),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

final class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.controller,
    required this.label,
    super.key,
    this.errorText,
    this.focusNode,
    this.onSubmitted,
    this.textInputAction,
    this.autofillHints = const [AutofillHints.password],
  });

  final TextEditingController controller;
  final String label;
  final String? errorText;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final Iterable<String> autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

final class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscure,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        suffixIcon: IconButton(
          tooltip:
              _obscure
                  ? appStrings(context).showPassword
                  : appStrings(context).hidePassword,
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
        ),
      ),
    );
  }
}
