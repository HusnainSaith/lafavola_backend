import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:la_favola_admin/app/providers.dart';
import 'package:la_favola_admin/core/theme/app_theme.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await ref
        .read(sessionControllerProvider.notifier)
        .signIn(_email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final busy = session.status == SessionStatus.signingIn;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.local_pizza_rounded,
                            color: BrandColors.terracotta,
                            size: 52,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'La Favola Admin',
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(
                              fontFamily: 'Lora',
                              color: BrandColors.coffee,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Accesso riservato al personale amministrativo',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          TextFormField(
                            key: const Key('admin-email-field'),
                            controller: _email,
                            focusNode: _emailFocus,
                            enabled: !busy,
                            autofocus: true,
                            autofillHints: const [
                              AutofillHints.username,
                              AutofillHints.email,
                            ],
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted:
                                (_) => _passwordFocus.requestFocus(),
                            decoration: const InputDecoration(
                              labelText: 'Email amministratore',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              final input = value?.trim() ?? '';
                              if (input.isEmpty || !input.contains('@')) {
                                return 'Inserisci un indirizzo email valido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('admin-password-field'),
                            controller: _password,
                            focusNode: _passwordFocus,
                            enabled: !busy,
                            obscureText: _obscure,
                            enableSuggestions: false,
                            autocorrect: false,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip:
                                    _obscure
                                        ? 'Mostra password'
                                        : 'Nascondi password',
                                onPressed:
                                    busy
                                        ? null
                                        : () => setState(
                                          () => _obscure = !_obscure,
                                        ),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator:
                                (value) =>
                                    (value?.isEmpty ?? true)
                                        ? 'Inserisci la password'
                                        : null,
                          ),
                          if (session.message != null) ...[
                            const SizedBox(height: 16),
                            Semantics(
                              liveRegion: true,
                              child: MaterialBanner(
                                content: Text(session.message!),
                                leading: const Icon(
                                  Icons.error_outline,
                                  color: BrandColors.destructive,
                                ),
                                actions: const [SizedBox.shrink()],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            key: const Key('admin-sign-in-button'),
                            onPressed: busy ? null : _submit,
                            icon:
                                busy
                                    ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.login_rounded),
                            label: Text(busy ? 'Accesso in corso…' : 'Accedi'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed:
                                busy
                                    ? null
                                    : () => context.go('/forgot-password'),
                            child: const Text('Password dimenticata?'),
                          ),
                        ],
                      ),
                    ),
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
