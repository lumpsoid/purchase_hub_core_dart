import 'package:purchase_hub_core/src/domain/failures/purchase_failure.dart';
import 'package:purchase_hub_core/src/domain/models/purchase_options.dart';
import 'package:purchase_hub_core/src/domain/models/purchase_product.dart';
import 'package:purchase_hub_core/src/domain/models/purchase_result.dart';
import 'package:purchase_hub_core/src/domain/models/subscription.dart';

/// The central port every store adapter must implement.
///
/// **Contract rules for implementors:**
/// - All methods MUST throw a [PurchaseFailure] subtype on error —
///  never a raw [Exception] or platform exception.
/// - [subscriptionUpdates] MUST emit on every state change and MUST NOT
///  close until [dispose] is called.
/// - Implementations MUST be idempotent where noted.
abstract interface class PurchaseAdapter {
  // Lifecycle

  /// Initialise the underlying SDK.
  ///
  /// Called once per app session before any other method.
  /// Idempotent — safe to call multiple times.
  Future<void> initialize();

  /// Release all resources held by this adapter.
  ///
  /// After [dispose], the behaviour of all other methods is undefined.
  Future<void> dispose();

  // Streaming state

  /// Broadcasts the current [Subscription] on every store-side update.
  ///
  /// Emits [Subscription.none] when the user has no active subscription.
  /// The first event is emitted as soon as the adapter has fetched initial
  /// customer info (typically right after [initialize]).
  Stream<Subscription> get subscriptionUpdates;

  // Queries

  /// Returns the current subscription state.
  ///
  /// Throws [NetworkFailure] or [BackendFailure] on connectivity issues.
  Future<Subscription> getCurrentSubscription();

  /// Returns all purchasable products in the configured offering.
  ///
  /// Throws [NoOfferingsFailure] when the store returns an empty offering.
  Future<List<PurchaseProduct>> getAvailableProducts();

  // Mutations

  /// Initiates a purchase flow for [productId].
  ///
  /// Throws:
  /// - [PurchaseCancelledFailure] — user dismissed the native sheet.
  /// - [AlreadySubscribedFailure] — product already owned.
  /// - [ProductNotFoundFailure] — [productId] not in the current offering.
  Future<PurchaseResult> purchase(String productId, {PurchaseOptions? options});

  /// Restores prior purchases (required by App Store guidelines).
  ///
  /// Throws [NoPurchasesToRestoreFailure] when nothing is found.
  Future<Subscription> restorePurchases();

  /// Sync purchases
  Future<void> syncPurchases();

  // Identity

  /// Associates a logged-in user with the store account.
  ///
  /// Call this after your own authentication succeeds.
  /// Pass `null` to reset to an anonymous identity (on logout).
  ///
  /// Idempotent — safe to call with the same [userId] multiple times.
  Future<void> setUserId(String? userId);
}
