import 'package:meta/meta.dart';

/// An introductory or trial price offered for a product.
@immutable
final class IntroductoryOffer {
  const IntroductoryOffer({
    required this.priceString,
    required this.price,
    required this.periodNumberOfUnits,
    required this.periodUnit,
    this.isTrial = false,
  });

  /// Localised price string, e.g. `"$0.00"` for a free trial.
  final String priceString;

  /// Numeric price. `0.0` for a free trial.
  final double price;

  /// Duration expressed in [periodUnit] units.
  final int periodNumberOfUnits;

  /// Unit label, e.g. `"day"`, `"week"`, `"month"`.
  final String periodUnit;

  /// `true` when this is a zero-cost trial rather than a discounted price.
  final bool isTrial;

  @override
  String toString() =>
      'IntroductoryOffer($periodNumberOfUnits $periodUnit '
      '@ $priceString, trial: $isTrial)';
}
