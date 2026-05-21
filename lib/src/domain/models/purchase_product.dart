import 'package:meta/meta.dart';
import 'package:purchase_hub_core/src/domain/models/introductory_offer.dart';
import 'package:purchase_hub_core/src/domain/models/subscription_period.dart';
import 'package:purchase_hub_core/src/domain/models/subscription_scope.dart';

/// A purchasable product returned by the store.
@immutable
final class PurchaseProduct {
  const PurchaseProduct({
    required this.id,
    required this.storeId,
    required this.title,
    required this.description,
    required this.priceString,
    required this.price,
    required this.currencyCode,
    required this.period,
    required this.scope,
    this.introductoryOffer,
  });

  final String id;
  final String storeId;
  final String title;
  final String description;

  /// Localised price string provided by the store.
  final String priceString;

  /// Raw numeric price in [currencyCode].
  final double price;
  final String currencyCode;

  final SubscriptionPeriod period;
  final SubscriptionScope scope;

  /// Present when the store offers an introductory or trial price.
  final IntroductoryOffer? introductoryOffer;

  bool get hasIntroductoryOffer => introductoryOffer != null;
  bool get hasTrial => introductoryOffer?.isTrial ?? false;

  @override
  String toString() =>
      'PurchaseProduct(id: $id, price: $priceString, period: $period)';
}
