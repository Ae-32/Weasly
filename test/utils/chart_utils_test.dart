import 'package:flutter_test/flutter_test.dart';
import 'package:Weasly/utils/chart_utils.dart';

void main() {
  group('formatCompactCurrency', () {
    test('formats zero correctly', () {
      expect(formatCompactCurrency(0), '₱0');
      expect(formatCompactCurrency(0.0), '₱0');
      expect(formatCompactCurrency(-0.0), '₱0');
    });

    test('formats clean thousands correctly', () {
      expect(formatCompactCurrency(1000), '₱1K');
      expect(formatCompactCurrency(2000), '₱2K');
      expect(formatCompactCurrency(3000), '₱3K');
      expect(formatCompactCurrency(4000), '₱4K');
      expect(formatCompactCurrency(10000), '₱10K');
      expect(formatCompactCurrency(50000), '₱50K');
    });

    test('formats values under 1000 correctly', () {
      expect(formatCompactCurrency(500), '₱500');
      expect(formatCompactCurrency(250), '₱250');
      expect(formatCompactCurrency(100), '₱100');
    });

    test('formats non-integer thousands cleanly', () {
      expect(formatCompactCurrency(1500), '₱1.5K');
      expect(formatCompactCurrency(2500), '₱2.5K');
      expect(formatCompactCurrency(1250), '₱1.25K');
    });

    test('formats millions correctly', () {
      expect(formatCompactCurrency(1000000), '₱1M');
      expect(formatCompactCurrency(2500000), '₱2.5M');
    });

    test('handles floating point near-integer precision', () {
      expect(formatCompactCurrency(1000.00000001), '₱1K');
      expect(formatCompactCurrency(1999.99999999), '₱2K');
    });
  });

  group('ChartAxisHelper.computeNiceYAxis', () {
    test('returns reasonable defaults for zero or negative values', () {
      final res = ChartAxisHelper.computeNiceYAxis(maxValue: 0);
      expect(res.interval, 1000.0);
      expect(res.maxY, 4000.0);
    });

    test('computes nice step of 1000 for mid-range values (e.g. 3260)', () {
      final res = ChartAxisHelper.computeNiceYAxis(maxValue: 3260);
      expect(res.interval, 1000.0);
      expect(res.maxY, 4000.0);
    });

    test('adds headroom when max value is too close to interval boundary', () {
      final res = ChartAxisHelper.computeNiceYAxis(maxValue: 3900);
      expect(res.interval, 1000.0);
      expect(res.maxY, 5000.0);
    });

    test('computes nice step for smaller values', () {
      final res = ChartAxisHelper.computeNiceYAxis(maxValue: 500);
      expect(res.interval, 200.0);
      expect(res.maxY, 600.0);
    });

    test('computes nice step for larger values', () {
      final res = ChartAxisHelper.computeNiceYAxis(maxValue: 12000);
      expect(res.interval, 5000.0);
      expect(res.maxY, 15000.0);
    });
  });
}
