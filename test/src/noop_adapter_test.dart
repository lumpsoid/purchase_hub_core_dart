import 'package:purchase_hub_core/purchase_hub_core.dart';
import 'package:test/test.dart';

void main() {
  group('NoOpPurchaseAdapter', () {
    late NoOpPurchaseAdapter adapter;

    setUp(() => adapter = NoOpPurchaseAdapter());
    tearDown(() => adapter.dispose());

    test('initialize emits Subscription.none', () async {
      final events = <Subscription>[];
      adapter.subscriptionUpdates.listen(events.add);

      await adapter.initialize();
      await Future<void>.delayed(Duration.zero);

      expect(events, [Subscription.none]);
    });

    test('getCurrentSubscription returns Subscription.none', () async {
      final result = await adapter.getCurrentSubscription();
      expect(result, Subscription.none);
    });

    test('getAvailableProducts returns empty list', () async {
      final result = await adapter.getAvailableProducts();
      expect(result, isEmpty);
    });

    test('purchase returns inactive PurchaseResult', () async {
      final result = await adapter.purchase('any_product');
      expect(result.subscription.isActive, isFalse);
      expect(result.isNewPurchase, isFalse);
    });

    test('restorePurchases returns Subscription.none', () async {
      final result = await adapter.restorePurchases();
      expect(result, Subscription.none);
    });

    test('setUserId does not throw', () async {
      await expectLater(adapter.setUserId('user_123'), completes);
      await expectLater(adapter.setUserId(null), completes);
    });

    test('dispose closes the stream', () async {
      await adapter.initialize();
      await adapter.dispose();

      // Attempting to listen after close should not receive events.
      var received = false;
      adapter.subscriptionUpdates.listen((_) => received = true);
      await Future<void>.delayed(Duration.zero);

      expect(received, isFalse);
    });
  });
}
