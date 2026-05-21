/// Platform-agnostic replacement mode used when upgrading or downgrading
/// an existing subscription.
enum PurchaseReplacementMode {
  /// Replacement takes effect immediately.
  /// Remaining time on the old plan is prorated and credited.
  immediateWithTimeProration,

  /// Replacement takes effect immediately.
  /// The new price is charged on the next renewal; billing cycle is unchanged.
  immediateWithoutProration,

  /// Replacement takes effect immediately.
  /// The user is charged the full price of the new plan immediately and
  /// receives a full new billing cycle, plus prorated credit from the old plan.
  immediateAndChargeFullPrice,

  /// Replacement takes effect immediately.
  /// The user is charged a prorated price for the new plan immediately;
  /// the billing cycle stays the same.
  immediateAndChargeProratedPrice,

  /// Replacement takes effect when the current plan expires.
  /// The new price is charged at the next renewal date.
  deferred,
}
