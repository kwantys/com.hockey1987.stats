import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorites_store.dart';

/// Сервіс для роботи з улюбленими іграми
class FavoritesService {
  static const String _favoritesKey = 'favorites_store';

  /// Завантажити favorites
  Future<FavoritesStore> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_favoritesKey);

      if (jsonString == null) {
        return const FavoritesStore();
      }

      return FavoritesStore.fromJsonString(jsonString);
    } catch (e) {
      return const FavoritesStore();
    }
  }

  /// Зберегти favorites
  Future<bool> saveFavorites(FavoritesStore favorites) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = favorites.toJsonString();
      return await prefs.setString(_favoritesKey, jsonString);
    } catch (e) {
      return false;
    }
  }

  /// Додати гру до улюблених
  Future<bool> addFavoriteGame(int gameId) async {
    final favorites = await loadFavorites();
    final updated = favorites.addFavoriteGame(gameId);
    return await saveFavorites(updated);
  }

  /// Видалити гру з улюблених
  Future<bool> removeFavoriteGame(int gameId) async {
    final favorites = await loadFavorites();
    final updated = favorites.removeFavoriteGame(gameId);
    return await saveFavorites(updated);
  }

  /// Перемкнути статус улюбленої гри
  Future<bool> toggleFavoriteGame(int gameId) async {
    final favorites = await loadFavorites();
    final updated = favorites.toggleFavoriteGame(gameId);
    return await saveFavorites(updated);
  }

  /// Увімкнути сповіщення для гри
  Future<bool> enableAlertsForGame(int gameId) async {
    final favorites = await loadFavorites();
    final updated = favorites.enableAlertsForGame(gameId);
    return await saveFavorites(updated);
  }

  /// Вимкнути сповіщення для гри
  Future<bool> disableAlertsForGame(int gameId) async {
    final favorites = await loadFavorites();
    final updated = favorites.disableAlertsForGame(gameId);
    return await saveFavorites(updated);
  }

  /// Перемкнути сповіщення для гри
  Future<bool> toggleAlertsForGame(int gameId) async {
    final favorites = await loadFavorites();
    final updated = favorites.toggleAlertsForGame(gameId);
    return await saveFavorites(updated);
  }

  /// Чи гра в улюблених
  Future<bool> isFavorite(int gameId) async {
    final favorites = await loadFavorites();
    return favorites.isFavorite(gameId);
  }

  /// Чи увімкнені сповіщення для гри
  Future<bool> hasAlerts(int gameId) async {
    final favorites = await loadFavorites();
    return favorites.hasAlerts(gameId);
  }

  /// Очистити всі favorites
  Future<bool> clearFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_favoritesKey);
    } catch (e) {
      return false;
    }
  }
}