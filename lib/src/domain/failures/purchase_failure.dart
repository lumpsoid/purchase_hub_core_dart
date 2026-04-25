import 'package:meta/meta.dart';

/// Base class for all purchase-layer failures.
///
/// Failures are typed value objects — never raw exceptions.
/// The domain and UI layers pattern-match on subtypes.
@immutable
sealed class PurchaseFailure implements Exception {
  const PurchaseFailure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

// User-initiated

/// The user dismissed the purchase sheet before completing.
final class PurchaseCancelledFailure extends PurchaseFailure {
  const PurchaseCancelledFailure() : super('Purchase cancelled by user.');
}

// Product / Offering

/// The requested product ID could not be found in any offering.
final class ProductNotFoundFailure extends PurchaseFailure {
  const ProductNotFoundFailure(String productId)
    : super('Product not found: $productId');
}

/// No offerings were returned by the store.
final class NoOfferingsFailure extends PurchaseFailure {
  const NoOfferingsFailure() : super('No offerings available from the store.');
}

// Ownership

/// The product is already owned by this account.
final class AlreadySubscribedFailure extends PurchaseFailure {
  const AlreadySubscribedFailure()
    : super('This subscription is already active.');
}

/// A restore was attempted but no prior purchases were found.
final class NoPurchasesToRestoreFailure extends PurchaseFailure {
  const NoPurchasesToRestoreFailure()
    : super('No previous purchases found to restore.');
}

// Platform / Network

/// The device is not allowed to make purchases (parental controls, etc.).
final class PurchasesNotAllowedFailure extends PurchaseFailure {
  const PurchasesNotAllowedFailure()
    : super('This device is not permitted to make purchases.');
}

/// A network call to the store backend failed.
final class NetworkFailure extends PurchaseFailure {
  const NetworkFailure([String? detail])
    : super(detail ?? 'A network error occurred.');
}

/// The store itself returned an error (App Store / Play Billing issue).
final class StoreFailure extends PurchaseFailure {
  const StoreFailure([String? detail])
    : super(detail ?? 'The store returned an error.');
}

/// The purchase server or receipt validation backend failed.
final class BackendFailure extends PurchaseFailure {
  const BackendFailure([String? detail])
    : super(detail ?? 'The purchase backend returned an error.');
}

// Catch-all

/// Any error not covered by a specific subtype.
final class UnknownPurchaseFailure extends PurchaseFailure {
  const UnknownPurchaseFailure([String? detail])
    : super(detail ?? 'An unknown purchase error occurred.');
}
