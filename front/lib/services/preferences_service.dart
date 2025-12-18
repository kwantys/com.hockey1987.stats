import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences.dart';
import '../shared/services/logger.dart'; // Додано для логування

/// Сервіс для роботи з налаштуваннями користувача
class PreferencesService {
  static const String _prefsKey = 'user_prefs';

  /// Завантажити налаштування
  Future<UserPreferences> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);

      if (jsonString == null) {
        AppLogger.d('No preferences found, returning defaults');
        return const UserPreferences();
      }

      return UserPreferences.fromJsonString(jsonString);
    } catch (e, stack) {
      AppLogger.e('Error loading preferences', e, stack);
      return const UserPreferences();
    }
  }

  /// Зберегти налаштування
  Future<bool> savePreferences(UserPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = preferences.toJsonString();
      final result = await prefs.setString(_prefsKey, jsonString);

      if (result) {
        AppLogger.d('Preferences saved successfully: $jsonString');
      }
      return result;
    } catch (e, stack) {
      AppLogger.e('Failed to save preferences', e, stack);
      return false;
    }
  }

  /// Оновити конкретне поле (ВИПРАВЛЕНО: додано нові поля сповіщень)
  Future<bool> updatePreference({
    bool? isFirstLaunch,
    String? defaultGameDay,
    bool? goalAlerts,           // Оновлено
    bool? finalScoreAlerts,     // Додано
    bool? predictionReminders,  // Додано
    String? homeFocus,
  }) async {
    final currentPrefs = await loadPreferences();
    final updatedPrefs = currentPrefs.copyWith(
      isFirstLaunch: isFirstLaunch,
      defaultGameDay: defaultGameDay,
      goalAlerts: goalAlerts,
      finalScoreAlerts: finalScoreAlerts,
      predictionReminders: predictionReminders,
      homeFocus: homeFocus,
    );

    AppLogger.i('Updating preference field');
    return await savePreferences(updatedPrefs);
  }

  /// Перевірити чи це перший запуск
  Future<bool> isFirstLaunch() async {
    final prefs = await loadPreferences();
    return prefs.isFirstLaunch;
  }

  /// Встановити що онбординг пройдено
  Future<bool> setOnboardingCompleted() async {
    AppLogger.i('Onboarding completed');
    return await updatePreference(isFirstLaunch: false);
  }

  /// Скинути налаштування до дефолтних
  Future<bool> resetToDefaults() async {
    AppLogger.w('Resetting preferences to defaults');
    return await savePreferences(const UserPreferences());
  }

  /// Очистити всі налаштування
  Future<bool> clearPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      AppLogger.w('Clearing all shared preferences');
      return await prefs.remove(_prefsKey);
    } catch (e, stack) {
      AppLogger.e('Error clearing preferences', e, stack);
      return false;
    }
  }
}