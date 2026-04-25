import 'package:purchase_hub_core/purchase_hub_core.dart';
import 'package:test/test.dart';

// Helpers

const _productId = 'pro_monthly';

PurchaseProduct _makeProduct({
  String id = _productId,
  SubscriptionPeriod period = SubscriptionPeriod.monthly,
}) => PurchaseProduct(
  id: id,
  title: 'Pro Monthly',
  description: 'Full access',
  priceString: r'$9.99',
  price: 9.99,
  currencyCode: 'USD',
  period: period,
  scope: SubscriptionScope.pro,
);

// Tests

void main() {
  group('MockPurchaseAdapter', () {
    // initialize

    group('initialize()', () {
      test('emits initial subscription to stream', () async {
        final adapter = MockPurchaseAdapter.activeSubscription();
        addTearDown(adapter.dispose);

        final events = <Subscription>[];
        adapter.subscriptionUpdates.listen(events.add);

        await adapter.initialize();
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        expect(events.first.isActive, isTrue);
      });

      test('records the call', () async {
        final adapter = MockPurchaseAdapter();
        addTearDown(adapter.dispose);

        await adapter.initialize();

        expect(adapter.initializeCallCount, 1);
        expect(adapter.lastCall?.method, 'initialize');
      });

      test(
        'throws NetworkFailure when initializeBehavior is networkError',
        () async {
          final adapter = MockPurchaseAdapter.unavailable();
          addTearDown(adapter.dispose);

          await expectLater(
            adapter.initialize(),
            throwsA(isA<NetworkFailure>()),
          );
        },
      );

      test('emits Subscription.none when starting inactive', () async {
        final adapter = MockPurchaseAdapter(
          initialSubscription: Subscription.none,
        );
        addTearDown(adapter.dispose);

        final events = <Subscription>[];
        adapter.subscriptionUpdates.listen(events.add);

        await adapter.initialize();
        await Future<void>.delayed(Duration.zero);

        expect(events, [Subscription.none]);
      });
    });

    // getAvailableProducts

    group('getAvailableProducts()', () {
      test('returns configured products', () async {
        final product = _makeProduct();
        final adapter = MockPurchaseAdapter(
          availableProducts: [product],
        );
        addTearDown(adapter.dispose);

        final result = await adapter.getAvailableProducts();

        expect(result, [product]);
      });

      test('returns updated products after setAvailableProducts', () async {
        final adapter = MockPurchaseAdapter();
        addTearDown(adapter.dispose);

        adapter.setAvailableProducts([_makeProduct()]);
        final result = await adapter.getAvailableProducts();

        expect(result, hasLength(1));
      });

      test('records the call', () async {
        final adapter = MockPurchaseAdapter();
        addTearDown(adapter.dispose);

        await adapter.getAvailableProducts();

        expect(adapter.lastCall?.method, 'getAvailableProducts');
      });
    });

    // purchase

    group('purchase()', () {
      test('succeed — activates subscription and emits update', () async {
        final product = _makeProduct();
        final adapter = MockPurchaseAdapter(
          availableProducts: [product],
          purchaseBehavior: MockPurchaseBehavior.succeed,
        );
        addTearDown(adapter.dispose);

        final events = <Subscription>[];
        adapter.subscriptionUpdates.listen(events.add);

        final result = await adapter.purchase(_productId);

        expect(result.isNewPurchase, isTrue);
        expect(result.subscription.isActive, isTrue);
        expect(result.subscription.productId, _productId);
        expect(result.subscription.period, SubscriptionPeriod.monthly);

        await Future<void>.delayed(Duration.zero);
        expect(events.last.isActive, isTrue);
      });

      test(
        'succeed — falls back to defaults when product not in catalogue',
        () async {
          final adapter = MockPurchaseAdapter(
            purchaseBehavior: MockPurchaseBehavior.succeed,
          );
          addTearDown(adapter.dispose);

          final result = await adapter.purchase('unknown_product');

          expect(result.subscription.isActive, isTrue);
          expect(result.subscription.period, SubscriptionPeriod.monthly);
        },
      );

      test('cancel — throws PurchaseCancelledFailure', () async {
        final adapter = MockPurchaseAdapter(
          purchaseBehavior: MockPurchaseBehavior.cancel,
        );
        addTearDown(adapter.dispose);

        await expectLater(
          adapter.purchase(_productId),
          throwsA(isA<PurchaseCancelledFailure>()),
        );
      });

      test('alreadySubscribed — throws AlreadySubscribedFailure', () async {
        final adapter = MockPurchaseAdapter(
          purchaseBehavior: MockPurchaseBehavior.alreadySubscribed,
        );
        addTearDown(adapter.dispose);

        await expectLater(
          adapter.purchase(_productId),
          throwsA(isA<AlreadySubscribedFailure>()),
        );
      });

      test('networkError — throws NetworkFailure', () async {
        final adapter = MockPurchaseAdapter(
          purchaseBehavior: MockPurchaseBehavior.networkError,
        );
        addTearDown(adapter.dispose);

        await expectLater(
          adapter.purchase(_productId),
          throwsA(isA<NetworkFailure>()),
        );
      });

      test('storeError — throws StoreFailure', () async {
        final adapter = MockPurchaseAdapter(
          purchaseBehavior: MockPurchaseBehavior.storeError,
        );
        addTearDown(adapter.dispose);

        await expectLater(
          adapter.purchase(_productId),
          throwsA(isA<StoreFailure>()),
        );
      });

      test('records call with productId argument', () async {
        final adapter = MockPurchaseAdapter(
          purchaseBehavior: MockPurchaseBehavior.succeed,
        );
        addTearDown(adapter.dispose);

        await adapter.purchase(_productId);

        expect(adapter.purchaseCallCount, 1);
        expect(adapter.lastCall?.method, 'purchase');
        expect(adapter.lastCall?.argument, _productId);
      });

      test('behavior can be changed between calls', () async {
        final adapter = MockPurchaseAdapter(
          purchaseBehavior: MockPurchaseBehavior.succeed,
        );
        addTearDown(adapter.dispose);

        final first = await adapter.purchase(_productId);
        expect(first.subscription.isActive, isTrue);

        adapter.purchaseBehavior = MockPurchaseBehavior.cancel;

        await expectLater(
          adapter.purchase(_productId),
          throwsA(isA<PurchaseCancelledFailure>()),
        );

        expect(adapter.purchaseCallCount, 2);
      });

      test('respects purchaseDelay', () async {
        final adapter = MockPurchaseAdapter(
          purchaseBehavior: MockPurchaseBehavior.succeed,
          purchaseDelay: const Duration(milliseconds: 50),
        );
        addTearDown(adapter.dispose);

        final stopwatch = Stopwatch()..start();
        await adapter.purchase(_productId);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(50));
      });
    });

    // restorePurchases

    group('restorePurchases()', () {
      test('succeed — returns current subscription', () async {
        final adapter = MockPurchaseAdapter.activeSubscription();
        addTearDown(adapter.dispose);

        final result = await adapter.restorePurchases();

        expect(result.isActive, isTrue);
      });

      test('nothingToRestore — throws NoPurchasesToRestoreFailure', () async {
        final adapter = MockPurchaseAdapter(
          initialSubscription: Subscription.none,
          restoreBehavior: MockRestoreBehavior.nothingToRestore,
        );
        addTearDown(adapter.dispose);

        await expectLater(
          adapter.restorePurchases(),
          throwsA(isA<NoPurchasesToRestoreFailure>()),
        );
      });

      test('networkError — throws NetworkFailure', () async {
        final adapter = MockPurchaseAdapter(
          restoreBehavior: MockRestoreBehavior.networkError,
        );
        addTearDown(adapter.dispose);

        await expectLater(
          adapter.restorePurchases(),
          throwsA(isA<NetworkFailure>()),
        );
      });

      test('records the call', () async {
        final adapter = MockPurchaseAdapter.activeSubscription();
        addTearDown(adapter.dispose);

        await adapter.restorePurchases();

        expect(adapter.restoreCallCount, 1);
        expect(adapter.lastCall?.method, 'restorePurchases');
      });
    });

    // setUserId

    group('setUserId()', () {
      test('stores userId and marks as identified', () async {
        final adapter = MockPurchaseAdapter();
        addTearDown(adapter.dispose);

        await adapter.setUserId('user_abc');

        expect(adapter.isIdentified, isTrue);
        expect(adapter.currentUserId, 'user_abc');
      });

      test('setUserId(null) clears identity', () async {
        final adapter = MockPurchaseAdapter();
        addTearDown(adapter.dispose);

        await adapter.setUserId('user_abc');
        await adapter.setUserId(null);

        expect(adapter.isIdentified, isFalse);
        expect(adapter.currentUserId, isNull);
      });

      test('records calls with correct arguments', () async {
        final adapter = MockPurchaseAdapter();
        addTearDown(adapter.dispose);

        await adapter.setUserId('user_abc');
        await adapter.setUserId(null);

        expect(adapter.recordedCalls[0].argument, 'user_abc');
        expect(adapter.recordedCalls[1].argument, isNull);
      });
    });

    // simulateExternalSubscriptionChange

    group('simulateExternalSubscriptionChange()', () {
      test(
        'pushes new subscription to stream and updates currentSubscription',
        () async {
          final adapter = MockPurchaseAdapter();
          addTearDown(adapter.dispose);

          final events = <Subscription>[];
          adapter.subscriptionUpdates.listen(events.add);

          const newSub = Subscription(
            productId: 'pro_annual',
            period: SubscriptionPeriod.annual,
            status: SubscriptionStatus.active,
            scope: SubscriptionScope.pro,
            willRenew: true,
            isTrial: false,
          );

          adapter.simulateExternalSubscriptionChange(newSub);
          await Future<void>.delayed(Duration.zero);

          expect(events.last, newSub);
          expect(adapter.currentSubscription, newSub);
        },
      );
    });

    // recordedCalls

    group('recordedCalls', () {
      test('captures calls in order', () async {
        final adapter = MockPurchaseAdapter(
          purchaseBehavior: MockPurchaseBehavior.succeed,
        );
        addTearDown(adapter.dispose);

        await adapter.initialize();
        await adapter.getCurrentSubscription();
        await adapter.purchase(_productId);
        await adapter.setUserId('u1');

        final methods = adapter.recordedCalls.map((c) => c.method).toList();
        expect(methods, [
          'initialize',
          'getCurrentSubscription',
          'purchase',
          'setUserId',
        ]);
      });

      test('clearRecordedCalls resets call history', () async {
        final adapter = MockPurchaseAdapter();
        addTearDown(adapter.dispose);

        await adapter.initialize();
        expect(adapter.recordedCalls, isNotEmpty);

        adapter.clearRecordedCalls();
        expect(adapter.recordedCalls, isEmpty);
      });
    });

    // Named constructors

    group('named constructors', () {
      test('activeSubscription — starts with active subscription', () async {
        final adapter = MockPurchaseAdapter.activeSubscription(
          productId: 'pro_annual',
          period: SubscriptionPeriod.annual,
        );
        addTearDown(adapter.dispose);

        final sub = await adapter.getCurrentSubscription();

        expect(sub.isActive, isTrue);
        expect(sub.productId, 'pro_annual');
        expect(sub.period, SubscriptionPeriod.annual);
      });

      test('readyToPurchase — starts inactive with succeed behavior', () async {
        final adapter = MockPurchaseAdapter.readyToPurchase(
          products: [_makeProduct()],
        );
        addTearDown(adapter.dispose);

        final sub = await adapter.getCurrentSubscription();
        expect(sub.isActive, isFalse);

        final result = await adapter.purchase(_productId);
        expect(result.subscription.isActive, isTrue);
      });

      test('unavailable — initialize throws NetworkFailure', () async {
        final adapter = MockPurchaseAdapter.unavailable();
        addTearDown(adapter.dispose);

        await expectLater(
          adapter.initialize(),
          throwsA(isA<NetworkFailure>()),
        );
      });
    });
  });
}
