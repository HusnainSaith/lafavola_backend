import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
    Locale('it', 'IT')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'La Favola'**
  String get appTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @italian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get italian;

  /// No description provided for @publicMenu.
  ///
  /// In en, this message translates to:
  /// **'Public menu'**
  String get publicMenu;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @contentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Content not found'**
  String get contentNotFound;

  /// No description provided for @invalidMenuItem.
  ///
  /// In en, this message translates to:
  /// **'This menu item is no longer available.'**
  String get invalidMenuItem;

  /// No description provided for @createYourPizza.
  ///
  /// In en, this message translates to:
  /// **'Create your pizza'**
  String get createYourPizza;

  /// No description provided for @createPizzaWithLivePricing.
  ///
  /// In en, this message translates to:
  /// **'Create your pizza with live pricing'**
  String get createPizzaWithLivePricing;

  /// No description provided for @yourOrder.
  ///
  /// In en, this message translates to:
  /// **'Your order'**
  String get yourOrder;

  /// No description provided for @closeCheckout.
  ///
  /// In en, this message translates to:
  /// **'Close checkout'**
  String get closeCheckout;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @fulfilment.
  ///
  /// In en, this message translates to:
  /// **'Fulfilment'**
  String get fulfilment;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery address'**
  String get deliveryAddress;

  /// No description provided for @missingDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Add a saved delivery address in Profile before requesting delivery.'**
  String get missingDeliveryAddress;

  /// No description provided for @promoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get promoCode;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @cashOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery'**
  String get cashOnDelivery;

  /// No description provided for @cashOnPickup.
  ///
  /// In en, this message translates to:
  /// **'Cash at pickup'**
  String get cashOnPickup;

  /// No description provided for @payOnHandover.
  ///
  /// In en, this message translates to:
  /// **'Pay when the order is handed over.'**
  String get payOnHandover;

  /// No description provided for @onlineCard.
  ///
  /// In en, this message translates to:
  /// **'Online card'**
  String get onlineCard;

  /// No description provided for @onlineCardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not activated yet. No card details are collected.'**
  String get onlineCardUnavailable;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place order with live total'**
  String get placeOrder;

  /// No description provided for @orderReceived.
  ///
  /// In en, this message translates to:
  /// **'Your order is received'**
  String get orderReceived;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference: {reference}'**
  String reference(String reference);

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total: {total}'**
  String total(String total);

  /// No description provided for @orderVisibleToTeam.
  ///
  /// In en, this message translates to:
  /// **'La Favola’s order team can now see this order.'**
  String get orderVisibleToTeam;

  /// No description provided for @backToMenu.
  ///
  /// In en, this message translates to:
  /// **'Back to menu'**
  String get backToMenu;

  /// No description provided for @trackOrder.
  ///
  /// In en, this message translates to:
  /// **'Track order'**
  String get trackOrder;

  /// No description provided for @livePriceNotice.
  ///
  /// In en, this message translates to:
  /// **'The final total, tax, promotions and availability are recalculated securely before confirmation.'**
  String get livePriceNotice;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @chooseUpTo.
  ///
  /// In en, this message translates to:
  /// **'Choose up to {count}'**
  String chooseUpTo(int count);

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noMenuItems.
  ///
  /// In en, this message translates to:
  /// **'No menu items are available right now.'**
  String get noMenuItems;

  /// No description provided for @searchMenu.
  ///
  /// In en, this message translates to:
  /// **'Search the menu'**
  String get searchMenu;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @orderTracking.
  ///
  /// In en, this message translates to:
  /// **'Order tracking'**
  String get orderTracking;

  /// No description provided for @estimatedReady.
  ///
  /// In en, this message translates to:
  /// **'Estimated ready time'**
  String get estimatedReady;

  /// No description provided for @estimatedArrival.
  ///
  /// In en, this message translates to:
  /// **'Estimated arrival'**
  String get estimatedArrival;

  /// No description provided for @remainingMinutes.
  ///
  /// In en, this message translates to:
  /// **'About {minutes} min remaining'**
  String remainingMinutes(int minutes);

  /// No description provided for @dueNow.
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get dueNow;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated {time}'**
  String lastUpdated(String time);

  /// No description provided for @liveUpdates.
  ///
  /// In en, this message translates to:
  /// **'Live updates'**
  String get liveUpdates;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get reconnecting;

  /// No description provided for @offlineTracking.
  ///
  /// In en, this message translates to:
  /// **'Live updates are unavailable. The app will keep retrying safely.'**
  String get offlineTracking;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get cancelOrder;

  /// No description provided for @cancelReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for cancellation'**
  String get cancelReason;

  /// No description provided for @confirmCancellation.
  ///
  /// In en, this message translates to:
  /// **'Confirm cancellation'**
  String get confirmCancellation;

  /// No description provided for @keepOrder.
  ///
  /// In en, this message translates to:
  /// **'Keep order'**
  String get keepOrder;

  /// No description provided for @orderReceipt.
  ///
  /// In en, this message translates to:
  /// **'Order receipt'**
  String get orderReceipt;

  /// No description provided for @receiptNotice.
  ///
  /// In en, this message translates to:
  /// **'This is an order receipt, not a fiscal invoice. A fiscal document is issued by the configured provider when applicable.'**
  String get receiptNotice;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee'**
  String get deliveryFee;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @grandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand total'**
  String get grandTotal;

  /// No description provided for @statusPendingPayment.
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment'**
  String get statusPendingPayment;

  /// No description provided for @statusPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order placed'**
  String get statusPlaced;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get statusPreparing;

  /// No description provided for @statusBaking.
  ///
  /// In en, this message translates to:
  /// **'Baking'**
  String get statusBaking;

  /// No description provided for @statusPacking.
  ///
  /// In en, this message translates to:
  /// **'Packing'**
  String get statusPacking;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusReady;

  /// No description provided for @statusDriverAssigned.
  ///
  /// In en, this message translates to:
  /// **'Driver assigned'**
  String get statusDriverAssigned;

  /// No description provided for @statusOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for delivery'**
  String get statusOutForDelivery;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusClosed;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @bresciaItaly.
  ///
  /// In en, this message translates to:
  /// **'BRESCIA · ITALY'**
  String get bresciaItaly;

  /// No description provided for @menuHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'The menu,\nmade memorable.'**
  String get menuHeroTitle;

  /// No description provided for @liveCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Live menu · catalogue {version}'**
  String liveCatalogue(String version);

  /// No description provided for @menuCategories.
  ///
  /// In en, this message translates to:
  /// **'Menu categories'**
  String get menuCategories;

  /// No description provided for @discoverFavourites.
  ///
  /// In en, this message translates to:
  /// **'Discover today’s favourites'**
  String get discoverFavourites;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @menuResultCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items} =1{1 item} other{{count} items}}'**
  String menuResultCount(int count);

  /// No description provided for @madeWithCare.
  ///
  /// In en, this message translates to:
  /// **'Made with care'**
  String get madeWithCare;

  /// No description provided for @detailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Details are not available for this item.'**
  String get detailsUnavailable;

  /// No description provided for @dietaryAllergenInfo.
  ///
  /// In en, this message translates to:
  /// **'Dietary and allergen information'**
  String get dietaryAllergenInfo;

  /// No description provided for @customizePizza.
  ///
  /// In en, this message translates to:
  /// **'Customize your pizza'**
  String get customizePizza;

  /// No description provided for @addToOrder.
  ///
  /// In en, this message translates to:
  /// **'Add to order'**
  String get addToOrder;

  /// No description provided for @builderIntro.
  ///
  /// In en, this message translates to:
  /// **'Make it yours. Live price updates as you choose.'**
  String get builderIntro;

  /// No description provided for @chooseOne.
  ///
  /// In en, this message translates to:
  /// **'Choose one'**
  String get chooseOne;

  /// No description provided for @checkingPrice.
  ///
  /// In en, this message translates to:
  /// **'Checking live pricing…'**
  String get checkingPrice;

  /// No description provided for @livePriceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Live pricing is not available.'**
  String get livePriceUnavailable;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @weCouldNotLoadMenu.
  ///
  /// In en, this message translates to:
  /// **'We could not load the live menu'**
  String get weCouldNotLoadMenu;

  /// No description provided for @menuUpdating.
  ///
  /// In en, this message translates to:
  /// **'The menu is being updated'**
  String get menuUpdating;

  /// No description provided for @noLiveCategories.
  ///
  /// In en, this message translates to:
  /// **'No live categories are available right now.'**
  String get noLiveCategories;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No menu items match this search.'**
  String get noSearchResults;

  /// No description provided for @orderHistory.
  ///
  /// In en, this message translates to:
  /// **'Your order history'**
  String get orderHistory;

  /// No description provided for @allOrders.
  ///
  /// In en, this message translates to:
  /// **'All orders'**
  String get allOrders;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @noOrders.
  ///
  /// In en, this message translates to:
  /// **'Your placed orders will appear here.'**
  String get noOrders;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @orderReceivedTimeline.
  ///
  /// In en, this message translates to:
  /// **'The order has been received.'**
  String get orderReceivedTimeline;

  /// No description provided for @requestCancellation.
  ///
  /// In en, this message translates to:
  /// **'Request cancellation'**
  String get requestCancellation;

  /// No description provided for @sendingRequest.
  ///
  /// In en, this message translates to:
  /// **'Sending request…'**
  String get sendingRequest;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get sendRequest;

  /// No description provided for @estimatePending.
  ///
  /// In en, this message translates to:
  /// **'Estimate pending'**
  String get estimatePending;

  /// No description provided for @finalisingNow.
  ///
  /// In en, this message translates to:
  /// **'Finalising now'**
  String get finalisingNow;

  /// No description provided for @countdown.
  ///
  /// In en, this message translates to:
  /// **'{minutes}:{seconds} remaining'**
  String countdown(int minutes, String seconds);

  /// No description provided for @lateEstimate.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min later than estimated'**
  String lateEstimate(int minutes);

  /// No description provided for @estimatedCollectionReady.
  ///
  /// In en, this message translates to:
  /// **'Estimated collection readiness'**
  String get estimatedCollectionReady;

  /// No description provided for @estimatedKitchenReady.
  ///
  /// In en, this message translates to:
  /// **'Estimated kitchen readiness'**
  String get estimatedKitchenReady;

  /// No description provided for @viewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View receipt'**
  String get viewReceipt;

  /// No description provided for @receiptLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading receipt…'**
  String get receiptLoading;

  /// No description provided for @receiptFailed.
  ///
  /// In en, this message translates to:
  /// **'The receipt could not be loaded.'**
  String get receiptFailed;

  /// No description provided for @issuedAt.
  ///
  /// In en, this message translates to:
  /// **'Issued {date}'**
  String issuedAt(String date);

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get unitPrice;

  /// No description provided for @optionCharges.
  ///
  /// In en, this message translates to:
  /// **'Option charges'**
  String get optionCharges;

  /// No description provided for @statusPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get statusPickedUp;

  /// No description provided for @statusServed.
  ///
  /// In en, this message translates to:
  /// **'Served'**
  String get statusServed;

  /// No description provided for @statusDeliveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Delivery needs attention'**
  String get statusDeliveryFailed;

  /// No description provided for @waitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for restaurant confirmation'**
  String get waitingConfirmation;

  /// No description provided for @orderConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Order confirmed'**
  String get orderConfirmed;

  /// No description provided for @orderBeingPrepared.
  ///
  /// In en, this message translates to:
  /// **'Your order is being prepared'**
  String get orderBeingPrepared;

  /// No description provided for @pizzaInOven.
  ///
  /// In en, this message translates to:
  /// **'Your pizza is in the oven'**
  String get pizzaInOven;

  /// No description provided for @packingOrder.
  ///
  /// In en, this message translates to:
  /// **'Packing your order'**
  String get packingOrder;

  /// No description provided for @readyForRider.
  ///
  /// In en, this message translates to:
  /// **'Ready and waiting for the rider'**
  String get readyForRider;

  /// No description provided for @readyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for collection'**
  String get readyForPickup;

  /// No description provided for @riderOnWay.
  ///
  /// In en, this message translates to:
  /// **'Rider on the way'**
  String get riderOnWay;

  /// No description provided for @tableLabel.
  ///
  /// In en, this message translates to:
  /// **'Table {table}'**
  String tableLabel(String table);

  /// No description provided for @selectionRequired.
  ///
  /// In en, this message translates to:
  /// **'Select at least {count}'**
  String selectionRequired(int count);

  /// No description provided for @selectionTooMany.
  ///
  /// In en, this message translates to:
  /// **'Select no more than {count}'**
  String selectionTooMany(int count);

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your account or browse the public menu.'**
  String get signInSubtitle;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @otherSignInMethods.
  ///
  /// In en, this message translates to:
  /// **'Other sign-in methods'**
  String get otherSignInMethods;

  /// No description provided for @continueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueGoogle;

  /// No description provided for @continueApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueApple;

  /// No description provided for @continueGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueGuest;

  /// No description provided for @guestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore La Favola’s full menu without signing in'**
  String get guestSubtitle;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// No description provided for @haveVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Already have a verification code?'**
  String get haveVerificationCode;

  /// No description provided for @publicAccountNotice.
  ///
  /// In en, this message translates to:
  /// **'The menu is public. Profile, addresses and privacy require an account.'**
  String get publicAccountNotice;

  /// No description provided for @sessionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Session unavailable'**
  String get sessionUnavailable;

  /// No description provided for @validEmailError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get validEmailError;

  /// No description provided for @passwordMinError.
  ///
  /// In en, this message translates to:
  /// **'The password must contain at least 8 characters.'**
  String get passwordMinError;

  /// No description provided for @registration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get registration;

  /// No description provided for @registrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account to save favourites and orders.'**
  String get registrationSubtitle;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating account…'**
  String get creatingAccount;

  /// No description provided for @goToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Go to sign in'**
  String get goToSignIn;

  /// No description provided for @registrationCompleted.
  ///
  /// In en, this message translates to:
  /// **'Registration completed'**
  String get registrationCompleted;

  /// No description provided for @registrationCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account is ready. Sign in with your email and password.'**
  String get registrationCompletedMessage;

  /// No description provided for @fixFields.
  ///
  /// In en, this message translates to:
  /// **'Check the highlighted fields'**
  String get fixFields;

  /// No description provided for @passwordRequirements.
  ///
  /// In en, this message translates to:
  /// **'8 to 72 characters. Paste and password managers are supported.'**
  String get passwordRequirements;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notices and terms'**
  String get termsTitle;

  /// No description provided for @termsMessage.
  ///
  /// In en, this message translates to:
  /// **'Registration does not enable marketing. Applicable notices must be available before release.'**
  String get termsMessage;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get verifyEmail;

  /// No description provided for @verifyEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the one-time code sent to your email.'**
  String get verifyEmailSubtitle;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get verificationCode;

  /// No description provided for @verifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get verifying;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Email for a new code'**
  String get resendEmail;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @verificationResult.
  ///
  /// In en, this message translates to:
  /// **'Verification result'**
  String get verificationResult;

  /// No description provided for @passwordRecovery.
  ///
  /// In en, this message translates to:
  /// **'Password recovery'**
  String get passwordRecovery;

  /// No description provided for @recoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery and reset'**
  String get recoveryTitle;

  /// No description provided for @recoverySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Request a link or complete the reset with the code you received.'**
  String get recoverySubtitle;

  /// No description provided for @requestRecovery.
  ///
  /// In en, this message translates to:
  /// **'Request recovery'**
  String get requestRecovery;

  /// No description provided for @resetCode.
  ///
  /// In en, this message translates to:
  /// **'Reset code'**
  String get resetCode;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get updatePassword;

  /// No description provided for @operationCompleted.
  ///
  /// In en, this message translates to:
  /// **'Operation completed'**
  String get operationCompleted;

  /// No description provided for @requestRecoveryStep.
  ///
  /// In en, this message translates to:
  /// **'1. Request recovery'**
  String get requestRecoveryStep;

  /// No description provided for @requestRecoveryHelp.
  ///
  /// In en, this message translates to:
  /// **'The response does not confirm whether the account exists.'**
  String get requestRecoveryHelp;

  /// No description provided for @resetPasswordStep.
  ///
  /// In en, this message translates to:
  /// **'2. Set a new password'**
  String get resetPasswordStep;

  /// No description provided for @resetPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Expired or already-used one-time codes do not modify the account.'**
  String get resetPasswordHelp;

  /// No description provided for @providerSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with {provider}'**
  String providerSignIn(String provider);

  /// No description provided for @providerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Linking completes only after a verified provider return.'**
  String get providerSubtitle;

  /// No description provided for @providerNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Method not configured'**
  String get providerNotConfigured;

  /// No description provided for @providerNotConfiguredMessage.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method is unavailable in this configuration.'**
  String get providerNotConfiguredMessage;

  /// No description provided for @startSecureSignIn.
  ///
  /// In en, this message translates to:
  /// **'Start secure sign in'**
  String get startSecureSignIn;

  /// No description provided for @startSecureSignInHelp.
  ///
  /// In en, this message translates to:
  /// **'No account is linked until the return is verified.'**
  String get startSecureSignInHelp;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get preparing;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @waitingProvider.
  ///
  /// In en, this message translates to:
  /// **'Waiting for provider'**
  String get waitingProvider;

  /// No description provided for @waitingProviderMessage.
  ///
  /// In en, this message translates to:
  /// **'Complete sign in in the protected window. You can go back without changing the account.'**
  String get waitingProviderMessage;

  /// No description provided for @profileLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading customer profile'**
  String get profileLoading;

  /// No description provided for @profileData.
  ///
  /// In en, this message translates to:
  /// **'Profile details'**
  String get profileData;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @verifiedEmail.
  ///
  /// In en, this message translates to:
  /// **'Verified email'**
  String get verifiedEmail;

  /// No description provided for @optionalPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get optionalPhone;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @accountSummary.
  ///
  /// In en, this message translates to:
  /// **'Account summary'**
  String get accountSummary;

  /// No description provided for @versionValue.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionValue(String version);

  /// No description provided for @currentLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language: English'**
  String get currentLanguage;

  /// No description provided for @emailReadOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'Email changes are not included in general profile updates.'**
  String get emailReadOnlyNotice;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your versioned details. Email remains a read-only identity.'**
  String get profileSubtitle;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @addresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get addresses;

  /// No description provided for @savedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved addresses'**
  String get savedAddresses;

  /// No description provided for @addressesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading saved addresses'**
  String get addressesLoading;

  /// No description provided for @addressesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only your details are shown. Delivery eligibility is always checked by the service.'**
  String get addressesSubtitle;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addAddress;

  /// No description provided for @addressesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Addresses updated'**
  String get addressesUpdated;

  /// No description provided for @noSavedAddresses.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses'**
  String get noSavedAddresses;

  /// No description provided for @noSavedAddressesMessage.
  ///
  /// In en, this message translates to:
  /// **'Add an address to find it quickly during future orders.'**
  String get noSavedAddressesMessage;

  /// No description provided for @addFirstAddress.
  ///
  /// In en, this message translates to:
  /// **'Add your first address'**
  String get addFirstAddress;

  /// No description provided for @defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @archiveAddressQuestion.
  ///
  /// In en, this message translates to:
  /// **'Archive address?'**
  String get archiveAddressQuestion;

  /// No description provided for @archiveDefaultWarning.
  ///
  /// In en, this message translates to:
  /// **'Choose another default address before archiving this one.'**
  String get archiveDefaultWarning;

  /// No description provided for @archiveAddressWarning.
  ///
  /// In en, this message translates to:
  /// **'The address will be archived, not permanently deleted.'**
  String get archiveAddressWarning;

  /// No description provided for @editAddress.
  ///
  /// In en, this message translates to:
  /// **'Edit address'**
  String get editAddress;

  /// No description provided for @newAddress.
  ///
  /// In en, this message translates to:
  /// **'New address'**
  String get newAddress;

  /// No description provided for @checkFields.
  ///
  /// In en, this message translates to:
  /// **'Check the fields'**
  String get checkFields;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get addressLabel;

  /// No description provided for @recipientName.
  ///
  /// In en, this message translates to:
  /// **'Recipient name'**
  String get recipientName;

  /// No description provided for @streetAddress.
  ///
  /// In en, this message translates to:
  /// **'Street and number'**
  String get streetAddress;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @province.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get province;

  /// No description provided for @postalCode.
  ///
  /// In en, this message translates to:
  /// **'Postcode'**
  String get postalCode;

  /// No description provided for @optionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get optionalNotes;

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get setAsDefault;

  /// No description provided for @saveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save address'**
  String get saveAddress;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @securityPreferences.
  ///
  /// In en, this message translates to:
  /// **'Security and preferences'**
  String get securityPreferences;

  /// No description provided for @securityLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading preferences and sessions'**
  String get securityLoading;

  /// No description provided for @securitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Versioned preferences, essential alerts and session controls.'**
  String get securitySubtitle;

  /// No description provided for @refreshSession.
  ///
  /// In en, this message translates to:
  /// **'Refresh session'**
  String get refreshSession;

  /// No description provided for @settingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Settings updated'**
  String get settingsUpdated;

  /// No description provided for @communications.
  ///
  /// In en, this message translates to:
  /// **'Communications'**
  String get communications;

  /// No description provided for @communicationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional communications are disabled by default.'**
  String get communicationsSubtitle;

  /// No description provided for @marketingEmails.
  ///
  /// In en, this message translates to:
  /// **'Optional marketing emails'**
  String get marketingEmails;

  /// No description provided for @marketingEmailsHelp.
  ///
  /// In en, this message translates to:
  /// **'This preference does not change essential communications.'**
  String get marketingEmailsHelp;

  /// No description provided for @securityAlerts.
  ///
  /// In en, this message translates to:
  /// **'Essential security alerts'**
  String get securityAlerts;

  /// No description provided for @securityAlertsHelp.
  ///
  /// In en, this message translates to:
  /// **'Enabled and separate from marketing preferences.'**
  String get securityAlertsHelp;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @signInMethods.
  ///
  /// In en, this message translates to:
  /// **'Sign-in methods'**
  String get signInMethods;

  /// No description provided for @signInMethodsHelp.
  ///
  /// In en, this message translates to:
  /// **'Manage email/password and configured providers.'**
  String get signInMethodsHelp;

  /// No description provided for @emailPassword.
  ///
  /// In en, this message translates to:
  /// **'Email and password'**
  String get emailPassword;

  /// No description provided for @currentMethod.
  ///
  /// In en, this message translates to:
  /// **'Current method'**
  String get currentMethod;

  /// No description provided for @additionalProviders.
  ///
  /// In en, this message translates to:
  /// **'Additional providers'**
  String get additionalProviders;

  /// No description provided for @noProviders.
  ///
  /// In en, this message translates to:
  /// **'No providers configured'**
  String get noProviders;

  /// No description provided for @configured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get configured;

  /// No description provided for @activeSessions.
  ///
  /// In en, this message translates to:
  /// **'Active sessions'**
  String get activeSessions;

  /// No description provided for @sessionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session} other{{count} sessions}}'**
  String sessionCount(int count);

  /// No description provided for @unnamedDevice.
  ///
  /// In en, this message translates to:
  /// **'Unnamed device'**
  String get unnamedDevice;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @lastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used {date}'**
  String lastUsed(String date);

  /// No description provided for @revokeSession.
  ///
  /// In en, this message translates to:
  /// **'Revoke session'**
  String get revokeSession;

  /// No description provided for @privacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Exports and deletions show authoritative status without promising a completion time.'**
  String get privacySubtitle;

  /// No description provided for @reauthenticationRequired.
  ///
  /// In en, this message translates to:
  /// **'Reauthentication required'**
  String get reauthenticationRequired;

  /// No description provided for @reauthenticationHelp.
  ///
  /// In en, this message translates to:
  /// **'Confirm with your password. The app does not store the password or proof.'**
  String get reauthenticationHelp;

  /// No description provided for @requestExport.
  ///
  /// In en, this message translates to:
  /// **'Request export'**
  String get requestExport;

  /// No description provided for @requestDeletion.
  ///
  /// In en, this message translates to:
  /// **'Start deletion request'**
  String get requestDeletion;

  /// No description provided for @noRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests'**
  String get noRequests;

  /// No description provided for @noRequestsMessage.
  ///
  /// In en, this message translates to:
  /// **'Submitted requests appear here with their latest status.'**
  String get noRequestsMessage;

  /// No description provided for @requestStatus.
  ///
  /// In en, this message translates to:
  /// **'Request status'**
  String get requestStatus;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @deletion.
  ///
  /// In en, this message translates to:
  /// **'Deletion'**
  String get deletion;

  /// No description provided for @requestInformation.
  ///
  /// In en, this message translates to:
  /// **'Request information'**
  String get requestInformation;

  /// No description provided for @requestInformationHelp.
  ///
  /// In en, this message translates to:
  /// **'Retention obligations and available actions come from the service response.'**
  String get requestInformationHelp;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @sessionRequired.
  ///
  /// In en, this message translates to:
  /// **'Session required'**
  String get sessionRequired;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @protectedRouteNotice.
  ///
  /// In en, this message translates to:
  /// **'Protected destinations do not retain data when no session is available.'**
  String get protectedRouteNotice;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'We could not complete that action'**
  String get errorTitle;

  /// No description provided for @referenceCode.
  ///
  /// In en, this message translates to:
  /// **'Reference: {code}'**
  String referenceCode(String code);

  /// No description provided for @tapToContinue.
  ///
  /// In en, this message translates to:
  /// **'Tap to continue'**
  String get tapToContinue;

  /// No description provided for @timing.
  ///
  /// In en, this message translates to:
  /// **'Timing'**
  String get timing;

  /// No description provided for @asSoonAsPossible.
  ///
  /// In en, this message translates to:
  /// **'As soon as possible'**
  String get asSoonAsPossible;

  /// No description provided for @scheduleOrder.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleOrder;

  /// No description provided for @chooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get chooseDate;

  /// No description provided for @scheduledTime.
  ///
  /// In en, this message translates to:
  /// **'Scheduled time'**
  String get scheduledTime;

  /// No description provided for @noTimeSlots.
  ///
  /// In en, this message translates to:
  /// **'No fulfilment times are available for this date. Choose another date.'**
  String get noTimeSlots;

  /// No description provided for @closedNow.
  ///
  /// In en, this message translates to:
  /// **'La Favola is closed right now. Choose an available scheduled time.'**
  String get closedNow;

  /// No description provided for @leadTime.
  ///
  /// In en, this message translates to:
  /// **'Current estimate: about {minutes} minutes'**
  String leadTime(int minutes);

  /// No description provided for @nameValidation.
  ///
  /// In en, this message translates to:
  /// **'Name is required, must be at most 100 characters, and cannot contain control characters.'**
  String get nameValidation;

  /// No description provided for @phoneValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid international phone number.'**
  String get phoneValidation;

  /// No description provided for @passwordRangeError.
  ///
  /// In en, this message translates to:
  /// **'The password must contain 8 to 72 characters.'**
  String get passwordRangeError;

  /// No description provided for @passwordMismatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordMismatchError;

  /// No description provided for @verificationCodeMinError.
  ///
  /// In en, this message translates to:
  /// **'The code must contain at least 8 characters.'**
  String get verificationCodeMinError;

  /// No description provided for @emailVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email verified. You can now sign in.'**
  String get emailVerifiedSuccess;

  /// No description provided for @resendVerificationAccepted.
  ///
  /// In en, this message translates to:
  /// **'The resend request was accepted without revealing the account status.'**
  String get resendVerificationAccepted;

  /// No description provided for @recoveryAccepted.
  ///
  /// In en, this message translates to:
  /// **'Request received. The result remains neutral for every email address.'**
  String get recoveryAccepted;

  /// No description provided for @resetTokenMinError.
  ///
  /// In en, this message translates to:
  /// **'The reset code must contain at least 8 characters.'**
  String get resetTokenMinError;

  /// No description provided for @resetValidationError.
  ///
  /// In en, this message translates to:
  /// **'Check the reset code and new password (at least 8 characters).'**
  String get resetValidationError;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Other sessions have been revoked.'**
  String get passwordResetSuccess;

  /// No description provided for @profileSavedVersion.
  ///
  /// In en, this message translates to:
  /// **'Profile saved as version {version}.'**
  String profileSavedVersion(String version);

  /// No description provided for @addressCreated.
  ///
  /// In en, this message translates to:
  /// **'Address created.'**
  String get addressCreated;

  /// No description provided for @addressUpdated.
  ///
  /// In en, this message translates to:
  /// **'Address updated.'**
  String get addressUpdated;

  /// No description provided for @addressArchived.
  ///
  /// In en, this message translates to:
  /// **'Address archived.'**
  String get addressArchived;

  /// No description provided for @preferencesSavedVersion.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved as version {version}.'**
  String preferencesSavedVersion(String version);

  /// No description provided for @sessionRevoked.
  ///
  /// In en, this message translates to:
  /// **'Session revoked.'**
  String get sessionRevoked;

  /// No description provided for @privacyPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm the request.'**
  String get privacyPasswordRequired;

  /// No description provided for @privacyStateRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get privacyStateRequested;

  /// No description provided for @privacyStateInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get privacyStateInReview;

  /// No description provided for @privacyStateCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get privacyStateCompleted;

  /// No description provided for @privacyStateCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get privacyStateCancelled;

  /// No description provided for @privacyStateRetention.
  ///
  /// In en, this message translates to:
  /// **'Retention required'**
  String get privacyStateRetention;

  /// No description provided for @reauthUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Reauthentication unavailable'**
  String get reauthUnavailable;

  /// No description provided for @reauthUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Update the service contract before submitting privacy requests.'**
  String get reauthUnavailableMessage;

  /// No description provided for @signInProtectedRoute.
  ///
  /// In en, this message translates to:
  /// **'Sign in to open this protected destination.'**
  String get signInProtectedRoute;

  /// No description provided for @signInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to continue.'**
  String get signInAgain;

  /// No description provided for @noActionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No action available'**
  String get noActionAvailable;

  /// No description provided for @addressLabelRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an address label.'**
  String get addressLabelRequired;

  /// No description provided for @recipientRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the recipient name.'**
  String get recipientRequired;

  /// No description provided for @streetRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the street and number.'**
  String get streetRequired;

  /// No description provided for @cityRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the city.'**
  String get cityRequired;

  /// No description provided for @provinceRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the province.'**
  String get provinceRequired;

  /// No description provided for @postalCodeValidation.
  ///
  /// In en, this message translates to:
  /// **'The postcode must contain five digits.'**
  String get postalCodeValidation;

  /// No description provided for @notesLengthValidation.
  ///
  /// In en, this message translates to:
  /// **'Notes cannot exceed 500 characters.'**
  String get notesLengthValidation;

  /// No description provided for @completeRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Complete the highlighted fields.'**
  String get completeRequiredFields;

  /// No description provided for @sessionRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Session refreshed.'**
  String get sessionRefreshed;

  /// No description provided for @lastMethodProtection.
  ///
  /// In en, this message translates to:
  /// **'Last sign-in method protection'**
  String get lastMethodProtection;

  /// No description provided for @lastMethodProtectionMessage.
  ///
  /// In en, this message translates to:
  /// **'The final sign-in method cannot be disconnected.'**
  String get lastMethodProtectionMessage;

  /// No description provided for @oneTimeCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Paste and one-time-code autofill are supported.'**
  String get oneTimeCodeHelp;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'it': {
  switch (locale.countryCode) {
    case 'IT': return AppLocalizationsItIt();
   }
  break;
   }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'it': return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
