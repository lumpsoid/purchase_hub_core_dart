import 'package:meta/meta.dart';
import 'package:purchase_hub_core/purchase_hub_core.dart'
    show PurchaseHub, Subscription;

/// Tunable knobs for [PurchaseHub] behaviour.
@immutable
final class PurchaseHubConfig {
  const PurchaseHubConfig({
    this.offeringId = 'default',
    this.emitNoneOnStartup = true,
    this.autoFetchOnInitialize = true,
  });

  /// The offering ID to fetch from the store. `"default"` uses the
  /// currently-active offering in the dashboard.
  final String offeringId;

  /// When `true`, [PurchaseHub.subscriptionUpdates] emits
  /// [Subscription.none] immediately if no active subscription is found
  /// during initialisation — preventing indefinite loading states.
  final bool emitNoneOnStartup;

  /// When `true`, [PurchaseHub.initialize] eagerly fetches
  /// [PurchaseHub.getCurrentSubscription] and seeds
  /// [PurchaseHub.subscriptionUpdates].
  final bool autoFetchOnInitialize;
}
