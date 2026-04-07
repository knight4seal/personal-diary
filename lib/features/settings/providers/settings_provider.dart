import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
      'sharedPreferencesProvider must be overridden at app startup');
});

// --- Theme Mode ---

class ThemeModeNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _key = 'is_dark_mode';

  ThemeModeNotifier(this._prefs) : super(_prefs.getBool(_key) ?? false);

  void toggle() {
    state = !state;
    _prefs.setBool(_key, state);
  }

  void setDarkMode(bool isDark) {
    state = isDark;
    _prefs.setBool(_key, isDark);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

// --- Biometric Enabled ---

class BiometricEnabledNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _key = 'biometric_enabled';

  BiometricEnabledNotifier(this._prefs)
      : super(_prefs.getBool(_key) ?? false);

  void setEnabled(bool enabled) {
    state = enabled;
    _prefs.setBool(_key, enabled);
  }
}

final biometricEnabledProvider =
    StateNotifierProvider<BiometricEnabledNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BiometricEnabledNotifier(prefs);
});

// --- Auto Lock Timeout ---

class AutoLockTimeoutNotifier extends StateNotifier<int> {
  final SharedPreferences _prefs;
  static const _key = 'auto_lock_timeout';
  static const _defaultMinutes = 5;

  AutoLockTimeoutNotifier(this._prefs)
      : super(_prefs.getInt(_key) ?? _defaultMinutes);

  void setTimeout(int minutes) {
    state = minutes;
    _prefs.setInt(_key, minutes);
  }
}

final autoLockTimeoutProvider =
    StateNotifierProvider<AutoLockTimeoutNotifier, int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AutoLockTimeoutNotifier(prefs);
});
