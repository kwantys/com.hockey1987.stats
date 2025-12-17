import 'package:flutter/foundation.dart'; // Додайте цей імпорт!
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorites_store.dart';

/// Сервіс для роботи з улюбленими іграми, командами та гравцями
class FavoritesService {
  static const String _favoritesKey = 'favorites_store';

  // !!! НОВЕ: Сповіщувач про зміни. Статичний, щоб був доступний всюди.
  static final ValueNotifier<int> updateNotifier = ValueNotifier(0);

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
      final result = await prefs.setString(_favoritesKey, jsonString);

      // !!! НОВЕ: Сповіщаємо слухачів, що дані змінилися
      if (result) {
        updateNotifier.value++;
      }

      return result;
    } catch (e) {
      return false;
    }
  }

  // ========== МЕТОДИ ДЛЯ ІГОР ==========

  Future<bool> addFavoriteGame(int gameId) async {
    final favorites = await loadFavorites();
    final updated = favorites.addFavoriteGame(gameId);
    return await saveFavorites(updated);
  }

  Future<bool> removeFavoriteGame(int gameId) async {
    final favorites = await loadFavorites();
    final updated = favorites.removeFavoriteGame(gameId);
    return await saveFavorites(updated);
  }

  Future<bool> toggleFavoriteGame(int gameId) async {
    final favorites = await loadFavorites();
    final updated = favorites.toggleFavoriteGame(gameId);
    return await saveFavorites(updated);
  }

  Future<bool> enableAlertsForGame(int gameId) async {
    final favorites = await loadFavorites();
    final updated = favorites.enableAlertsForGame(gameId);
    return await saveFavorites(updated);
  }

  Future<bool> disableAlertsForGame(int gameId) async {
    final favorites = await loadFavorites();
    final updated = favorites.disableAlertsForGame(gameId);
    return await saveFavorites(updated);
  }

  Future<bool> toggleAlertsForGame(int gameId) async {
    final favorites = await loadFavorites();
    final updated = favorites.toggleAlertsForGame(gameId);
    return await saveFavorites(updated);
  }

  Future<bool> isFavorite(int gameId) async {
    final favorites = await loadFavorites();
    return favorites.isFavoriteGame(gameId);
  }

  Future<bool> hasAlerts(int gameId) async {
    final favorites = await loadFavorites();
    return favorites.hasAlertsForGame(gameId);
  }

  Future<List<int>> getFavoriteGames() async {
    final favorites = await loadFavorites();
    return favorites.favoriteGames;
  }

  Future<List<int>> getGamesWithAlerts() async {
    final favorites = await loadFavorites();
    return favorites.gamesWithAlerts;
  }

  // ========== МЕТОДИ ДЛЯ КОМАНД ==========

  Future<bool> addFavoriteTeam(int teamId) async {
    final favorites = await loadFavorites();
    final updated = favorites.addFavoriteTeam(teamId);
    return await saveFavorites(updated);
  }

  Future<bool> removeFavoriteTeam(int teamId) async {
    final favorites = await loadFavorites();
    final updated = favorites.removeFavoriteTeam(teamId);
    return await saveFavorites(updated);
  }

  Future<bool> toggleFavoriteTeam(int teamId) async {
    final favorites = await loadFavorites();
    final updated = favorites.toggleFavoriteTeam(teamId);
    return await saveFavorites(updated);
  }

  Future<bool> isFavoriteTeam(int teamId) async {
    final favorites = await loadFavorites();
    return favorites.isFavoriteTeam(teamId);
  }

  Future<List<int>> getFavoriteTeams() async {
    final favorites = await loadFavorites();
    return favorites.favoriteTeams;
  }

  // ========== МЕТОДИ ДЛЯ ГРАВЦІВ ==========

  Future<bool> addFavoritePlayer(int playerId) async {
    final favorites = await loadFavorites();
    final updated = favorites.addFavoritePlayer(playerId);
    return await saveFavorites(updated);
  }

  Future<bool> removeFavoritePlayer(int playerId) async {
    final favorites = await loadFavorites();
    final updated = favorites.removeFavoritePlayer(playerId);
    return await saveFavorites(updated);
  }

  Future<bool> toggleFavoritePlayer(int playerId) async {
    final favorites = await loadFavorites();
    final updated = favorites.toggleFavoritePlayer(playerId);
    return await saveFavorites(updated);
  }

  Future<bool> isFavoritePlayer(int playerId) async {
    final favorites = await loadFavorites();
    return favorites.isFavoritePlayer(playerId);
  }

  Future<List<int>> getFavoritePlayers() async {
    final favorites = await loadFavorites();
    return favorites.favoritePlayers;
  }

  // ========== ЗАГАЛЬНІ МЕТОДИ ==========

  Future<bool> clearFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_favoritesKey);
    } catch (e) {
      return false;
    }
  }
}