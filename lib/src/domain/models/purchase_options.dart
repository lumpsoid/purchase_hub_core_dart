import 'package:purchase_hub_core/src/domain/models/purchase_replacement_mode.dart';

/// Optional context for a purchase call.
///
/// Pass this when the user is upgrading or downgrading an existing subscription
/// so that adapters that support mid-cycle transitions can apply the correct
/// proration behaviour.
///
/// ### Example — upgrading from a monthly to an annual plan:
/// ```dart
/// await hub.purchase(
///   'pro_annual',
///   options: PurchaseOptions(
///     currentProductId: currentSubscription.productId,
///     replacementMode: PurchaseReplacementMode.deferred,
///   ),
/// );
/// ```
final class PurchaseOptions {
  const PurchaseOptions({
    required this.currentProductId,
    this.replacementMode,
  });

  /// The product identifier the user currently holds and wishes to replace.
  final String currentProductId;

  /// How the transition should be handled mid-cycle.
  ///
  /// Ignored on platforms that do not support explicit proration control.
  final PurchaseReplacementMode? replacementMode;

  @override
  String toString() =>
      'PurchaseOptions(currentProductId: $currentProductId, '
      'replacementMode: $replacementMode)';
}
