import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_provider.dart';

/// Available visualization styles for pie and donut charts throughout the app.
enum PieChartStyle {
  interactive('Interactive Pop-Out', 'Tap slices for center focus label with section pop-out'),
  bubble('Floating Speech Bubbles', 'Display slice-anchored percentage speech bubble badges');

  final String title;
  final String description;

  const PieChartStyle(this.title, this.description);
}

const String _kPieChartStyleKey = 'pie_chart_style';

/// Controller managing the persistent "Pie Chart Style" user preference.
class PieChartStyleNotifier extends StateNotifier<PieChartStyle> {
  final SharedPreferences _prefs;

  PieChartStyleNotifier(this._prefs)
      : super(
          _prefs.getString(_kPieChartStyleKey) == 'bubble'
              ? PieChartStyle.bubble
              : PieChartStyle.interactive,
        );

  /// Sets and persists the user's preferred pie chart visualization style.
  Future<void> setStyle(PieChartStyle style) async {
    await _prefs.setString(_kPieChartStyleKey, style.name);
    state = style;
  }
}

/// Provider exposing the current PieChartStyle user setting.
final pieChartStyleProvider =
    StateNotifierProvider<PieChartStyleNotifier, PieChartStyle>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PieChartStyleNotifier(prefs);
});
