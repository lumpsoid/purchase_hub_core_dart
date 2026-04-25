import 'dart:async';


import 'package:purchase_hub_core/src/domain/failures/purchase_failure.dart';
import 'package:purchase_hub_core/src/domain/models/purchase_product.dart';
import 'package:purchase_hub_core/src/domain/models/purchase_result.dart';
import 'package:purchase_hub_core/src/domain/models/subscription.dart';
import 'package:purchase_hub_core/src/ports/purchase_adapter.dart';
import 'package:purchase_hub_core/src/ports/purchase_initializer.dart';
import 'package:purchase_hub_core/src/hub/purchase_hub_config.dart';

/// The single entry-point for all purchase operations.
///
/// [PurchaseHub] is a thin orchestration façade that:
/// - Holds the [PurchaseAdapter] lifecycle.
/// - Merges adapter updates with locally-derived events.
/// - Enforces the [PurchaseHubConfig] policy layer.
///
/// In production, resolve this as a singleton through your DI container.
final class PurchaseHub {
  PurchaseHub({
    required PurchaseInitializer initializer,
    PurchaseHubConfig config = const PurchaseHubConfig(),
  }) : _initializer = initializer,
       _config = config;

  final PurchaseInitializer _initializer;
  final PurchaseHubConfig _config;

  PurchaseAdapter? _adapter;
  StreamSubscription<Subscription>? _adapterSub;

  final StreamController<Subscription> _subscriptionController =
      StreamController<Subscription>.broadcast();

  bool _initialized = false;

  // Lifecycle

  /// Initialise the store.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _adapter = _initializer.createAdapter();
    await _adapter!.initialize();

    // Pipe adapter updates into our controller.
    _adapterSub = _adapter!.subscriptionUpdates.listen(
      _subscriptionController.add,
      onError: _subscriptionController.addError,
    );

    if (_config.autoFetchOnInitialize) {
      try {
        final current = await _adapter!.getCurrentSubscription();
        _subscriptionController.add(current);
      } on PurchaseFailure {
        if (_config.emitNoneOnStartup) {
          _subscriptionController.add(Subscription.none);
        }
      }
    }
  }

  /// Release all resources. Call this when the app is being torn down.
  Future<void> dispose() async {
    await _adapterSub?.cancel();
    await _adapter?.dispose();
    await _subscriptionController.close();
    _initialized = false;
  }

  // Streaming state

  /// Broadcasts [Subscription] updates for the current user.
  ///
  /// Emits [Subscription.none] until a subscription is confirmed.
  Stream<Subscription> get subscriptionUpdates =>
      _subscriptionController.stream;

  // Queries

  Future<Subscription> getCurrentSubscription() =>
      _requireAdapter().getCurrentSubscription();

  Future<List<PurchaseProduct>> getAvailableProducts() =>
      _requireAdapter().getAvailableProducts();

  // Mutations

  Future<PurchaseResult> purchase(String productId) =>
      _requireAdapter().purchase(productId);

  Future<Subscription> restorePurchases() =>
      _requireAdapter().restorePurchases();

  // Identity

  Future<void> setUserId(String? userId) => _requireAdapter().setUserId(userId);

  // Internal

  @pragma('vm:prefer-inline')
  PurchaseAdapter _requireAdapter() {
    if (_adapter == null) {
      throw StateError(
        'PurchaseStore has not been initialised. '
        'Call initialize() before using the store.',
      );
    }
    return _adapter!;
  }
}
