import 'package:la_favola_generated_api/la_favola_api.dart';

enum Week2Operation {
  register,
  login,
  verifyEmail,
  resendVerification,
  requestRecovery,
  resetPassword,
  startFederated,
  completeFederated,
  reauthenticate,
  refreshSession,
  logout,
  getProfile,
  updateProfile,
  getAddresses,
  createAddress,
  updateAddress,
  archiveAddress,
  getPreferences,
  updatePreferences,
  getSecuritySessions,
  revokeSecuritySession,
  requestPrivacyExport,
  requestPrivacyDeletion,
  getPrivacyRequest,
  getMenu,
  getMenuItem,
  // Commerce additions
  createQuote,
  getQuote,
  applyPromotion,
  getOrders,
  getOrder,
  cancelOrder,
}

enum Week2FailureKind {
  validation,
  unauthenticated,
  verificationRequired,
  forbidden,
  notFound,
  rateLimited,
  dependencyUnavailable,
  timeout,
  conflict,
  sessionExpired,
  sessionRevoked,
  sessionReuseDetected,
  providerCancelled,
  providerDenied,
  providerUnavailable,
  malformedResponse,
}

final class Week2Failure implements Exception {
  const Week2Failure({
    required this.kind,
    required this.message,
    required this.correlationId,
    this.retryable = false,
    this.field,
    this.fieldErrors = const {},
    this.currentVersion,
  });

  final Week2FailureKind kind;
  final String message;
  final String correlationId;
  final bool retryable;
  final String? field;
  final Map<String, String> fieldErrors;
  final String? currentVersion;

  @override
  String toString() => 'Week2Failure($kind, $correlationId)';
}

final class CustomerSession {
  const CustomerSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.sessionId,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String sessionId;
}

final class ProviderIntent {
  const ProviderIntent({
    required this.provider,
    required this.intentId,
    required this.nonce,
    required this.state,
    required this.live,
  });

  final String provider;
  final String intentId;
  final String nonce;
  final String state;
  final bool live;
}

final class CustomerProfile {
  const CustomerProfile({
    required this.version,
    required this.displayName,
    required this.email,
    required this.emailVerified,
    required this.phone,
    required this.locale,
  });

  final String version;
  final String displayName;
  final String email;
  final bool emailVerified;
  final String? phone;
  final String locale;

  CustomerProfile copyWith({
    String? version,
    String? displayName,
    String? phone,
    bool clearPhone = false,
  }) {
    return CustomerProfile(
      version: version ?? this.version,
      displayName: displayName ?? this.displayName,
      email: email,
      emailVerified: emailVerified,
      phone: clearPhone ? null : phone ?? this.phone,
      locale: locale,
    );
  }
}

final class CustomerAddress {
  const CustomerAddress({
    required this.id,
    required this.version,
    required this.label,
    required this.recipientName,
    required this.addressLine,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.countryCode,
    required this.deliveryNotes,
    required this.isDefault,
    required this.archivedAt,
  });

  final String id;
  final String version;
  final String label;
  final String recipientName;
  final String addressLine;
  final String city;
  final String province;
  final String postalCode;
  final String countryCode;
  final String? deliveryNotes;
  final bool isDefault;
  final String? archivedAt;

  CustomerAddress copyWith({
    String? version,
    String? label,
    String? recipientName,
    String? addressLine,
    String? city,
    String? province,
    String? postalCode,
    String? deliveryNotes,
    bool? isDefault,
    String? archivedAt,
  }) {
    return CustomerAddress(
      id: id,
      version: version ?? this.version,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      province: province ?? this.province,
      postalCode: postalCode ?? this.postalCode,
      countryCode: countryCode,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      isDefault: isDefault ?? this.isDefault,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }
}

final class CustomerPreferences {
  const CustomerPreferences({
    required this.version,
    required this.marketingEmailOptIn,
    required this.securityAlertsEnabled,
  });

  final String version;
  final bool marketingEmailOptIn;
  final bool securityAlertsEnabled;
}

final class SecuritySession {
  const SecuritySession({
    required this.id,
    required this.createdAt,
    required this.lastUsedAt,
    required this.expiresAt,
    required this.deviceLabel,
    required this.current,
  });

  final String id;
  final String createdAt;
  final String lastUsedAt;
  final String expiresAt;
  final String? deviceLabel;
  final bool current;
}

enum PrivacyRequestKind { export, deletion }

enum PrivacyRequestState {
  requested,
  inReview,
  completed,
  cancelled,
  retentionRequired,
}

final class PrivacyRequest {
  const PrivacyRequest({
    required this.id,
    required this.kind,
    required this.state,
    required this.requestedAt,
    required this.completedAt,
    required this.recoveryAction,
  });

  final String id;
  final PrivacyRequestKind kind;
  final PrivacyRequestState state;
  final String requestedAt;
  final String? completedAt;
  final String? recoveryAction;
}

final class MenuItemSummary {
  const MenuItemSummary({
    required this.id,
    required this.version,
    required this.categoryId,
    required this.name,
    this.description,
    this.price,
    this.note,
    this.attributes = const [],
    required this.displayOrder,
    this.syntheticMediaReference,
    this.basePriceMinor,
    this.allergenTags = const [],
    this.dietaryTags = const [],
    this.isBuilderProduct = false,
    this.availabilityState,
    this.optionGroups = const [],
  });

  final String id;
  final String version;
  final String categoryId;
  final String name;
  final String? description;
  final String? price;
  final String? note;
  final List<String> attributes;
  final int displayOrder;
  final String? syntheticMediaReference;
  final int? basePriceMinor;
  final List<String> allergenTags;
  final List<String> dietaryTags;
  final bool isBuilderProduct;
  final String? availabilityState;
  final List<OptionGroupSummary> optionGroups;
}

final class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.version,
    required this.parentCategoryId,
    required this.name,
    required this.description,
    required this.displayOrder,
    required this.items,
    this.optionGroups = const [],
  });

  final String id;
  final String version;
  final String? parentCategoryId;
  final String name;
  final String? description;
  final int displayOrder;
  final List<MenuItemSummary> items;
  final List<OptionGroupSummary> optionGroups;
}

final class MenuSnapshot {
  const MenuSnapshot({
    required this.catalogVersion,
    required this.categories,
    this.isStale = false,
  });

  final String catalogVersion;
  final List<MenuCategory> categories;
  final bool isStale;
}

// ===== WEEK 3 MODELS =====

final class OptionGroupSummary {
  const OptionGroupSummary({
    required this.id,
    required this.version,
    required this.name,
    this.description,
    required this.displayOrder,
    required this.required,
    required this.minChoices,
    required this.maxChoices,
    required this.appliesToItemIds,
    required this.choices,
    required this.state,
  });

  final String id;
  final String version;
  final String name;
  final String? description;
  final int displayOrder;
  final bool required;
  final int minChoices;
  final int maxChoices;
  final List<String> appliesToItemIds;
  final List<OptionChoiceSummary> choices;
  final String state;
}

final class OptionChoiceSummary {
  const OptionChoiceSummary({
    required this.id,
    required this.version,
    required this.optionGroupId,
    required this.name,
    this.description,
    required this.displayOrder,
    required this.priceAdjustmentMinor,
    required this.allergenTags,
    required this.dietaryTags,
    required this.available,
    required this.state,
  });

  final String id;
  final String version;
  final String optionGroupId;
  final String name;
  final String? description;
  final int displayOrder;
  final int priceAdjustmentMinor;
  final List<String> allergenTags;
  final List<String> dietaryTags;
  final bool available;
  final String state;
}

final class BuilderRuleSummary {
  const BuilderRuleSummary({
    required this.id,
    required this.version,
    required this.itemId,
    required this.groupSequence,
  });

  final String id;
  final String version;
  final String itemId;
  final List<String> groupSequence;
}

final class PriceRuleSummary {
  const PriceRuleSummary({
    required this.id,
    required this.version,
    required this.targetType,
    required this.targetId,
    required this.basePriceMinor,
    required this.currency,
    required this.effectiveFrom,
    this.effectiveTo,
  });

  final String id;
  final String version;
  final String targetType;
  final String targetId;
  final int basePriceMinor;
  final String currency;
  final String effectiveFrom;
  final String? effectiveTo;
}

final class PromotionSummary {
  const PromotionSummary({
    required this.id,
    required this.version,
    required this.code,
    required this.name,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.maxDiscountMinor,
    required this.minOrderMinor,
    required this.eligibleItemIds,
    required this.eligibleCategoryIds,
    this.stackingGroup,
    this.usageLimitTotal,
    required this.usageLimitPerCustomer,
    required this.validFrom,
    required this.validTo,
    required this.active,
  });

  final String id;
  final String version;
  final String code;
  final String name;
  final String? description;
  final String discountType;
  final int discountValue;
  final int? maxDiscountMinor;
  final int minOrderMinor;
  final List<String> eligibleItemIds;
  final List<String> eligibleCategoryIds;
  final String? stackingGroup;
  final int? usageLimitTotal;
  final int usageLimitPerCustomer;
  final String validFrom;
  final String validTo;
  final bool active;
}

// ===== WEEK 3 QUOTE MODELS =====

final class QuoteLineInput {
  const QuoteLineInput({
    required this.itemId,
    required this.quantity,
    required this.choiceIds,
  });

  final String itemId;
  final int quantity;
  final List<String> choiceIds;

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'quantity': quantity,
    'choiceIds': choiceIds,
  };
}

enum FulfillmentType { delivery, pickup }

enum PaymentMethod { onlineCard, cash }

final class FulfillmentContext {
  const FulfillmentContext({
    required this.type,
    this.addressId,
    this.scheduledFor,
  });

  final FulfillmentType type;
  final String? addressId;
  final String? scheduledFor;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    if (addressId != null) 'addressId': addressId,
    if (scheduledFor != null) 'scheduledFor': scheduledFor,
  };
}

final class FulfillmentAvailability {
  const FulfillmentAvailability({
    required this.serverNow,
    required this.timezone,
    required this.date,
    required this.orderType,
    required this.leadMinutes,
    required this.asapAvailable,
    required this.slots,
    this.estimatedReadyAt,
    this.estimatedDeliveryAt,
  });

  final String serverNow;
  final String timezone;
  final String date;
  final FulfillmentType orderType;
  final int leadMinutes;
  final bool asapAvailable;
  final String? estimatedReadyAt;
  final String? estimatedDeliveryAt;
  final List<FulfillmentSlot> slots;
}

final class FulfillmentSlot {
  const FulfillmentSlot({required this.scheduledFor, required this.localTime});

  final String scheduledFor;
  final String localTime;
}

final class QuoteLineChoice {
  const QuoteLineChoice({
    required this.choiceId,
    required this.name,
    required this.priceAdjustmentMinor,
  });

  final String choiceId;
  final String name;
  final int priceAdjustmentMinor;
}

final class QuoteLine {
  const QuoteLine({
    required this.itemId,
    required this.itemVersion,
    required this.name,
    required this.quantity,
    required this.choices,
    required this.unitBasePriceMinor,
    required this.unitTotalMinor,
    required this.lineTotalMinor,
  });

  final String itemId;
  final String itemVersion;
  final String name;
  final int quantity;
  final List<QuoteLineChoice> choices;
  final int unitBasePriceMinor;
  final int unitTotalMinor;
  final int lineTotalMinor;
}

final class AppliedPromotion {
  const AppliedPromotion({
    required this.id,
    required this.code,
    required this.discountMinor,
    this.stackingGroup,
  });

  final String id;
  final String code;
  final int discountMinor;
  final String? stackingGroup;
}

final class QuoteWarning {
  const QuoteWarning({
    required this.path,
    required this.code,
    required this.message,
  });

  final String path;
  final String code;
  final String message;
}

final class Quote {
  const Quote({
    required this.quoteId,
    required this.catalogVersion,
    required this.configurationVersion,
    required this.expiresAt,
    required this.lines,
    required this.subtotalMinor,
    required this.discountMinor,
    required this.feeMinor,
    required this.taxMinor,
    required this.totalMinor,
    required this.currency,
    required this.appliedPromotions,
    required this.warnings,
  });

  final String quoteId;
  final String catalogVersion;
  final String configurationVersion;
  final String expiresAt;
  final List<QuoteLine> lines;
  final int subtotalMinor;
  final int discountMinor;
  final int feeMinor;
  final int taxMinor;
  final int totalMinor;
  final String currency;
  final List<AppliedPromotion> appliedPromotions;
  final List<QuoteWarning> warnings;
}

final class OrderReceipt {
  const OrderReceipt({
    required this.orderId,
    required this.reference,
    required this.status,
    required this.totalMinor,
    required this.currency,
    required this.createdAt,
    this.orderSource = 'customer_app',
    this.fulfillmentType = 'delivery',
    this.version = '1',
    this.paymentMethod = PaymentMethod.cash,
    this.paymentStatus = 'collection_pending',
    this.cancellationStatus = 'not_requested',
    this.refundStatus = 'not_applicable',
    this.refundMinor = 0,
    this.etaMinutes,
    this.estimatedReadyAt,
    this.estimatedDeliveryAt,
    this.estimateUpdatedAt,
    this.serverTime,
    this.tableLabel,
    this.guestName,
    this.timeline = const [],
  });

  final String orderId;
  final String reference;
  final String status;
  final int totalMinor;
  final String currency;
  final String createdAt;
  final String orderSource;
  final String fulfillmentType;
  final String version;
  final PaymentMethod paymentMethod;
  final String paymentStatus;
  final String cancellationStatus;
  final String refundStatus;
  final int refundMinor;
  final int? etaMinutes;
  final String? estimatedReadyAt;
  final String? estimatedDeliveryAt;
  final String? estimateUpdatedAt;
  final String? serverTime;
  final String? tableLabel;
  final String? guestName;
  final List<OrderTimelineEvent> timeline;
}

final class CustomerOrderReceiptDocument {
  const CustomerOrderReceiptDocument({
    required this.documentType,
    required this.fiscalDocument,
    required this.issuedAt,
    required this.restaurant,
    required this.order,
    required this.notice,
  });

  final String documentType;
  final bool fiscalDocument;
  final String issuedAt;
  final ReceiptRestaurant restaurant;
  final ReceiptOrder order;
  final String notice;
}

final class ReceiptRestaurant {
  const ReceiptRestaurant({
    required this.name,
    required this.address,
    this.vatNumber,
    this.fiscalCode,
    this.phone,
    this.email,
  });

  final String name;
  final List<String> address;
  final String? vatNumber;
  final String? fiscalCode;
  final String? phone;
  final String? email;
}

final class ReceiptOrder {
  const ReceiptOrder({
    required this.number,
    required this.type,
    required this.status,
    required this.paymentStatus,
    required this.currency,
    required this.items,
    required this.totals,
    this.paymentMethod,
  });

  final String number;
  final String type;
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final String currency;
  final List<ReceiptOrderItem> items;
  final ReceiptTotals totals;
}

final class ReceiptOrderItem {
  const ReceiptOrderItem({
    required this.name,
    required this.quantity,
    required this.unitPriceMinor,
    required this.lineTotalMinor,
    required this.options,
    this.size,
  });

  final String name;
  final String? size;
  final int quantity;
  final int unitPriceMinor;
  final int lineTotalMinor;
  final List<ReceiptOrderOption> options;
}

final class ReceiptOrderOption {
  const ReceiptOrderOption({
    required this.name,
    required this.quantity,
    required this.totalPriceAdjustmentMinor,
  });

  final String name;
  final int quantity;
  final int totalPriceAdjustmentMinor;
}

final class ReceiptTotals {
  const ReceiptTotals({
    required this.subtotalMinor,
    required this.optionChargesMinor,
    required this.discountMinor,
    required this.deliveryFeeMinor,
    required this.taxMinor,
    required this.grandTotalMinor,
  });

  final int subtotalMinor;
  final int optionChargesMinor;
  final int discountMinor;
  final int deliveryFeeMinor;
  final int taxMinor;
  final int grandTotalMinor;
}

final class OrderRealtimeEvent {
  const OrderRealtimeEvent({required this.sequence, required this.orderId});
  final String sequence;
  final String orderId;
}

final class OrderTimelineEvent {
  const OrderTimelineEvent({
    required this.type,
    required this.priorStatus,
    required this.nextStatus,
    required this.reason,
    required this.occurredAt,
  });

  final String type;
  final String? priorStatus;
  final String? nextStatus;
  final String? reason;
  final String occurredAt;
}

abstract interface class Week2Gateway {
  Set<String> get configuredFederatedProviders;
  bool get supportsCustomerReauthentication;
  Map<String, JsonOperationContract> get generatedOperations;

  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  });

  Future<CustomerSession> login({
    required String email,
    required String password,
  });

  Future<void> verifyEmail(String token);
  Future<void> resendVerification(String email);
  Future<void> requestPasswordRecovery(String email);

  Future<void> resetPassword({required String token, required String password});

  Future<ProviderIntent> startFederated(String provider);

  Future<CustomerSession> completeFederated({
    required ProviderIntent intent,
    required String result,
  });

  Future<String> reauthenticate(String password);
  Future<CustomerSession> refreshSession(String refreshToken);
  Future<void> logout();
  Future<CustomerProfile> getProfile();

  Future<CustomerProfile> updateProfile({
    required String displayName,
    required String? phone,
    required String expectedVersion,
  });

  Future<List<CustomerAddress>> getAddresses();
  Future<CustomerAddress> createAddress(CustomerAddress input);
  Future<CustomerAddress> updateAddress(CustomerAddress input);
  Future<CustomerAddress> archiveAddress(CustomerAddress input);
  Future<CustomerPreferences> getPreferences();

  Future<CustomerPreferences> updatePreferences({
    required bool marketingEmailOptIn,
    required String expectedVersion,
  });

  Future<List<SecuritySession>> getSecuritySessions();
  Future<void> revokeSecuritySession(String id);
  Future<PrivacyRequest> requestPrivacyExport(String reauthenticationProof);
  Future<PrivacyRequest> requestPrivacyDeletion(String reauthenticationProof);
  Future<PrivacyRequest> getPrivacyRequest(String id);
  Future<MenuSnapshot> getMenu();
  Future<MenuItemSummary> getMenuItem(String id);
  Future<FulfillmentAvailability> getFulfillmentAvailability({
    required FulfillmentType type,
    String? date,
    String? menuItemId,
  });

  // Quotes and promotions
  Future<Quote> createQuote({
    required String locationId,
    required List<QuoteLineInput> lines,
    required FulfillmentContext fulfillmentContext,
    String? couponCode,
    bool loyaltyIntent = false,
  });
  Future<Quote> getQuote(String quoteId);
  Future<Quote> applyPromotion(String quoteId, String code);
  Future<OrderReceipt> submitOrder(String quoteId, PaymentMethod paymentMethod);
  Future<List<OrderReceipt>> getOrders();
  Future<OrderReceipt> getOrder(String orderId);
  Future<CustomerOrderReceiptDocument> getOrderReceipt(String orderId);
  Stream<OrderRealtimeEvent> watchOrderEvents(String orderId);
  Future<OrderReceipt> requestOrderCancellation({
    required String orderId,
    required String expectedVersion,
    required String reason,
  });
}
