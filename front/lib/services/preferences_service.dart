import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences.dart';

/// Сервіс для роботи з налаштуваннями користувача
class PreferencesService {
  static const String _prefsKey = 'user_prefs';

  /// Завантажити налаштування
  Future<UserPreferences> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);

      if (jsonString == null) {
        // Якщо налаштувань немає - повертаємо дефолтні
        return const UserPreferences();
      }

      return UserPreferences.fromJsonString(jsonString);
    } catch (e) {
      // У разі помилки повертаємо дефолтні налаштування
      return const UserPreferences();
    }
  }

  /// Зберегти налаштування
  Future<bool> savePreferences(UserPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = preferences.toJsonString();
      return await prefs.setString(_prefsKey, jsonString);
    } catch (e) {
      return false;
    }
  }

  /// Оновити конкретне поле
  Future<bool> updatePreference({
    bool? isFirstLaunch,
    String? defaultGameDay,
    bool? goalAlertsEnabled,
    String? homeFocus,
  }) async {
    final currentPrefs = await loadPreferences();
    final updatedPrefs = currentPrefs.copyWith(
      isFirstLaunch: isFirstLaunch,
      defaultGameDay: defaultGameDay,
      goalAlertsEnabled: goalAlertsEnabled,
      homeFocus: homeFocus,
    );
    return await savePreferences(updatedPrefs);
  }

  /// Перевірити чи це перший запуск
  Future<bool> isFirstLaunch() async {
    final prefs = await loadPreferences();
    return prefs.isFirstLaunch;
  }

  /// Встановити що онбординг пройдено
  Future<bool> setOnboardingCompleted() async {
    return await updatePreference(isFirstLaunch: false);
  }

  /// Скинути налаштування до дефолтних (для re-run onboarding)
  Future<bool> resetToDefaults() async {
    return await savePreferences(const UserPreferences());
  }

  /// Очистити всі налаштування
  Future<bool> clearPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_prefsKey);
    } catch (e) {
      return false;
    }
  }
}