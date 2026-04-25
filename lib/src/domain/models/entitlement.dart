import 'package:meta/meta.dart';

/// A single granted entitlement returned by the store.
@immutable
final class Entitlement {
  const Entitlement({
    required this.id,
    required this.productId,
    required this.willRenew,
    this.expiresAt,
  });

  final String id;
  final String productId;
  final DateTime? expiresAt;
  final bool willRenew;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  Entitlement copyWith({
    String? id,
    String? productId,
    DateTime? expiresAt,
    bool? willRenew,
  }) => Entitlement(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    expiresAt: expiresAt ?? this.expiresAt,
    willRenew: willRenew ?? this.willRenew,
  );

  @override
  String toString() =>
      'Entitlement(id: $id, productId: $productId, '
      'expiresAt: $expiresAt, willRenew: $willRenew)';
}

/// Convenience typedef for an immutable list of entitlements.
typedef Entitlements = List<Entitlement>;
