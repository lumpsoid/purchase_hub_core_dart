import 'package:meta/meta.dart';
import 'package:purchase_hub_core/purchase_hub_core.dart' show PurchaseAdapter;
import 'package:purchase_hub_core/src/domain/models/subscription.dart';
import 'package:purchase_hub_core/src/ports/purchase_adapter.dart'
    show PurchaseAdapter;

/// The outcome of a [PurchaseAdapter.purchase] call.
@immutable
final class PurchaseResult {
  const PurchaseResult({
    this.isNewPurchase = true,
    this.subscription,
  });

  /// The resolved subscription after the purchase.
  /// Can be null if it was not a subscription purchase.
  final Subscription? subscription;

  /// `false` when the purchase was already owned (e.g. cross-device restore).
  final bool isNewPurchase;

  @override
  String toString() =>
      'PurchaseResult(subscription: $subscription, '
      'isNewPurchase: $isNewPurchase)';
}
