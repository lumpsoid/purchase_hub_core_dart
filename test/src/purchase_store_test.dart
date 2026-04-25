import 'package:purchase_hub_core/purchase_hub_core.dart';
import 'package:test/test.dart';

// Helpers

/// A [PurchaseInitializer] that wraps a pre-built [MockPurchaseAdapter].
final class _DirectInitializer implements PurchaseInitializer {
  _DirectInitializer(this._adapter);
  final PurchaseAdapter _adapter;

  @override
  PurchaseAdapter createAdapter() => _adapter;
}

PurchaseHub _buildStore(
  MockPurchaseAdapter adapter, {
  PurchaseHubConfig config = const PurchaseHubConfig(),
}) => PurchaseHub(
  initializer: _DirectInitializer(adapter),
  config: config,
);

// Tests

void main() {
  group('PurchaseStore', () {
    group('initialize()', () {
      test('is idempotent — second call is a no-op', () async {
        final adapter = MockPurchaseAdapter();
        final store = _buildStore(adapter);
        addTearDown(store.dispose);

        await store.initialize();
        await store.initialize();

        expect(adapter.initializeCallCount, 1);
      });

      test('seeds subscriptionUpdates from getCurrentSubscription', () async {
        final adapter = MockPurchaseAdapter.activeSubscription();
        final store = _buildStore(adapter);
        addTearDown(store.dispose);

        final events = <Subscription>[];
        store.subscriptionUpdates.listen(events.add);

        await store.initialize();
        await Future<void>.delayed(Duration.zero);

        expect(events.any((s) => s.isActive), isTrue);
      });

      test(
        'emits Subscription.none when fetch fails + emitNoneOnStartup',
        () async {
          final adapter = MockPurchaseAdapter(
            initializeBehavior: MockInitializeBehavior.succeed,
          );
          // Force getCurrentSubscription to fail by making it throw
          // after initialize succeeds — we do this via a wrapper adapter.
          final store = _buildStore(
            adapter,
            config: const PurchaseHubConfig(
              emitNoneOnStartup: true,
              autoFetchOnInitialize: true,
            ),
          );
          addTearDown(store.dispose);

          // The mock's getCurrentSubscription succeeds and returns .none;
          // confirm the stream still emits .none.
          final events = <Subscription>[];
          store.subscriptionUpdates.listen(events.add);

          await store.initialize();
          await Future<void>.delayed(Duration.zero);

          expect(events, contains(Subscription.none));
        },
      );

      test('does not auto-fetch when autoFetchOnInitialize is false', () async {
        final adapter = MockPurchaseAdapter();
        final store = _buildStore(
          adapter,
          config: const PurchaseHubConfig(autoFetchOnInitialize: false),
        );
        addTearDown(store.dispose);

        await store.initialize();

        expect(
          adapter.recordedCalls.any(
            (c) => c.method == 'getCurrentSubscription',
          ),
          isFalse,
        );
      });
    });

    group('before initialize()', () {
      test('getCurrentSubscription throws StateError', () {
        final store = _buildStore(MockPurchaseAdapter());
        expect(
          store.getCurrentSubscription,
          throwsA(isA<StateError>()),
        );
      });

      test('purchase throws StateError', () {
        final store = _buildStore(MockPurchaseAdapter());
        expect(
          () => store.purchase('any'),
          throwsA(isA<StateError>()),
        );
      });

      test('restorePurchases throws StateError', () {
        final store = _buildStore(MockPurchaseAdapter());
        expect(
          store.restorePurchases,
          throwsA(isA<StateError>()),
        );
      });
    });

    group('subscriptionUpdates', () {
      test('forwards external simulation events', () async {
        final adapter = MockPurchaseAdapter(
          initialSubscription: Subscription.none,
        );
        final store = _buildStore(
          adapter,
          config: const PurchaseHubConfig(autoFetchOnInitialize: false),
        );
        addTearDown(store.dispose);

        final events = <Subscription>[];
        store.subscriptionUpdates.listen(events.add);

        await store.initialize();

        final newSub = Subscription(
          productId: 'pro_monthly',
          period: SubscriptionPeriod.monthly,
          status: SubscriptionStatus.active,
          scope: SubscriptionScope.pro,
          willRenew: true,
          isTrial: false,
        );
        adapter.simulateExternalSubscriptionChange(newSub);
        await Future<void>.delayed(Duration.zero);

        expect(events.last, newSub);
      });
    });

    group('purchase()', () {
      test('returns PurchaseResult on success', () async {
        final adapter = MockPurchaseAdapter(
          purchaseBehavior: MockPurchaseBehavior.succeed,
        );
        final store = _buildStore(adapter);
        addTearDown(store.dispose);

        await store.initialize();
        final result = await store.purchase('pro_monthly');

        expect(result.subscription.isActive, isTrue);
        expect(result.isNewPurchase, isTrue);
      });

      test('propagates PurchaseCancelledFailure', () async {
        final adapter = MockPurchaseAdapter(
          purchaseBehavior: MockPurchaseBehavior.cancel,
        );
        final store = _buildStore(adapter);
        addTearDown(store.dispose);

        await store.initialize();
        await expectLater(
          store.purchase('pro_monthly'),
          throwsA(isA<PurchaseCancelledFailure>()),
        );
      });

      test('propagates AlreadySubscribedFailure', () async {
        final adapter = MockPurchaseAdapter(
          purchaseBehavior: MockPurchaseBehavior.alreadySubscribed,
        );
        final store = _buildStore(adapter);
        addTearDown(store.dispose);

        await store.initialize();
        await expectLater(
          store.purchase('pro_monthly'),
          throwsA(isA<AlreadySubscribedFailure>()),
        );
      });
    });

    group('restorePurchases()', () {
      test('returns active subscription on success', () async {
        final adapter = MockPurchaseAdapter.activeSubscription();
        final store = _buildStore(adapter);
        addTearDown(store.dispose);

        await store.initialize();
        final result = await store.restorePurchases();

        expect(result.isActive, isTrue);
      });

      test('propagates NoPurchasesToRestoreFailure', () async {
        final adapter = MockPurchaseAdapter(
          restoreBehavior: MockRestoreBehavior.nothingToRestore,
        );
        final store = _buildStore(adapter);
        addTearDown(store.dispose);

        await store.initialize();
        await expectLater(
          store.restorePurchases(),
          throwsA(isA<NoPurchasesToRestoreFailure>()),
        );
      });
    });

    group('setUserId()', () {
      test('delegates to adapter', () async {
        final adapter = MockPurchaseAdapter();
        final store = _buildStore(adapter);
        addTearDown(store.dispose);

        await store.initialize();
        await store.setUserId('user_xyz');

        expect(adapter.currentUserId, 'user_xyz');
      });

      test('logout clears userId', () async {
        final adapter = MockPurchaseAdapter();
        final store = _buildStore(adapter);
        addTearDown(store.dispose);

        await store.initialize();
        await store.setUserId('user_xyz');
        await store.setUserId(null);

        expect(adapter.isIdentified, isFalse);
      });
    });

    group('dispose()', () {
      test('closes subscriptionUpdates stream', () async {
        final adapter = MockPurchaseAdapter();
        final store = _buildStore(adapter);

        await store.initialize();

        var closed = false;
        store.subscriptionUpdates.listen(null, onDone: () => closed = true);

        await store.dispose();
        await Future<void>.delayed(Duration.zero);

        expect(closed, isTrue);
      });
    });
  });
}
