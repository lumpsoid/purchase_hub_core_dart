/// Billing cadence for a subscription product.
enum SubscriptionPeriod {
  /// Not known / not set.
  unknown,

  /// A custom period defined by the developer.
  custom,

  /// Weekly billing (7 days).
  weekly,

  /// Monthly billing (≈30 days).
  monthly,

  /// Exactly two months.
  twoMonth,

  /// Quarterly billing (3 months).
  quarterly,

  /// Six‑month / semi‑annual billing.
  semiAnnual,

  /// Yearly billing (12 months).
  annual,

  /// Lifetime, non‑renewing purchase.
  lifetime
  ;

  /// Whether this period represents a one-time, non-renewing purchase.
  bool get isOneTime => this == lifetime;
}
