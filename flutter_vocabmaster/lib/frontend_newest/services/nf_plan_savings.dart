/// How much cheaper the annual plan really is, as a buyer would work it out.
///
/// The paywall used to say "Save 40%" from a string in the translation table.
/// Nothing computed it. With the real prices — ₺149.99 a month against
/// ₺1,199.99 a year — twelve monthly payments come to ₺1,799.88 and the saving
/// is 33%, so the badge was wrong in the currency it was written for. In every
/// other country Google converts the two products separately, so the true
/// figure drifts further, and "40% off" in front of a German or Spanish buyer
/// when the arithmetic says 31 is not a rounding error but a misleading price
/// claim. The badge now states the number the two prices actually produce, or
/// nothing.
///
/// The comparison is the one a customer makes: one annual charge against
/// twelve monthly ones. Per-day normalisation (365 vs 30) gives a slightly
/// higher figure and is not what "instead of paying monthly" means to anyone.
library;

/// Percent saved by paying [annual] once instead of [monthly] twelve times,
/// rounded to the nearest whole number. Null when there is nothing honest to
/// say: a missing or non-positive price, or an annual plan that is not
/// actually cheaper.
int? annualSavingsPercent({required double monthly, required double annual}) {
  if (!monthly.isFinite || !annual.isFinite || monthly <= 0 || annual <= 0) {
    return null;
  }
  final double twelveMonths = monthly * 12;
  if (annual >= twelveMonths) {
    return null;
  }
  final int percent = ((1 - annual / twelveMonths) * 100).round();
  return percent < 1 ? null : percent;
}
