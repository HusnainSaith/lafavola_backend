// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'La Favola';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get italian => 'Italian';

  @override
  String get publicMenu => 'Public menu';

  @override
  String get signIn => 'Sign in';

  @override
  String get menu => 'Menu';

  @override
  String get orders => 'Orders';

  @override
  String get profile => 'Profile';

  @override
  String get preferences => 'Preferences';

  @override
  String get privacy => 'Privacy';

  @override
  String get contentNotFound => 'Content not found';

  @override
  String get invalidMenuItem => 'This menu item is no longer available.';

  @override
  String get createYourPizza => 'Create your pizza';

  @override
  String get createPizzaWithLivePricing => 'Create your pizza with live pricing';

  @override
  String get yourOrder => 'Your order';

  @override
  String get closeCheckout => 'Close checkout';

  @override
  String get quantity => 'Quantity';

  @override
  String get fulfilment => 'Fulfilment';

  @override
  String get delivery => 'Delivery';

  @override
  String get pickup => 'Pickup';

  @override
  String get deliveryAddress => 'Delivery address';

  @override
  String get missingDeliveryAddress => 'Add a saved delivery address in Profile before requesting delivery.';

  @override
  String get promoCode => 'Promo code';

  @override
  String get apply => 'Apply';

  @override
  String get payment => 'Payment';

  @override
  String get cashOnDelivery => 'Cash on delivery';

  @override
  String get cashOnPickup => 'Cash at pickup';

  @override
  String get payOnHandover => 'Pay when the order is handed over.';

  @override
  String get onlineCard => 'Online card';

  @override
  String get onlineCardUnavailable => 'Not activated yet. No card details are collected.';

  @override
  String get placeOrder => 'Place order with live total';

  @override
  String get orderReceived => 'Your order is received';

  @override
  String reference(String reference) {
    return 'Reference: $reference';
  }

  @override
  String total(String total) {
    return 'Total: $total';
  }

  @override
  String get orderVisibleToTeam => 'La Favola’s order team can now see this order.';

  @override
  String get backToMenu => 'Back to menu';

  @override
  String get trackOrder => 'Track order';

  @override
  String get livePriceNotice => 'The final total, tax, promotions and availability are recalculated securely before confirmation.';

  @override
  String get size => 'Size';

  @override
  String get required => 'Required';

  @override
  String chooseUpTo(int count) {
    return 'Choose up to $count';
  }

  @override
  String get loading => 'Loading…';

  @override
  String get retry => 'Retry';

  @override
  String get noMenuItems => 'No menu items are available right now.';

  @override
  String get searchMenu => 'Search the menu';

  @override
  String get refresh => 'Refresh';

  @override
  String get orderTracking => 'Order tracking';

  @override
  String get estimatedReady => 'Estimated ready time';

  @override
  String get estimatedArrival => 'Estimated arrival';

  @override
  String remainingMinutes(int minutes) {
    return 'About $minutes min remaining';
  }

  @override
  String get dueNow => 'Due now';

  @override
  String lastUpdated(String time) {
    return 'Last updated $time';
  }

  @override
  String get liveUpdates => 'Live updates';

  @override
  String get reconnecting => 'Reconnecting…';

  @override
  String get offlineTracking => 'Live updates are unavailable. The app will keep retrying safely.';

  @override
  String get cancelOrder => 'Cancel order';

  @override
  String get cancelReason => 'Reason for cancellation';

  @override
  String get confirmCancellation => 'Confirm cancellation';

  @override
  String get keepOrder => 'Keep order';

  @override
  String get orderReceipt => 'Order receipt';

  @override
  String get receiptNotice => 'This is an order receipt, not a fiscal invoice. A fiscal document is issued by the configured provider when applicable.';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get options => 'Options';

  @override
  String get deliveryFee => 'Delivery fee';

  @override
  String get discount => 'Discount';

  @override
  String get tax => 'Tax';

  @override
  String get grandTotal => 'Grand total';

  @override
  String get statusPendingPayment => 'Awaiting payment';

  @override
  String get statusPlaced => 'Order placed';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusPreparing => 'Preparing';

  @override
  String get statusBaking => 'Baking';

  @override
  String get statusPacking => 'Packing';

  @override
  String get statusReady => 'Ready';

  @override
  String get statusDriverAssigned => 'Driver assigned';

  @override
  String get statusOutForDelivery => 'Out for delivery';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusClosed => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get bresciaItaly => 'BRESCIA · ITALY';

  @override
  String get menuHeroTitle => 'The menu,\nmade memorable.';

  @override
  String liveCatalogue(String version) {
    return 'Live menu · catalogue $version';
  }

  @override
  String get menuCategories => 'Menu categories';

  @override
  String get discoverFavourites => 'Discover today’s favourites';

  @override
  String get clearSearch => 'Clear search';

  @override
  String menuResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String get madeWithCare => 'Made with care';

  @override
  String get detailsUnavailable => 'Details are not available for this item.';

  @override
  String get dietaryAllergenInfo => 'Dietary and allergen information';

  @override
  String get customizePizza => 'Customize your pizza';

  @override
  String get addToOrder => 'Add to order';

  @override
  String get builderIntro => 'Make it yours. Live price updates as you choose.';

  @override
  String get chooseOne => 'Choose one';

  @override
  String get checkingPrice => 'Checking live pricing…';

  @override
  String get livePriceUnavailable => 'Live pricing is not available.';

  @override
  String get items => 'Items';

  @override
  String get weCouldNotLoadMenu => 'We could not load the live menu';

  @override
  String get menuUpdating => 'The menu is being updated';

  @override
  String get noLiveCategories => 'No live categories are available right now.';

  @override
  String get noSearchResults => 'No menu items match this search.';

  @override
  String get orderHistory => 'Your order history';

  @override
  String get allOrders => 'All orders';

  @override
  String get active => 'Active';

  @override
  String get completed => 'Completed';

  @override
  String get noOrders => 'Your placed orders will appear here.';

  @override
  String get timeline => 'Timeline';

  @override
  String get orderReceivedTimeline => 'The order has been received.';

  @override
  String get requestCancellation => 'Request cancellation';

  @override
  String get sendingRequest => 'Sending request…';

  @override
  String get sendRequest => 'Send request';

  @override
  String get estimatePending => 'Estimate pending';

  @override
  String get finalisingNow => 'Finalising now';

  @override
  String countdown(int minutes, String seconds) {
    return '$minutes:$seconds remaining';
  }

  @override
  String lateEstimate(int minutes) {
    return '$minutes min later than estimated';
  }

  @override
  String get estimatedCollectionReady => 'Estimated collection readiness';

  @override
  String get estimatedKitchenReady => 'Estimated kitchen readiness';

  @override
  String get viewReceipt => 'View receipt';

  @override
  String get receiptLoading => 'Loading receipt…';

  @override
  String get receiptFailed => 'The receipt could not be loaded.';

  @override
  String issuedAt(String date) {
    return 'Issued $date';
  }

  @override
  String get unitPrice => 'Unit price';

  @override
  String get optionCharges => 'Option charges';

  @override
  String get statusPickedUp => 'Collected';

  @override
  String get statusServed => 'Served';

  @override
  String get statusDeliveryFailed => 'Delivery needs attention';

  @override
  String get waitingConfirmation => 'Waiting for restaurant confirmation';

  @override
  String get orderConfirmed => 'Order confirmed';

  @override
  String get orderBeingPrepared => 'Your order is being prepared';

  @override
  String get pizzaInOven => 'Your pizza is in the oven';

  @override
  String get packingOrder => 'Packing your order';

  @override
  String get readyForRider => 'Ready and waiting for the rider';

  @override
  String get readyForPickup => 'Ready for collection';

  @override
  String get riderOnWay => 'Rider on the way';

  @override
  String tableLabel(String table) {
    return 'Table $table';
  }

  @override
  String selectionRequired(int count) {
    return 'Select at least $count';
  }

  @override
  String selectionTooMany(int count) {
    return 'Select no more than $count';
  }

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signInSubtitle => 'Sign in to manage your account or browse the public menu.';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get otherSignInMethods => 'Other sign-in methods';

  @override
  String get continueGoogle => 'Continue with Google';

  @override
  String get continueApple => 'Continue with Apple';

  @override
  String get continueGuest => 'Continue as guest';

  @override
  String get guestSubtitle => 'Explore La Favola’s full menu without signing in';

  @override
  String get createAccount => 'Create an account';

  @override
  String get haveVerificationCode => 'Already have a verification code?';

  @override
  String get publicAccountNotice => 'The menu is public. Profile, addresses and privacy require an account.';

  @override
  String get sessionUnavailable => 'Session unavailable';

  @override
  String get validEmailError => 'Enter a valid email address.';

  @override
  String get passwordMinError => 'The password must contain at least 8 characters.';

  @override
  String get registration => 'Registration';

  @override
  String get registrationSubtitle => 'Create your account to save favourites and orders.';

  @override
  String get name => 'Name';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get creatingAccount => 'Creating account…';

  @override
  String get goToSignIn => 'Go to sign in';

  @override
  String get registrationCompleted => 'Registration completed';

  @override
  String get registrationCompletedMessage => 'Your account is ready. Sign in with your email and password.';

  @override
  String get fixFields => 'Check the highlighted fields';

  @override
  String get passwordRequirements => '8 to 72 characters. Paste and password managers are supported.';

  @override
  String get termsTitle => 'Notices and terms';

  @override
  String get termsMessage => 'Registration does not enable marketing. Applicable notices must be available before release.';

  @override
  String get verifyEmail => 'Verify email';

  @override
  String get verifyEmailSubtitle => 'Enter the one-time code sent to your email.';

  @override
  String get verificationCode => 'Verification code';

  @override
  String get verifying => 'Verifying…';

  @override
  String get verify => 'Verify';

  @override
  String get resendEmail => 'Email for a new code';

  @override
  String get resend => 'Resend';

  @override
  String get verificationResult => 'Verification result';

  @override
  String get passwordRecovery => 'Password recovery';

  @override
  String get recoveryTitle => 'Recovery and reset';

  @override
  String get recoverySubtitle => 'Request a link or complete the reset with the code you received.';

  @override
  String get requestRecovery => 'Request recovery';

  @override
  String get resetCode => 'Reset code';

  @override
  String get newPassword => 'New password';

  @override
  String get updatePassword => 'Update password';

  @override
  String get operationCompleted => 'Operation completed';

  @override
  String get requestRecoveryStep => '1. Request recovery';

  @override
  String get requestRecoveryHelp => 'The response does not confirm whether the account exists.';

  @override
  String get resetPasswordStep => '2. Set a new password';

  @override
  String get resetPasswordHelp => 'Expired or already-used one-time codes do not modify the account.';

  @override
  String providerSignIn(String provider) {
    return 'Sign in with $provider';
  }

  @override
  String get providerSubtitle => 'Linking completes only after a verified provider return.';

  @override
  String get providerNotConfigured => 'Method not configured';

  @override
  String get providerNotConfiguredMessage => 'This sign-in method is unavailable in this configuration.';

  @override
  String get startSecureSignIn => 'Start secure sign in';

  @override
  String get startSecureSignInHelp => 'No account is linked until the return is verified.';

  @override
  String get preparing => 'Preparing…';

  @override
  String get continueAction => 'Continue';

  @override
  String get waitingProvider => 'Waiting for provider';

  @override
  String get waitingProviderMessage => 'Complete sign in in the protected window. You can go back without changing the account.';

  @override
  String get profileLoading => 'Loading customer profile';

  @override
  String get profileData => 'Profile details';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get displayName => 'Display name';

  @override
  String get verifiedEmail => 'Verified email';

  @override
  String get optionalPhone => 'Phone (optional)';

  @override
  String get saving => 'Saving…';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get accountSummary => 'Account summary';

  @override
  String versionValue(String version) {
    return 'Version $version';
  }

  @override
  String get currentLanguage => 'Language: English';

  @override
  String get emailReadOnlyNotice => 'Email changes are not included in general profile updates.';

  @override
  String get profileSubtitle => 'Your versioned details. Email remains a read-only identity.';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get addresses => 'Addresses';

  @override
  String get savedAddresses => 'Saved addresses';

  @override
  String get addressesLoading => 'Loading saved addresses';

  @override
  String get addressesSubtitle => 'Only your details are shown. Delivery eligibility is always checked by the service.';

  @override
  String get addAddress => 'Add address';

  @override
  String get addressesUpdated => 'Addresses updated';

  @override
  String get noSavedAddresses => 'No saved addresses';

  @override
  String get noSavedAddressesMessage => 'Add an address to find it quickly during future orders.';

  @override
  String get addFirstAddress => 'Add your first address';

  @override
  String get defaultLabel => 'Default';

  @override
  String get archive => 'Archive';

  @override
  String get archiveAddressQuestion => 'Archive address?';

  @override
  String get archiveDefaultWarning => 'Choose another default address before archiving this one.';

  @override
  String get archiveAddressWarning => 'The address will be archived, not permanently deleted.';

  @override
  String get editAddress => 'Edit address';

  @override
  String get newAddress => 'New address';

  @override
  String get checkFields => 'Check the fields';

  @override
  String get addressLabel => 'Label';

  @override
  String get recipientName => 'Recipient name';

  @override
  String get streetAddress => 'Street and number';

  @override
  String get city => 'City';

  @override
  String get province => 'Province';

  @override
  String get postalCode => 'Postcode';

  @override
  String get optionalNotes => 'Notes (optional)';

  @override
  String get setAsDefault => 'Set as default';

  @override
  String get saveAddress => 'Save address';

  @override
  String get security => 'Security';

  @override
  String get securityPreferences => 'Security and preferences';

  @override
  String get securityLoading => 'Loading preferences and sessions';

  @override
  String get securitySubtitle => 'Versioned preferences, essential alerts and session controls.';

  @override
  String get refreshSession => 'Refresh session';

  @override
  String get settingsUpdated => 'Settings updated';

  @override
  String get communications => 'Communications';

  @override
  String get communicationsSubtitle => 'Optional communications are disabled by default.';

  @override
  String get marketingEmails => 'Optional marketing emails';

  @override
  String get marketingEmailsHelp => 'This preference does not change essential communications.';

  @override
  String get securityAlerts => 'Essential security alerts';

  @override
  String get securityAlertsHelp => 'Enabled and separate from marketing preferences.';

  @override
  String get enabled => 'Enabled';

  @override
  String get signInMethods => 'Sign-in methods';

  @override
  String get signInMethodsHelp => 'Manage email/password and configured providers.';

  @override
  String get emailPassword => 'Email and password';

  @override
  String get currentMethod => 'Current method';

  @override
  String get additionalProviders => 'Additional providers';

  @override
  String get noProviders => 'No providers configured';

  @override
  String get configured => 'Configured';

  @override
  String get activeSessions => 'Active sessions';

  @override
  String sessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String get unnamedDevice => 'Unnamed device';

  @override
  String get current => 'Current';

  @override
  String lastUsed(String date) {
    return 'Last used $date';
  }

  @override
  String get revokeSession => 'Revoke session';

  @override
  String get privacySubtitle => 'Exports and deletions show authoritative status without promising a completion time.';

  @override
  String get reauthenticationRequired => 'Reauthentication required';

  @override
  String get reauthenticationHelp => 'Confirm with your password. The app does not store the password or proof.';

  @override
  String get requestExport => 'Request export';

  @override
  String get requestDeletion => 'Start deletion request';

  @override
  String get noRequests => 'No requests';

  @override
  String get noRequestsMessage => 'Submitted requests appear here with their latest status.';

  @override
  String get requestStatus => 'Request status';

  @override
  String get export => 'Export';

  @override
  String get deletion => 'Deletion';

  @override
  String get requestInformation => 'Request information';

  @override
  String get requestInformationHelp => 'Retention obligations and available actions come from the service response.';

  @override
  String get signOut => 'Sign out';

  @override
  String get sessionRequired => 'Session required';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get protectedRouteNotice => 'Protected destinations do not retain data when no session is available.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get errorTitle => 'We could not complete that action';

  @override
  String referenceCode(String code) {
    return 'Reference: $code';
  }

  @override
  String get tapToContinue => 'Tap to continue';

  @override
  String get timing => 'Timing';

  @override
  String get asSoonAsPossible => 'As soon as possible';

  @override
  String get scheduleOrder => 'Schedule';

  @override
  String get chooseDate => 'Choose date';

  @override
  String get scheduledTime => 'Scheduled time';

  @override
  String get noTimeSlots => 'No fulfilment times are available for this date. Choose another date.';

  @override
  String get closedNow => 'La Favola is closed right now. Choose an available scheduled time.';

  @override
  String leadTime(int minutes) {
    return 'Current estimate: about $minutes minutes';
  }

  @override
  String get nameValidation => 'Name is required, must be at most 100 characters, and cannot contain control characters.';

  @override
  String get phoneValidation => 'Enter a valid international phone number.';

  @override
  String get passwordRangeError => 'The password must contain 8 to 72 characters.';

  @override
  String get passwordMismatchError => 'Passwords do not match.';

  @override
  String get verificationCodeMinError => 'The code must contain at least 8 characters.';

  @override
  String get emailVerifiedSuccess => 'Email verified. You can now sign in.';

  @override
  String get resendVerificationAccepted => 'The resend request was accepted without revealing the account status.';

  @override
  String get recoveryAccepted => 'Request received. The result remains neutral for every email address.';

  @override
  String get resetTokenMinError => 'The reset code must contain at least 8 characters.';

  @override
  String get resetValidationError => 'Check the reset code and new password (at least 8 characters).';

  @override
  String get passwordResetSuccess => 'Password updated. Other sessions have been revoked.';

  @override
  String profileSavedVersion(String version) {
    return 'Profile saved as version $version.';
  }

  @override
  String get addressCreated => 'Address created.';

  @override
  String get addressUpdated => 'Address updated.';

  @override
  String get addressArchived => 'Address archived.';

  @override
  String preferencesSavedVersion(String version) {
    return 'Preferences saved as version $version.';
  }

  @override
  String get sessionRevoked => 'Session revoked.';

  @override
  String get privacyPasswordRequired => 'Enter your password to confirm the request.';

  @override
  String get privacyStateRequested => 'Requested';

  @override
  String get privacyStateInReview => 'In review';

  @override
  String get privacyStateCompleted => 'Completed';

  @override
  String get privacyStateCancelled => 'Cancelled';

  @override
  String get privacyStateRetention => 'Retention required';

  @override
  String get reauthUnavailable => 'Reauthentication unavailable';

  @override
  String get reauthUnavailableMessage => 'Update the service contract before submitting privacy requests.';

  @override
  String get signInProtectedRoute => 'Sign in to open this protected destination.';

  @override
  String get signInAgain => 'Sign in again to continue.';

  @override
  String get noActionAvailable => 'No action available';

  @override
  String get addressLabelRequired => 'Enter an address label.';

  @override
  String get recipientRequired => 'Enter the recipient name.';

  @override
  String get streetRequired => 'Enter the street and number.';

  @override
  String get cityRequired => 'Enter the city.';

  @override
  String get provinceRequired => 'Enter the province.';

  @override
  String get postalCodeValidation => 'The postcode must contain five digits.';

  @override
  String get notesLengthValidation => 'Notes cannot exceed 500 characters.';

  @override
  String get completeRequiredFields => 'Complete the highlighted fields.';

  @override
  String get sessionRefreshed => 'Session refreshed.';

  @override
  String get lastMethodProtection => 'Last sign-in method protection';

  @override
  String get lastMethodProtectionMessage => 'The final sign-in method cannot be disconnected.';

  @override
  String get oneTimeCodeHelp => 'Paste and one-time-code autofill are supported.';
}
