import 'dart:async';

import 'package:meta/meta.dart';
import 'package:purchase_hub_core/src/domain/failures/purchase_failure.dart';
import 'package:purchase_hub_core/src/domain/models/purchase_product.dart';
import 'package:purchase_hub_core/src/domain/models/purchase_result.dart';
import 'package:purchase_hub_core/src/domain/models/subscription.dart';
import 'package:purchase_hub_core/src/domain/models/subscription_period.dart';
import 'package:purchase_hub_core/src/domain/models/subscription_scope.dart';
import 'package:purchase_hub_core/src/domain/models/subscription_status.dart';
import 'package:purchase_hub_core/src/ports/purchase_adapter.dart';

// Behaviour configuration

/// Controls what [MockPurchaseAdapter.purchase] does.
enum MockPurchaseBehavior {
  /// Complete successfully and activate the purchased product.
  succeed,

  /// Throw [PurchaseCancelledFailure].
  cancel,

  /// Throw [AlreadySubscribedFailure].
  alreadySubscribed,

  /// Throw [NetworkFailure].
  networkError,

  /// Throw [StoreFailure].
  storeError,
}

/// Controls what [MockPurchaseAdapter.restorePurchases] does.
enum MockRestoreBehavior {
  /// Return the current [MockPurchaseAdapter.currentSubscription].
  succeed,

  /// Throw [NoPurchasesToRestoreFailure].
  nothingToRestore,

  /// Throw [NetworkFailure].
  networkError,
}

/// Controls what [MockPurchaseAdapter.initialize] does.
enum MockInitializeBehavior {
  /// Complete normally.
  succeed,

  /// Throw [NetworkFailure] to simulate SDK init failure.
  networkError,
}

// Recorded call

/// An invocation recorded by [MockPurchaseAdapter].
@immutable
final class RecordedCall {
  const RecordedCall(this.method, {this.argument});

  final String method;
  final Object? argument;

  @override
  String toString() => argument == null
      ? 'RecordedCall($method)'
      : 'RecordedCall($method, argument: $argument)';
}

// Adapter

/// A fully configurable in-process [PurchaseAdapter] for testing and
/// development.
///
/// ### Quick start — test
/// ```dart
/// final adapter = MockPurchaseAdapter(
///  initialSubscription: Subscription.none,
///  purchaseBehavior: MockPurchaseBehavior.succeed,
/// );
/// ```
///
/// ### Quick start — dev / Storybook preview
/// ```dart
/// final adapter = MockPurchaseAdapter.activeSubscription(
///  productId: 'pro_annual',
///  period: SubscriptionPeriod.annual,
/// );
/// ```
///
/// ### Configuring behaviour at runtime
/// ```dart
/// adapter.purchaseBehavior = MockPurchaseBehavior.cancel;
/// adapter.simulateExternalSubscriptionChange(newSubscription);
/// ```
final class MockPurchaseAdapter implements PurchaseAdapter {
  MockPurchaseAdapter({
    Subscription? initialSubscription,
    List<PurchaseProduct> availableProducts = const [],
    this.purchaseBehavior = MockPurchaseBehavior.succeed,
    this.restoreBehavior = MockRestoreBehavior.succeed,
    this.initializeBehavior = MockInitializeBehavior.succeed,
    this.purchaseDelay = Duration.zero,
    this.restoreDelay = Duration.zero,
    this.initializeDelay = Duration.zero,
  }) : _currentSubscription = initialSubscription ?? Subscription.none,
       _availableProducts = availableProducts;

  // Named constructors / presets

  /// Preset: already has an active subscription.
  factory MockPurchaseAdapter.activeSubscription({
    String productId = 'mock_pro_monthly',
    SubscriptionPeriod period = SubscriptionPeriod.monthly,
    SubscriptionScope scope = SubscriptionScope.pro,
    DateTime? expiresAt,
    bool willRenew = true,
  }) {
    final sub = Subscription(
      productId: productId,
      period: period,
      status: SubscriptionStatus.active,
      scope: scope,
      willRenew: willRenew,
      isTrial: false,
      expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 30)),
    );
    return MockPurchaseAdapter(initialSubscription: sub);
  }

  /// Preset: not subscribed, but purchase will succeed.
  factory MockPurchaseAdapter.readyToPurchase({
    List<PurchaseProduct> products = const [],
  }) => MockPurchaseAdapter(
    initialSubscription: Subscription.none,
    availableProducts: products,
    purchaseBehavior: MockPurchaseBehavior.succeed,
  );

  /// Preset: simulates a device with no store access.
  factory MockPurchaseAdapter.unavailable() => MockPurchaseAdapter(
    initializeBehavior: MockInitializeBehavior.networkError,
  );

  // Mutable configuration

  /// What [purchase] will do on the next call.
  MockPurchaseBehavior purchaseBehavior;

  /// What [restorePurchases] will do on the next call.
  MockRestoreBehavior restoreBehavior;

  /// What [initialize] will do.
  MockInitializeBehavior initializeBehavior;

  /// Artificial delay injected into [purchase].
  Duration purchaseDelay;

  /// Artificial delay injected into [restorePurchases].
  Duration restoreDelay;

  /// Artificial delay injected into [initialize].
  Duration initializeDelay;

  // Internal state

  Subscription _currentSubscription;
  List<PurchaseProduct> _availableProducts;
  String? _userId;

  final StreamController<Subscription> _controller =
      StreamController<Subscription>.broadcast();

  final List<RecordedCall> _calls = [];

  // Inspection API (for assertions in tests)

  /// Every method invocation in call order.
  List<RecordedCall> get recordedCalls => List.unmodifiable(_calls);

  /// The most recently recorded call, or `null` if none.
  RecordedCall? get lastCall => _calls.isEmpty ? null : _calls.last;

  /// Number of times [purchase] was called.
  int get purchaseCallCount =>
      _calls.where((c) => c.method == 'purchase').length;

  /// Number of times [restorePurchases] was called.
  int get restoreCallCount =>
      _calls.where((c) => c.method == 'restorePurchases').length;

  /// Number of times [initialize] was called.
  int get initializeCallCount =>
      _calls.where((c) => c.method == 'initialize').length;

  /// Whether [setUserId] was called with a non-null value.
  bool get isIdentified => _userId != null;

  /// The last userId supplied to [setUserId].
  String? get currentUserId => _userId;

  /// Snapshot of the current subscription held by the adapter.
  Subscription get currentSubscription => _currentSubscription;

  // Simulation API (for test-driving external events)

  /// Programmatically push a new subscription event — simulates an
  /// external change (e.g. a webhook arriving, cross-device purchase).
  void simulateExternalSubscriptionChange(Subscription subscription) {
    _currentSubscription = subscription;
    _controller.add(subscription);
  }

  /// Swap the product catalogue at runtime.
  void setAvailableProducts(List<PurchaseProduct> products) {
    _availableProducts = products;
  }

  /// Clear all recorded calls (useful for resetting state between test phases).
  void clearRecordedCalls() => _calls.clear();

  // PurchaseAdapter

  @override
  Future<void> initialize() async {
    _calls.add(const RecordedCall('initialize'));
    await _simulateDelay(initializeDelay);

    switch (initializeBehavior) {
      case MockInitializeBehavior.succeed:
        _controller.add(_currentSubscription);
      case MockInitializeBehavior.networkError:
        throw const NetworkFailure('Mock: SDK init failed.');
    }
  }

  @override
  Future<void> dispose() async {
    _calls.add(const RecordedCall('dispose'));
    await _controller.close();
  }

  @override
  Stream<Subscription> get subscriptionUpdates => _controller.stream;

  @override
  Future<Subscription> getCurrentSubscription() async {
    _calls.add(const RecordedCall('getCurrentSubscription'));
    return _currentSubscription;
  }

  @override
  Future<List<PurchaseProduct>> getAvailableProducts() async {
    _calls.add(const RecordedCall('getAvailableProducts'));
    return List.unmodifiable(_availableProducts);
  }

  @override
  Future<PurchaseResult> purchase(String productId) async {
    _calls.add(RecordedCall('purchase', argument: productId));
    await _simulateDelay(purchaseDelay);

    switch (purchaseBehavior) {
      case MockPurchaseBehavior.cancel:
        throw const PurchaseCancelledFailure();

      case MockPurchaseBehavior.alreadySubscribed:
        throw const AlreadySubscribedFailure();

      case MockPurchaseBehavior.networkError:
        throw const NetworkFailure('Mock: network unreachable.');

      case MockPurchaseBehavior.storeError:
        throw const StoreFailure('Mock: store returned an error.');

      case MockPurchaseBehavior.succeed:
        // Find the product in the catalogue to derive correct metadata,
        // falling back to minimal defaults if the product isn't listed.
        final product = _availableProducts
            .where((p) => p.id == productId)
            .firstOrNull;

        final next = Subscription(
          productId: productId,
          period: product?.period ?? SubscriptionPeriod.monthly,
          status: SubscriptionStatus.active,
          scope: product?.scope ?? SubscriptionScope.fromProductId(productId),
          willRenew: true,
          isTrial: false,
          purchasedAt: DateTime.now(),
          expiresAt: _expiresAt(product?.period ?? SubscriptionPeriod.monthly),
        );

        _currentSubscription = next;
        _controller.add(next);
        return PurchaseResult(subscription: next, isNewPurchase: true);
    }
  }

  @override
  Future<Subscription> restorePurchases() async {
    _calls.add(const RecordedCall('restorePurchases'));
    await _simulateDelay(restoreDelay);

    switch (restoreBehavior) {
      case MockRestoreBehavior.nothingToRestore:
        throw const NoPurchasesToRestoreFailure();

      case MockRestoreBehavior.networkError:
        throw const NetworkFailure('Mock: network unreachable.');

      case MockRestoreBehavior.succeed:
        _controller.add(_currentSubscription);
        return _currentSubscription;
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    _calls.add(RecordedCall('setUserId', argument: userId));
    _userId = userId;
  }

  // Helpers

  static Future<void> _simulateDelay(Duration delay) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  static DateTime _expiresAt(SubscriptionPeriod period) =>
      DateTime.now().add(switch (period) {
        SubscriptionPeriod.weekly => const Duration(days: 7),
        SubscriptionPeriod.monthly => const Duration(days: 30),
        SubscriptionPeriod.quarterly => const Duration(days: 90),
        SubscriptionPeriod.semiAnnual => const Duration(days: 180),
        SubscriptionPeriod.annual => const Duration(days: 365),
        SubscriptionPeriod.lifetime => const Duration(days: 36500),
      });
}
