import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where settings are saved. Tests use the in-memory store.
abstract interface class SettingsStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class MemorySettingsStore implements SettingsStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}

/// Saves settings on the device (browser storage on web, app storage on Android).
class PrefsSettingsStore implements SettingsStore {
  @override
  Future<String?> read(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> write(String key, String value) async {
    await (await SharedPreferences.getInstance()).setString(key, value);
  }
}

/// User choices that apply to the whole app: language, theme, class reminder.
class AppSettings extends ChangeNotifier {
  AppSettings({SettingsStore? store}) : _store = store ?? MemorySettingsStore();

  /// Minutes before class; 0 turns reminders off.
  static const reminderOptions = [0, 5, 10, 15, 30, 60];

  final SettingsStore _store;
  String _language = 'en';
  ThemeMode _themeMode = ThemeMode.system;
  int _reminderMinutes = 15;

  /// 'en' or 'fr'.
  String get language => _language;
  ThemeMode get themeMode => _themeMode;
  int get reminderMinutes => _reminderMinutes;

  Future<void> load() async {
    final language = await _store.read('language');
    final theme = await _store.read('themeMode');
    final reminder = await _store.read('reminderMinutes');

    if (language == 'en' || language == 'fr') _language = language!;
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == theme,
      orElse: () => ThemeMode.system,
    );
    final minutes = int.tryParse(reminder ?? '');
    if (minutes != null && reminderOptions.contains(minutes)) {
      _reminderMinutes = minutes;
    }
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (code != 'en' && code != 'fr') return;
    _language = code;
    notifyListeners();
    await _store.write('language', code);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _store.write('themeMode', mode.name);
  }

  Future<void> setReminderMinutes(int minutes) async {
    _reminderMinutes = minutes;
    notifyListeners();
    await _store.write('reminderMinutes', '$minutes');
  }
}

/// Makes [AppSettings] available to every screen. Screens that read it are
/// rebuilt automatically when a setting changes.
class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  /// Null when there is no scope (for example in a small widget test).
  static AppSettings? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppSettingsScope>()?.notifier;
}
