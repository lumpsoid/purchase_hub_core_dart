import 'package:purchase_hub_core/purchase_hub_core.dart' show Subscription;
import 'package:purchase_hub_core/src/domain/models/subscription.dart' show Subscription;

/// Lifecycle state of a subscription.
enum SubscriptionStatus {
  /// Active and paid.
  active,

  /// Within grace period after a billing failure — still grants access.
  gracePeriod,

  /// Billing failed and grace period has ended.
  billingRetry,

  /// Voluntarily cancelled; still active until [Subscription.expiresAt].
  cancelled,

  /// Expired or never purchased.
  inactive,

  /// The store returned an unknown state.
  unknown
  ;

  /// Convenience: any status that should grant content access.
  bool get grantsAccess => switch (this) {
    active || gracePeriod || cancelled => true,
    _ => false,
  };
}
