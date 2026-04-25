/// Billing cadence for a subscription product.
enum SubscriptionPeriod {
  weekly,
  monthly,
  quarterly,
  semiAnnual,
  annual,
  lifetime
  ;

  /// Whether this period represents a one-time, non-renewing purchase.
  bool get isOneTime => this == lifetime;
}
