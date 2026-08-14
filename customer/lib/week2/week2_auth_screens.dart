import 'package:flutter/material.dart';
import 'package:la_favola/l10n/app_strings.dart';
import 'package:la_favola/l10n/locale_scope.dart';
import 'package:la_favola/week2/week2_models.dart';
import 'package:la_favola/week2/week2_theme.dart';
import 'package:la_favola/week2/week2_widgets.dart';

typedef Week2SignedIn = void Function(CustomerSession session);

final class SignInScreen extends StatefulWidget {
  const SignInScreen({
    required this.gateway,
    required this.onSignedIn,
    required this.onOpenRegistration,
    required this.onOpenVerification,
    required this.onOpenRecovery,
    required this.onOpenProvider,
    required this.onOpenPublicMenu,
    super.key,
    this.sessionNotice,
  });

  final Week2Gateway gateway;
  final Week2SignedIn onSignedIn;
  final VoidCallback onOpenRegistration;
  final VoidCallback onOpenVerification;
  final VoidCallback onOpenRecovery;
  final ValueChanged<String> onOpenProvider;
  final VoidCallback onOpenPublicMenu;
  final String? sessionNotice;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

final class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _busy = false;
  String? _emailError;
  String? _passwordError;
  Week2Failure? _failure;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final strings = appStrings(context);
    final email = _email.text.trim();
    final password = _password.text;
    final emailError = _validEmail(email) ? null : strings.validEmailError;
    final passwordError =
        password.length >= 8 ? null : strings.passwordMinError;
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _failure = null;
    });
    if (emailError != null || passwordError != null) {
      (emailError != null ? _emailFocus : _passwordFocus).requestFocus();
      return;
    }
    setState(() => _busy = true);
    try {
      final session = await widget.gateway.login(
        email: email,
        password: password,
      );
      _password.clear();
      if (mounted) widget.onSignedIn(session);
    } on Week2Failure catch (failure) {
      if (mounted) {
        setState(() {
          _failure = failure;
          _emailError = failure.fieldErrors['email'];
          _passwordError = failure.fieldErrors['password'];
        });
        if (_emailError != null) {
          _emailFocus.requestFocus();
        } else if (_passwordError != null) {
          _passwordFocus.requestFocus();
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    return Scaffold(
      body: Week2Page(
        title: strings.signIn,
        subtitle: strings.signInSubtitle,
        actions: const [LanguageMenuButton()],
        maxWidth: 720,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.sessionNotice != null) ...[
                const SizedBox(height: 16),
                Week2StatePanel(
                  title: strings.sessionUnavailable,
                  message: widget.sessionNotice!,
                  kind: Week2FailureKind.sessionExpired,
                ),
              ],
              if (_failure != null) ...[
                const SizedBox(height: 16),
                Week2StatePanel.failure(_failure!, onRetry: _submit),
              ],
              const SizedBox(height: 24),
              TextField(
                key: const Key('sign-in-email'),
                controller: _email,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _passwordFocus.requestFocus(),
                decoration: InputDecoration(
                  labelText: strings.email,
                  errorText: _emailError,
                ),
              ),
              const SizedBox(height: 16),
              PasswordField(
                key: const Key('sign-in-password'),
                controller: _password,
                focusNode: _passwordFocus,
                label: strings.password,
                errorText: _passwordError,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                key: const Key('sign-in-submit'),
                onPressed: _busy ? null : _submit,
                icon:
                    _busy
                        ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.login),
                label: Text(_busy ? strings.signingIn : strings.signIn),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : widget.onOpenRecovery,
                child: Text(strings.forgotPassword),
              ),
              const SizedBox(height: 16),
              if (widget.gateway.configuredFederatedProviders.isNotEmpty) ...[
                Semantics(
                  header: true,
                  child: Text(
                    strings.otherSignInMethods,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (widget.gateway.configuredFederatedProviders.contains(
                      'google',
                    ))
                      OutlinedButton.icon(
                        onPressed:
                            _busy
                                ? null
                                : () => widget.onOpenProvider('google'),
                        icon: const Icon(Icons.account_circle_outlined),
                        label: Text(strings.continueGoogle),
                      ),
                    if (widget.gateway.configuredFederatedProviders.contains(
                      'apple',
                    ))
                      OutlinedButton.icon(
                        onPressed:
                            _busy ? null : () => widget.onOpenProvider('apple'),
                        icon: const Icon(Icons.phone_iphone),
                        label: Text(strings.continueApple),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Container(
                decoration: BoxDecoration(
                  color: Week2Colors.primaryAction.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Week2Colors.primaryAction.withValues(alpha: 0.25),
                  ),
                ),
                child: ListTile(
                  key: const Key('open-public-menu'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Week2Colors.primaryAction,
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    strings.continueGuest,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Week2Colors.primaryText,
                    ),
                  ),
                  subtitle: Text(
                    strings.guestSubtitle,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Week2Colors.primaryAction,
                  ),
                  onTap: _busy ? null : widget.onOpenPublicMenu,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _busy ? null : widget.onOpenRegistration,
                child: Text(strings.createAccount),
              ),
              TextButton(
                onPressed: _busy ? null : widget.onOpenVerification,
                child: Text(strings.haveVerificationCode),
              ),
              const SizedBox(height: 16),
              Text(strings.publicAccountNotice),
            ],
          ),
        ),
      ),
    );
  }
}

final class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({
    required this.gateway,
    required this.onRegistrationCompleted,
    super.key,
  });

  final Week2Gateway gateway;
  final VoidCallback onRegistrationCompleted;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

final class _RegistrationScreenState extends State<RegistrationScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmationFocus = FocusNode();
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmationError;
  bool _busy = false;
  bool _success = false;
  Week2Failure? _failure;
  String? _summary;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmationFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final strings = appStrings(context);
    final name = _name.text.trim();
    final email = _email.text.trim();
    final nameError =
        name.isEmpty || name.runes.length > 100 ? strings.nameValidation : null;
    final emailError = _validEmail(email) ? null : strings.validEmailError;
    final passwordError =
        _password.text.length < 8 || _password.text.length > 72
            ? strings.passwordRangeError
            : null;
    final confirmationError =
        _password.text == _confirmation.text
            ? null
            : strings.passwordMismatchError;
    final issues = [
      nameError,
      emailError,
      passwordError,
      confirmationError,
    ].whereType<String>().toList(growable: false);
    setState(() {
      _nameError = nameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmationError = confirmationError;
      _summary = issues.isEmpty ? null : issues.join(' ');
      _failure = null;
      _success = false;
    });
    final firstInvalid =
        nameError != null
            ? _nameFocus
            : emailError != null
            ? _emailFocus
            : passwordError != null
            ? _passwordFocus
            : confirmationError != null
            ? _confirmationFocus
            : null;
    if (firstInvalid != null) {
      firstInvalid.requestFocus();
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.gateway.register(
        displayName: name,
        email: email,
        password: _password.text,
      );
      _password.clear();
      _confirmation.clear();
      if (mounted) setState(() => _success = true);
    } on Week2Failure catch (failure) {
      if (mounted) {
        setState(() {
          _failure = failure;
          _nameError = failure.fieldErrors['displayName'];
          _emailError = failure.fieldErrors['email'];
          _passwordError = failure.fieldErrors['password'];
        });
        if (_nameError != null) {
          _nameFocus.requestFocus();
        } else if (_emailError != null) {
          _emailFocus.requestFocus();
        } else if (_passwordError != null) {
          _passwordFocus.requestFocus();
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.registration)),
      body: Week2Page(
        title: strings.createAccount,
        subtitle: strings.registrationSubtitle,
        maxWidth: 720,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_summary != null) ...[
                const SizedBox(height: 16),
                Week2StatePanel(
                  title: strings.fixFields,
                  message: _summary!,
                  kind: Week2FailureKind.validation,
                ),
              ],
              if (_failure != null) ...[
                const SizedBox(height: 16),
                Week2StatePanel.failure(_failure!, onRetry: _submit),
              ],
              if (_success) ...[
                const SizedBox(height: 16),
                Week2SuccessPanel(
                  title: strings.registrationCompleted,
                  message: strings.registrationCompletedMessage,
                ),
              ],
              const SizedBox(height: 24),
              TextField(
                controller: _name,
                focusNode: _nameFocus,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: strings.name,
                  errorText: _nameError,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _email,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: strings.email,
                  errorText: _emailError,
                ),
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _password,
                focusNode: _passwordFocus,
                label: strings.password,
                errorText: _passwordError,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              Text(strings.passwordRequirements),
              const SizedBox(height: 16),
              PasswordField(
                controller: _confirmation,
                focusNode: _confirmationFocus,
                label: strings.confirmPassword,
                errorText: _confirmationError,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              Week2StatePanel(
                title: strings.termsTitle,
                message: strings.termsMessage,
                kind: Week2FailureKind.dependencyUnavailable,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: Text(
                  _busy ? strings.creatingAccount : strings.createAccount,
                ),
              ),
              if (_success) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: widget.onRegistrationCompleted,
                  child: Text(strings.goToSignIn),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final class VerificationScreen extends StatefulWidget {
  const VerificationScreen({required this.gateway, super.key});

  final Week2Gateway gateway;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

final class _VerificationScreenState extends State<VerificationScreen> {
  final _token = TextEditingController();
  final _email = TextEditingController();
  final _tokenFocus = FocusNode();
  final _emailFocus = FocusNode();
  String? _tokenError;
  String? _emailError;
  Future<void> Function()? _retryAction;
  String? _retryResult;
  bool _busy = false;
  String? _result;
  Week2Failure? _failure;

  @override
  void dispose() {
    _token.dispose();
    _email.dispose();
    _tokenFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final strings = appStrings(context);
    if (!RegExp(r'^\d{6}$').hasMatch(_token.text.trim())) {
      setState(() {
        _tokenError = strings.verificationCodeMinError;
        _failure = Week2Failure(
          kind: Week2FailureKind.validation,
          message: strings.verificationCodeMinError,
          correlationId: 'lf-mobile-local',
        );
      });
      _tokenFocus.requestFocus();
      return;
    }
    await _run(
      () => widget.gateway.verifyEmail(_token.text.trim()),
      strings.emailVerifiedSuccess,
    );
  }

  Future<void> _resend() async {
    final strings = appStrings(context);
    if (!_validEmail(_email.text.trim())) {
      setState(() {
        _emailError = strings.validEmailError;
        _failure = Week2Failure(
          kind: Week2FailureKind.validation,
          message: strings.validEmailError,
          correlationId: 'lf-mobile-local',
        );
      });
      _emailFocus.requestFocus();
      return;
    }
    await _run(
      () => widget.gateway.resendVerification(_email.text.trim()),
      strings.resendVerificationAccepted,
    );
  }

  Future<void> _run(Future<void> Function() action, String result) async {
    _retryAction = action;
    _retryResult = result;
    setState(() {
      _busy = true;
      _tokenError = null;
      _emailError = null;
      _failure = null;
      _result = null;
    });
    try {
      await action();
      if (mounted) setState(() => _result = result);
    } on Week2Failure catch (failure) {
      if (mounted) {
        setState(() {
          _failure = failure;
          _tokenError = failure.fieldErrors['token'];
          _emailError = failure.fieldErrors['email'];
        });
        if (_tokenError != null) {
          _tokenFocus.requestFocus();
        }
        if (_tokenError == null && _emailError != null) {
          _emailFocus.requestFocus();
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.verifyEmail)),
      body: Week2Page(
        title: strings.verifyEmail,
        subtitle: strings.verifyEmailSubtitle,
        maxWidth: 720,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_failure != null) ...[
              const SizedBox(height: 16),
              Week2StatePanel.failure(
                _failure!,
                onRetry:
                    _retryAction == null
                        ? null
                        : () => _run(_retryAction!, _retryResult!),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              Week2SuccessPanel(
                title: strings.verificationResult,
                message: _result!,
              ),
            ],
            const SizedBox(height: 24),
            TextField(
              controller: _token,
              focusNode: _tokenFocus,
              autofillHints: const [AutofillHints.oneTimeCode],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _verify(),
              decoration: InputDecoration(
                labelText: strings.verificationCode,
                errorText: _tokenError,
                helperText: strings.oneTimeCodeHelp,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _verify,
              child: Text(_busy ? strings.verifying : strings.verify),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _email,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: strings.resendEmail,
                errorText: _emailError,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy ? null : _resend,
              child: Text(strings.resend),
            ),
          ],
        ),
      ),
    );
  }
}

final class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({required this.gateway, super.key});

  final Week2Gateway gateway;

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

final class _RecoveryScreenState extends State<RecoveryScreen> {
  final _email = TextEditingController();
  final _token = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _tokenFocus = FocusNode();
  final _passwordFocus = FocusNode();
  String? _emailError;
  String? _tokenError;
  String? _passwordError;
  Future<void> Function()? _retryAction;
  String? _retryResult;
  bool _busy = false;
  String? _result;
  Week2Failure? _failure;

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _tokenFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    final strings = appStrings(context);
    if (!_validEmail(_email.text.trim())) {
      _emailError = strings.validEmailError;
      setState(
        () =>
            _failure = Week2Failure(
              kind: Week2FailureKind.validation,
              message: strings.validEmailError,
              correlationId: 'lf-mobile-local',
            ),
      );
      _emailFocus.requestFocus();
      return;
    }
    await _run(
      () => widget.gateway.requestPasswordRecovery(_email.text.trim()),
      strings.recoveryAccepted,
    );
  }

  Future<void> _reset() async {
    final strings = appStrings(context);
    if (!RegExp(r'^\d{6}$').hasMatch(_token.text.trim()) ||
        _password.text.length < 8) {
      _tokenError = !RegExp(r'^\d{6}$').hasMatch(_token.text.trim())
          ? strings.resetTokenMinError
          : null;
      _passwordError =
          _password.text.length < 8 ? strings.passwordMinError : null;
      setState(
        () =>
            _failure = Week2Failure(
              kind: Week2FailureKind.validation,
              message: strings.resetValidationError,
              correlationId: 'lf-mobile-local',
            ),
      );
      (_tokenError != null ? _tokenFocus : _passwordFocus).requestFocus();
      return;
    }
    await _run(
      () => widget.gateway.resetPassword(
        code: _token.text.trim(),
        password: _password.text,
      ),
      strings.passwordResetSuccess,
    );
    if (_result != null) _password.clear();
  }

  Future<void> _run(Future<void> Function() action, String result) async {
    _retryAction = action;
    _retryResult = result;
    setState(() {
      _busy = true;
      _emailError = null;
      _tokenError = null;
      _passwordError = null;
      _failure = null;
      _result = null;
    });
    try {
      await action();
      if (mounted) setState(() => _result = result);
    } on Week2Failure catch (failure) {
      if (mounted) {
        setState(() {
          _failure = failure;
          _emailError = failure.fieldErrors['email'];
          _tokenError = failure.fieldErrors['token'];
          _passwordError = failure.fieldErrors['password'];
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    final mode = week2LayoutMode(MediaQuery.sizeOf(context).width);
    final cards = [
      Week2SectionCard(
        title: strings.requestRecoveryStep,
        subtitle: strings.requestRecoveryHelp,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _email,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: strings.email,
                errorText: _emailError,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _busy ? null : _request,
              child: Text(strings.requestRecovery),
            ),
          ],
        ),
      ),
      Week2SectionCard(
        title: strings.resetPasswordStep,
        subtitle: strings.resetPasswordHelp,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _token,
              focusNode: _tokenFocus,
              autofillHints: const [AutofillHints.oneTimeCode],
              decoration: InputDecoration(
                labelText: strings.resetCode,
                errorText: _tokenError,
              ),
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _password,
              focusNode: _passwordFocus,
              label: strings.newPassword,
              errorText: _passwordError,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _reset(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _busy ? null : _reset,
              child: Text(strings.updatePassword),
            ),
          ],
        ),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(strings.passwordRecovery)),
      body: Week2Page(
        title: strings.recoveryTitle,
        subtitle: strings.recoverySubtitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_failure != null) ...[
              const SizedBox(height: 16),
              Week2StatePanel.failure(
                _failure!,
                onRetry:
                    _retryAction == null
                        ? null
                        : () => _run(_retryAction!, _retryResult!),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              Week2SuccessPanel(
                title: strings.operationCompleted,
                message: _result!,
              ),
            ],
            const SizedBox(height: 20),
            if (mode == Week2LayoutMode.compact)
              ...cards.expand((card) => [card, const SizedBox(height: 16)])
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[1]),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

final class ProviderReturnScreen extends StatefulWidget {
  const ProviderReturnScreen({
    required this.gateway,
    required this.provider,
    required this.onSignedIn,
    super.key,
  });

  final Week2Gateway gateway;
  final String provider;
  final Week2SignedIn onSignedIn;

  @override
  State<ProviderReturnScreen> createState() => _ProviderReturnScreenState();
}

final class _ProviderReturnScreenState extends State<ProviderReturnScreen> {
  ProviderIntent? _intent;
  bool _busy = false;
  Week2Failure? _failure;

  Future<void> _begin() async {
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final intent = await widget.gateway.startFederated(widget.provider);
      if (mounted) setState(() => _intent = intent);
    } on Week2Failure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    final providerLabel = widget.provider == 'apple' ? 'Apple' : 'Google';
    final configured = widget.gateway.configuredFederatedProviders.contains(
      widget.provider,
    );
    return Scaffold(
      appBar: AppBar(title: Text(strings.providerSignIn(providerLabel))),
      body: Week2Page(
        title: strings.providerSignIn(providerLabel),
        subtitle: strings.providerSubtitle,
        maxWidth: 720,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_failure != null) ...[
              Week2StatePanel.failure(_failure!, onRetry: _begin),
              const SizedBox(height: 20),
            ],
            if (!configured)
              Week2StatePanel(
                title: strings.providerNotConfigured,
                message: strings.providerNotConfiguredMessage,
                kind: Week2FailureKind.providerUnavailable,
              )
            else if (_intent == null)
              Week2SectionCard(
                title: strings.startSecureSignIn,
                subtitle: strings.startSecureSignInHelp,
                child: ElevatedButton(
                  onPressed: _busy ? null : _begin,
                  child: Text(
                    _busy ? strings.preparing : strings.continueAction,
                  ),
                ),
              )
            else
              Week2StatePanel(
                title: strings.waitingProvider,
                message: strings.waitingProviderMessage,
                kind: Week2FailureKind.providerUnavailable,
              ),
          ],
        ),
      ),
    );
  }
}

bool _validEmail(String value) {
  return RegExp(
    r"^(?!\.)(?!.*\.\.)([A-Za-z0-9_'+\-\.]*)[A-Za-z0-9_+-]@([A-Za-z0-9][A-Za-z0-9\-]*\.)+[A-Za-z]{2,}$",
  ).hasMatch(value);
}
