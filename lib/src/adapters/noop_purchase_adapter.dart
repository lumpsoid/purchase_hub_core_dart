import 'dart:async';

import 'package:purchase_hub_core/src/domain/models/purchase_options.dart';
import 'package:purchase_hub_core/src/domain/models/purchase_product.dart';
import 'package:purchase_hub_core/src/domain/models/purchase_result.dart';
import 'package:purchase_hub_core/src/domain/models/subscription.dart';
import 'package:purchase_hub_core/src/ports/purchase_adapter.dart';

/// A no-operation [PurchaseAdapter] that never throws and never purchases.
///
/// Use cases:
/// - Unsupported platforms (web, desktop without a billing SDK).
/// - CI / server-side builds where no store SDK is available.
/// - Fallback while a real adapter is loading.
///
/// All queries return empty / inactive results.
/// All mutations silently succeed and return [Subscription.none].
final class NoOpPurchaseAdapter implements PurchaseAdapter {
  NoOpPurchaseAdapter();

  final StreamController<Subscription> _controller =
      StreamController<Subscription>.broadcast();

  @override
  Future<void> initialize() async {
    // Emit the inactive state once so subscribers don't stall.
    _controller.add(Subscription.none);
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Stream<Subscription> get subscriptionUpdates => _controller.stream;

  @override
  Future<Subscription> getCurrentSubscription() async => Subscription.none;

  @override
  Future<List<PurchaseProduct>> getAvailableProducts() async => const [];

  @override
  Future<PurchaseResult> purchase(
    String productId, {
    PurchaseOptions? options,
  }) async => const PurchaseResult(
    subscription: Subscription.none,
    isNewPurchase: false,
  );

  @override
  Future<Subscription> restorePurchases() async => Subscription.none;

  @override
  Future<void> syncPurchases() => Future.syncValue(null);

  @override
  Future<void> setUserId(String? userId) async {}
}
