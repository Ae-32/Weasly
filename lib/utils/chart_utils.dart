import 'dart:math' as math;

/// Utility class providing nice interval calculation for charts (fl_chart).
class ChartAxisHelper {
  /// Computes a "nice" step interval and maxY for chart Y-axes.
  ///
  /// Guarantees clean, round numbers (e.g. 100, 200, 500, 1000, 2000, 5000, etc.)
  /// with appropriate headroom above the highest data point.
  static ({double interval, double maxY}) computeNiceYAxis({
    required double maxValue,
    int targetSteps = 4,
    double minInterval = 100.0,
    double minHeadroomRatio = 0.15,
  }) {
    if (maxValue <= 0) {
      return (interval: 1000.0, maxY: 4000.0);
    }

    // Estimate step based on target steps and required headroom
    final roughMax = maxValue * (1 + minHeadroomRatio);
    final roughStep = roughMax / targetSteps;

    // Determine order of magnitude
    final exponent = (math.log(roughStep) / math.ln10).floor();
    final magnitude = math.pow(10, exponent).toDouble();
    final fraction = roughStep / magnitude;

    double step;
    if (fraction <= 1.2) {
      step = 1.0 * magnitude;
    } else if (fraction <= 2.5) {
      step = 2.0 * magnitude;
    } else if (fraction <= 6.0) {
      step = 5.0 * magnitude;
    } else {
      step = 10.0 * magnitude;
    }

    if (step < minInterval) {
      step = minInterval;
    }

    // Snap maxY to multiple of step
    double maxY = (maxValue / step).ceil() * step;
    if ((maxY - maxValue) < (maxY * minHeadroomRatio)) {
      maxY += step;
    }

    if (maxY <= 0) {
      maxY = step * targetSteps;
    }

    return (interval: step, maxY: maxY);
  }
}

/// Formats a numeric value into compact currency with clean thousands
/// (e.g., ₱0, ₱1K, ₱2K, ₱3K, ₱10K, ₱1.5K, etc.).
String formatCompactCurrency(num value, {String symbol = '₱'}) {
  final rounded = value.roundToDouble();
  final effectiveValue = (value - rounded).abs() < 1e-6 ? rounded : value;

  if (effectiveValue == 0) return '${symbol}0';

  final isNegative = effectiveValue < 0;
  final absVal = effectiveValue.abs();

  String formatted;
  if (absVal >= 1000000) {
    final m = absVal / 1000000;
    if (m % 1 == 0) {
      formatted = '${m.toInt()}M';
    } else if ((m * 10) % 1 == 0) {
      formatted = '${m.toStringAsFixed(1)}M';
    } else {
      formatted = '${m.toStringAsFixed(2)}M';
    }
  } else if (absVal >= 1000) {
    final k = absVal / 1000;
    if (k % 1 == 0) {
      formatted = '${k.toInt()}K';
    } else if ((k * 10) % 1 == 0) {
      formatted = '${k.toStringAsFixed(1)}K';
    } else {
      formatted = '${k.toStringAsFixed(2)}K';
    }
  } else {
    formatted = absVal % 1 == 0 ? '${absVal.toInt()}' : absVal.toStringAsFixed(0);
  }

  return isNegative ? '-$symbol$formatted' : '$symbol$formatted';
}
