import 'package:meta/meta.dart';
import 'package:purchase_hub_core/purchase_hub_core.dart' show PurchaseHub;
import 'package:purchase_hub_core/src/hub/purchase_hub.dart' show PurchaseHub;

/// The feature-set unlocked by a subscription.
///
/// Extend this with a factory if your app has custom scopes.
@immutable
final class SubscriptionScope {
  const SubscriptionScope(this.id);

  /// Derive a scope from a product identifier.
  ///
  /// Override this factory by registering a custom [ScopeMatcher] on
  /// [PurchaseHub] if your product IDs follow a different naming scheme.
  factory SubscriptionScope.fromProductId(String productId) {
    final id = productId.toLowerCase();
    if (id.contains('premium')) return premium;
    if (id.contains('family')) return family;
    if (id.contains('pro')) return pro;
    return none;
  }

  /// The raw scope identifier, typically derived from the product ID.
  final String id;

  // Well-known scopes

  static const SubscriptionScope none = SubscriptionScope('none');
  static const SubscriptionScope pro = SubscriptionScope('pro');
  static const SubscriptionScope premium = SubscriptionScope('premium');
  static const SubscriptionScope family = SubscriptionScope('family');

  @override
  bool operator ==(Object other) =>
      other is SubscriptionScope && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SubscriptionScope($id)';
}
