import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:la_favola/l10n/app_strings.dart';
import 'package:la_favola/l10n/generated/app_localizations.dart';
import 'package:la_favola/week2/week2_models.dart';
import 'package:la_favola/week2/week2_theme.dart';
import 'package:la_favola/week2/week2_widgets.dart';

final class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.gateway, super.key});

  final Week2Gateway gateway;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

final class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  String? _nameError;
  String? _phoneError;
  Future<void> Function()? _retry;
  CustomerProfile? _profile;
  Week2Failure? _failure;
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;
  String? _success;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
      _retry = _load;
    });
    try {
      final profile = await widget.gateway.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _syncFields(profile);
        });
      }
    } on Week2Failure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _syncFields(CustomerProfile profile) {
    _name.text = profile.displayName;
    _phone.text = profile.phone ?? '';
  }

  void _cancel() {
    _syncFields(_profile!);
    setState(() {
      _editing = false;
      _failure = null;
    });
  }

  Future<void> _save() async {
    final strings = appStrings(context);
    final displayName = _name.text.trim();
    final phone = _phone.text.trim();
    if (displayName.isEmpty ||
        displayName.runes.length > 100 ||
        displayName.contains(RegExp(r'[\x00-\x1F]'))) {
      setState(() {
        _nameError = strings.nameValidation;
        _failure = Week2Failure(
          kind: Week2FailureKind.validation,
          message: strings.nameValidation,
          correlationId: 'lf-mobile-local',
        );
      });
      _nameFocus.requestFocus();
      return;
    }
    if (phone.isNotEmpty && !RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(phone)) {
      setState(() {
        _phoneError = strings.phoneValidation;
        _failure = Week2Failure(
          kind: Week2FailureKind.validation,
          message: strings.phoneValidation,
          correlationId: 'lf-mobile-local',
        );
      });
      _phoneFocus.requestFocus();
      return;
    }
    setState(() {
      _saving = true;
      _failure = null;
      _nameError = null;
      _phoneError = null;
      _retry = _save;
      _success = null;
    });
    try {
      final profile = await widget.gateway.updateProfile(
        displayName: displayName,
        phone: phone.isEmpty ? null : phone,
        expectedVersion: _profile!.version,
      );
      if (mounted) {
        setState(() {
          _profile = profile;
          _editing = false;
          _success = strings.profileSavedVersion(profile.version);
        });
      }
    } on Week2Failure catch (failure) {
      if (mounted) {
        setState(() {
          _failure = failure;
          _nameError = failure.fieldErrors['displayName'];
          _phoneError = failure.fieldErrors['phone'];
        });
        if (_nameError != null) {
          _nameFocus.requestFocus();
        }
        if (_nameError == null && _phoneError != null) {
          _phoneFocus.requestFocus();
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    if (_loading) {
      return Week2Page(
        title: strings.profile,
        child: Week2Loading(label: strings.profileLoading),
      );
    }
    if (_profile == null) {
      return Week2Page(
        title: strings.profile,
        child: Week2StatePanel.failure(_failure!, onRetry: _retry),
      );
    }
    final mode = week2LayoutMode(MediaQuery.sizeOf(context).width);
    final form = Week2SectionCard(
      title: _editing ? strings.editProfile : strings.profileData,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            focusNode: _nameFocus,
            enabled: _editing && !_saving,
            autofillHints: const [AutofillHints.name],
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: strings.displayName,
              errorText: _nameError,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _profile!.email,
            enabled: false,
            decoration: InputDecoration(
              labelText: strings.verifiedEmail,
              suffixIcon:
                  _profile!.emailVerified
                      ? const Icon(Icons.verified_outlined)
                      : null,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phone,
            focusNode: _phoneFocus,
            enabled: _editing && !_saving,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _editing ? _save() : null,
            decoration: InputDecoration(
              labelText: strings.optionalPhone,
              errorText: _phoneError,
            ),
          ),
          const SizedBox(height: 20),
          if (_editing)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? strings.saving : strings.save),
                ),
                OutlinedButton(
                  onPressed: _saving ? null : _cancel,
                  child: Text(strings.cancel),
                ),
              ],
            )
          else
            ElevatedButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined),
              label: Text(strings.edit),
            ),
        ],
      ),
    );
    final summary = Week2SectionCard(
      title: strings.accountSummary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.versionValue(_profile!.version)),
          const SizedBox(height: 8),
          Text(strings.currentLanguage),
          const SizedBox(height: 8),
          Text(strings.emailReadOnlyNotice),
        ],
      ),
    );
    return Week2Page(
      title: strings.profile,
      subtitle: strings.profileSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_failure != null) ...[
            const SizedBox(height: 16),
            Week2StatePanel.failure(_failure!, onRetry: _retry),
          ],
          if (_success != null) ...[
            const SizedBox(height: 16),
            Week2SuccessPanel(
              title: strings.profileUpdated,
              message: _success!,
            ),
          ],
          const SizedBox(height: 20),
          if (mode == Week2LayoutMode.compact) ...[
            form,
            const SizedBox(height: 16),
            summary,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: form),
                const SizedBox(width: 20),
                Expanded(flex: 5, child: summary),
              ],
            ),
        ],
      ),
    );
  }
}

final class AddressesScreen extends StatefulWidget {
  const AddressesScreen({required this.gateway, super.key});

  final Week2Gateway gateway;

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

final class _AddressesScreenState extends State<AddressesScreen> {
  List<CustomerAddress>? _addresses;
  Week2Failure? _failure;
  bool _loading = true;
  String? _success;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final addresses = await widget.gateway.getAddresses();
      if (mounted) setState(() => _addresses = addresses);
    } on Week2Failure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([CustomerAddress? value]) async {
    final result = await showModalBottomSheet<CustomerAddress>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (context) =>
              AddressEditorSheet(gateway: widget.gateway, value: value),
    );
    if (result != null) {
      setState(
        () =>
            _success =
                value == null
                    ? appStrings(context).addressCreated
                    : appStrings(context).addressUpdated,
      );
      await _load();
    }
  }

  Future<void> _archive(CustomerAddress value) async {
    final strings = appStrings(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(strings.archiveAddressQuestion),
            content: Text(
              value.isDefault
                  ? strings.archiveDefaultWarning
                  : strings.archiveAddressWarning,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(strings.cancel),
              ),
              ElevatedButton(
                onPressed:
                    value.isDefault ? null : () => Navigator.pop(context, true),
                child: Text(strings.archive),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    try {
      await widget.gateway.archiveAddress(value);
      setState(() => _success = strings.addressArchived);
      await _load();
    } on Week2Failure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    if (_loading && _addresses == null) {
      return Week2Page(
        title: strings.addresses,
        child: Week2Loading(label: strings.addressesLoading),
      );
    }
    if (_addresses == null) {
      return Week2Page(
        title: strings.addresses,
        child: Week2StatePanel.failure(_failure!, onRetry: _load),
      );
    }
    return Week2Page(
      title: strings.savedAddresses,
      subtitle: strings.addressesSubtitle,
      actions: [
        ElevatedButton.icon(
          key: const Key('add-address'),
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add),
          label: Text(strings.addAddress),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_failure != null) ...[
            const SizedBox(height: 16),
            Week2StatePanel.failure(_failure!, onRetry: _load),
          ],
          if (_success != null) ...[
            const SizedBox(height: 16),
            Week2SuccessPanel(
              title: strings.addressesUpdated,
              message: _success!,
            ),
          ],
          const SizedBox(height: 20),
          if (_addresses!.isEmpty)
            Week2Empty(
              title: strings.noSavedAddresses,
              message: strings.noSavedAddressesMessage,
              action: ElevatedButton(
                onPressed: () => _openForm(),
                child: Text(strings.addFirstAddress),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 760 ? 2 : 1;
                final width =
                    columns == 2
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final address in _addresses!)
                      SizedBox(
                        width: width,
                        child: Week2SectionCard(
                          title: address.label,
                          subtitle:
                              '${address.isDefault ? "${strings.defaultLabel} · " : ""}${strings.versionValue(address.version)}',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(address.recipientName),
                              Text(address.addressLine),
                              Text(
                                '${address.postalCode} ${address.city} (${address.province})',
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _openForm(address),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: Text(strings.edit),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _archive(address),
                                    icon: const Icon(Icons.archive_outlined),
                                    label: Text(strings.archive),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

final class AddressEditorSheet extends StatefulWidget {
  const AddressEditorSheet({required this.gateway, super.key, this.value});

  final Week2Gateway gateway;
  final CustomerAddress? value;

  @override
  State<AddressEditorSheet> createState() => _AddressEditorSheetState();
}

final class _AddressEditorSheetState extends State<AddressEditorSheet> {
  late final TextEditingController _label;
  late final TextEditingController _recipient;
  late final TextEditingController _addressLine;
  late final TextEditingController _city;
  late final TextEditingController _province;
  late final TextEditingController _postalCode;
  late final TextEditingController _notes;
  final _labelFocus = FocusNode();
  final _recipientFocus = FocusNode();
  final _addressLineFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _provinceFocus = FocusNode();
  final _postalCodeFocus = FocusNode();
  final _notesFocus = FocusNode();
  final Map<String, String?> _fieldErrors = {};
  bool _isDefault = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final value = widget.value;
    _label = TextEditingController(text: value?.label ?? '');
    _recipient = TextEditingController(text: value?.recipientName ?? '');
    _addressLine = TextEditingController(text: value?.addressLine ?? '');
    _city = TextEditingController(text: value?.city ?? '');
    _province = TextEditingController(text: value?.province ?? '');
    _postalCode = TextEditingController(text: value?.postalCode ?? '');
    _notes = TextEditingController(text: value?.deliveryNotes ?? '');
    _isDefault = value?.isDefault ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    _recipient.dispose();
    _addressLine.dispose();
    _city.dispose();
    _province.dispose();
    _postalCode.dispose();
    _notes.dispose();
    _labelFocus.dispose();
    _recipientFocus.dispose();
    _addressLineFocus.dispose();
    _cityFocus.dispose();
    _provinceFocus.dispose();
    _postalCodeFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final strings = appStrings(context);
    final errors = <String, String?>{
      'label': _label.text.trim().isEmpty ? strings.addressLabelRequired : null,
      'recipientName':
          _recipient.text.trim().isEmpty ? strings.recipientRequired : null,
      'addressLine':
          _addressLine.text.trim().isEmpty ? strings.streetRequired : null,
      'city': _city.text.trim().isEmpty ? strings.cityRequired : null,
      'province':
          _province.text.trim().isEmpty ? strings.provinceRequired : null,
      'postalCode':
          RegExp(r'^\d{5}$').hasMatch(_postalCode.text.trim())
              ? null
              : strings.postalCodeValidation,
      'deliveryNotes':
          _notes.text.runes.length > 500 ? strings.notesLengthValidation : null,
    };
    final firstKey =
        errors.entries.where((entry) => entry.value != null).firstOrNull?.key;
    if (firstKey != null) {
      setState(() {
        _fieldErrors
          ..clear()
          ..addAll(errors);
        _error = strings.completeRequiredFields;
      });
      <String, FocusNode>{
        'label': _labelFocus,
        'recipientName': _recipientFocus,
        'addressLine': _addressLineFocus,
        'city': _cityFocus,
        'province': _provinceFocus,
        'postalCode': _postalCodeFocus,
        'deliveryNotes': _notesFocus,
      }[firstKey]!.requestFocus();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _fieldErrors.clear();
    });
    final original = widget.value;
    final input = CustomerAddress(
      id: original?.id ?? '99999999-9999-4999-8999-999999999999',
      version: original?.version ?? '1',
      label: _label.text.trim(),
      recipientName: _recipient.text.trim(),
      addressLine: _addressLine.text.trim(),
      city: _city.text.trim(),
      province: _province.text.trim(),
      postalCode: _postalCode.text.trim(),
      countryCode: 'IT',
      deliveryNotes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      isDefault: _isDefault,
      archivedAt: null,
    );
    try {
      final result =
          original == null
              ? await widget.gateway.createAddress(input)
              : await widget.gateway.updateAddress(input);
      if (mounted) Navigator.pop(context, result);
    } on Week2Failure catch (failure) {
      if (mounted) {
        setState(() {
          _error = failure.message;
          _fieldErrors.addAll(failure.fieldErrors);
        });
        final focus =
            <String, FocusNode>{
              'label': _labelFocus,
              'recipientName': _recipientFocus,
              'addressLine': _addressLineFocus,
              'city': _cityFocus,
              'province': _provinceFocus,
              'postalCode': _postalCodeFocus,
              'deliveryNotes': _notesFocus,
            }[failure.field];
        focus?.requestFocus();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.value == null ? strings.addAddress : strings.editAddress,
        ),
      ),
      body: Week2Page(
        title: widget.value == null ? strings.newAddress : strings.editAddress,
        maxWidth: 720,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                const SizedBox(height: 16),
                Week2StatePanel(
                  title: strings.checkFields,
                  message: _error!,
                  kind: Week2FailureKind.validation,
                ),
              ],
              const SizedBox(height: 20),
              TextField(
                controller: _label,
                focusNode: _labelFocus,
                decoration: InputDecoration(
                  labelText: strings.addressLabel,
                  errorText: _fieldErrors['label'],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _recipient,
                focusNode: _recipientFocus,
                autofillHints: const [AutofillHints.name],
                decoration: InputDecoration(
                  labelText: strings.recipientName,
                  errorText: _fieldErrors['recipientName'],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressLine,
                focusNode: _addressLineFocus,
                autofillHints: const [AutofillHints.streetAddressLine1],
                decoration: InputDecoration(
                  labelText: strings.streetAddress,
                  errorText: _fieldErrors['addressLine'],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _city,
                focusNode: _cityFocus,
                autofillHints: const [AutofillHints.addressCity],
                decoration: InputDecoration(
                  labelText: strings.city,
                  errorText: _fieldErrors['city'],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _province,
                focusNode: _provinceFocus,
                textCapitalization: TextCapitalization.characters,
                autofillHints: const [AutofillHints.addressState],
                decoration: InputDecoration(
                  labelText: strings.province,
                  errorText: _fieldErrors['province'],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _postalCode,
                focusNode: _postalCodeFocus,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.postalCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: strings.postalCode,
                  errorText: _fieldErrors['postalCode'],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notes,
                focusNode: _notesFocus,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: strings.optionalNotes,
                  errorText: _fieldErrors['deliveryNotes'],
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isDefault,
                onChanged:
                    _busy
                        ? null
                        : (value) => setState(() => _isDefault = value),
                title: Text(strings.setAsDefault),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? strings.saving : strings.saveAddress),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class PreferencesSecurityScreen extends StatefulWidget {
  const PreferencesSecurityScreen({
    required this.gateway,
    this.session,
    super.key,
  });

  final Week2Gateway gateway;
  final CustomerSession? session;

  @override
  State<PreferencesSecurityScreen> createState() =>
      _PreferencesSecurityScreenState();
}

final class _PreferencesSecurityScreenState
    extends State<PreferencesSecurityScreen> {
  CustomerPreferences? _preferences;
  List<SecuritySession>? _sessions;
  Week2Failure? _failure;
  bool _loading = true;
  bool _saving = false;
  String? _success;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final results = await Future.wait<Object>([
        widget.gateway.getPreferences(),
        widget.gateway.getSecuritySessions(),
      ]);
      if (mounted) {
        setState(() {
          _preferences = results[0] as CustomerPreferences;
          _sessions = results[1] as List<SecuritySession>;
        });
      }
    } on Week2Failure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setMarketing(bool value) async {
    setState(() {
      _saving = true;
      _failure = null;
      _success = null;
    });
    try {
      final preferences = await widget.gateway.updatePreferences(
        marketingEmailOptIn: value,
        expectedVersion: _preferences!.version,
      );
      if (mounted) {
        setState(() {
          _preferences = preferences;
          _success = appStrings(
            context,
          ).preferencesSavedVersion(preferences.version);
        });
      }
    } on Week2Failure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _revoke(SecuritySession session) async {
    try {
      await widget.gateway.revokeSecuritySession(session.id);
      setState(() => _success = appStrings(context).sessionRevoked);
      await _load();
    } on Week2Failure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    }
  }

  Future<void> _recoverSession() async {
    try {
      await widget.gateway.refreshSession(widget.session!.refreshToken);
      if (mounted) {
        setState(() => _success = appStrings(context).sessionRefreshed);
      }
    } on Week2Failure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    if (_loading && _preferences == null) {
      return Week2Page(
        title: strings.security,
        child: Week2Loading(label: strings.securityLoading),
      );
    }
    if (_preferences == null || _sessions == null) {
      return Week2Page(
        title: strings.security,
        child: Week2StatePanel.failure(_failure!, onRetry: _load),
      );
    }
    return Week2Page(
      title: strings.securityPreferences,
      subtitle: strings.securitySubtitle,
      actions: [
        OutlinedButton.icon(
          onPressed: widget.session == null ? null : _recoverSession,
          icon: const Icon(Icons.sync),
          label: Text(strings.refreshSession),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_failure != null) ...[
            const SizedBox(height: 16),
            Week2StatePanel.failure(_failure!, onRetry: _load),
          ],
          if (_success != null) ...[
            const SizedBox(height: 16),
            Week2SuccessPanel(
              title: strings.settingsUpdated,
              message: _success!,
            ),
          ],
          const SizedBox(height: 20),
          Week2SectionCard(
            title: strings.communications,
            subtitle: strings.communicationsSubtitle,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _preferences!.marketingEmailOptIn,
                  onChanged: _saving ? null : _setMarketing,
                  title: Text(strings.marketingEmails),
                  subtitle: Text(strings.marketingEmailsHelp),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.security),
                  title: Text(strings.securityAlerts),
                  subtitle: Text(strings.securityAlertsHelp),
                  trailing: Text(strings.enabled),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Week2SectionCard(
            title: strings.signInMethods,
            subtitle: strings.signInMethodsHelp,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.password),
                  title: Text(strings.emailPassword),
                  subtitle: Text(strings.currentMethod),
                ),
                if (widget.gateway.configuredFederatedProviders.isEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.info_outline),
                    title: Text(strings.additionalProviders),
                    subtitle: Text(strings.noProviders),
                  )
                else
                  for (final provider
                      in widget.gateway.configuredFederatedProviders)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.account_circle_outlined),
                      title: Text(provider == 'apple' ? 'Apple' : 'Google'),
                      subtitle: Text(strings.configured),
                    ),
                Week2StatePanel(
                  title: strings.lastMethodProtection,
                  message: strings.lastMethodProtectionMessage,
                  kind: Week2FailureKind.providerUnavailable,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Week2SectionCard(
            title: strings.activeSessions,
            subtitle: strings.sessionCount(_sessions!.length),
            child: Column(
              children: [
                for (final session in _sessions!)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      session.current ? Icons.phone_android : Icons.tablet,
                    ),
                    title: Text(session.deviceLabel ?? strings.unnamedDevice),
                    subtitle: Text(
                      '${session.current ? "${strings.current} · " : ""}${strings.lastUsed(session.lastUsedAt)}',
                    ),
                    trailing:
                        session.current
                            ? Text(strings.current)
                            : IconButton(
                              tooltip: strings.revokeSession,
                              onPressed: () => _revoke(session),
                              icon: const Icon(Icons.logout),
                            ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({required this.gateway, super.key});

  final Week2Gateway gateway;

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

final class _PrivacyScreenState extends State<PrivacyScreen> {
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  String? _passwordError;
  PrivacyRequestKind? _retryKind;
  final List<PrivacyRequest> _requests = [];
  Week2Failure? _failure;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _request(PrivacyRequestKind kind) async {
    final strings = appStrings(context);
    if (_password.text.length < 8) {
      _passwordError = strings.passwordMinError;
      setState(
        () =>
            _failure = Week2Failure(
              kind: Week2FailureKind.validation,
              message: strings.privacyPasswordRequired,
              correlationId: 'lf-mobile-local',
            ),
      );
      _passwordFocus.requestFocus();
      return;
    }
    _retryKind = kind;
    setState(() {
      _busy = true;
      _failure = null;
      _passwordError = null;
    });
    try {
      final proof = await widget.gateway.reauthenticate(_password.text);
      final value =
          kind == PrivacyRequestKind.export
              ? await widget.gateway.requestPrivacyExport(proof)
              : await widget.gateway.requestPrivacyDeletion(proof);
      if (mounted) {
        setState(() {
          final index = _requests.indexWhere(
            (request) => request.id == value.id,
          );
          if (index < 0) {
            _requests.add(value);
          } else {
            _requests[index] = value;
          }
        });
      }
    } on Week2Failure catch (failure) {
      if (mounted) {
        setState(() {
          _failure = failure;
          _passwordError = failure.fieldErrors['password'];
        });
        _passwordFocus.requestFocus();
      }
    } finally {
      if (_failure == null) _password.clear();
      if (mounted) setState(() => _busy = false);
    }
  }

  String _stateLabel(AppLocalizations strings, PrivacyRequestState state) =>
      switch (state) {
        PrivacyRequestState.requested => strings.privacyStateRequested,
        PrivacyRequestState.inReview => strings.privacyStateInReview,
        PrivacyRequestState.completed => strings.privacyStateCompleted,
        PrivacyRequestState.cancelled => strings.privacyStateCancelled,
        PrivacyRequestState.retentionRequired => strings.privacyStateRetention,
      };

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    final reauthenticationAvailable =
        widget.gateway.supportsCustomerReauthentication;
    return Week2Page(
      title: strings.privacy,
      subtitle: strings.privacySubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!reauthenticationAvailable) ...[
            Week2StatePanel(
              title: strings.reauthUnavailable,
              message: strings.reauthUnavailableMessage,
              kind: Week2FailureKind.dependencyUnavailable,
            ),
            const SizedBox(height: 16),
          ],
          if (_failure != null) ...[
            const SizedBox(height: 16),
            Week2StatePanel.failure(
              _failure!,
              onRetry: _retryKind == null ? null : () => _request(_retryKind!),
            ),
          ],
          const SizedBox(height: 20),
          Week2SectionCard(
            title: strings.reauthenticationRequired,
            subtitle: strings.reauthenticationHelp,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PasswordField(
                  key: const Key('privacy-reauth-password'),
                  controller: _password,
                  focusNode: _passwordFocus,
                  label: strings.password,
                  errorText: _passwordError,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed:
                          _busy || !reauthenticationAvailable
                              ? null
                              : () => _request(PrivacyRequestKind.export),
                      icon: const Icon(Icons.download_outlined),
                      label: Text(strings.requestExport),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Week2Colors.error,
                      ),
                      onPressed:
                          _busy || !reauthenticationAvailable
                              ? null
                              : () => _request(PrivacyRequestKind.deletion),
                      icon: const Icon(Icons.person_remove_outlined),
                      label: Text(strings.requestDeletion),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_requests.isEmpty)
            Week2Empty(
              title: strings.noRequests,
              message: strings.noRequestsMessage,
            )
          else
            Week2SectionCard(
              title: strings.requestStatus,
              child: Column(
                children: [
                  for (final request in _requests)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        request.kind == PrivacyRequestKind.export
                            ? Icons.download_outlined
                            : Icons.person_remove_outlined,
                      ),
                      title: Text(
                        request.kind == PrivacyRequestKind.export
                            ? strings.export
                            : strings.deletion,
                      ),
                      subtitle: Text(
                        '${_stateLabel(strings, request.state)} · ${request.requestedAt}\n${request.recoveryAction ?? strings.noActionAvailable}',
                      ),
                      isThreeLine: true,
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Week2StatePanel(
            title: strings.requestInformation,
            message: strings.requestInformationHelp,
            kind: Week2FailureKind.providerUnavailable,
          ),
        ],
      ),
    );
  }
}
