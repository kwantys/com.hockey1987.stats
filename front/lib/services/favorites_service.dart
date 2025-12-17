import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorites_store.dart';

/// Сервіс для роботи з улюбленими іграми та командами
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

  // ========== МЕТОДИ ДЛЯ ІГОР ==========

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
    return favorites.isFavoriteGame(gameId);
  }

  /// Чи увімкнені сповіщення для гри
  Future<bool> hasAlerts(int gameId) async {
    final favorites = await loadFavorites();
    return favorites.hasAlertsForGame(gameId);
  }

  // ========== МЕТОДИ ДЛЯ КОМАНД (ДОДАНО) ==========

  /// Додати команду до улюблених
  Future<bool> addFavoriteTeam(int teamId) async {
    final favorites = await loadFavorites();
    final updated = favorites.addFavoriteTeam(teamId);
    return await saveFavorites(updated);
  }

  /// Видалити команду з улюблених
  Future<bool> removeFavoriteTeam(int teamId) async {
    final favorites = await loadFavorites();
    final updated = favorites.removeFavoriteTeam(teamId);
    return await saveFavorites(updated);
  }

  /// Перемкнути статус улюбленої команди
  Future<bool> toggleFavoriteTeam(int teamId) async {
    final favorites = await loadFavorites();
    final updated = favorites.toggleFavoriteTeam(teamId);
    return await saveFavorites(updated);
  }

  /// Чи команда в улюблених
  Future<bool> isFavoriteTeam(int teamId) async {
    final favorites = await loadFavorites();
    return favorites.isFavoriteTeam(teamId);
  }

  /// Отримати список улюблених команд
  Future<List<int>> getFavoriteTeams() async {
    final favorites = await loadFavorites();
    return favorites.favoriteTeams;
  }

  /// Отримати список улюблених ігор
  Future<List<int>> getFavoriteGames() async {
    final favorites = await loadFavorites();
    return favorites.favoriteGames;
  }

  // ========== ЗАГАЛЬНІ МЕТОДИ ==========

  /// Очистити всі favorites
  Future<bool> clearFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_favoritesKey);
    } catch (e) {
      return false;
    }
  }

  /// Очистити тільки ігри
  Future<bool> clearFavoriteGames() async {
    final favorites = await loadFavorites();
    final updated = favorites.copyWith(
      favoriteGames: [],
      gamesWithAlerts: [],
    );
    return await saveFavorites(updated);
  }

  /// Очистити тільки команди
  Future<bool> clearFavoriteTeams() async {
    final favorites = await loadFavorites();
    final updated = favorites.copyWith(favoriteTeams: []);
    return await saveFavorites(updated);
  }
}