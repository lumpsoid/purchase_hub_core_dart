import 'package:meta/meta.dart';

/// The store / billing backend an entitlement was unlocked from.
///
/// Open by design: the core ships the well-known stores as constants, but a
/// backend extension MAY mint its own [SubscriptionStore] with any [id]
/// without changing the core — so this is intentionally *not* a closed enum.
@immutable
final class SubscriptionStore {
  const SubscriptionStore(this.id);

  /// The raw store identifier.
  final String id;

  // Well-known stores — a convenience set, NOT exhaustive.

  static const SubscriptionStore appStore = SubscriptionStore('app_store');
  static const SubscriptionStore playStore = SubscriptionStore('play_store');
  static const SubscriptionStore amazon = SubscriptionStore('amazon');
  static const SubscriptionStore stripe = SubscriptionStore('stripe');
  static const SubscriptionStore promotional = SubscriptionStore(
    'promotional',
  );
  static const SubscriptionStore unknown = SubscriptionStore('unknown');

  @override
  bool operator ==(Object other) =>
      other is SubscriptionStore && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SubscriptionStore($id)';
}
