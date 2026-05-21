import 'package:purchase_hub_core/purchase_hub_core.dart' show PurchaseHub;
import 'package:purchase_hub_core/src/hub/purchase_hub.dart' show PurchaseHub;
import 'package:purchase_hub_core/src/ports/purchase_adapter.dart';

/// Factory contract for constructing a [PurchaseAdapter].
///
/// Adapter packages expose a concrete implementation of this interface
/// so that [PurchaseHub] can initialise them without compile-time
/// knowledge of the underlying SDK.
///
/// ```dart
/// // In your DI setup:
/// final store = PurchaseStore(
///  initializer: RevenueCatInitializer(apiKey: 'appl_xxx'),
/// );
/// await store.initialize();
/// ```
abstract interface class PurchaseInitializer {
  /// Build and return a fully-configured [PurchaseAdapter].
  ///
  /// The returned adapter has NOT yet been initialised — [PurchaseHub]
  /// calls [PurchaseAdapter.initialize] at the right time.
  PurchaseAdapter createAdapter();
}
