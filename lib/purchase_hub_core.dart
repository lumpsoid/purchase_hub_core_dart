/// Purchase Hub Core — store-agnostic purchase & subscription abstraction.
library;

// Bundled adapters
export 'src/adapters/mock_purchase_adapter.dart';
export 'src/adapters/noop_purchase_adapter.dart';
// Failures
export 'src/domain/failures/purchase_failure.dart';
// Domain models
export 'src/domain/models/entitlement.dart';
export 'src/domain/models/introductory_offer.dart';
export 'src/domain/models/purchase_product.dart';
export 'src/domain/models/purchase_result.dart';
export 'src/domain/models/subscription.dart';
export 'src/domain/models/subscription_period.dart';
export 'src/domain/models/subscription_scope.dart';
export 'src/domain/models/subscription_status.dart';
// Store facade
export 'src/hub/purchase_hub.dart';
export 'src/hub/purchase_hub_config.dart';
// Ports
export 'src/ports/purchase_adapter.dart';
export 'src/ports/purchase_initializer.dart';
