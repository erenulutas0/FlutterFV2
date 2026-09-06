import 'package:flutter_test/flutter_test.dart';
import 'package:vocabmaster/frontend_newest/services/nf_plan_savings.dart';

/// The number on the annual plan's badge.
///
/// It was the string "Save 40%" in seven languages and nothing computed it.
/// With the prices the app actually charges the true figure is 33, and in any
/// other currency it is whatever Google's two separate conversions make it —
/// so the badge was wrong at home and unknowable abroad. A price claim that is
/// not derived from the prices is not a rounding error; it is the thing
/// consumer law is about.
void main() {
  test('the real Turkish prices save a third, not forty percent', () {
    // ₺149.99 × 12 = ₺1,799.88 against ₺1,199.99 a year.
    expect(annualSavingsPercent(monthly: 149.99, annual: 1199.99), 33);
  });

  test('the comparison is twelve monthly charges, as a buyer makes it', () {
    // 10 a month, 60 a year: half of 120.
    expect(annualSavingsPercent(monthly: 10, annual: 60), 50);
    // Per-day normalisation (365/30) would say 51 here; that is not what
    // "instead of paying monthly" means to anyone reading the badge.
  });

  test('an annual plan that is not cheaper gets no badge at all', () {
    // Google's per-country conversion can leave the two products at a ratio
    // where "save" would be a lie. Say nothing rather than say 0%.
    expect(annualSavingsPercent(monthly: 10, annual: 120), isNull);
    expect(annualSavingsPercent(monthly: 10, annual: 130), isNull);
  });

  test('a saving under one percent is not worth a badge', () {
    expect(annualSavingsPercent(monthly: 10, annual: 119.5), isNull);
  });

  test('a missing or broken price says nothing rather than something', () {
    // The store product failed to load, or a plan came back with no price.
    expect(annualSavingsPercent(monthly: 0, annual: 100), isNull);
    expect(annualSavingsPercent(monthly: 10, annual: 0), isNull);
    expect(annualSavingsPercent(monthly: -5, annual: 40), isNull);
    expect(annualSavingsPercent(monthly: double.nan, annual: 40), isNull);
    expect(annualSavingsPercent(monthly: 10, annual: double.infinity), isNull);
  });

  test('rounding is to the nearest whole percent', () {
    // 1 - 79/120 = 34.17 -> 34; 1 - 78/120 = 35.0 -> 35.
    expect(annualSavingsPercent(monthly: 10, annual: 79), 34);
    expect(annualSavingsPercent(monthly: 10, annual: 78), 35);
  });
}
