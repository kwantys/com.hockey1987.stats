import 'dart:convert';

/// Модель для збереження улюблених ігор та налаштувань сповіщень
class FavoritesStore {
  final List<int> favoriteGames; // GameID улюблених ігор
  final List<int> gamesWithAlerts; // GameID ігор з увімкненими сповіщеннями

  const FavoritesStore({
    this.favoriteGames = const [],
    this.gamesWithAlerts = const [],
  });

  /// Створити копію з новими значеннями
  FavoritesStore copyWith({
    List<int>? favoriteGames,
    List<int>? gamesWithAlerts,
  }) {
    return FavoritesStore(
      favoriteGames: favoriteGames ?? this.favoriteGames,
      gamesWithAlerts: gamesWithAlerts ?? this.gamesWithAlerts,
    );
  }

  /// Додати гру до улюблених
  FavoritesStore addFavoriteGame(int gameId) {
    if (favoriteGames.contains(gameId)) {
      return this;
    }
    return copyWith(
      favoriteGames: [...favoriteGames, gameId],
    );
  }

  /// Видалити гру з улюблених
  FavoritesStore removeFavoriteGame(int gameId) {
    return copyWith(
      favoriteGames: favoriteGames.where((id) => id != gameId).toList(),
    );
  }

  /// Перемкнути статус улюбленої гри
  FavoritesStore toggleFavoriteGame(int gameId) {
    if (favoriteGames.contains(gameId)) {
      return removeFavoriteGame(gameId);
    } else {
      return addFavoriteGame(gameId);
    }
  }

  /// Увімкнути сповіщення для гри
  FavoritesStore enableAlertsForGame(int gameId) {
    if (gamesWithAlerts.contains(gameId)) {
      return this;
    }
    return copyWith(
      gamesWithAlerts: [...gamesWithAlerts, gameId],
    );
  }

  /// Вимкнути сповіщення для гри
  FavoritesStore disableAlertsForGame(int gameId) {
    return copyWith(
      gamesWithAlerts: gamesWithAlerts.where((id) => id != gameId).toList(),
    );
  }

  /// Перемкнути сповіщення для гри
  FavoritesStore toggleAlertsForGame(int gameId) {
    if (gamesWithAlerts.contains(gameId)) {
      return disableAlertsForGame(gameId);
    } else {
      return enableAlertsForGame(gameId);
    }
  }

  /// Чи гра в улюблених
  bool isFavorite(int gameId) => favoriteGames.contains(gameId);

  /// Чи увімкнені сповіщення для гри
  bool hasAlerts(int gameId) => gamesWithAlerts.contains(gameId);

  /// Конвертувати в JSON
  Map<String, dynamic> toJson() {
    return {
      'favoriteGames': favoriteGames,
      'gamesWithAlerts': gamesWithAlerts,
    };
  }

  /// Створити з JSON
  factory FavoritesStore.fromJson(Map<String, dynamic> json) {
    return FavoritesStore(
      favoriteGames: (json['favoriteGames'] as List?)
          ?.map((e) => e as int)
          .toList() ??
          [],
      gamesWithAlerts: (json['gamesWithAlerts'] as List?)
          ?.map((e) => e as int)
          .toList() ??
          [],
    );
  }

  /// Конвертувати в String для збереження
  String toJsonString() => jsonEncode(toJson());

  /// Створити з String
  factory FavoritesStore.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return FavoritesStore.fromJson(json);
  }

  @override
  String toString() {
    return 'FavoritesStore(favorites: ${favoriteGames.length}, '
        'alerts: ${gamesWithAlerts.length})';
  }
}