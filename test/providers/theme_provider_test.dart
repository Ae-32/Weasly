import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Weasly/providers/theme_provider.dart';
import 'package:Weasly/utils/app_colors.dart';
import 'package:Weasly/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeModeNotifier Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('theme mode defaults to ThemeMode.system', () {
      final notifier = ThemeModeNotifier(prefs);
      expect(notifier.state, ThemeMode.system);
    });

    test('reads stored theme mode from SharedPreferences', () async {
      await prefs.setString(kAppThemeModeKey, 'dark');
      final notifier = ThemeModeNotifier(prefs);
      expect(notifier.state, ThemeMode.dark);
    });

    test('setThemeMode changes state and persists to SharedPreferences', () async {
      final notifier = ThemeModeNotifier(prefs);

      await notifier.setThemeMode(ThemeMode.dark);
      expect(notifier.state, ThemeMode.dark);
      expect(prefs.getString(kAppThemeModeKey), 'dark');

      await notifier.setThemeMode(ThemeMode.light);
      expect(notifier.state, ThemeMode.light);
      expect(prefs.getString(kAppThemeModeKey), 'light');

      await notifier.setThemeMode(ThemeMode.system);
      expect(notifier.state, ThemeMode.system);
      expect(prefs.getString(kAppThemeModeKey), 'system');
    });

    test('AppTheme.darkTheme has Brightness.dark and AppColorsExtension.dark', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.scaffoldBackgroundColor, AppColors.darkBgBase);

      final extension = darkTheme.extension<AppColorsExtension>();
      expect(extension, isNotNull);
      expect(extension!.bgBase, AppColors.darkBgBase);
      expect(extension.bgSurface, AppColors.darkBgSurface);
      expect(extension.accentPrimary, AppColors.darkAccentPrimary);
    });
  });
}
