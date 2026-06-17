import 'package:meta/meta.dart';

import 'package:purchase_hub_core/src/domain/models/entitlement.dart';
import 'package:purchase_hub_core/src/domain/models/subscription_period.dart';
import 'package:purchase_hub_core/src/domain/models/subscription_scope.dart';
import 'package:purchase_hub_core/src/domain/models/subscription_status.dart';
import 'package:purchase_hub_core/src/domain/models/subscription_store.dart';

/// The resolved subscription state for the current user.
@immutable
final class Subscription {
  const Subscription({
    required this.productId,
    required this.period,
    required this.status,
    required this.scope,
    required this.willRenew,
    required this.isTrial,
    this.store = SubscriptionStore.unknown,
    this.expiresAt,
    this.purchasedAt,
    this.entitlements,
  });

  final String productId;
  final SubscriptionPeriod period;
  final SubscriptionStatus status;
  final SubscriptionScope scope;
  final bool willRenew;
  final bool isTrial;

  /// The store / billing backend this subscription was purchased through.
  final SubscriptionStore store;
  final DateTime? expiresAt;
  final DateTime? purchasedAt;

  /// All active entitlements for this user.
  final Entitlements? entitlements;

  // Sentinel value

  /// Represents the absence of an active subscription.
  static const Subscription none = Subscription(
    productId: '',
    period: SubscriptionPeriod.monthly,
    status: SubscriptionStatus.inactive,
    scope: SubscriptionScope.none,
    willRenew: false,
    isTrial: false,
  );

  // Convenience

  bool get isActive => status.grantsAccess;
  bool get isNone => this == none;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  /// Whether this subscription grants access to [scope].
  bool grantsScope(SubscriptionScope scope) =>
      isActive &&
      (this.scope == scope || this.scope == SubscriptionScope.premium);

  Subscription copyWith({
    String? productId,
    SubscriptionPeriod? period,
    SubscriptionStatus? status,
    SubscriptionScope? scope,
    bool? willRenew,
    bool? isTrial,
    SubscriptionStore? store,
    DateTime? expiresAt,
    DateTime? purchasedAt,
    Entitlements? entitlements,
  }) => Subscription(
    productId: productId ?? this.productId,
    period: period ?? this.period,
    status: status ?? this.status,
    scope: scope ?? this.scope,
    willRenew: willRenew ?? this.willRenew,
    isTrial: isTrial ?? this.isTrial,
    store: store ?? this.store,
    expiresAt: expiresAt ?? this.expiresAt,
    purchasedAt: purchasedAt ?? this.purchasedAt,
    entitlements: entitlements ?? this.entitlements,
  );

  @override
  bool operator ==(Object other) =>
      other is Subscription &&
      other.productId == productId &&
      other.status == status &&
      other.store == store &&
      other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(productId, status, store, expiresAt);

  @override
  String toString() =>
      'Subscription(productId: $productId, status: $status, '
      'period: $period, scope: $scope, store: $store, expiresAt: $expiresAt)';
}
